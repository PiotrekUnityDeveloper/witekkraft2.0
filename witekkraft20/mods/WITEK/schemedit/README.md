# Schematic Editor [`schemedit`]

## Version
1.8.0

## Description
This is a mod which allows you to edit and export schematics (`.mts` files).

This mod works in Minetest 5.0.0 or later, but recommended is version 5.1.0
or later.

It supports node probabilities, forced node placement and slice probabilities.

It adds 3 items:

* Schematic Creator: Used to mark a region and export or import it as schematic
* Schematic Void: Marks a position in a schematic which should not replace anything when placed as a schematic
* Schematic Node Probability Tool: Set per-node probabilities and forced node placement

Note: The import feature requires Minetest 5.1.0 or later.

It also adds these server commands:

* `placeschem` to place a schematic
* `mts2lua` to convert .mts files to .lua files (Lua code)

There's also a setting `schemedit_export_lua` to enable automatic export to .lua files.

## Quick Start

### Creating a schematic

To create a schematic file:

1. Choose a cuboid area you like to used for a schematic
2. Place a schematic creator in front of one of the bottom 4 corners of that area
3. Use (rightclick) the schematic creator
4. Enter a size and click on “Save size”
5. Enter a schematic name and click on “Export schematic”

The schematic will be saved in your world directory; you’ll see the exact location in chat.

### Importing a schematic

You can import a schematic file for editing if it already exists in your world directory
under `schems`. To import it:

1. Place a schematic creator on the ground
2. Enter the schematic file name
3. Click on “Import schematic”

This will put the schematic in the world and import advanced information like
probabilities, force-placement, schematic voids.

### Placing a schematic

Use the `/placeschem` chat command to place a schematic as if it were placed by the game.
This is useful to test a schematic to see the end result.

Use `/help placeschem` to get a list of parameters.

## Advanced usage

By default, if you export a schematic and then place it, every node will be placed,
including air. This is because the air is exported, too. This is by design.

But you can place a special Schematic Void to mark positions that should not be overridden
when the schematic is placed. This is very useful for trees.

You can also set probabilities for certain nodes to be placed, or tell the game to
force-place nodes.

For detailed information read `USAGE.md`.

You can also find the same help texts in-game if you if you use the optional Help modpack
(mods `doc` and `doc_items`).

For general information on how schematics work, please refer to the Minetest Lua API
documentation.

## License of everything
MIT License
