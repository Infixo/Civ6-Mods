--------------------------------------------------------------
-- Real Era Stop
-- Author: Infixo
-- Mar 9, 2017: Version 1
--		Unfortunately, disconnecting techs doesn't work - the game finds them available to research, same as initial ones from Ancient Era
--		Can delete them completely - the game doesn't break
--		BUT must also delete all related objects as game finds them also available to build
--		Other things to consider:
--			- There's one Government available in Medieval - removed, if Medieval is last Era
--			- Must add Future Civic to finish Civic tree (will make things much easier)
-- Mar 13, 2017: Version 1.2 & 1.3
--		Added support for ATOMIC Era
--		Removed connections to Future Society from Lev3 Governments (like in Vanilla game, you don't have to choose any to progress further)
-- Mar 18, 2017: Version 1.4
--		Added removal of Great People since they can be recruited despite the fact that they are from later Eras
--		Fixed ENGLAND CTD
--		Added some clean-up related to modifiers (e.g. Policies that affect buildings from later Eras)
-- Mar 22, 2017: Version 1.5
--		Fixed CTD when building an Archaeologist due to missing SHIPWRECK resource
-- Mar 23, 2017: Version 1.6
--		Added support for CLASSICAL Era
-- Mar 25, 2017: Version 1.7
--		Tweak for Crossing Oceans ability for Medieval and Classical. Without it some maps are unplayable (cannot cross oceans).
--		For Medieval - move CARTOGRAPHY to Medieval, without a Caravel
--		For Classical - move ability 'can cross oceans' to SHIPBUILDING (from CARTOGRAPHY),
--						'allows all land units to embark' to CELESTIAL_NAVIGATION (from SHIPBUILDING)
-- March 28, 2017: Version 2.1
--      Update for Spring 2017 Patch (game's Future Civic will be used)
-- April 17, 2017: Version 2.2
--		Fix for Industrial Zone Projects when Classical Era is last
-- 		Fix for Collosal Heads instead of Goody Huts when Classical is last - must NOT remove Lumber Mills since the MapUtilities.lua uses RowId as Index of the Goody Hut,
--			so there must not be any empty spaces; it will be moved to Engineering in that case
-- April 17, 2017: Version 2.3
--		Proper handling of some Great People bonuses that depend on Era (Eurekas for specifc or random boosts mostly, unit granting)
-- February 21, 2019: Version 2.4 / 2.5
--		Gathering Storm update. Fix for Railroads being built by a Trader.
-- August 30, 2020: Version 3.0
--      Mod config via Advanced Options
--------------------------------------------------------------


--------------------------------------------------------------
-- PREPARATIONS
--------------------------------------------------------------

-- We will delete all Eras AFTER the last one
CREATE VIEW RESEras AS
SELECT EraType
FROM Eras
WHERE ChronologyIndex > (SELECT Value FROM GlobalParameters WHERE Name = 'RES_MAX_ERA');

CREATE VIEW RESTechnologies AS
SELECT TechnologyType
FROM Technologies
WHERE EraType IN (SELECT EraType FROM RESEras);

CREATE VIEW RESCivics AS
SELECT CivicType
FROM Civics
WHERE EraType IN (SELECT EraType FROM RESEras);

--------------------------------------------------------------
-- CIVILIZATIONS
-- What to do with UU/UB that are going to be removed?
-- America's UB - Film Studio (Broadcast Tower)
-- America's UU - P-51 Mustang (Fighter)
-- Brazil's UU - Minas Geraes (Battleship)
-- England's UU - Sea Dog (Privateer)
-- France's UU - Garde Imperiale
-- Germany's UU - U-Boat (Submarine)
-- Japan's UB - Electronics Factory
--------------------------------------------------------------

--------------------------------------------------------------
-- TECH TREE
--------------------------------------------------------------

-- Version 1.7 Ocean Crossing Fix (for Medieval) - move CARTOGRAPHY to Medieval
UPDATE Technologies
SET EraType = 'ERA_MEDIEVAL'
WHERE TechnologyType = 'TECH_CARTOGRAPHY' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '3');
-- same column (=Cost)as EDUCATION
UPDATE Technologies
SET Cost = (SELECT Cost FROM Technologies WHERE TechnologyType = 'TECH_EDUCATION')
WHERE TechnologyType = 'TECH_CARTOGRAPHY' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '3');
-- replace Prereqs
DELETE FROM TechnologyPrereqs
WHERE Technology = 'TECH_CARTOGRAPHY' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '3');
INSERT INTO TechnologyPrereqs (Technology, PrereqTech)
SELECT 'TECH_CARTOGRAPHY', 'TECH_SHIPBUILDING' FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '3';
INSERT INTO TechnologyPrereqs (Technology, PrereqTech)
SELECT 'TECH_CARTOGRAPHY', 'TECH_APPRENTICESHIP' FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '3';
-- Caravels cannot be available - move them to any Renaissance tech, will be removed anyway
UPDATE Units
SET PrereqTech = 'TECH_ASTRONOMY'
WHERE UnitType = 'UNIT_CARAVEL' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '3');

