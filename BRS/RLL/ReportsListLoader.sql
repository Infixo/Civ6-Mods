-- ===========================================================================
-- ReportsList Loader
-- Author: Infixo
-- 2019-03-30: Created
-- I hereby grant the permission to use RLL in other Civ6 mods provided no changes are made to the code.
-- 2019-06-20: Updated for June 2019 Patch (Gossip tab)
-- ===========================================================================

/*

INSTRUCTIONS

1. Add the 2 RLL files to the mod and register them in the <Files> section.

2. Add the following lines to the .modinfo

	<!-- reports list loader -->
	<UpdateDatabase id="RLL_Database">
		<File>RLL/ReportsListLoader.sql</File>
	</UpdateDatabase>
	<ImportFiles id="RLL_Imports">
		<File>RLL/ReportsListLoader.lua</File>
	</ImportFiles>
	<ReplaceUIScript id="RLL_ReplaceUI_ReportsList">
		<Properties>
			<LoadOrder>99999</LoadOrder>
			<LuaContext>ReportsList</LuaContext>
			<LuaReplace>RLL/ReportsListLoader.lua</LuaReplace>
		</Properties>
	</ReplaceUIScript>

3. Register new reports in RLLReports via any .sql or .xml in the mod.
   Please do NOT modify THIS file. Just use any other suitable .sql or .xml.
   Important! LoadOrder must be >0 so the table is created beforehand.
   
*/


-- just to make versioning easier
INSERT OR REPLACE INTO GlobalParameters (Name, Value) VALUES ('RLL_VERSION_MAJOR', '1');
INSERT OR REPLACE INTO GlobalParameters (Name, Value) VALUES ('RLL_VERSION_MINOR', '1');


-- ===========================================================================
-- TABLE DEFINITION
-- ===========================================================================

CREATE TABLE IF NOT EXISTS RLLReports (
	ReportType     TEXT NOT NULL,
	ButtonLabel    TEXT NOT NULL,
	LuaEvent       TEXT NOT NULL,
	StackID        TEXT NOT NULL CHECK (StackID IN ('EmpireReportsStack', 'GlobalReportsStack')),
	SortOrder      INTEGER NOT NULL DEFAULT 9999,
	RequiresXP1    BOOLEAN NOT NULL CHECK (RequiresXP1 IN (0,1)) DEFAULT 0, -- report will be added if XP1 or XP2 is available
	RequiresXP2    BOOLEAN NOT NULL CHECK (RequiresXP2 IN (0,1)) DEFAULT 0, -- report will be added only if XP2 is available
	GameCapability TEXT,                                                    -- report will be added only if this capability is enabled
	PRIMARY KEY (ReportType),
	FOREIGN KEY (GameCapability)  REFERENCES GameCapabilities (GameCapability) ON DELETE CASCADE ON UPDATE CASCADE
);


-- ===========================================================================
-- BASE GAME REPORTS
-- ===========================================================================

INSERT OR REPLACE INTO RLLReports (ReportType, ButtonLabel, LuaEvent, StackID, SortOrder, GameCapability) VALUES
('REPORT_EMPIRE_YIELDS',      'LOC_PARTIALSCREEN_REPORTS_YIELDS',      'ReportsList_OpenYields',          'EmpireReportsStack', 110, NULL),
('REPORT_EMPIRE_RESOURCES',   'LOC_PARTIALSCREEN_REPORTS_RESOURCES',   'ReportsList_OpenResources',       'EmpireReportsStack', 120, NULL),
('REPORT_EMPIRE_CITY_STATUS', 'LOC_PARTIALSCREEN_REPORTS_CITY_STATUS', 'ReportsList_OpenCityStatus',      'EmpireReportsStack', 130, NULL),
('REPORT_EMPIRE_GOSSIP',      'LOC_PARTIALSCREEN_REPORTS_GOSSIP',      'ReportsList_OpenGossip',          'EmpireReportsStack', 135, 'CAPABILITY_GOSSIP_REPORT'),
('REPORT_GLOBAL_RESOURCES',   'LOC_PARTIALSCREEN_REPORTS_RESOURCES',   'GlobalReportsList_OpenResources', 'GlobalReportsStack', 510, 'CAPABILITY_DIPLOMACY_DEALS');
