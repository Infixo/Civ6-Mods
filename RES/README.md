# Real Era Stop

*New v3.2 as of 11.04 - World Congress fix, Future era added.*

Allows to stop the game at a specific Era, **from Classical to Information**. This mod literally removes all techs, civics, and items associated with them that are from eras past the last one. For R&F it also removes Game Eras past last one, so the game won't accidentally progress into the next era.

**Important!** The Last Era is set via Advanced Options when the game is created. See the attached screenshot. The Calendar is set also in Advanced Options by selecting it from Game Speed dropbox. Do **not** use *No turn limit* option when setting up a game - see Known Issues.

Links: [CivFanatics](http://forums.civfanatics.com/resources/real-era-stop.25998) [GitHub (RES)](https://github.com/Infixo/Civ6-Mods)

## How to use

When you create a game, go to the Advanced Options and choose Last Era from the dropdown list. See the screenshot.
There is also "Future Era" available and this is a default option since v3.2. This allows for the mod to stay enabled all the time and just use it whenever you need.

## Custom Calendars (*optional* functionality for better immersion)
Allows you to choose in Advanced Options a custom Game Speed that will make the dates displayed in the top right corner aligned with chosen Last Era. E.g. if you choose Renaissance, after 500 turns the date will be 1745 AD. Or if ou choose Medieval, after 500 turns the date will be 1400 AD. Please note that these calendars are only for [u]standard[/u] game speeds.

## Notes

- The mod is designed to be used together with [Real Tech Tree](http://steamcommunity.com/sharedfiles/filedetails/?id=871465857). RTT fills gaps in trees so the Future Tech and Future Civic will work as intended. You can use RES without RTT, but due to many gaps in vanilla trees, there will be techs and civics "hanging" without connection to Future Tech and Future Civic.
- For balance purposes if you choose Medieval as the last Era, Monarchy is removed from the tree. It's because other 2 govs from 2nd tier govs are not available until Renaissance.
- Shipwrecks are moved earlier if last Era is Industrial or Modern. It seems that without them game crashes when an Archaeologist is trainied.
- For Medieval - Cartography is moved to Medieval (without Caravels), so ocean-crossing is available.
- For Classical - all land units can embark when Celestial Navigation is researched and researching Shipbuilding allows for ocean crossing (tweak).
- For Classical - Lumber Mill is moved to Engineering (this is to fix Goody Hut situation - the MapUtilities.lua script uses a row id from database to mark Goody Huts, so there cannot be any deleted rows before GH for it to work correctly).
- Gathering Storm - Flood Barrier is moved earlier and has adjusted cost if the last era is Industrial or Modern. For Industrial - to Sanitation, costs 70%. For Modern - to Electricity, costs 85%.
- World Congress - The Patronage Resolution is valid only till the era before the last one i.e it should never be selected during the last era. This should prevent the situation when all Great People are gone and the resolution is still selected in the WC.

## Great People

Some Great People have bonuses related to Eras beyond the last one. This may cause a CTD (e.g. when triggering a boost for a tech that's not there). Also, makes those GPs less valuable. To fix this the following changes are applied:
- If a GP boosts a specific tech that's not available, it will boost a tech from the last Era (i.e. Sheng - Education, Lovelace - Economics or Electricity, Mendeleev - Scientific Theory, Turing - Electricity, Goddard - Chemistry),
- If a GP boosts some random techs/civics from an Era beyond the last one, he/she will simply boost techs/civics from the last Era (there are many cases like this),
- If a GP grants a unit that is not available any more - another one will be granted instead (one case, Yi Sun Sin will grant Caravel instead of Ironclad).
- **Important!** Please note that the descriptions for those GPs are not changed! E.g. for Bi Sheng it will always say that he grants Printing, even if last Era will be Medieval (in which case he will grant a boost for Education, despite the description). Sorry for that little inconvinience.

## Compatibility notes

- Can be used with any other mod that adds new units and/or buildings (normal and unique), tested for *Wondrous Wonders* and *Moar Units*.
- The Production Queue mod (the old one) will not work if last era is Renaissance or earlier.

## Known issues

- Do **not** use *No turn limit* option when setting up a game. It will make the game progress to the era past the last one causing issues with World Congress. If you want to play longer, use custom turn limit and set it to e.g. 1000 or bigger.
