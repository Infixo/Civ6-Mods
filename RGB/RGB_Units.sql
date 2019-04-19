--------------------------------------------------------------
-- Real Game Balance - Units
-- Author: Infixo
-- 2019-04-18: Created
--------------------------------------------------------------


--------------------------------------------------------------
-- UNIT_COURSER

UPDATE Units SET PrereqTech = 'TECH_STIRRUPS' WHERE UnitType = 'UNIT_COURSER';


--------------------------------------------------------------
-- UNIT_FIELD_CANNON

UPDATE Units SET Combat = 45, RangedCombat = 55, Cost = 260, Maintenance = 4, PrereqTech = 'TECH_METAL_CASTING' WHERE UnitType = 'UNIT_FIELD_CANNON';


--------------------------------------------------------------
-- UNIT_DLV_GATLING_GUN

UPDATE Units SET Range = 2, Cost = 380, Maintenance = 5, PrereqTech = 'TECH_RIFLING' WHERE UnitType = 'UNIT_DLV_GATLING_GUN';

-- upgrades from UNIT_FIELD_CANNON instead of UNIT_MACHINE_GUN
DELETE FROM UnitUpgrades WHERE Unit = 'UNIT_FIELD_CANNON';
INSERT INTO UnitUpgrades (Unit, UpgradeUnit) VALUES ('UNIT_FIELD_CANNON', 'UNIT_DLV_GATLING_GUN');
DELETE FROM UnitUpgrades WHERE Unit = (SELECT CivUniqueUnitType FROM UnitReplaces WHERE ReplacesUnitType = 'UNIT_FIELD_CANNON');
INSERT INTO UnitUpgrades (Unit, UpgradeUnit) SELECT CivUniqueUnitType, 'UNIT_DLV_GATLING_GUN' FROM UnitReplaces WHERE ReplacesUnitType = 'UNIT_FIELD_CANNON';


--------------------------------------------------------------
-- UNIT_MACHINE_GUN

-- restore range 2 and no ZOC, cost little less than base game
UPDATE Units SET Range = 2, ZoneOfControl = 0, Cost = 460, Maintenance = 4 WHERE UnitType = 'UNIT_MACHINE_GUN';


--------------------------------------------------------------
-- UNIT_DLV_MORTAR

UPDATE Units SET Combat = 75, RangedCombat = 85, Cost = 600, Maintenance = 6, PrereqTech = 'TECH_GUIDANCE_SYSTEMS' WHERE UnitType = 'UNIT_DLV_MORTAR';

-- upgrades from UNIT_MACHINE_GUN
DELETE FROM UnitUpgrades WHERE Unit = 'UNIT_DLV_MORTAR'; -- last unit in the line

INSERT INTO UnitUpgrades (Unit, UpgradeUnit) VALUES ('UNIT_MACHINE_GUN', 'UNIT_DLV_MORTAR');
INSERT INTO UnitUpgrades (Unit, UpgradeUnit) SELECT CivUniqueUnitType, 'UNIT_DLV_MORTAR' FROM UnitReplaces WHERE ReplacesUnitType = 'UNIT_MACHINE_GUN';
