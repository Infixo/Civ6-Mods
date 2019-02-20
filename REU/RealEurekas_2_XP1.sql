--------------------------------------------------------------
-- RealEurekas - Rise & Fall changes
-- Author: Infixo
-- 2018-04-01: Created
--------------------------------------------------------------

--------------------------------------------------------------
-- There's no HAVE_RESEARCH_AGREEMENT in R&F, instead there's BOOST_TRIGGER_HAVE_ALLIANCE_LEVEL_X (Have a level 2 Alliance.)
--------------------------------------------------------------

UPDATE REurBoostDefs SET BClass = 'HAVE_ALLIANCE_LEVEL_X', NItems = 2 WHERE BClass = 'HAVE_RESEARCH_AGREEMENT';
UPDATE REurBoostDefs SET TDesc = 'HAVE_ALLIANCE_L2_CH' WHERE TDesc = 'HAVE_RA_CH';
UPDATE REurBoostDefs SET TDesc = 'HAVE_ALLIANCE_L2_EL' WHERE TDesc = 'HAVE_RA_EL';
UPDATE REurBoostDefs SET TDesc = 'HAVE_ALLIANCE_L2_ST' WHERE TDesc = 'HAVE_RA_ST';
