--------------------------------------------------------------
-- Real Era Stop Text
-- Author: Infixo
-- March  3rd, 2017: Version 1, Created
-- March 26th, 2017: Version 2, Custom Game Speeds that allow for slowing down calendars
-- March 28th, 2017: Version 2.1, Update for Spring 2017 Patch (game's Future Civic will be used)
--------------------------------------------------------------

/* Version 2.1
-- Civic: Future Society
INSERT INTO LocalizedText (Tag, Language, Text)
VALUES ('LOC_CIVIC_FUTURE_SOCIETY_NAME', 'en_US', 'Future Society');
INSERT INTO LocalizedText (Tag, Language, Text)
VALUES ('LOC_CIVIC_FUTURE_SOCIETY_DESCRIPTION', 'en_US', 'Can be completed multiple times, increasing your points towards the Score Victory.');
*/

-- Version 2, custom Game Speeds

INSERT INTO LocalizedText (Tag, Language, Text)
VALUES
	('LOC_GAMESPEED_LASTERACLA_NAME', 'en_US', 'Last Era Classical'),
	('LOC_GAMESPEED_LASTERAMED_NAME', 'en_US', 'Last Era Medieval'),
	('LOC_GAMESPEED_LASTERAREN_NAME', 'en_US', 'Last Era Renaissance'),
	('LOC_GAMESPEED_LASTERAIND_NAME', 'en_US', 'Last Era Industrial'),
	('LOC_GAMESPEED_LASTERAMOD_NAME', 'en_US', 'Last Era Modern'),
	('LOC_GAMESPEED_LASTERAATO_NAME', 'en_US', 'Last Era Atomic');
	
INSERT INTO LocalizedText (Tag, Language, Text)
VALUES
	('LOC_GAMESPEED_LASTERACLA_HELP', 'en_US', 'Last Era Classical (up to 600 AD)'),
	('LOC_GAMESPEED_LASTERAMED_HELP', 'en_US', 'Last Era Medieval (up to 1400 AD'),
	('LOC_GAMESPEED_LASTERAREN_HELP', 'en_US', 'Last Era Renaissance (up to 1745 AD)'),
	('LOC_GAMESPEED_LASTERAIND_HELP', 'en_US', 'Last Era Industrial (up to  1900 AD)'),
	('LOC_GAMESPEED_LASTERAMOD_HELP', 'en_US', 'Last Era Modern (up to  1945 AD)'),
	('LOC_GAMESPEED_LASTERAATO_HELP', 'en_US', 'Last Era Atomic (up to 1987 AD)');
