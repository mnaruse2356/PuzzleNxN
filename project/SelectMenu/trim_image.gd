class_name TrimImage
extends Node2D

func _ready() -> void:
	var os = OS.get_name()
	if (os == "iOS" || os == "Android"):
		_mouse_wheel_enabled = false
	elif OS.has_feature("web_android") || OS.has_feature("web_ios"):
		_mouse_wheel_enabled = false
		_web_mobile = true
	else:
		_mouse_wheel_enabled = true

func _process(delta: float) -> void:
	if _web_mobile:
		var pt0 = _touch_pos[0]
		var pt1 = _touch_pos[1]
		if pt0 != null && pt1 != null:
			var length = (pt0 - pt1).length()
			var diff = length - _prev_touch_length
			if (_prev_touch_length > 0 && absf(diff) > 2.0):
				var factor = diff * 0.005 + 1.0
				_zoom_image(factor)
			_prev_touch_length = length
			_mouse_drag = false

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var button_index = event.get_button_index()
		if button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				_mouse_drag = true
			elif event.is_released():
				_mouse_drag = false
		elif _mouse_wheel_enabled:
			if event.is_pressed():
				if button_index == MOUSE_BUTTON_WHEEL_DOWN:
					_mouse_drag = false
					zoom_in()
				elif button_index == MOUSE_BUTTON_WHEEL_UP:
					_mouse_drag = false
					zoom_out()
	elif event is InputEventMouseMotion:
		if _mouse_drag:
			_move_image(event.relative)

func _input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		_mouse_drag = false
		_zoom_image(event.factor)
	elif _web_mobile:
		if event is InputEventScreenTouch:
			if event.pressed:
				if event.index > 0:
					_mouse_drag = false
			else:
				_touch_pos[event.index] = null
				_prev_touch_length = 0.0
		if event is InputEventScreenDrag:
			_touch_pos[event.index] = event.position

func _on_area_2d_mouse_exited() -> void:
	_mouse_drag = false

func _on_button_rotate_pressed() -> void:
	var image = $Area2D/Mask/Image
	image.global_rotation_degrees += 90
	rotate_num += 1
	if rotate_num > 4:
		rotate_num -= 4
	_limit_image_position(image)

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
	if rotate_num % 2 == 1:
		rect.position.x = texture_size.y * 0.5 - (border_length * 0.5 + image_position.x) / image_scale.y
		rect.position.y = texture_size.x * 0.5 - (border_length * 0.5 + image_position.y) / image_scale.x
		rect.size.x = border_length / image_scale.y
		rect.size.y = border_length / image_scale.x
	else:
		rect.position.x = texture_size.x * 0.5 - (border_length * 0.5 + image_position.x) / image_scale.x
		rect.position.y = texture_size.y * 0.5 - (border_length * 0.5 + image_position.y) / image_scale.y
		rect.size.x = border_length / image_scale.x
		rect.size.y = border_length / image_scale.y
	return rect

func _limit_image_position(image: Sprite2D) -> void:
	var current_rect = _get_image_scaled_rect(image)
	var border_half = $Border.rect_length * 0.5
	if (current_rect.position.x > -border_half):
		image.position.x = _calc_image_position_x(-border_half, image)
	elif (current_rect.position.x + current_rect.size.x < border_half):
		image.position.x = _calc_image_position_x(border_half - current_rect.size.x, image)
	if (current_rect.position.y > -border_half):
		image.position.y = _calc_image_position_y(-border_half, image)
	elif (current_rect.position.y + current_rect.size.y < border_half):
		image.position.y = _calc_image_position_y(border_half - current_rect.size.y, image)

func _get_image_scaled_rect(image: Sprite2D) -> Rect2:
	var texture_size = image.texture.get_size()
	var image_position = image.position
	var image_scale = image.scale
	var rect: Rect2
	if rotate_num % 2 == 1:
		rect.position.x = -texture_size.y * 0.5 * image_scale.y + image_position.x
		rect.position.y = -texture_size.x * 0.5 * image_scale.x + image_position.y
		rect.size.x = texture_size.y * image_scale.y
		rect.size.y = texture_size.x * image_scale.x
	else:
		rect.position.x = -texture_size.x * 0.5 * image_scale.x + image_position.x
		rect.position.y = -texture_size.y * 0.5 * image_scale.y + image_position.y
		rect.size.x = texture_size.x * image_scale.x
		rect.size.y = texture_size.y * image_scale.y
	return rect

func _calc_image_position_x(x: float, image: Sprite2D) -> float:
	if rotate_num % 2 == 1:
		x += image.texture.get_size().y * 0.5 * image.scale.y
	else:
		x += image.texture.get_size().x * 0.5 * image.scale.x
	return x

func _calc_image_position_y(y: float, image: Sprite2D) -> float:
	if rotate_num % 2 == 1:
		y += image.texture.get_size().x * 0.5 * image.scale.x
	else:
		y += image.texture.get_size().y * 0.5 * image.scale.y
	return y

const _ZOOM_OUT_LIMIT = 1.0
const _DISP_RECT_SIZE = 512

var _mouse_drag = false
var _scale_factor: float = 1.0
var _scale_coefficient: float = 1.0

var _mouse_wheel_enabled = false

var _web_mobile = false
var _touch_pos = [null, null]
var _prev_touch_length = 0.0

var rotate_num: int = 0
