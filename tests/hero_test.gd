extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("run_checks")


func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1


func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func run_checks() -> void:
	var world := (load("res://world.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	var ground := world.get_node("Ground") as TileMapLayer
	check(ground.get_used_rect() == Rect2i(0, 0, 100, 100), "Marble map must be 100 by 100 tiles")
	check(ground.get_used_cells().size() == 10000, "Marble map must have no empty cells")
	check(ground.tile_set.resource_path == "res://marble_tileset.tres", "Main map must use the marble tileset")
	check((Vector2(ground.tile_set.tile_size) * ground.scale).is_equal_approx(Vector2(16, 16)), "Marble tiles must fit the world scale")
	for source_id in range(3):
		var source := ground.tile_set.get_source(source_id) as TileSetAtlasSource
		check(source != null and source.has_tile(Vector2i.ZERO), "Missing marble atlas tile " + str(source_id))
		if source:
			check(source.texture.resource_path == "res://assets/marble-tileset.png", "Marble atlas must use the supplied texture")
	check((world.get_node("Fountain") as Node2D).position == Vector2(800, 800), "Fountain must be at the map center")
	var road := ground.get_node("Road") as TileMapLayer
	check(road.tile_set.resource_path == "res://marble_road_tileset.tres", "Road must use the marble brick tileset")
	var road_source := road.tile_set.get_source(0) as TileSetAtlasSource
	check(road_source.texture.resource_path == "res://assets/marble-tileset.png", "Road bricks must come from the marble sheet")
	check(road.get_used_rect() == Rect2i(0, 0, 101, 101), "Roads must reach every map edge")
	check(road.get_used_cells().size() == 597, "Roads must form a three-tile-wide cross")
	var road_is_cross := true
	for y in range(101):
		for x in range(101):
			var expected := (x >= 49 and x <= 51) or (y >= 49 and y <= 51)
			if (road.get_cell_source_id(Vector2i(x, y)) == 0) != expected:
				road_is_cross = false
	check(road_is_cross, "Road tiles must form uninterrupted north, south, east, and west routes")
	var road_center := road.to_global(road.map_to_local(Vector2i(50, 50)))
	var road_step := road.to_global(road.map_to_local(Vector2i(51, 50))) - road_center
	check(road_center.is_equal_approx(Vector2(800, 800)), "Roads must be centered on the fountain")
	check(road_step.is_equal_approx(Vector2(16, 0)), "Road tiles must match the floor's world scale")
	var grassland := (load("res://grassland.tscn") as PackedScene).instantiate()
	var grass_ground := grassland.get_node("Ground") as TileMapLayer
	check(grass_ground.get_used_rect() == Rect2i(0, 0, 100, 100), "Original grassland map must be preserved")
	check(grass_ground.tile_set.resource_path == "res://grass_tileset.tres", "Original map must use the grass tileset")
	check((grassland.get_node("Fountain") as Node2D).position == Vector2(688, 784), "Original fountain placement must be preserved")
	var grass_fountain := grassland.get_node("Fountain/AnimatedSprite2D") as AnimatedSprite2D
	check(grass_fountain.autoplay == "default" and grass_fountain.sprite_frames.resource_path == "res://fountain_frames.tres", "Grassland fountain must use the animated frames")
	grassland.free()
	var hero := world.get_node("Hero") as Node2D
	hero.set_physics_process(false)
	var sprite := hero.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var frames := sprite.sprite_frames
	check(world.get_node("Hero/Camera2D") is Camera2D, "Camera does not follow hero")
	check(frames.get_animation_names().size() == 12, "Expected twelve directional animations")
	var row_starts := {
		"idle": [15, 118, 300, 209],
		"walk": [410, 507, 671, 591],
		"sit": [780, 865, 1004, 936],
	}
	var columns := [461, 599, 738, 876]
	for action in ["idle", "walk", "sit"]:
		var directions := ["down", "left", "up", "right"]
		for direction_index in range(directions.size()):
			var direction: String = directions[direction_index]
			var animation: String = action + "_" + direction
			check(frames.has_animation(animation), "Missing animation: " + animation)
			check(frames.get_frame_count(animation) == 4, "Expected four frames: " + animation)
			check(frames.get_animation_loop(animation), "Animation must loop: " + animation)
			for i in range(frames.get_frame_count(animation)):
				var atlas := frames.get_frame_texture(animation, i) as AtlasTexture
				check(atlas != null and atlas.atlas.resource_path == "res://assets/hero2.png", "Wrong sprite sheet: " + animation)
				if atlas:
					check(atlas.get_size() == Vector2(110, 150), "Frame alignment changed: " + animation)
					check(atlas.region.position == Vector2(columns[i], row_starts[action][direction_index]), "Wrong frame region: " + animation)

	var keys := [KEY_DOWN, KEY_LEFT, KEY_UP, KEY_RIGHT]
	var directions := ["down", "left", "up", "right"]
	var offsets := [Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT]
	for i in range(4):
		hero.position = Vector2(300, 300)
		key(keys[i], true)
		hero.call("_physics_process", 1.0)
		check(hero.position.is_equal_approx(Vector2(300, 300) + offsets[i] * 120), "Movement failed: " + directions[i])
		check(sprite.animation == "walk_" + directions[i], "Walking animation failed: " + directions[i])
		key(keys[i], false)
		hero.call("_physics_process", 0.1)
		check(sprite.animation == "idle_" + directions[i], "Idle facing failed: " + directions[i])
	hero.position = Vector2(300, 300)
	key(KEY_W, true)
	key(KEY_D, true)
	hero.call("_physics_process", 1.0)
	check(is_equal_approx(hero.position.distance_to(Vector2(300, 300)), 120.0), "Diagonal movement must be normalized")
	check(sprite.animation == "walk_up", "WASD diagonal animation failed")
	key(KEY_W, false)
	key(KEY_D, false)
	hero.position = Vector2(1592, 1600)
	key(KEY_RIGHT, true)
	key(KEY_DOWN, true)
	hero.call("_physics_process", 1.0)
	check(hero.position == Vector2(1592, 1600), "Hero left map bounds")
	check(sprite.animation == "idle_down", "Blocked hero should use idle animation")
	key(KEY_RIGHT, false)
	key(KEY_DOWN, false)

	for i in range(4):
		hero.position = Vector2(300, 300)
		key(keys[i], true)
		hero.call("_physics_process", 0.1)
		key(keys[i], false)
		key(KEY_SPACE, true)
		hero.call("_physics_process", 0.1)
		check(sprite.animation == "sit_" + directions[i], "Sitting direction failed: " + directions[i])
		var seated_position := hero.position
		hero.call("_physics_process", 0.1)
		check(sprite.animation == "sit_" + directions[i] and hero.position == seated_position, "Holding sit must not toggle or move")
		key(KEY_SPACE, false)
		hero.call("_physics_process", 0.1)
		key(KEY_SPACE, true)
		hero.call("_physics_process", 0.1)
		check(sprite.animation == "idle_" + directions[i], "Standing up failed: " + directions[i])
		key(KEY_SPACE, false)
		hero.call("_physics_process", 0.1)

	key(KEY_SPACE, true)
	hero.call("_physics_process", 0.1)
	key(KEY_SPACE, false)
	hero.call("_physics_process", 0.1)
	var seated_position := hero.position
	key(KEY_RIGHT, true)
	hero.call("_physics_process", 0.1)
	check(sprite.animation == "walk_right" and hero.position.x > seated_position.x, "Moving must stand the hero up")
	key(KEY_RIGHT, false)
	hero.call("_physics_process", 0.1)
	check(sprite.animation == "idle_right", "Hero must remain standing after moving")

	var fountain := world.get_node("Fountain") as StaticBody2D
	check(world.y_sort_enabled, "World must sort the hero and fountain by their ground positions")
	var fountain_sprite := fountain.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var fountain_frames := fountain_sprite.sprite_frames
	check(fountain_sprite.is_playing(), "Fountain animation must start automatically")
	check(fountain_frames.get_frame_count("default") == 8 and fountain_frames.get_animation_loop("default"), "Fountain must loop all eight frames")
	for i in range(8):
		var atlas := fountain_frames.get_frame_texture("default", i) as AtlasTexture
		check(atlas != null and atlas.atlas.resource_path == "res://assets/fountain.png", "Fountain must use the new sheet")
		if atlas:
			check(atlas.region == Rect2((i % 4) * 543, (i / 4) * 362, 543, 362), "Incorrect fountain frame: " + str(i))
	fountain_sprite.set_frame_and_progress(0, 0)
	await create_timer(0.2).timeout
	check(fountain_sprite.frame != 0, "Fountain animation must advance")
	check(fountain.get_node("CollisionPolygon2D") is CollisionPolygon2D, "Fountain footprint is missing")
	for approach in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		hero.position = fountain.position + approach * 140.0
		await physics_frame
		var approach_key: Key
		if approach == Vector2.UP:
			approach_key = KEY_DOWN
		elif approach == Vector2.DOWN:
			approach_key = KEY_UP
		elif approach == Vector2.LEFT:
			approach_key = KEY_RIGHT
		else:
			approach_key = KEY_LEFT
		key(approach_key, true)
		hero.call("_physics_process", 2.0)
		key(approach_key, false)
		var distance := (hero.position - fountain.position).dot(approach)
		check(distance > 25.0 and distance < 100.0, "Fountain should block at its base from " + str(approach))
		if approach == Vector2.UP:
			check(hero.position.y < fountain.position.y, "Hero must be sorted behind the fountain from above")
		elif approach == Vector2.DOWN:
			check(hero.position.y > fountain.position.y, "Hero must be sorted in front of the fountain from below")

	hero.position = fountain.position + Vector2(-60, -44)
	await physics_frame
	key(KEY_RIGHT, true)
	hero.call("_physics_process", 1.0)
	key(KEY_RIGHT, false)
	check(hero.position.is_equal_approx(fountain.position + Vector2(60, -44)), "Hero must be able to walk behind the statuary")

	if failures == 0:
		print("Verified marble roads, animations, sitting, movement, map bounds, and fountain collision and sorting")
	world.queue_free()
	quit(1 if failures else 0)
