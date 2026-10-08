# Fishing Helper

Fishing Helper is a World of Warcraft addon designed to simplify the fishing experience for **World of Warcraft: Forever**, Classic Era, and TBC Classic. It allows you to manage your fishing outfit and lures, provides a single button for equipping gear and casting the fishing spell, and includes quality-of-life features like automatic volume enhancement and auto-loot toggling.

## Features

- **One-Button Fishing**: A single macro button handles everything. Press it to automatically equip your configured fishing gear, apply a lure if needed, and cast the Fishing spell.
- **Outfit Management**: Configure your fishing gear (Fishing Pole, Hat, Gloves, and Boots) via an intuitive graphical interface. Simply drag and drop items into the slots or select them from the popup menu.
- **Lure Management**: Assign a specific lure (including classic lures and WoW Forever's *"Secret" Bait*) to auto-apply whenever your fishing pole lacks an active lure or enchant. The UI displays your current stock of that lure.
- **Quality-of-Life Sound**: Automatically increases the game's Master and SFX volume while you are actively channeling the Fishing spell, making it easier to hear the bobber splash. The volume is restored to its original level when you stop casting.
- **Auto-Loot**: Automatically enables the game's Auto Loot feature when your fishing gear is equipped.
- **Restore Previous State**: A convenient "Stop Fishing" button will unequip your fishing outfit, restore your previously equipped gear, and revert your Auto Loot setting.
- **Minimap Keybindings Menu & Addon Compartment**: Right-click the minimap button to open a settings panel and configure your Cast Fishing and Stop Fishing keybinds directly. Supports keyboard keys, modifiers, mouse buttons (like Mouse Button 4/5), and the mouse scroll wheel. Also integrates directly into the modern Addon Compartment dropdown.
- **World Map Fishing Level Display**: Displays the required Fishing skill to never miss catching a fish (0% getaway chance) directly at the top of the in-game map, right next to the area name drop-down menu. Includes a rich tooltip showing minimum cast skill, your character's current skill, catch status, and zone notes.

## Slash Commands

- `/fh` - Toggles the Fishing Helper configuration frame.

## Usage

1. Type `/fh` in chat to open the Fishing Helper frame (or click the minimap icon / Addon Compartment entry).
2. Drag and drop your fishing pole, fishing hat, gloves, boots, and preferred lure into the corresponding slots on the frame. To clear a slot, right-click it.
3. Drag the main action button from the top-left of the frame onto your standard action bar, or set a keybind for it. The dragged macro will dynamically update its icon and tooltip to show exactly what action it will perform next!
4. Click your action bar button (or press your keybind) to start fishing!
    - **First click**: Equips your configured fishing gear.
    - **Second click**: Applies the configured lure to your fishing pole (if the pole does not currently have a lure or enchant).
    - **Subsequent clicks**: Casts the Fishing spell.
5. When you are finished fishing, open the configuration frame (`/fh`) and click **Stop Fishing**. This will restore the gear you were wearing before you started fishing and revert your auto-loot preference.

## Installation

1. Download the latest release.
2. Extract the `FishingHelper` folder into your World of Warcraft AddOns directory (e.g. `World of Warcraft\_classic_beta_\Interface\AddOns\FishingHelper`).
3. Ensure the addon is enabled in the AddOn selection screen when logging in.
