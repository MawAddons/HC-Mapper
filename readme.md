# HC Mapper 0.2.0

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

## Controls

- `/hcm` opens the manager.
- `/hcm map` opens the World Map.
- `/hcm dungeon` opens the dungeon browser.
- `/hcm sync` requests a peer refresh.
- On a zone map, click **Add Pin**, then click the map.
- In the dungeon browser, choose a map, click **Add Pin**, then click the map.
- Shift-right-click one of your pin icons to delete it.

World and continent maps display pins created on their underlying zones. New outdoor pins
must be placed on a zone map so HC Mapper has canonical coordinates to project upward.

## License and credits

HC Mapper is distributed under GPL-2.0-or-later. See `LICENSE` and `ATTRIBUTION.md`.
The instance textures come from Atlas-CFM; coordinate data is derived from Astrolabe 0.2.
