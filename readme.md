# DragonUI for WotLK 3.3.5a

![Interface Version](https://img.shields.io/badge/Interface-30300-blue)
![WoW Version](https://img.shields.io/badge/WoW-3.3.5a-orange)
![Status](https://img.shields.io/badge/Status-Stable-green)

A personal project bringing Dragonflight UI aesthetics to WotLK 3.3.5a.

![DragonUI Interface](https://i.postimg.cc/L8MPT006/1.png)

![DragonUI Features](https://i.postimg.cc/KYk0MWKc/3.png)


## Features

*   **Unit Frames:** Player, Target, Focus, and Party frames with ToT/ToF support
*   **Micro Menu:** Enhanced design with player portrait and faction-based PvP indicators
*   **Cast Bars:** Improved casting bars with modern styling
*   **Minimap:** Redesigned with better integration and customization options
*   **Comprehensive Configuration:** Extensive in-game options panel with customization for positioning, scaling and visual elements
*   **Profile Management:** Save and switch between different UI configurations per character
*   **Conflict Detection:** Warns about potentially conflicting addons

## Installation

1. Download the latest release from the [Releases page](https://github.com/NeticSoul/DragonUI/releases/tag/v1.0.3)
2. Extract the downloaded ZIP file
3. Rename the extracted folder from `DragonUI-x.x.x` to `DragonUI`
4. Move the `DragonUI` folder to `Interface\AddOns`
5. Enable the addon in-game
6. Open the configuration panel via ESC menu > DragonUI button or type `/dragonui`
7. Customize positioning, scaling and visual elements to your preference

## Notes

This addon is not finished and may contain bugs. I'm working on it alone while still learning, so some parts of the code might look a bit wild - but that's the plan, to improve it over time.

If you're interested in helping develop it or making improvements, contributions are welcome! There's definitely room for optimization and fixes.

## Known Issues

- **Party Frames Vehicle Bug:** Party frames do not display correctly when party members enter vehicles

## Credits

This project combines and adapts code from several sources:

- **[s0h2x](https://github.com/s0h2x)** - Two specific addons: one for action bars and another for minimap, which have been merged and integrated into DragonUI
- **[KarlHeinz_Schneider - Dragonflight UI (Classic)](https://www.curseforge.com/wow/addons/dragonflight-ui-classic)** - Original addon from which many elements have been taken and backported/adapted to 3.3.5a, including the micro menu and other features built from scratch based on this design
- **[TheLinuxITGuy - Chromie-Dragonflight](https://github.com/TheLinuxITGuy/Chromie-Dragonflight)** - Used as reference for implementation approaches and some adapted code solutions

## Special Thanks

- **CromieCraft Community** - For helping test and provide feedback on various addon features
- **Teknishun** - Special thanks for extensive testing and valuable feedback
