--------------------------------------------------------------
-- RealEurekas - Gathering Storm changes
-- Author: Infixo
-- 2019-02-20: Created
--------------------------------------------------------------

UPDATE Boosts SET Boost = 90 WHERE CivicType = 'CIVIC_NEAR_FUTURE_GOVERNANCE'; -- Boost=90??? Bug?

--------------------------------------------------------------
-- TABLE REurMapping
--------------------------------------------------------------
INSERT INTO REurMapping (BoostID,BoostSeq,BoostTypeID)
VALUES  -- below part is generated from Excel - should not be changed manually
(113,0,282),
(114,0,425),
(115,0,594),
(116,0,552),
(117,0,224),
(118,0,232),
(119,0,297),
(120,0,102),
(121,0,102),
(122,0,102),
(123,0,102),
(124,0,102),
(125,0,102),
(126,0,102);
