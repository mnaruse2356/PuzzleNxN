class_name TrimImage
extends Node2D


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var button_index = event.get_button_index()
		if button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				_mouse_drag = true
			elif event.is_released():
				_mouse_drag = false
	elif event is InputEventMouseMotion:
		if _mouse_drag:
			_move_image(event.relative)

func _input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		_zoom_image(event.factor)

func _on_area_2d_mouse_exited() -> void:
	_mouse_drag = false

func set_texture(texture: ImageTexture) -> void:
	var image: Sprite2D = $Area2D/Mask/Image
	image.texture = texture
	var image_size = texture.get_size()
	var length: float
	if image_size.x < image_size.y:
		length = image_size.x
	else:
		length = image_size.y
	var disp_scale_factor = _DISP_RECT_SIZE / length
	image.scale.x = disp_scale_factor
	image.scale.y = disp_scale_factor
	_scale_factor = _DISP_RECT_SIZE / $Border.rect_length
	_scale_coefficient = $Border.rect_length / length

func _move_image(move: Vector2) -> void:
	var image: Sprite2D = $Area2D/Mask/Image
	image.position.x += move.x
	image.position.y += move.y
	_limit_image_position(image)

func _zoom_image(factor: float) -> void:
	_scale_factor += clamp(factor, 0.8, 1.5) - 1.0
	_scale_factor = max(_scale_factor, _ZOOM_OUT_LIMIT)
	_set_zoom_image(_scale_factor * _scale_coefficient)

func _set_zoom_image(scale_value: float) -> void:
	var image: Sprite2D = $Area2D/Mask/Image
	image.scale.x = scale_value
	image.scale.y = scale_value
	_limit_image_position(image)

func zoom_in() -> void:
	_scale_factor += _calc_zoom_step()
	_set_zoom_image(_scale_factor * _scale_coefficient)

func zoom_out() -> void:
	_scale_factor -= _calc_zoom_step()
	_scale_factor = max(_scale_factor, _ZOOM_OUT_LIMIT)
	_set_zoom_image(_scale_factor * _scale_coefficient)

func _calc_zoom_step() -> float:
	if _scale_factor >= 1.0:
		return floor(_scale_factor) * 0.1
	else:
		return 0.1

func get_trim_rect() -> Rect2:
	var image: Sprite2D = $Area2D/Mask/Image
	var texture_size = image.texture.get_size()
	var image_position = image.position
	var image_scale = image.scale
	var border_length = $Border.rect_length
	var rect: Rect2
	rect.position.x = texture_size.x * 0.5 - (border_length * 0.5 + image_position.x) / image_scale.x
	rect.position.y = texture_size.y * 0.5 - (border_length * 0.5 + image_position.y) / image_scale.y
	rect.size.x = border_length / image_scale.x
	rect.size.y = border_length / image_scale.y
	return rect

func _limit_image_position(image: Sprite2D) -> void:
	var current_rect = _get_image_scaled_rect(image)
	var border_half = $Border.rect_length * 0.5
	if (current_rect.position.x > -border_half):
		image.position.x = calc_image_position_x(-border_half, image)
	elif (current_rect.position.x + current_rect.size.x < border_half):
		image.position.x = calc_image_position_x(border_half - current_rect.size.x, image)
	if (current_rect.position.y > -border_half):
		image.position.y = calc_image_position_y(-border_half, image)
	elif (current_rect.position.y + current_rect.size.y < border_half):
		image.position.y = calc_image_position_y(border_half - current_rect.size.y, image)

func _get_image_scaled_rect(image: Sprite2D) -> Rect2:
	var texture_size = image.texture.get_size()
	var image_position = image.position
	var image_scale = image.scale
	var rect: Rect2
	rect.position.x = -texture_size.x * 0.5 * image_scale.x + image_position.x
	rect.position.y = -texture_size.y * 0.5 * image_scale.y + image_position.y
	rect.size.x = texture_size.x * image_scale.x
	rect.size.y = texture_size.y * image_scale.y
	return rect

func calc_image_position_x(x: float, image: Sprite2D) -> float:
	return x + image.texture.get_size().x * 0.5 * image.scale.x

func calc_image_position_y(x: float, image: Sprite2D) -> float:
	return x + image.texture.get_size().y * 0.5 * image.scale.y

const _ZOOM_OUT_LIMIT = 1.0
const _DISP_RECT_SIZE = 512

var _mouse_drag = false
var _scale_factor: float = 1.0
var _scale_coefficient: float = 1.0
