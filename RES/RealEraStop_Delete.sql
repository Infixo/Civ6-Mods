--------------------------------------------------------------
-- Real Era Stop - Removals after all expansions
-- Author: Infixo
-- 2019-02-21: Created
--------------------------------------------------------------

	
--------------------------------------------------------------
-- REMOVALS
-- If any of these should be available in the game, it should be connected to an earlier tech/civic
--------------------------------------------------------------

DELETE FROM Buildings WHERE PrereqTech IN (SELECT TechnologyType FROM RESTechnologies);
DELETE FROM Buildings WHERE PrereqCivic IN (SELECT CivicType FROM RESCivics);
-- special case for Rockets - have only District as prereq
DELETE FROM Buildings WHERE PrereqDistrict IN (SELECT DistrictType FROM Districts WHERE PrereqTech IN (SELECT TechnologyType FROM RESTechnologies));
DELETE FROM Buildings WHERE PrereqDistrict IN (SELECT DistrictType FROM Districts WHERE PrereqCivic IN (SELECT CivicType FROM RESCivics));

DELETE FROM Projects WHERE PrereqTech IN (SELECT TechnologyType FROM RESTechnologies);
DELETE FROM Projects WHERE PrereqCivic IN (SELECT CivicType FROM RESCivics);
-- Version 2.2 fix for Industrial Zone Projects
DELETE FROM Projects WHERE PrereqDistrict IN (SELECT DistrictType FROM Districts WHERE PrereqTech IN (SELECT TechnologyType FROM RESTechnologies));
DELETE FROM Projects WHERE PrereqDistrict IN (SELECT DistrictType FROM Districts WHERE PrereqCivic IN (SELECT CivicType FROM RESCivics));

DELETE FROM Districts WHERE PrereqTech IN (SELECT TechnologyType FROM RESTechnologies);
DELETE FROM Districts WHERE PrereqCivic IN (SELECT CivicType FROM RESCivics);

DELETE FROM Improvements WHERE PrereqTech IN (SELECT TechnologyType FROM RESTechnologies);
DELETE FROM Improvements WHERE PrereqCivic IN (SELECT CivicType FROM RESCivics);

DELETE FROM Policies WHERE PrereqCivic IN (SELECT CivicType FROM RESCivics);

DELETE FROM Governments WHERE PrereqCivic IN (SELECT CivicType FROM RESCivics);

DELETE FROM Resources WHERE PrereqTech IN (SELECT TechnologyType FROM RESTechnologies);
DELETE FROM Resources WHERE PrereqCivic IN (SELECT CivicType FROM RESCivics);

DELETE FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PrereqTech IN (SELECT TechnologyType FROM RESTechnologies));
DELETE FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PrereqCivic IN (SELECT CivicType FROM RESCivics));
DELETE FROM Units WHERE PrereqTech IN (SELECT TechnologyType FROM RESTechnologies);
DELETE FROM Units WHERE PrereqCivic IN (SELECT CivicType FROM RESCivics);

-- Version 1.4 removal of Great People
DELETE FROM GreatPersonIndividuals WHERE EraType IN (SELECT EraType FROM RESEras);

-- Version 1.4 clean-up modifier-related problems
-- this section assumes that all related objects have been removed - it uses NOT IN set
DELETE FROM PolicyModifiers WHERE ModifierID IN (SELECT ModifierID FROM ModifierArguments WHERE Name = 'BuildingType' AND Value NOT IN (SELECT BuildingType FROM Buildings));
DELETE FROM PolicyModifiers WHERE ModifierID IN (SELECT ModifierID FROM ModifierArguments WHERE Name = 'UnitType' AND Value NOT IN (SELECT UnitType FROM Units));
DELETE FROM PolicyModifiers WHERE ModifierID IN (SELECT ModifierID FROM ModifierArguments WHERE Name = 'DistrictType' AND Value NOT IN (SELECT DistrictType FROM Districts));
DELETE FROM PolicyModifiers WHERE ModifierID IN (SELECT ModifierID FROM ModifierArguments WHERE Name = 'ResourceType' AND Value NOT IN (SELECT ResourceType FROM Resources));
DELETE FROM PolicyModifiers WHERE ModifierID IN (SELECT ModifierID FROM ModifierArguments WHERE Name = 'ImprovementType' AND Value NOT IN (SELECT ImprovementType FROM Improvements));
DELETE FROM TraitModifiers WHERE ModifierID IN (SELECT ModifierID FROM ModifierArguments WHERE Name = 'BuildingType' AND Value NOT IN (SELECT BuildingType FROM Buildings));
DELETE FROM TraitModifiers WHERE ModifierID IN (SELECT ModifierID FROM ModifierArguments WHERE Name = 'UnitType' AND Value NOT IN (SELECT UnitType FROM Units));
DELETE FROM TraitModifiers WHERE ModifierID IN (SELECT ModifierID FROM ModifierArguments WHERE Name = 'DistrictType' AND Value NOT IN (SELECT DistrictType FROM Districts));
DELETE FROM TraitModifiers WHERE ModifierID IN (SELECT ModifierID FROM ModifierArguments WHERE Name = 'ResourceType' AND Value NOT IN (SELECT ResourceType FROM Resources));
DELETE FROM TraitModifiers WHERE ModifierID IN (SELECT ModifierID FROM ModifierArguments WHERE Name = 'ImprovementType' AND Value NOT IN (SELECT ImprovementType FROM Improvements));

-- Remove ALL techs after the last Era
DELETE FROM Technologies WHERE EraType IN (SELECT EraType FROM RESEras);
-- Remove ALL civics after the last Era
DELETE FROM Civics WHERE EraType IN (SELECT EraType FROM RESEras);


--------------------------------------------------------------
-- CLEAN-UP
--------------------------------------------------------------

DROP TABLE RESModifierArgumentsUpdate;
DROP VIEW RESCivics;
DROP VIEW RESTechnologies;
DROP VIEW RESEras;
