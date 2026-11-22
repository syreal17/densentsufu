extends CharacterBody2D

const WALK_SPEED := 120.0
const MAP_MIN := Vector2(8, 27)
const MAP_MAX := Vector2(1592, 1600)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var facing := "down"
var sitting := false
var sit_key_held := false


func _physics_process(delta: float) -> void:
	var sit_pressed := Input.is_key_pressed(KEY_SPACE)
	if sit_pressed and not sit_key_held:
		sitting = not sitting
	sit_key_held = sit_pressed

	var direction := Vector2(
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))
		- float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
		- float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	).normalized()

	if direction != Vector2.ZERO:
		sitting = false
		if absf(direction.x) > absf(direction.y):
			facing = "right" if direction.x > 0 else "left"
		else:
			facing = "down" if direction.y > 0 else "up"
		var next_position := (position + direction * WALK_SPEED * delta).clamp(MAP_MIN, MAP_MAX)
		var previous_position := position
		var collision := move_and_collide(next_position - position)
		if collision:
			move_and_collide(collision.get_remainder().slide(collision.get_normal()))
		var moving := not position.is_equal_approx(previous_position)
		sprite.play(("walk_" if moving else "idle_") + facing)
	else:
		sprite.play(("sit_" if sitting else "idle_") + facing)
