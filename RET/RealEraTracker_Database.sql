-- ===========================================================================
-- Real Era Tracker
-- Author: Infixo
-- 2019-03-28: Created
-- ===========================================================================

-- just to make versioning easier
INSERT INTO GlobalParameters (Name, Value) VALUES ('RET_VERSION_MAJOR', '0');
INSERT INTO GlobalParameters (Name, Value) VALUES ('RET_VERSION_MINOR', '1');

-- options
INSERT INTO GlobalParameters (Name, Value) VALUES ('RET_OPTION_INCLUDE_OTHERS', '1'); -- set to 1 to detect historic moments that other players earned 
																					  -- please note that this is technically cheating as the game doesn't inform you about them (with few exceptions)



-- ===========================================================================
-- EVENTS
-- These are the events to track
-- I don't use 'moment' to not get confused with actual moments
-- ===========================================================================
/*
CREATE TABLE RETEvents (
	EventType      TEXT NOT NULL,
	Description    TEXT NOT NULL,
	EventDataType  TEXT,    -- type of the object associated (e.g. MOMENT_DATA_DISTRICT)
	DataType       TEXT,    -- actual type of the object (e.g. DISTRICT_CAMPUS)
	Category       INTEGER NOT NULL CHECK (Category IN (1,2,3)) DEFAULT 1, -- 1:world, 2: local, 3:repeatable
	EraScore       INTEGER NOT NULL DEFAULT 0,
	MinimumGameEra TEXT,
	MaximumGameEra TEXT,
	PRIMARY KEY (EventType),
	FOREIGN KEY (EventDataType)  REFERENCES MomentDataTypes(MomentDataType) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (DataType)       REFERENCES Types(Type)                     ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (MinimumGameEra) REFERENCES Eras(EraType)                   ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (MaximumGameEra) REFERENCES Eras(EraType)                   ON DELETE CASCADE ON UPDATE CASCADE
);
*/


																					  
-- ===========================================================================
-- EXTRA DATA IN MOMENTS TABLE
-- Each moment earned will be registered to a tracked one.
-- In some cases the call will be infused with extra data.
-- ===========================================================================

ALTER TABLE Moments ADD COLUMN Category INTEGER NOT NULL CHECK (Category IN (1,2,3)) DEFAULT 2; -- 1:world, 2: local, 3:repeatable
ALTER TABLE Moments ADD COLUMN Special TEXT; -- marks moments that need special treatment (usually will be dynamically generated)
ALTER TABLE Moments ADD COLUMN MinEra TEXT REFERENCES Eras (EraType) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE Moments ADD COLUMN MaxEra TEXT REFERENCES Eras (EraType) ON DELETE CASCADE ON UPDATE CASCADE;

-- category WORLD
UPDATE Moments SET Category = 1 WHERE MomentType LIKE '%FIRST_IN_WORLD';
UPDATE Moments SET Category = 1 WHERE MomentType IN (
'MOMENT_UNIT_CREATED_FIRST_DOMAIN_AIR_IN_WORLD';
'MOMENT_UNIT_CREATED_FIRST_DOMAIN_SEA_IN_WORLD';
'MOMENT_UNIT_CREATED_FIRST_REQUIRING_STRATEGIC_IN_WORLD'
);



-- category Repeat - must be set manually
UPDATE Moments SET Category = 3 WHERE MomentType IN (
'MOMENT_ARTIFACT_EXTRACTED',
'MOMENT_BARBARIAN_CAMP_DESTROYED',
'MOMENT_BARBARIAN_CAMP_DESTROYED_NEAR_YOUR_CITY',
'MOMENT_BUILDING_CONSTRUCTED_GAME_ERA_WONDER',
'MOMENT_BUILDING_CONSTRUCTED_PAST_ERA_WONDER',
'MOMENT_CITY_BUILT_NEAR_NATURAL_WONDER',
'MOMENT_CITY_BUILT_NEAR_OTHER_CIV_CITY',
'MOMENT_CITY_BUILT_NEW_CONTINENT',
'MOMENT_CITY_BUILT_ON_DESERT',
'MOMENT_CITY_BUILT_ON_SNOW',
'MOMENT_CITY_BUILT_ON_TUNDRA',
'MOMENT_CITY_CHANGED_RELIGION_ENEMY_CITY_DURING_WAR',
'MOMENT_CITY_CHANGED_RELIGION_OTHER_HOLY_CITY',
'MOMENT_CITY_TRANSFERRED_DISLOYAL_FREE_CITY',
'MOMENT_CITY_TRANSFERRED_FOREIGN_CAPITAL',
'MOMENT_CITY_TRANSFERRED_TO_ORIGINAL_OWNER',
'MOMENT_EMERGENCY_WON_AS_MEMBER',
'MOMENT_EMERGENCY_WON_AS_TARGET',
'MOMENT_FIND_NATURAL_WONDER',
'MOMENT_GOODY_HUT_TRIGGERED',
'MOMENT_GREAT_PERSON_CREATED_GAME_ERA',
'MOMENT_GREAT_PERSON_CREATED_PAST_ERA',
'MOMENT_GREAT_PERSON_CREATED_PATRONAGE_FAITH_OVER_HALF',
'MOMENT_GREAT_PERSON_CREATED_PATRONAGE_GOLD_OVER_HALF',
'MOMENT_PLAYER_GAVE_ENVOY_CANCELED_LEVY',
'MOMENT_PLAYER_GAVE_ENVOY_CANCELED_SUZERAIN_DURING_WAR',
'MOMENT_PLAYER_LEVIED_MILITARY',
'MOMENT_PLAYER_LEVIED_MILITARY_NEAR_ENEMY_CITY',
'MOMENT_PLAYER_MET_MAJOR',
'MOMENT_SPY_MAX_LEVEL',
'MOMENT_TRADING_POST_CONSTRUCTED_IN_OTHER_CIV',
'MOMENT_UNIT_HIGH_LEVEL',
'MOMENT_UNIT_KILLED_UNDERDOG_MILITARY_FORMATION',
'MOMENT_UNIT_KILLED_UNDERDOG_PROMOTIONS',
'MOMENT_WAR_DECLARED_USING_CASUS_BELLI',
'MOMENT_CITY_BUILT_NEAR_FLOODABLE_RIVER',
'MOMENT_CITY_BUILT_NEAR_VOLCANO',
'MOMENT_MITIGATED_COASTAL_FLOOD',
'MOMENT_MITIGATED_RIVER_FLOOD',
'MOMENT_PLAYER_EARNED_DIPLOMATIC_VICTORY_POINT'
);

