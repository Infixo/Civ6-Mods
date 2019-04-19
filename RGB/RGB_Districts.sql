--------------------------------------------------------------
-- Real Game Balance - Districts
-- Author: Infixo
-- 2019-04-1: Created
--------------------------------------------------------------
-- Credits
-- Oasis adjacency idea from Oasis Caravanserai by JNR.
--------------------------------------------------------------



--------------------------------------------------------------
-- DISTRICT_COMMERCIAL_HUB

-- +1 Gold from adjacent Oasis
INSERT OR REPLACE INTO District_Adjacencies (DistrictType, YieldChangeId) VALUES
('DISTRICT_COMMERCIAL_HUB',	'Oasis_Gold');

INSERT OR REPLACE INTO Adjacency_YieldChanges (ID, Description, YieldType, YieldChange,	TilesRequired, AdjacentFeature) VALUES
('Oasis_Gold', 'LOC_DISTRICT_OASIS_GOLD', 'YIELD_GOLD', 1, 1, 'FEATURE_OASIS');


--------------------------------------------------------------
-- DISTRICT_SUGUBA

-- +2 Gold from adjacent Oasis
INSERT OR REPLACE INTO District_Adjacencies (DistrictType, YieldChangeId) VALUES
('DISTRICT_SUGUBA',	'Oasis_Gold_Suguba');

INSERT OR REPLACE INTO Adjacency_YieldChanges (ID, Description, YieldType, YieldChange,	TilesRequired, AdjacentFeature) VALUES
('Oasis_Gold_Suguba', 'LOC_DISTRICT_OASIS_GOLD', 'YIELD_GOLD', 2, 1, 'FEATURE_OASIS');
