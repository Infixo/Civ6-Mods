--------------------------------------------------------------
-- Real Game Balance
-- Author: Infixo
-- 2019-04-14: Created
--------------------------------------------------------------
-- Credits
-- Original scripts created by Olleus for 8 Ages of Pace.
-- Original idea by alpaca and Gedemon.
--------------------------------------------------------------



--------------------------------------------------------------
-- Decrease Science and Culture from population
UPDATE GlobalParameters SET Value = '40' WHERE Name = 'SCIENCE_PERCENTAGE_YIELD_PER_POP'; -- base game 70, rise & fall 50
UPDATE GlobalParameters SET Value = '30' WHERE Name = 'CULTURE_PERCENTAGE_YIELD_PER_POP'; -- default is 30

-- Boosts, base game 50, rise & fall 40, real tech tree 35
UPDATE Boosts SET Boost = 30;

-- Era Score
UPDATE GlobalParameters SET Value = '12' WHERE Name = 'DARK_AGE_SCORE_BASE_THRESHOLD';       -- default 12
UPDATE GlobalParameters SET Value = '30' WHERE Name = 'GOLDEN_AGE_SCORE_BASE_THRESHOLD';     -- default 24
UPDATE GlobalParameters SET Value = '-6' WHERE Name = 'THRESHOLD_SHIFT_PER_PAST_DARK_AGE';   -- default -5
UPDATE GlobalParameters SET Value =  '6' WHERE Name = 'THRESHOLD_SHIFT_PER_PAST_GOLDEN_AGE'; -- default 5
UPDATE GlobalParameters SET Value =  '2' WHERE Name = 'THRESHOLD_SHIFT_PER_CITY';            -- default 1



