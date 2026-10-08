# HC Mapper 0.5.4

Version 0.5.4 adds one shared, rate-limited MawAddons peer version check. A newer peer version produces one update notice with `https://github.com/MawAddons/HC-Mapper`.

HC Mapper is a lightweight map pin addon for World of Warcraft 1.12.1. Players can create
pins on zone maps or included Vanilla dungeon maps and automatically exchange shared pins
with nearby peers using a hidden, rate-limited channel.

## First working release

- Zone pins are projected onto the matching zone, continent, and Azeroth world maps.
- 42 bundled Vanilla dungeon, raid, wing, and entrance maps.
- Dungeon pins use coordinates on the selected instance map.
- Seven categories: Danger, Treasure, Vendor, Profession, Resource, Travel, and Note.
- Sharing scopes: Peers, Guild, or Private.
- Account-wide pins, peer cache, ownership-aware deletion, and seven-day delete tombstones.
- Automatic sync with five-second pacing, six-message-per-minute rate limit, coalescing,
  bounded queues, and thirty-day expiry for cached peer pins.
- World Map controls, dungeon browser, manager window, and minimap button.
- Movable minimap button with a map icon; left-click opens the manager and right-click opens dungeon maps.
- Mockup-inspired unified map dashboard with World, Continent, Zone, and Dungeon tabs.
- Drag your own zone or dungeon pins directly; changes remain a local draft until Save and can be discarded with Undo.
- Movable title bar and matching minimize/restore control.
- Fully automatic, rotating peer snapshots keep a local pin database on every client; no manual push is required.
- Shared deletion is owner-only and requires confirmation; forged remote deletes are ignored.
- Native-style map navigation: left-click drills World to Continent to Zone, while right-click goes back.
- Character-specific discovered-area overlays use the same exploration data as the default World Map.
- Click a pin in the map or manager list to open its exact zone or dungeon map.
- Choose from a 25-icon palette including question, danger, information, bank, crossed swords, herbs, professions, travel, and dungeon symbols.
- Your position and current party or raid members are shown live on outdoor dashboard maps.
- The New Pin editor is a modal dialog above the map, so creating a pin always gives immediate visual feedback.
- The minimap icon and `/hcm` now open Blizzard's standard World Map at its native size and position; HC Mapper only adds pins and compact controls on top.
- The pin editor can always be dismissed with its standard X button, Cancel, or Escape.
- Pins, Dungeons, and Add Pin are placed in a compact bottom-right map toolbar so they do not overlap the native continent, zone, or zoom controls.
- The searchable, filterable pin manager is now a bordered drawer inside the standard World Map instead of a differently-sized map window.
- Zone lookup is read-only: arming Add Pin cannot cycle through or change the currently selected map zone.
- Map toolbar buttons are kept above map overlays for reliable clicks, and the minimap tooltip displays the installed addon version.
- Shift-right-click deletion uses a dedicated modal confirmation above the World Map and pin-manager drawer.

## Controls

- `/hcm` and `/hcm map` open the standard World Map.
- `/hcm pins` opens the standard World Map with its integrated pin-manager drawer.
- `/hcm dungeon` opens the dungeon browser.
- On a zone map, click **Add Pin**, then click the map.
- In the dungeon browser, choose a map, click **Add Pin**, then click the map.
- Shift-right-click one of your pin icons to delete it.
- Left-click the dashboard map to zoom in and right-click to zoom out, just like the default World Map.

World and continent maps display pins created on their underlying zones. New outdoor pins
must be placed on a zone map so HC Mapper has canonical coordinates to project upward.

## License and credits

HC Mapper is distributed under GPL-2.0-or-later. See `LICENSE` and `ATTRIBUTION.md`.
The instance textures come from Atlas-CFM; coordinate data is derived from Astrolabe 0.2.