-- Connect Future Tech
-- We don't know where Future Tech will be, so we'll add to many Eras and remove unnecessary ones
INSERT INTO TechnologyPrereqs (Technology, PrereqTech)
VALUES
	-- Classical Verson 1.6
	('TECH_FUTURE_TECH', 'TECH_SHIPBUILDING'),
	('TECH_FUTURE_TECH', 'TECH_MATHEMATICS'),
	('TECH_FUTURE_TECH', 'TECH_ENGINEERING'),
	('TECH_FUTURE_TECH', 'TECH_HORSEBACK_RIDING'),
	('TECH_FUTURE_TECH', 'TECH_CONSTRUCTION'),
	-- Medieval
	('TECH_FUTURE_TECH', 'TECH_CARTOGRAPHY'),  -- Version 1.7 ocean crossing, CARTOGRAPHY moved to Medieval
	('TECH_FUTURE_TECH', 'TECH_EDUCATION'),
	('TECH_FUTURE_TECH', 'TECH_STIRRUPS'),
	('TECH_FUTURE_TECH', 'TECH_MILITARY_ENGINEERING'),
	('TECH_FUTURE_TECH', 'TECH_CASTLES'),
	-- Renaissance
	('TECH_FUTURE_TECH', 'TECH_SQUARE_RIGGING'),
	('TECH_FUTURE_TECH', 'TECH_ASTRONOMY'),
	('TECH_FUTURE_TECH', 'TECH_BANKING'),
	('TECH_FUTURE_TECH', 'TECH_METAL_CASTING'),
	('TECH_FUTURE_TECH', 'TECH_PRINTING'),
	('TECH_FUTURE_TECH', 'TECH_SIEGE_TACTICS'),
	-- Industrial
	('TECH_FUTURE_TECH', 'TECH_STEAM_POWER'),
	('TECH_FUTURE_TECH', 'TECH_SANITATION'),
	('TECH_FUTURE_TECH', 'TECH_ECONOMICS'),
	('TECH_FUTURE_TECH', 'TECH_RIFLING'),
	-- Modern
	('TECH_FUTURE_TECH', 'TECH_ELECTRICITY'),
	('TECH_FUTURE_TECH', 'TECH_RADIO'),
	('TECH_FUTURE_TECH', 'TECH_CHEMISTRY'),
	('TECH_FUTURE_TECH', 'TECH_REPLACEABLE_PARTS'),
	('TECH_FUTURE_TECH', 'TECH_COMBUSTION'),
	-- Atomic
	('TECH_FUTURE_TECH', 'TECH_COMPUTERS'),
	('TECH_FUTURE_TECH', 'TECH_ADVANCED_FLIGHT'),
	('TECH_FUTURE_TECH', 'TECH_ROCKETRY'),
	('TECH_FUTURE_TECH', 'TECH_NUCLEAR_FISSION'),
	('TECH_FUTURE_TECH', 'TECH_SYNTHETIC_MATERIALS');

