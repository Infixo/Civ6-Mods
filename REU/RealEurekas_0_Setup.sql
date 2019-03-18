--------------------------------------------------------------
-- Real Eurekas
-- Author: Infixo
-- 2019-03-14: Created
--------------------------------------------------------------



-- INSTRUCTIONS
-- There are 3 lines with INSERT statement. It contains so called 'random seed' that determines what boosts will be selected.
-- Depending on your preference and if you play MP or SP games, uncomment ONLY ONE statement. The other two must be commented out.



-- OPTION A - for SP & MP
-- This is an option for MultiPlayer games. Put any number you want instead of 987654321 and make sure that other players also use the same number.
-- That way all players will have the same boosts and they will stay the same through the entire game.
-- This option is also for SinglePlayer if you want to play entire game with the same set of boosts.
-- As long as the number is the same, the mod will select the same boosts. Different number will give a different set.

--INSERT INTO GlobalParameters (Name, Value) VALUES ('REU_RANDOM_SEED', '987654321');



-- OPTION B - for SP
-- This option rolls randomly new set of boosts each time the game is started or re-loaded.
-- It is basically as the mod has been working so far. 
-- Please do NOT change anything in the statement (except comment ofc).

--INSERT INTO GlobalParameters (Name, Value) VALUES ('REU_RANDOM_SEED', STRFTIME("%d%H%M%S"));



-- OPTION C - for SP
-- This option rolls randomly new set of boosts but it will change every day.
-- As long as you start a new game or reload a game within the same day - the boosts will be the same.
-- This option is for people you don't like when boosts change every time the game is reloaded, but would like some variety. New day - new boosts :)
-- Please do NOT change anything in the statement (except comment ofc).

INSERT INTO GlobalParameters (Name, Value) VALUES ('REU_RANDOM_SEED', STRFTIME("%Y%m%d"));
