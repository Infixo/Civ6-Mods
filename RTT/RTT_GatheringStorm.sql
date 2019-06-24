--------------------------------------------------------------
-- Real Tech Tree - Gathering Storm compatibility
-- Future Era is not changed in both trees
-- Author: Infixo
-- 2019-02-15: Created
-- 2019-06-24: June 2019 Patch changes
--------------------------------------------------------------


-- TECHS
-- There are 2 new techs: Buttress - MED1, Refining - MOD1

UPDATE Technologies SET UITreeRow = 4 WHERE TechnologyType = 'TECH_REFINING';

DELETE FROM TechnologyPrereqs WHERE Technology = 'TECH_SQUARE_RIGGING' AND PrereqTech = 'TECH_MASS_PRODUCTION'; -- removed for balance purposes (Buttress)
DELETE FROM TechnologyPrereqs WHERE Technology = 'TECH_NUCLEAR_FUSION' AND PrereqTech = 'TECH_NUCLEAR_FISSION'; -- added via TECH_COMPOSITES
DELETE FROM TechnologyPrereqs WHERE Technology = 'TECH_FUTURE_TECH' AND PrereqTech = 'TECH_STEALTH_TECHNOLOGY'; -- not needed
DELETE FROM TechnologyPrereqs WHERE Technology = 'TECH_FUTURE_TECH' AND PrereqTech = 'TECH_TELECOMMUNICATIONS'; -- not needed

INSERT INTO TechnologyPrereqs (Technology, PrereqTech) VALUES
('TECH_BUTTRESS', 'TECH_THE_WHEEL'),
('TECH_REFINING', 'TECH_INDUSTRIALIZATION'),
('TECH_ROBOTICS', 'TECH_TELECOMMUNICATIONS'),
('TECH_NUCLEAR_FUSION', 'TECH_COMPOSITES'),
('TECH_NANOTECHNOLOGY', 'TECH_STEALTH_TECHNOLOGY');


-- CIVICS
-- CIVIC_ENVIRONMENTALISM (INF1)
-- CIVIC_NEAR_FUTURE_GOVERNANCE (INF2)
-- New govs: CIVIC_CORPORATE_LIBERTARIANISM, CIVIC_DIGITAL_DEMOCRACY, CIVIC_SYNTHETIC_TECHNOCRACY (INF2)

UPDATE Civics SET UITreeRow = -3 WHERE CivicType = 'CIVIC_ENVIRONMENTALISM';
UPDATE Civics SET UITreeRow = -2 WHERE CivicType = 'CIVIC_NEAR_FUTURE_GOVERNANCE';

INSERT INTO CivicPrereqs (Civic, PrereqCivic) VALUES
('CIVIC_ENVIRONMENTALISM', 'CIVIC_SPACE_RACE');


-- 2019-06-24 June 2019 Patch changes

DELETE FROM TechnologyPrereqs WHERE Technology = 'TECH_STIRRUPS' AND PrereqTech = 'TECH_ENGINEERING'; -- not needed
DELETE FROM TechnologyPrereqs WHERE Technology = 'TECH_STIRRUPS' AND PrereqTech = 'TECH_MILITARY_TACTICS'; -- not needed
INSERT INTO TechnologyPrereqs (Technology, PrereqTech) VALUES -- revert to the original prereq
('TECH_STIRRUPS', 'TECH_HORSEBACK_RIDING');

DELETE FROM TechnologyPrereqs WHERE Technology = 'TECH_CHEMISTRY' AND PrereqTech = 'TECH_STEAM_POWER'; -- not needed
