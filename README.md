# densentsufu

The main scene, `world.tscn`, is a 100 × 100 marble tile map using
`marble_tileset.tres`. Its ground layer is scaled so each tile occupies
16 × 16 world units. The original grassland and cobblestone roads are
preserved in `grassland.tscn`, using `grass_tileset.tres`.
Open either scene in Godot to edit it. Run the project and use WASD or the
arrow keys to walk around.
The hero faces the direction of travel and has directional walking and idle animations.
Press Space to sit or stand; walking also stands the hero up.
The fountain blocks movement at its base; the hero
can walk behind its statuary or in front of it.

Run the hero checks with `godot --headless --path . --script res://tests/hero_test.gd`.
