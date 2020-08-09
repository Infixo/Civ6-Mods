-- ===========================================================================
-- Real Governor Inspector
-- Author: Infixo
-- 2020-06-03: Created
-- ===========================================================================

-- just to make versioning easier
INSERT INTO GlobalParameters (Name, Value) VALUES ('RGI_VERSION_MAJOR', '1');
INSERT INTO GlobalParameters (Name, Value) VALUES ('RGI_VERSION_MINOR', '2');

-- options
INSERT INTO GlobalParameters (Name, Value) VALUES ('RGI_OPTION_TOTAL_ALL', '0'); -- '0' total sums up only active promotions / '1' total sums up all promotions


-- ReportsList Loader
INSERT OR REPLACE INTO RLLReports (ReportType, ButtonLabel, LuaEvent, StackID, SortOrder, RequiresXP2) VALUES
('REPORT_GOV_INSPECTOR', 'LOC_RGI_BUTTON_LABEL', 'ReportsList_OpenGovernorInspector', 'GlobalReportsStack', 530, 1);
