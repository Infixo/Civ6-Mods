-- ===========================================================================
-- Better Report Screen
-- Author: Infixo
-- 2018-03-21: Created
-- 2019-03-30: Added ReportsList Loader
-- ===========================================================================

-- just to make versioning easier
INSERT INTO GlobalParameters (Name, Value) VALUES ('BRS_VERSION_MAJOR', '5');
INSERT INTO GlobalParameters (Name, Value) VALUES ('BRS_VERSION_MINOR', '6');

-- options
INSERT INTO GlobalParameters (Name, Value) VALUES ('BRS_OPTION_MODIFIERS', '0');


-- ReportsList Loader

UPDATE RLLReports SET ButtonLabel = 'LOC_HUD_REPORTS_TAB_CITIES' WHERE ReportType = 'REPORT_EMPIRE_CITY_STATUS';

INSERT OR REPLACE INTO RLLReports (ReportType, ButtonLabel, LuaEvent, StackID, SortOrder, RequiresXP2) VALUES
('REPORT_EMPIRE_DEALS',    'LOC_HUD_REPORTS_TAB_DEALS',    'ReportsList_OpenDeals',    'EmpireReportsStack', 140, 0),
('REPORT_EMPIRE_UNITS',    'LOC_HUD_REPORTS_TAB_UNITS',    'ReportsList_OpenUnits',    'EmpireReportsStack', 150, 0),
('REPORT_EMPIRE_POLICIES', 'LOC_HUD_REPORTS_TAB_POLICIES', 'ReportsList_OpenPolicies', 'EmpireReportsStack', 160, 0),
('REPORT_EMPIRE_MINORS',   'LOC_HUD_REPORTS_TAB_MINORS',   'ReportsList_OpenMinors',   'EmpireReportsStack', 170, 0),
('REPORT_EMPIRE_CITIES2',  'LOC_HUD_REPORTS_TAB_CITIES2',  'ReportsList_OpenCities2',  'EmpireReportsStack', 180, 1);