--- specials - eras
UPDATE Moments SET Special = 'ERA' WHERE MomentIllustrationType = 'MOMENT_ILLUSTRATION_CIVIC_ERA';
UPDATE Moments SET Special = 'ERA' WHERE MomentIllustrationType = 'MOMENT_ILLUSTRATION_TECHNOLOGY_ERA';
-- specials - strategic resource type
UPDATE Moments SET Special = 'STRATEGIC' WHERE MomentType = 'MOMENT_UNIT_CREATED_FIRST_REQUIRING_STRATEGIC';
UPDATE Moments SET Special = 'STRATEGIC' WHERE MomentType = 'MOMENT_UNIT_CREATED_FIRST_REQUIRING_STRATEGIC_IN_WORLD';
-- specials - uniques
UPDATE Moments SET Special = 'UNIQUE' WHERE MomentIllustrationType LIKE 'MOMENT_ILLUSTRATION_UNIQUE%';

-- eras
UPDATE Moments SET MinEra = MinimumGameEra WHERE MinimumGameEra IS NOT NULL;
UPDATE Moments SET MaxEra = ObsoleteEra    WHERE ObsoleteEra    IS NOT NULL;
UPDATE Moments SET MaxEra = MaximumGameEra WHERE MinimumGameEra IS NOT NULL;
-- special cases?


/*
-- by default, EventType is the same as MomentType
UPDATE Moments SET EventType = MomentType;

-- process exceptions

-- full districts
UPDATE Moments SET EventType = 'MOMENT_RET_FULL_DISTRICT_FIRST', EventDataType = 'MOMENT_DATA_DISTRICT', DataType = 'DISTRICT_AERODROME'                   WHERE MomentType = 'BUILDING_CONSTRUCTED_FULL_AERODROME_FIRST';
UPDATE Moments SET EventType = 'MOMENT_RET_FULL_DISTRICT_FIRST', EventDataType = 'MOMENT_DATA_DISTRICT', DataType = 'DISTRICT_ENCAMPMENT'                  WHERE MomentType = 'BUILDING_CONSTRUCTED_FULL_ENCAMPMENT_FIRST';
UPDATE Moments SET EventType = 'MOMENT_RET_FULL_DISTRICT_FIRST', EventDataType = 'MOMENT_DATA_DISTRICT', DataType = 'DISTRICT_ENTERTAINMENT_COMPLEX'       WHERE MomentType = 'BUILDING_CONSTRUCTED_FULL_ENTERTAINMENT_COMPLEX_FIRST';
UPDATE Moments SET EventType = 'MOMENT_RET_FULL_DISTRICT_FIRST', EventDataType = 'MOMENT_DATA_DISTRICT', DataType = 'DISTRICT_WATER_ENTERTAINMENT_COMPLEX' WHERE MomentType = 'BUILDING_CONSTRUCTED_FULL_WATER_ENTERTAINMENT_COMPLEX_FIRST';


UPDATE Moments SET EventType = '', EventDataType = '', DataType = '' WHERE MomentType = '';
UPDATE Moments SET EventType = '', EventDataType = '', DataType = '' WHERE MomentType = '';
UPDATE Moments SET EventType = '', EventDataType = '', DataType = '' WHERE MomentType = '';
UPDATE Moments SET EventType = '', EventDataType = '', DataType = '' WHERE MomentType = '';
UPDATE Moments SET EventType = '', EventDataType = '', DataType = '' WHERE MomentType = '';
UPDATE Moments SET EventType = '', EventDataType = '', DataType = '' WHERE MomentType = '';
UPDATE Moments SET EventType = '', EventDataType = '', DataType = '' WHERE MomentType = '';
UPDATE Moments SET EventType = '', EventDataType = '', DataType = '' WHERE MomentType = '';
UPDATE Moments SET EventType = '', EventDataType = '', DataType = '' WHERE MomentType = '';
*/
