--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2019-04-06: Created
--------------------------------------------------------------


--------------------------------------------------------------
-- GRAND_BAZAAR

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType) VALUES
('BUILDING_GRAND_BAZAAR_UPGRADE', 'BUILDING_BANK_UPGRADE');

UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_GRAND_BAZAAR'
WHERE BuildingType = 'BUILDING_GRAND_BAZAAR_UPGRADE';

-- +1 GMP (bank)
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn) VALUES
('BUILDING_GRAND_BAZAAR_UPGRADE', 'GREAT_PERSON_CLASS_MERCHANT', 1);

-- +2/+4 to outgoing domestic/international TR in the City (bank)
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_GRAND_BAZAAR_UPGRADE', 'BANK_UPGRADE_DOMESTIC_GOLD'),
('BUILDING_GRAND_BAZAAR_UPGRADE', 'BANK_UPGRADE_INTERNATIONAL_GOLD');

-- +2 Gold from each improved Luxury resource
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_GRAND_BAZAAR_UPGRADE', 'GRAND_BAZAAR_UPGRADE_IMPROVED_LUXURY_GOLD');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('GRAND_BAZAAR_UPGRADE_IMPROVED_LUXURY_GOLD', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_IMPROVED_LUXURY_REQUIREMENTS');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('GRAND_BAZAAR_UPGRADE_IMPROVED_LUXURY_GOLD', 'YieldType', 'YIELD_GOLD'),
('GRAND_BAZAAR_UPGRADE_IMPROVED_LUXURY_GOLD', 'Amount',    '2');

INSERT OR REPLACE INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
('PLOT_HAS_IMPROVED_LUXURY_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL');

INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('PLOT_HAS_IMPROVED_LUXURY_REQUIREMENTS', 'REQUIRES_PLOT_HAS_ANY_IMPROVEMENT'),
('PLOT_HAS_IMPROVED_LUXURY_REQUIREMENTS', 'REQUIRES_PLOT_HAS_LUXURY'); -- exists

INSERT OR REPLACE INTO Requirements (RequirementId, RequirementType) VALUES
('REQUIRES_PLOT_HAS_ANY_IMPROVEMENT', 'REQUIREMENT_PLOT_HAS_ANY_IMPROVEMENT');

-- +2 Tourism
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_GRAND_BAZAAR_UPGRADE', 'GRAND_BAZAAR_UPGRADE_TOURISM');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('GRAND_BAZAAR_UPGRADE_TOURISM', 'MODIFIER_PLAYER_DISTRICT_ADJUST_TOURISM_CHANGE', 0, 0, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('GRAND_BAZAAR_UPGRADE_TOURISM', 'Amount', '2');