-- Move Future Tech to correct Era and set it Cost to be 50% higher than the most expensive tech in Era
UPDATE Technologies
SET EraType = (SELECT EraType FROM Eras WHERE ChronologyIndex = (SELECT Value FROM GlobalParameters WHERE Name = 'RES_MAX_ERA')),
	Cost = 1.5 * (SELECT MAX(Cost) FROM Technologies WHERE EraType = (SELECT EraType FROM Eras WHERE ChronologyIndex = (SELECT Value FROM GlobalParameters WHERE Name = 'RES_MAX_ERA')))
WHERE TechnologyType = 'TECH_FUTURE_TECH';

-- Remove unnecessary Future Tech prereqs - ALL EXCEPT last Era
DELETE FROM TechnologyPrereqs
WHERE
	Technology = 'TECH_FUTURE_TECH' AND
	PrereqTech IN (
		SELECT TechnologyType
		FROM Technologies
		WHERE EraType IN (
			SELECT EraType
			FROM Eras
			WHERE ChronologyIndex <> (SELECT Value FROM GlobalParameters WHERE Name = 'RES_MAX_ERA')));

-- Special case for Medieval Tech connecting to Classical Era tech
/* Version 1.7 if we move CARTOGRAPHY to Medieval, there will be no need to connect FUTURE_TECH to earlier Eras
INSERT INTO TechnologyPrereqs (Technology, PrereqTech)
SELECT 'TECH_FUTURE_TECH', 'TECH_SHIPBUILDING'
FROM GlobalParameters
WHERE Name = 'RES_MAX_ERA' AND Value = '3';
*/
-- Remove Prereqs from Techs we'll never get into
DELETE FROM TechnologyPrereqs
WHERE Technology IN (SELECT TechnologyType FROM RESTechnologies);

-- Version 1.7 Ocean-crossing, when CARTOGRAPHY is still in Renaissance there will be unnecessary connection for FUTURE_TECH
DELETE FROM TechnologyPrereqs
WHERE Technology = 'TECH_FUTURE_TECH' AND PrereqTech = 'TECH_CARTOGRAPHY' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '4');

--------------------------------------------------------------
-- CIVIC TREE
--------------------------------------------------------------

/* Version 2.1
-- need a finishing Civic "Future Society"
INSERT INTO Types (Type, Kind) VALUES ('CIVIC_FUTURE_SOCIETY', 'KIND_CIVIC');
INSERT INTO Civics (CivicType, Name, Cost, Repeatable, Description, EraType, BarbarianFree, UITreeRow, AdvisorType)
VALUES ('CIVIC_FUTURE_SOCIETY', 'LOC_CIVIC_FUTURE_SOCIETY_NAME', 3500, 1, 'LOC_CIVIC_FUTURE_SOCIETY_DESCRIPTION', 'ERA_INFORMATION', 0, 0, 'ADVISOR_GENERIC');
*/

-- Connect Future Civic
-- We don't know where Future Civic will be, so we'll add to many Eras and remove unnecessary ones
INSERT INTO CivicPrereqs (Civic, PrereqCivic)
VALUES
	-- Classical V1.6
	('CIVIC_FUTURE_CIVIC', 'CIVIC_MILITARY_TRAINING'),
	('CIVIC_FUTURE_CIVIC', 'CIVIC_DEFENSIVE_TACTICS'),
	('CIVIC_FUTURE_CIVIC', 'CIVIC_RECORDED_HISTORY'),
	('CIVIC_FUTURE_CIVIC', 'CIVIC_THEOLOGY'),
	-- Medieval
	('CIVIC_FUTURE_CIVIC', 'CIVIC_MERCENARIES'),
	('CIVIC_FUTURE_CIVIC', 'CIVIC_MEDIEVAL_FAIRES'),
	('CIVIC_FUTURE_CIVIC', 'CIVIC_GUILDS'),
	('CIVIC_FUTURE_CIVIC', 'CIVIC_DIVINE_RIGHT'),
	-- Renaissance
	('CIVIC_FUTURE_CIVIC', 'CIVIC_MERCANTILISM'),
	('CIVIC_FUTURE_CIVIC', 'CIVIC_THE_ENLIGHTENMENT'),
	-- Industrial
	('CIVIC_FUTURE_CIVIC', 'CIVIC_NATURAL_HISTORY'),
	('CIVIC_FUTURE_CIVIC', 'CIVIC_URBANIZATION'),
	('CIVIC_FUTURE_CIVIC', 'CIVIC_SCORCHED_EARTH'),
	-- Modern
	('CIVIC_FUTURE_CIVIC', 'CIVIC_CONSERVATION'),
	('CIVIC_FUTURE_CIVIC', 'CIVIC_NUCLEAR_PROGRAM'),
	('CIVIC_FUTURE_CIVIC', 'CIVIC_CAPITALISM'),
