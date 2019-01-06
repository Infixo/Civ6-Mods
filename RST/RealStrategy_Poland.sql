-- ===========================================================================
-- Real Strategy - main file for Poland DLC
-- Author: Infixo
-- 2019-01-05: Created
-- ===========================================================================

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('LEADER_JADWIGA', 'LEADER', '', 'CONQUEST', 4),
('LEADER_JADWIGA', 'LEADER', '', 'SCIENCE',  1),
('LEADER_JADWIGA', 'LEADER', '', 'CULTURE',  4),
('LEADER_JADWIGA', 'LEADER', '', 'RELIGION', 7);


-- JADWIGA / POLAND

UPDATE AiFavoredItems SET Value = 25 WHERE ListType = 'JadwigaUnitBuilds' AND Item = 'UNIT_MILITARY_ENGINEER'; -- was 1

INSERT INTO AiListTypes (ListType) VALUES
('JadwigaDiplomacy'),
('JadwigaPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('JadwigaDiplomacy',    'TRAIT_LEADER_LITHUANIAN_UNION', 'DiplomaticActions'),
('JadwigaPseudoYields', 'TRAIT_LEADER_LITHUANIAN_UNION', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('JadwigaDiplomacy', 'DIPLOACTION_PROPOSE_TRADE', 1, 0),
('JadwigaDiplomacy', 'DIPLOACTION_ALLIANCE', 1, 0),
('JadwigaPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_BONUS', 1, 5),
('JadwigaPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 50),
('JadwigaPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, 15),
('JadwigaPseudoYields', 'PSEUDOYIELD_GPP_MERCHANT', 1, 15),
('JadwigaPseudoYields', 'PSEUDOYIELD_GREATWORK_RELIC', 1, 20),
('JadwigaPseudoYields', 'PSEUDOYIELD_UNIT_RELIGIOUS', 1, 10);


/*
TODO: LuaScript
UNIT_MILITARY_ENGINEER
nothing special about him in the files - probably NOT used
		<Row UnitType="UNIT_MILITARY_ENGINEER" AiType="UNITTYPE_SIEGE_SUPPORT"/> (same as all Support Units), used ONLY in Siege City Assault => used in BH Trees
		<Row UnitType="UNIT_MILITARY_ENGINEER" AiType="UNITAI_BUILD"/> - flag that it can build on the map, same as Builder and Roman Legion => where is it used???
		<Row UnitType="UNIT_MILITARY_ENGINEER" AiType="UNITTYPE_CIVILIAN"/> => Used in BH Trees
		
Trees:
Build Trigger Improvement - generic, get unit, go to spot, clear, build - not used anywhere, no references!
Build City Improvement - same as above, but also reserves a plot, in DefaultCityBuilds and MinorCivBuilds, handles Boosts also

Also, Action 'Build Military Improvement' is available but only used during war time, so no Forts in peace time.
*/
