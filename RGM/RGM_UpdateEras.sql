--------------------------------------------------------------
-- RGM_UpdateEras
-- Author: Infixo
-- 2018-03-28: Created
--------------------------------------------------------------

-- Renaissance
UPDATE GreatPersonIndividuals SET EraType = 'ERA_RENAISSANCE' WHERE GreatPersonIndividualType = 'GREAT_PERSON_INDIVIDUAL_ANTONIO_VIVALDI' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RGM_OPTION_UPDATE_ERAS' AND Value = '1');
UPDATE GreatPersonIndividuals SET EraType = 'ERA_RENAISSANCE' WHERE GreatPersonIndividualType = 'GREAT_PERSON_INDIVIDUAL_JOHANN_SEBASTIAN_BACH' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RGM_OPTION_UPDATE_ERAS' AND Value = '1');
UPDATE GreatPersonIndividuals SET EraType = 'ERA_RENAISSANCE' WHERE GreatPersonIndividualType = 'GREAT_PERSON_INDIVIDUAL_LUDWIG_VAN_BEETHOVEN' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RGM_OPTION_UPDATE_ERAS' AND Value = '1');
UPDATE GreatPersonIndividuals SET EraType = 'ERA_RENAISSANCE' WHERE GreatPersonIndividualType = 'GREAT_PERSON_INDIVIDUAL_WOLFGANG_AMADEUS_MOZART' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RGM_OPTION_UPDATE_ERAS' AND Value = '1');
UPDATE GreatPersonIndividuals SET EraType = 'ERA_RENAISSANCE' WHERE GreatPersonIndividualType = 'GREAT_PERSON_INDIVIDUAL_YATSUHASHI_KENGYO' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RGM_OPTION_UPDATE_ERAS' AND Value = '1');
-- Industrial
UPDATE GreatPersonIndividuals SET EraType = 'ERA_INDUSTRIAL'  WHERE GreatPersonIndividualType = 'GREAT_PERSON_INDIVIDUAL_ANTONIN_DVORAK' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RGM_OPTION_UPDATE_ERAS' AND Value = '1');
UPDATE GreatPersonIndividuals SET EraType = 'ERA_INDUSTRIAL'  WHERE GreatPersonIndividualType = 'GREAT_PERSON_INDIVIDUAL_ANTONIO_CARLOS_GOMEZ' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RGM_OPTION_UPDATE_ERAS' AND Value = '1');
UPDATE GreatPersonIndividuals SET EraType = 'ERA_INDUSTRIAL'  WHERE GreatPersonIndividualType = 'GREAT_PERSON_INDIVIDUAL_CLARA_SCHUMANN' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RGM_OPTION_UPDATE_ERAS' AND Value = '1');
UPDATE GreatPersonIndividuals SET EraType = 'ERA_INDUSTRIAL'  WHERE GreatPersonIndividualType = 'GREAT_PERSON_INDIVIDUAL_FRANZ_LISZT' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RGM_OPTION_UPDATE_ERAS' AND Value = '1');
UPDATE GreatPersonIndividuals SET EraType = 'ERA_INDUSTRIAL'  WHERE GreatPersonIndividualType = 'GREAT_PERSON_INDIVIDUAL_FREDERIC_CHOPIN' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RGM_OPTION_UPDATE_ERAS' AND Value = '1');
UPDATE GreatPersonIndividuals SET EraType = 'ERA_INDUSTRIAL'  WHERE GreatPersonIndividualType = 'GREAT_PERSON_INDIVIDUAL_LILIUOKALANI' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RGM_OPTION_UPDATE_ERAS' AND Value = '1');
UPDATE GreatPersonIndividuals SET EraType = 'ERA_INDUSTRIAL'  WHERE GreatPersonIndividualType = 'GREAT_PERSON_INDIVIDUAL_PETER_ILYICH_TCHAIKOVSKY' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RGM_OPTION_UPDATE_ERAS' AND Value = '1');
-- Modern
UPDATE GreatPersonIndividuals SET EraType = 'ERA_MODERN'      WHERE GreatPersonIndividualType = 'GREAT_PERSON_INDIVIDUAL_GAUHAR_JAAN' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RGM_OPTION_UPDATE_ERAS' AND Value = '1');
UPDATE GreatPersonIndividuals SET EraType = 'ERA_MODERN'      WHERE GreatPersonIndividualType = 'GREAT_PERSON_INDIVIDUAL_JUVENTINO_ROSAS' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RGM_OPTION_UPDATE_ERAS' AND Value = '1');
UPDATE GreatPersonIndividuals SET EraType = 'ERA_MODERN'      WHERE GreatPersonIndividualType = 'GREAT_PERSON_INDIVIDUAL_LIU_TIANHUA' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RGM_OPTION_UPDATE_ERAS' AND Value = '1');
UPDATE GreatPersonIndividuals SET EraType = 'ERA_MODERN'      WHERE GreatPersonIndividualType = 'GREAT_PERSON_INDIVIDUAL_MYKOLA_LEONTOVYCH' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RGM_OPTION_UPDATE_ERAS' AND Value = '1');
-- Atomic
-- Information
