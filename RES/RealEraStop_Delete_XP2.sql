--------------------------------------------------------------
-- Real Era Stop - Removals of Gathering Storm left-overs
-- Author: Infixo
-- 2019-03-01: Created
--------------------------------------------------------------


--------------------------------------------------------------
-- 2019-03-01 Version 2.6 Emergencies clean-up
-- generally there could be buildings or districts not available in the game
-- score lines will be removed for them and as a result the competition will be meaningless
-- remove emergencies that have no score sources
-- as for now there is World Games (Information Era) that require Stadium or Aquatic Center (Atomic Era) so should be ok

DELETE FROM EmergencyAlliances WHERE EmergencyType NOT IN (SELECT EmergencyType FROM EmergencyScoreSources);


--------------------------------------------------------------
-- 2019-03-01 Resolutions
-- specific resolutions may need special treaty because they use Lua for validation
-- it means that there is no info in the DB what actual targets could be considered
-- As for now there is only one, however it triggers in Modern so no actual problem here

-- WC_RES_GLOBAL_ENERGY_TREATY	BUILDING
-- SELECT * FROM Buildings WHERE BuildingType = "BUILDING_COAL_POWER_PLANT" OR BuildingType = "BUILDING_FOSSIL_FUEL_POWER_PLANT" OR BuildingType = "BUILDING_POWER_PLANT"