--	('CIVIC_FUTURE_CIVIC', 'CIVIC_SUFFRAGE'),
--	('CIVIC_FUTURE_CIVIC', 'CIVIC_TOTALITARIANISM'),
--	('CIVIC_FUTURE_CIVIC', 'CIVIC_CLASS_STRUGGLE'),
	-- Atomic
	('CIVIC_FUTURE_CIVIC', 'CIVIC_CULTURAL_HERITAGE'),
	('CIVIC_FUTURE_CIVIC', 'CIVIC_RAPID_DEPLOYMENT'),
	('CIVIC_FUTURE_CIVIC', 'CIVIC_SPACE_RACE'),
	('CIVIC_FUTURE_CIVIC', 'CIVIC_PROFESSIONAL_SPORTS');

-- Move Future Civic to correct Era and set it Cost to be 50% higher than the most expensive civic in Era
UPDATE Civics
SET EraType = (SELECT EraType FROM Eras WHERE ChronologyIndex = (SELECT Value FROM GlobalParameters WHERE Name = 'RES_MAX_ERA')),
	Cost = 1.5 * (SELECT MAX(Cost) FROM Civics WHERE EraType = (SELECT EraType FROM Eras WHERE ChronologyIndex = (SELECT Value FROM GlobalParameters WHERE Name = 'RES_MAX_ERA')))
WHERE CivicType = 'CIVIC_FUTURE_CIVIC';

-- Remove unnecessary Future Civic prereqs - ALL EXCEPT last Era
DELETE FROM CivicPrereqs
WHERE
	Civic = 'CIVIC_FUTURE_CIVIC' AND
	PrereqCivic IN (
		SELECT CivicType
		FROM Civics
		WHERE EraType IN (
			SELECT EraType
			FROM Eras
			WHERE ChronologyIndex <> (SELECT Value FROM GlobalParameters WHERE Name = 'RES_MAX_ERA')));
	
-- Remove Prereqs from Civics we'll never get into
DELETE FROM CivicPrereqs
WHERE Civic IN (SELECT CivicType FROM RESCivics);


--------------------------------------------------------------
-- TWEAKS AND FIXES FOR NON-STANDARD SITUATIONS
--------------------------------------------------------------

-- For Medieval, we're gonna remove Monarchy; otherwise there will be 3 govs to close to Classical ones
-- move temp for Humanism - will be removed with all REN entries in a moment
UPDATE Governments SET PrereqCivic = 'CIVIC_HUMANISM' WHERE GovernmentType = 'GOVERNMENT_MONARCHY' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '3');

-- ENGLAND FIX (Version 1.4)
-- For Medieval, we're gonna remove England's Trait: TRAIT_CIVILIZATION_DOUBLE_ARCHAEOLOGY_SLOTS
-- It's trying to attach to Victoria a modifier with BuildintType='MUSEUM_ARTIFACT' which doesn't exist
--DELETE FROM CivilizationTraits WHERE TraitType = 'TRAIT_CIVILIZATION_DOUBLE_ARCHAEOLOGY_SLOTS' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '3');
-- Done differently, along with Modifiers clean-up.

