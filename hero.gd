extends Node2D

const WALK_SPEED := 120.0
const MAP_MIN := Vector2(8, 12)
const MAP_MAX := Vector2(1592, 1588)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var facing := "down"


func _physics_process(delta: float) -> void:
	var direction := Vector2(
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))
		- float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
		- float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	).normalized()

	if direction != Vector2.ZERO:
		if absf(direction.x) > absf(direction.y):
			facing = "right" if direction.x > 0 else "left"
		else:
			facing = "down" if direction.y > 0 else "up"
		var next_position := (position + direction * WALK_SPEED * delta).clamp(MAP_MIN, MAP_MAX)
		var moving := next_position != position
		position = next_position
		sprite.play(("walk_" if moving else "idle_") + facing)
	else:
		sprite.play("idle_" + facing)
