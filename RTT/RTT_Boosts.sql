-- Created by Infixo for Real Tech Tree (Jan 24, 2017)

-- Eurekas boost for Technologies
UPDATE Boosts
	SET Boost = 35
	WHERE TechnologyType IS NOT NULL;

-- Eurekas boost for Civics
UPDATE Boosts
	SET Boost = 35
	WHERE CivicType IS NOT NULL;