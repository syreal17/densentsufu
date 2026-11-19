extends Camera2D

const PAN_SPEED := 400.0


func _process(delta: float) -> void:
	var direction := Vector2(
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))
		- float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
		- float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	)
	position += direction.normalized() * PAN_SPEED * delta
	position = position.clamp(Vector2.ZERO, Vector2(1600, 1600))
