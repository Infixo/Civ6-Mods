--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2019-03-18: Separate file
--------------------------------------------------------------


--------------------------------------------------------------
-- PRASAT (Khmer DLC)

UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_PRASAT' WHERE BuildingType = 'BUILDING_PRASAT_UPGRADE';

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType)
SELECT 'BUILDING_PRASAT_UPGRADE', 'BUILDING_TEMPLE_UPGRADE'
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

-- +2 Faith
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange)
SELECT 'BUILDING_PRASAT_UPGRADE', 'YIELD_FAITH', 2
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

-- +1 Food
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange)
SELECT 'BUILDING_PRASAT_UPGRADE', 'YIELD_FOOD', 1
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

-- +1 GWR slot to Prasat (EFFECT_ADJUST_EXTRA_GREAT_WORK_SLOTS)
INSERT INTO BuildingModifiers (BuildingType, ModifierId) 
SELECT 'BUILDING_PRASAT_UPGRADE', 'PRASAT_UPGRADE_ADD_GREAT_WORK_SLOTS'
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) 
SELECT 'PRASAT_UPGRADE_ADD_GREAT_WORK_SLOTS', 'MODIFIER_SINGLE_CITY_ADJUST_EXTRA_GREAT_WORK_SLOTS', 1, 1, NULL, NULL
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

INSERT INTO ModifierArguments (ModifierId, Name, Value) 
SELECT 'PRASAT_UPGRADE_ADD_GREAT_WORK_SLOTS', 'BuildingType', 'BUILDING_PRASAT'
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

INSERT INTO ModifierArguments (ModifierId, Name, Value) 
SELECT 'PRASAT_UPGRADE_ADD_GREAT_WORK_SLOTS', 'GreatWorkSlotType', 'GREATWORKSLOT_RELIC'
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

INSERT INTO ModifierArguments (ModifierId, Name, Value) 
SELECT 'PRASAT_UPGRADE_ADD_GREAT_WORK_SLOTS', 'Amount', '1'
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

-- Same as Temple
INSERT INTO BuildingModifiers (BuildingType, ModifierId)
SELECT 'BUILDING_PRASAT_UPGRADE', 'TEMPLE_UPGRADE_ADD_RESOURCE_FAITH'
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

-- +3 Tourism
INSERT INTO BuildingModifiers (BuildingType, ModifierId)
SELECT 'BUILDING_PRASAT_UPGRADE', 'PRASAT_UPGRADE_TOURISM'
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId)
SELECT 'PRASAT_UPGRADE_TOURISM', 'MODIFIER_PLAYER_DISTRICT_ADJUST_TOURISM_CHANGE', 0, 0, NULL, NULL
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

INSERT INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'PRASAT_UPGRADE_TOURISM', 'Amount', '3'
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';
