--------------------------------------------------------------
-- Real Fixes
-- Author: Infixo
-- 2018-03-25: Created, Typos in Traits and AiFavoredItems, integrated existing mods
--------------------------------------------------------------

-- Traits
UPDATE Traits SET Name = 'LOC_TRAIT_LEADER_UNIT_ENGLISH_REDCOAT_NAME'      WHERE Name = 'LOC_TRAIT_LEADER_TRAIT_LEADER_UNIT_ENGLISH_REDCOAT_NAME'; -- typo
UPDATE Traits SET Name = 'LOC_TRAIT_LEADER_UNIT_NORWEGIAN_LONGSHIP_NAME'   WHERE Name = 'LOC_TRAIT_LEADER_TRAIT_LEADER_UNIT_NORWEGIAN_LONGSHIP_NAME'; -- typo
UPDATE Traits SET Name = 'LOC_TRAIT_LEADER_UNIT_AMERICAN_ROUGH_RIDER_NAME' WHERE Name = 'LOC_TRAIT_LEADER_TRAIT_LEADER_UNIT_AMERICAN_ROUGH_RIDER_NAME'; -- typo
UPDATE Traits SET Name = 'LOC_TRAIT_CIVILIZATION_UNIT_HETAIROI_NAME'       WHERE Name = 'LOC_TRAIT_LEADER_UNIT_HETAIROI_NAME'; -- different LOC defined

-- AiFavoredItems
UPDATE AiFavoredItems SET Item = 'CIVIC_NAVAL_TRADITION' WHERE Item = 'CIVIC_NAVAL_TRADITIION';
DELETE FROM AiFavoredItems WHERE Item = 'CIVIC_IMPERIALISM'; -- this is the only item defined for that list, and it is not existing in Civics, no idea what the author had in mind

-- Ai Strategy Medieval Fixes
UPDATE StrategyConditions SET ConditionFunction = 'Is Medieval' WHERE StrategyType = 'STRATEGY_MEDIEVAL_CHANGES' AND Disqualifier = 0;
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES ('STRATEGY_MEDIEVAL_CHANGES', 'MedievalSettlements');

-- Ai Yield Bias
UPDATE AiFavoredItems SET Item = 'YIELD_PRODUCTION' WHERE Item = 'YEILD_PRODUCTION';
UPDATE AiFavoredItems SET Item = 'YIELD_SCIENCE'    WHERE Item = 'YEILD_SCIENCE';
UPDATE AiFavoredItems SET Item = 'YIELD_CULTURE'    WHERE Item = 'YEILD_CULTURE';
UPDATE AiFavoredItems SET Item = 'YIELD_GOLD'       WHERE Item = 'YEILD_GOLD';
UPDATE AiFavoredItems SET Item = 'YIELD_FAITH'      WHERE Item = 'YEILD_FAITH';


-- ModifierArguments
-- The below Values of AGENDA_xxx do not exist anywhere
/*
AGENDA_AYYUBID_DYNASTY	StatementKey	ARGTYPE_IDENTITY	AGENDA_AYYUBID_DYNASTY_WARNING
AGENDA_BLACK_QUEEN	StatementKey	ARGTYPE_IDENTITY	AGENDA_BLACK_QUEEN_WARNING
AGENDA_BUSHIDO	StatementKey	ARGTYPE_IDENTITY	AGENDA_BUSHIDO_WARNING
AGENDA_LAST_VIKING_KING	StatementKey	ARGTYPE_IDENTITY	AGENDA_LAST_VIKING_KING_WARNING
AGENDA_OPTIMUS_PRINCEPS	StatementKey	ARGTYPE_IDENTITY	AGENDA_OPTIMUS_PRINCEPS_WARNING
AGENDA_PARANOID	StatementKey	ARGTYPE_IDENTITY	AGENDA_PARANOID_WARNING
AGENDA_QUEEN_OF_NILE	StatementKey	ARGTYPE_IDENTITY	AGENDA_QUEEN_OF_NILE_WARNING
*/