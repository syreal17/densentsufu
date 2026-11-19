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
	var hero := world.get_node("Hero") as Node2D
	hero.set_physics_process(false)
	var sprite := hero.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var frames := sprite.sprite_frames
	check(world.get_node("Hero/Camera2D") is Camera2D, "Camera does not follow hero")
	check(frames.get_animation_names().size() == 8, "Expected eight directional animations")
	for action in ["idle", "walk"]:
		for direction in ["down", "left", "up", "right"]:
			var animation: String = action + "_" + direction
			check(frames.has_animation(animation), "Missing animation: " + animation)
			check(frames.get_frame_count(animation) == 4, "Expected four frames: " + animation)
			check(frames.get_animation_loop(animation), "Animation must loop: " + animation)

	var keys := [KEY_DOWN, KEY_LEFT, KEY_UP, KEY_RIGHT]
	var directions := ["down", "left", "up", "right"]
	var offsets := [Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT]
	for i in range(4):
		hero.position = Vector2(800, 800)
		key(keys[i], true)
		hero.call("_physics_process", 1.0)
		check(hero.position.is_equal_approx(Vector2(800, 800) + offsets[i] * 120), "Movement failed: " + directions[i])
		check(sprite.animation == "walk_" + directions[i], "Walking animation failed: " + directions[i])
		key(keys[i], false)
		hero.call("_physics_process", 0.1)
		check(sprite.animation == "idle_" + directions[i], "Idle facing failed: " + directions[i])
	hero.position = Vector2(800, 800)
	key(KEY_W, true)
	key(KEY_D, true)
	hero.call("_physics_process", 1.0)
	check(is_equal_approx(hero.position.distance_to(Vector2(800, 800)), 120.0), "Diagonal movement must be normalized")
	check(sprite.animation == "walk_up", "WASD diagonal animation failed")
	key(KEY_W, false)
	key(KEY_D, false)
	hero.position = Vector2(1592, 1588)
	key(KEY_RIGHT, true)
	key(KEY_DOWN, true)
	hero.call("_physics_process", 1.0)
	check(hero.position == Vector2(1592, 1588), "Hero left map bounds")
	check(sprite.animation == "idle_down", "Blocked hero should use idle animation")
	key(KEY_RIGHT, false)
	key(KEY_DOWN, false)

	if failures == 0:
		print("Verified all eight animations, directional movement, idle facing, and map bounds")
	world.queue_free()
	quit(1 if failures else 0)
