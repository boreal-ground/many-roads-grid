# many-roads

A simple script switcher / menu system for monome grid iii.

## How to install

Designed to run on a monome grid with [iii firmware](https://monome.org/docs/iii/) installed.

Connect to your monome grid using the [diii](https://monome.org/diii/) browser utility, and upload the following files:
- many-roads.lua
- many-roads-data.lua

In the left-hand menu locate **many-roads.lua**, and select **'first'** from the **'...'** menu. See [dii documentation](https://monome.org/docs/iii/diii/) for more guidance on uploading and managing iii scripts.

## In use

On launch many-roads iterates over the lua scripts currently installed on the monome grid, and illuminates an led per script (filtering out init.lua, lib.lua, pset files etc.). A short press on the corresponding key launches that script (the script loads when the key is released). A listing of script to key assignments is output to the dii terminal on script launch.

Many-roads can launch as many scripts as your grid has keys, and is written to be grid-size agnostic. The script was built and tested using a monome 128 grid (late 2022 edition). It should also run on a 256 grid, but is currently untested.

I may add further features in the future.

## Script names on the grid

So you can tell which script is on which key without a computer, many-roads tours through the installed scripts: each script's key is lit brighter in turn while its name (without `.lua`) scrolls across the bottom five rows of the grid, then the tour moves on to the next script.

- **Hold a script key** (longer than 0.4 seconds) to scroll that script's name. The name repeats for as long as you hold the key, and releasing it does not load the script.
- **Press in the text area** to step through the tour by hand: the left half goes back to the previous script, the right half skips forward to the next.

The scrolling text needs the bottom five rows to be free of script keys. If you have too many scripts for that, the text is skipped and only the highlight moves from key to key.

To turn the tour off and get the plain view (all script keys lit evenly, no scrolling text), set `MR.tour = false` at the top of `many-roads-data.lua`. With the tour off, a short press still loads a script, but holding a key and releasing it does nothing.

The timings and brightness can be adjusted at the top of `many-roads-data.lua`:

| Setting | Default | Meaning |
| --- | --- | --- |
| `MR.tour` | `true` | Set to `false` to turn the name tour off |
| `MR.tour_step` | `0.08` | Seconds per column of scrolling text |
| `MR.hold_time` | `0.4` | Seconds a key must be held to show its name instead of loading |
| `MR.led_active` | `4` | Brightness of script keys |
| `MR.led_tour` | `15` | Brightness of the key whose name is scrolling |
| `MR.led_text` | `10` | Brightness of the scrolling text |

## Restart

Do a triple click of the top left key to restart the device and return to many roads.

On iii firmware v1.1.2 and later this uses `device_reset()`, which restarts the Lua environment and runs `init.lua` again (like `^^i` in diii). Before resetting, many-roads sends an All Notes Off message (MIDI CC 123) on all 16 channels so no notes are left hanging. On older firmware it falls back to forcing an out-of-memory error.

## Version history

- **v1.2.2**: Script names scroll across the grid in a tour; hold a key to see its name; press the text area to step through scripts; scripts load on key release; restart uses `device_reset()` where available. By [carlosedp](https://github.com/carlosedp).
- **v1.2.1**: Bugfix release.
- **v1.2**: Memory optimisations and Restart feature by [Quixotic7](https://github.com/Quixotic7).
- **v1.1**: Added support for more than 16 scripts.
- **v1.0**: Initial release.

## Acknowledgements

Credit to [monome](https://monome.org/) for creating the monome grid, and all their work on implementing the iii lua scripting environment.
Particular thanks to tehn for explaining how to retrieve the file listing.

I learned a huge amount about writing lua through reading monome iii and norns scripts generously shared on [lines](https://llllllll.co/).

Memory optimisations and restart feature added by [Quixotic7](https://github.com/Quixotic7).