-- ARCHAEOLOGIST FIX (Version 1.5)
-- need to move SHIPWRECK to a different Civic for Eras where he might be trained but Shipwrecks do not exists
-- for Industrial it will be the same time as Antiquity Sites appear, i.e. NATURAL_HISTORY
-- for Modern it will be CONSERVATION
UPDATE Resources SET PrereqCivic = 'CIVIC_NATURAL_HISTORY' 	WHERE ResourceType = 'RESOURCE_SHIPWRECK' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '5');
UPDATE Resources SET PrereqCivic = 'CIVIC_CONSERVATION' 	WHERE ResourceType = 'RESOURCE_SHIPWRECK' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '6');
UPDATE CivicModifiers SET CivicType = 'CIVIC_NATURAL_HISTORY' 	WHERE ModifierId = 'CIVIC_GENERATE_SEA_ANTIQUITIES' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '5');
UPDATE CivicModifiers SET CivicType = 'CIVIC_CONSERVATION' 		WHERE ModifierId = 'CIVIC_GENERATE_SEA_ANTIQUITIES' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '6');

-- OCEAN CROSSING FIX (Version 1.7)
-- For Classical - see description of changes at the top
UPDATE Technologies SET EmbarkUnitType = NULL
WHERE TechnologyType = 'TECH_CELESTIAL_NAVIGATION' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '2');
UPDATE Technologies SET EmbarkAll = 1
WHERE TechnologyType = 'TECH_CELESTIAL_NAVIGATION' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '2');
UPDATE Technologies SET EmbarkAll = 0
WHERE TechnologyType = 'TECH_SHIPBUILDING' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '2');
UPDATE TechnologyModifiers SET TechnologyType = 'TECH_SHIPBUILDING'
WHERE TechnologyType = 'TECH_CARTOGRAPHY' AND ModifierId = 'CARTOGRAPHY_GRANT_OCEAN_NAVIGATION' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '2');

-- GOODY HUT FIX (Version 2.2) for Classical
UPDATE Improvements SET PrereqTech = 'TECH_ENGINEERING'
WHERE ImprovementType = 'IMPROVEMENT_LUMBER_MILL' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '2');


--------------------------------------------------------------
-- GREAT PEOPLE, Version 2.3
-- This section updates Great People bonuses so they will not become invalid because an Era is removed
-- Basically 3 groups: eurekas for specific techs, eurekas for random techs and creating a unit
--------------------------------------------------------------

