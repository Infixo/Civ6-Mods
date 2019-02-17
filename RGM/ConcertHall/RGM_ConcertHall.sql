--------------------------------------------------------------
-- RGM_ConcertHall
-- Author: Infixo
-- 2018-03-28: Created
--------------------------------------------------------------

-- Type
INSERT INTO Types(Type, Kind)
SELECT 'BUILDING_CONCERT_HALL', 'KIND_BUILDING'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

-- Building
INSERT INTO Buildings (BuildingType, Name, PrereqTech, PrereqCivic, Cost, PrereqDistrict, Description, PurchaseYield, Maintenance, CitizenSlots, AdvisorType)
SELECT 'BUILDING_CONCERT_HALL', 'LOC_BUILDING_CONCERT_HALL_NAME', NULL, 'CIVIC_HUMANISM', 290, 'DISTRICT_THEATER', 'LOC_BUILDING_CONCERT_HALL_DESCRIPTION', 'YIELD_GOLD', 2, 1, 'ADVISOR_CULTURE'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

-- 2 GWoM slots
INSERT INTO Building_GreatWorks (BuildingType, GreatWorkSlotType, NumSlots, ThemingUniquePerson, ThemingYieldMultiplier, ThemingTourismMultiplier, ThemingBonusDescription)
SELECT 'BUILDING_CONCERT_HALL', 'GREATWORKSLOT_MUSIC', 2, 1, 100, 100, 'LOC_BUILDING_CONCERT_HALL_THEMINGBONUS'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

-- +2 Culture
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) 
SELECT 'BUILDING_CONCERT_HALL', 'YIELD_CULTURE', 2
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

-- +1 GWP (all level 2 give +1 GWP)
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn) 
SELECT 'BUILDING_CONCERT_HALL', 'GREAT_PERSON_CLASS_WRITER', 1
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

-- +1 GMP
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn) 
SELECT 'BUILDING_CONCERT_HALL', 'GREAT_PERSON_CLASS_MUSICIAN', 1
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

-- Required
INSERT INTO BuildingPrereqs(Building, PrereqBuilding) 
SELECT 'BUILDING_CONCERT_HALL', 'BUILDING_AMPHITHEATER'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

-- Mutually Exclusive
INSERT INTO MutuallyExclusiveBuildings (Building, MutuallyExclusiveBuilding) 
SELECT 'BUILDING_CONCERT_HALL',    'BUILDING_MUSEUM_ART'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

INSERT INTO MutuallyExclusiveBuildings (Building, MutuallyExclusiveBuilding) 
SELECT 'BUILDING_CONCERT_HALL',    'BUILDING_MUSEUM_ARTIFACT'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

INSERT INTO MutuallyExclusiveBuildings (Building, MutuallyExclusiveBuilding) 
SELECT 'BUILDING_MUSEUM_ART',      'BUILDING_CONCERT_HALL'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

INSERT INTO MutuallyExclusiveBuildings (Building, MutuallyExclusiveBuilding) 
SELECT 'BUILDING_MUSEUM_ARTIFACT', 'BUILDING_CONCERT_HALL'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

-- Enables
INSERT INTO BuildingPrereqs(Building, PrereqBuilding) 
SELECT 'BUILDING_BROADCAST_CENTER', 'BUILDING_CONCERT_HALL'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

-- Policy Grand Opera +100% yields to Theater buildings

INSERT INTO PolicyModifiers (PolicyType, ModifierId)
SELECT 'POLICY_GRAND_OPERA', 'GRANDOPERA_DOUBLECONCERTHALL'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

INSERT INTO Modifiers (ModifierId, ModifierType)
SELECT 'GRANDOPERA_DOUBLECONCERTHALL', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_MODIFIER'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

INSERT INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'GRANDOPERA_DOUBLECONCERTHALL', 'BuildingType', 'BUILDING_CONCERT_HALL'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

INSERT INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'GRANDOPERA_DOUBLECONCERTHALL', 'YieldType', 'YIELD_CULTURE'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

INSERT INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'GRANDOPERA_DOUBLECONCERTHALL', 'Amount', '100'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';
