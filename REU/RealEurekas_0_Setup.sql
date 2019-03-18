--------------------------------------------------------------
-- Real Eurekas
-- Author: Infixo
-- 2019-03-14: Created
--------------------------------------------------------------



-- INSTRUCTIONS
-- There are 3 lines with INSERT statement. It contains so called 'random seed' that determines what boosts will be selected.
-- Depending on your preference and if you play MP or SP games, uncomment ONLY ONE statement. The other two must be commented out.



-- OPTION A - for SP & MP
-- Use this option when you want to randomize boosts once and play entire game with this set.
-- Enable it and put any number instead of 987654321. As long as this number stays the same, the mod will generate the same set of boosts.
-- Different number will give a different set. Please use numbers that have 6 to 9 digits.
-- This is an option for MultiPlayer games. Select a number and make sure that other players also use the same number.
-- That way all players will have the same boosts and they will stay the same through the entire game.
-- This option is also for SinglePlayer if you want to play entire game with the same set of boosts.

--INSERT INTO GlobalParameters (Name, Value) VALUES ('REU_RANDOM_SEED', '987654321');



-- OPTION B - for SP
-- This option rolls randomly new set of boosts each time the game is started or re-loaded.
-- It is basically the same as the mod has been working so far.
-- If you don't mind that boosts change very often then use it.
-- Please do NOT change anything in the statement (except comment ofc).

--INSERT INTO GlobalParameters (Name, Value) VALUES ('REU_RANDOM_SEED', STRFTIME("%d%H%M%S"));



-- OPTION C - for SP
-- This option rolls randomly new set of boosts but it will change every day.
-- If you start a new game or reload a game within the same day - the boosts will be the same.
-- This option is for people who don't like when boosts change every time the game is reloaded, but would like some variety. New day - new boosts :)
-- Please do NOT change anything in the statement (except comment ofc).

INSERT INTO GlobalParameters (Name, Value) VALUES ('REU_RANDOM_SEED', STRFTIME("%Y%m%d"));