CREATE TABLE RESModifierArgumentsUpdate (
	LastEra		TEXT NOT NULL,
    ModifierId  TEXT NOT NULL,
    Name        TEXT NOT NULL,
    NewValue    TEXT NOT NULL,
    PRIMARY KEY (LastEra, ModifierId, Name),
    FOREIGN KEY (ModifierId) REFERENCES Modifiers (ModifierId) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO RESModifierArgumentsUpdate (LastEra, ModifierId, Name, NewValue)
VALUES
	-- MODIFIER_PLAYER_GRANT_SPECIFIC_TECH_BOOST
	('3', 'GREATPERSON_PRINTINGTECHBOOST',  'TechType', 'TECH_EDUCATION'),  -- TECH_PRINTING, Bi Sheng
	('5', 'GREATPERSON_COMPUTERSTECHBOOST', 'TechType', 'TECH_ECONOMICS'),  -- TECH_COMPUTERS, Ada Lovelace
	('5', 'GREATPERSON_CHEMISTRYTECHBOOST', 'TechType', 'TECH_SCIENTIFIC_THEORY'),  -- TECH_CHEMISTRY, Dmitri Mendeleev
	('6', 'GREATPERSON_COMPUTERSTECHBOOST', 'TechType', 'TECH_ELECTRICITY'),  -- TECH_COMPUTERS, Ada Lovelace and Alan Turing
	('6', 'GREATPERSON_ROCKETRYTECHBOOST',  'TechType', 'TECH_CHEMISTRY'),  -- TECH_ROCKETRY, Robert Goddard
	-- MODIFIER_PLAYER_GRANT_RANDOM_TECHNOLOGY_BOOST_BY_ERA
	('2', 'GREATPERSON_3CLASSICALMEDIEVALTECHBOOSTS', 	'EndEraType', 'ERA_CLASSICAL'),  -- ERA_MEDIEVAL, ARYABHATA
	('2', 'GREATPERSON_1MEDIEVALTECHBOOST', 			'StartEraType', 'ERA_CLASSICAL'),  -- ERA_MEDIEVAL, EUCLID
	('2', 'GREATPERSON_1MEDIEVALTECHBOOST', 			'EndEraType', 'ERA_CLASSICAL'),  -- ERA_MEDIEVAL, EUCLID
	('3', 'GREATPERSON_1MEDIEVALRENAISSANCETECHBOOST', 	'EndEraType', 'ERA_MEDIEVAL'),  -- ERA_RENAISSANCE, ABU_AL_QASIM_AL_ZAHRAWI
	('3', 'GREATPERSON_1MEDIEVALRENAISSANCECIVICBOOST', 'EndEraType', 'ERA_MEDIEVAL'),  -- ERA_RENAISSANCE, OMAR_KHAYYAM
	('3', 'GREATPERSON_2MEDIEVALRENAISSANCETECHBOOSTS', 'EndEraType', 'ERA_MEDIEVAL'),  -- ERA_RENAISSANCE, OMAR_KHAYYAM
	('4', 'GREATPERSON_3RENAISSANCEINDUSTRIALTECHBOOSTS', 'EndEraType', 'ERA_RENAISSANCE'),  -- ERA_INDUSTRIAL, EMILIE_DU_CHATELET
	('4', 'GREATPERSON_1MODERNTECHBOOST', 				'StartEraType', 'ERA_RENAISSANCE'),  -- ERA_MODERN, LEONARDO_DA_VINCI
	('4', 'GREATPERSON_1MODERNTECHBOOST', 				'EndEraType', 'ERA_RENAISSANCE'),  -- ERA_MODERN, LEONARDO_DA_VINCI
	('5', 'GREATPERSON_2INDUSTRIALMODERNTECHBOOSTS', 	'EndEraType', 'ERA_INDUSTRIAL'),  -- ERA_MODERN
	('6', 'GREATPERSON_1MODERNATOMICTECHBOOST', 		'EndEraType', 'ERA_MODERN'),  -- ERA_ATOMIC
	('6', 'BUILDING_BROADWAY_RANDOMCIVICBOOST', 		'StartEraType', 'ERA_MODERN'),  -- ERA_ATOMIC
	('6', 'BUILDING_BROADWAY_RANDOMCIVICBOOST', 		'EndEraType', 'ERA_MODERN'),  -- ERA_ATOMIC
	('7', 'GREATPERSON_3ATOMICINFORMATIONTECHBOOSTS',	'EndEraType', 'ERA_ATOMIC'),  -- ERA_INFORMATION
	('7', 'GREATPERSON_GRACE_HOPPER_ACTIVE', 			'EndEraType', 'ERA_ATOMIC'),  -- ERA_INFORMATION
	-- MODIFIER_PLAYER_UNIT_GRANT_UNIT_WITH_EXPERIENCE
	('4', 'GREATPERSON_YI_SUN_SIN_ACTIVE', 'UnitType', 'UNIT_CARAVEL');  -- UNIT_IRONCLAD, YI_SUN_SIN

-- r2u = rows to update, temporary view
WITH r2u (rowident, newvalue) AS (
	SELECT ModifierId||Name, NewValue
	FROM RESModifierArgumentsUpdate
	WHERE LastEra = (SELECT Value FROM GlobalParameters WHERE Name = 'RES_MAX_ERA')
)
UPDATE ModifierArguments
SET Value = (SELECT newvalue FROM r2u WHERE ModifierArguments.ModifierId||ModifierArguments.Name = rowident)
WHERE ModifierId||Name IN (SELECT rowident FROM r2u);