-- Temporary table, drop at the end
-- Scale is a percentage
CREATE TABLE RGBTechIncrease
(
	EraType TEXT NOT NULL,
	Scale INTEGER NOT NULL DEFAULT 100,
	FOREIGN KEY (EraType) REFERENCES Eras(EraType) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE RGBCivicIncrease
(
	EraType TEXT NOT NULL,
	Scale INTEGER NOT NULL DEFAULT 100,
	FOREIGN KEY (EraType) REFERENCES Eras(EraType) ON DELETE CASCADE ON UPDATE CASCADE
);


-- please note that these parameters are balanced for Emperor difficulty
-- 50% of AI civs hits the mark within given timeframe

INSERT INTO RGBTechIncrease	VALUES
("ERA_ANCIENT",     115), -- 11, 75 turns
("ERA_CLASSICAL",   150), -- 19, 60 turns
("ERA_MEDIEVAL",    130), -- 27, 60 turns
("ERA_RENAISSANCE", 150), -- 36, 60 turns
("ERA_INDUSTRIAL",  175), -- 44, 60 turns
("ERA_MODERN",      200), -- 52, 50 turns
("ERA_ATOMIC",      210), -- 60, 50 turns
("ERA_INFORMATION", 220), -- 69, 45 turns
("ERA_FUTURE",      230); -- 77, 40 turns

INSERT INTO RGBCivicIncrease VALUES
("ERA_ANCIENT",     160), --  7, 75 turns
("ERA_CLASSICAL",   130), -- 14, 60 turns
("ERA_MEDIEVAL",    130), -- 21, 60 turns
("ERA_RENAISSANCE", 150), -- 27, 60 turns
("ERA_INDUSTRIAL",  175), -- 34, 60 turns
("ERA_MODERN",      200), -- 42, 50 turns (2/3 gov)
("ERA_ATOMIC",      225), -- 47, 50 turns
("ERA_INFORMATION", 250), -- 53, 45 turns (2/3 gov)
("ERA_FUTURE",      275); -- 59, 40 turns


-- Technologies cost
UPDATE Technologies
SET Cost = ROUND(Cost*(SELECT RGBTechIncrease.Scale FROM RGBTechIncrease WHERE RGBTechIncrease.EraType = Technologies.EraType)/100);
UPDATE TechnologyRandomCosts
SET Cost = ROUND(Cost*(SELECT RGBTechIncrease.Scale FROM RGBTechIncrease WHERE RGBTechIncrease.EraType = (
	SELECT Technologies.EraType FROM Technologies WHERE Technologies.TechnologyType = TechnologyRandomCosts.TechnologyType))/100);
		
-- Civics cost
UPDATE Civics
SET Cost = ROUND(Cost*(SELECT RGBCivicIncrease.Scale FROM RGBCivicIncrease WHERE RGBCivicIncrease.EraType = Civics.EraType)/100);
UPDATE CivicRandomCosts
SET Cost = ROUND(Cost*(SELECT RGBCivicIncrease.Scale FROM RGBCivicIncrease WHERE RGBCivicIncrease.EraType = (
	SELECT Civics.EraType FROM Civics WHERE Civics.CivicType = CivicRandomCosts.CivicType))/100);


-- Great People Cost
-- Based on feedback, increase is 40% of the values above
UPDATE Eras SET GreatPersonBaseCost = ROUND(GreatPersonBaseCost*(SELECT RGBTechIncrease.Scale FROM RGBTechIncrease WHERE RGBTechIncrease.EraType = Eras.EraType)/250);


-- Increase the one off science/culture given by great people
-- This is complicated because the effects of GP is not defined uniquely per great person
-- and the table structure is very strange indeed.
-- Therefore have to look up each effect and see whether it needs to be boosted,
-- and then check which great person first calls it to know how much to boost it by.
-- (NB: this means that if several great people have the same ability, it will be scaled up according
-- to the first era it is used. Not that this happens anyway in vanilla)
/*
GREATPERSON_ADJACENT_NATURALWONDER_SCIENCE Darwin Gain 500 Science (on Standard speed) for each Natural Wonder tile here or adjacent. => 1 tile = 60%, 2 tiles = 120%
GREATPERSON_ADJACENT_DESERTMOUNTAIN_SCIENCE Galileo Gain 250 Science (on Standard speed) for each adjacent Mountain tile. => 2 tiles = 90%, 3 tiles = 135%
GREATPERSON_ADJACENT_GRASSMOUNTAIN_SCIENCE Galileo
GREATPERSON_ADJACENT_PLAINSMOUNTAIN_SCIENCE Galileo
GREATPERSON_ADJACENT_SNOWMOUNTAIN_SCIENCE Galileo
GREATPERSON_ADJACENT_TUNDRAMOUNTAIN_SCIENCE Galileo
GREATPERSON_ADJACENT_RAINFOREST_SCIENCE Janaki Ammal Gain 400 Science for each Rainforest tile here or adjacent => 3 tiles = 85%, 4 tiles = 115%
GREATPERSON_ARTIFACT_SCIENCE Mary Leakey Gain 350 Science for every Artifact in this city.  => 75% max
*/
-- Create a temporary table of which Modifiers to be scaled are called in which era
WITH ModIncreases AS
(
	SELECT Mods1.ModifierId, RGBTechIncrease.Scale FROM ModifierArguments AS Mods1, RGBTechIncrease
	INNER JOIN ModifierArguments AS Mods2,
			   GreatPersonIndividualActionModifiers AS GPMods,
			   GreatPersonIndividuals AS GPs
	ON Mods1.ModifierId = Mods2.ModifierId
	AND Mods1.Type = "ScaleByGameSpeed"
	AND Mods2.Name = "YieldType"
	AND Mods2.Value = "YIELD_SCIENCE"
	AND GPMods.ModifierID = Mods1.ModifierID
	AND GPMods.GreatPersonIndividualType = GPs.GreatPersonIndividualType
	AND RGBTechIncrease.EraType = GPs.EraType
)

/* NOTHING HERE */

-- Update the modifiers if they are in the table above by the lowest amount listed above
UPDATE ModifierArguments
	SET Value = ROUND(Value*(SELECT MIN(ModIncreases.Scale) 
					FROM ModIncreases
					WHERE ModIncreases.ModifierId = ModifierArguments.ModifierID)/100)
	WHERE EXISTS ( SELECT *
				FROM ModIncreases
				WHERE ModIncreases.ModifierId = ModifierArguments.ModifierID)
	AND ModifierArguments.Name = "Amount";
	
-- Create a temporary table of which Modifiers to be scaled are called in which era
WITH ModIncreases AS
(
	SELECT Mods1.ModifierId, RGBCivicIncrease.Scale FROM ModifierArguments AS Mods1, RGBCivicIncrease
	INNER JOIN ModifierArguments AS Mods2,
			   GreatPersonIndividualActionModifiers AS GPMods,
			   GreatPersonIndividuals AS GPs
	ON Mods1.ModifierId = Mods2.ModifierId
	AND Mods1.Type = "ScaleByGameSpeed"
	AND Mods2.Name = "YieldType"
	AND Mods2.Value = "YIELD_CULTURE"
	AND GPMods.ModifierID = Mods1.ModifierID
	AND GPMods.GreatPersonIndividualType = GPs.GreatPersonIndividualType
	AND RGBCivicIncrease.EraType = GPs.EraType
)

-- Update the modifiers if they are in the table above by the lowest amount listed above
UPDATE ModifierArguments
	SET Value = ROUND(Value*(SELECT MIN(ModIncreases.Scale) 
					FROM ModIncreases
					WHERE ModIncreases.ModifierId = ModifierArguments.ModifierID)/100)
	WHERE EXISTS ( SELECT *
				FROM ModIncreases
				WHERE ModIncreases.ModifierId = ModifierArguments.ModifierID)
	AND ModifierArguments.Name = "Amount";


--------------------------------------------------------------
-- Climate Change adjustments

--CO2 for Temp Increase adjusmtent
UPDATE Maps_XP2 SET CO2For1DegreeTempRise=CO2For1DegreeTempRise*2; -- 3.75 in updated 8AoP

/*
UPDATE Maps_XP2 SET CO2For1DegreeTempRise = 750000 WHERE MapSizeType = 'MAPSIZE_DUEL'; --Original value 500000
UPDATE Maps_XP2 SET CO2For1DegreeTempRise = 1500000 WHERE MapSizeType = 'MAPSIZE_TINY'; --Original value 1000000
UPDATE Maps_XP2 SET CO2For1DegreeTempRise = 2250000 WHERE MapSizeType = 'MAPSIZE_SMALL'; --Original value 150000
UPDATE Maps_XP2 SET CO2For1DegreeTempRise = 3000000 WHERE MapSizeType = 'MAPSIZE_STANDARD'; --Original value 2000000
UPDATE Maps_XP2 SET CO2For1DegreeTempRise = 3750000 WHERE MapSizeType = 'MAPSIZE_LARGE'; --Original value 2500000
UPDATE Maps_XP2 SET CO2For1DegreeTempRise = 4500000 WHERE MapSizeType = 'MAPSIZE_HUGE'; --Original value 3000000

--CO2 Emissions Adjustment
UPDATE Resource_Consumption SET CO2perkWh = 328 WHERE ResourceType = 'RESOURCE_COAL'; --Original value 820
UPDATE Resource_Consumption SET CO2perkWh = 196 WHERE ResourceType = 'RESOURCE_OIL'; --Original value 490
UPDATE Resource_Consumption SET CO2perkWh = 20 WHERE ResourceType = 'RESOURCE_URANIUM'; --Original value 48
*/

--------------------------------------------------------------
--World Congress
UPDATE GlobalParameters SET Value = 3 WHERE Name = 'WORLD_CONGRESS_INITIAL_ERA'; -- original 2

--UPDATE GlobalParameters SET Value = 40 WHERE Name = 'WORLD_CONGRESS_MAX_TIME_BETWEEN_MEETINGS'; --Original value 30
--UPDATE GlobalParameters SET Value = 20 WHERE Name = 'WORLD_CONGRESS_MIN_TIME_BETWEEN_SPECIAL_SESSIONS'; --Original value 15
	
	
-- Drop the temporary table created at the start
--DROP TABLE EraIncreases;
