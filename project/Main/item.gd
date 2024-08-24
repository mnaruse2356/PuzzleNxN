class_name Item
extends Node2D

signal moved_neighbour(item)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_mouse_drag = false
	pass # Replace with function body.

func _on_area_2d_mouse_exited() -> void:
	if _mouse_drag:
		_mouse_drag = false
		_end_move()

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if (_allow_input != Direction.NONE):
		if event is InputEventMouseButton:
			if event.get_button_index() == MOUSE_BUTTON_LEFT:
				if event.is_pressed():
					_source_position = position
					_mouse_drag = true
				elif event.is_released():
					if _mouse_drag:
						_mouse_drag = false
						_end_move()
		elif event is InputEventMouseMotion:
			if _mouse_drag:
				_moving(event.relative)

func _moving(move: Vector2) -> void:
	match _allow_input:
		Direction.UP:
			var moved_y = position.y + move.y
			position.y = clamp(moved_y, _source_position.y - _move_unit_height, _source_position.y)
		Direction.DOWN:
			var moved_y = position.y + move.y
			position.y = clamp(moved_y, _source_position.y, _source_position.y + _move_unit_height)
		Direction.LEFT:
			var moved_x = position.x + move.x
			position.x = clamp(moved_x, _source_position.x - _move_unit_width, _source_position.x)
		Direction.RIGHT:
			var moved_x = position.x + move.x
			position.x = clamp(moved_x, _source_position.x, _source_position.x + _move_unit_width)

func _end_move() -> void:
		match _allow_input:
			Direction.UP:
				if absf(position.y - _source_position.y) > _move_unit_height * 0.7:
					position.y = _source_position.y - _move_unit_height
					_move_position()
				else:
					_revert_position()
			Direction.DOWN:
				if absf(position.y - _source_position.y) > _move_unit_height * 0.7:
					position.y = _source_position.y + _move_unit_height
					_move_position()
				else:
					_revert_position()
			Direction.LEFT:
				if absf(position.x - _source_position.x) > _move_unit_width * 0.7:
					position.x = _source_position.x - _move_unit_width
					_move_position()
				else:
					_revert_position()
			Direction.RIGHT:
				if absf(position.x - _source_position.x) > _move_unit_width * 0.7:
					position.x = _source_position.x + _move_unit_width
					_move_position()
				else:
					_revert_position()

func _revert_position() -> void:
	position = _source_position

func _move_position() -> void:
	moved_neighbour.emit(self)

func setup(texture: Texture2D, div: int, x: int, y: int) -> void:
	sprite.texture = texture
	var unit_width: float = texture.get_width() / float(div)
	var unit_height: float = texture.get_height() / float(div)
	var rect: Rect2
	rect.size.x = unit_width
	rect.size.y = unit_height
	rect.position.x = unit_width * x
	rect.position.y = unit_height * y
	sprite.region_rect = rect
	border.points[0].x = - unit_width * 0.5
	border.points[0].y = - unit_height * 0.5
	border.points[1].x = unit_width * 0.5
	border.points[1].y = - unit_height * 0.5
	border.points[2].x = unit_width * 0.5
	border.points[2].y = unit_height * 0.5
	border.points[3].x = - unit_width * 0.5
	border.points[3].y = unit_height * 0.5
	collision.shape.size.x = unit_width
	collision.shape.size.y = unit_height
	pos_x = x
	pos_y = y
	_move_unit_width = unit_width
	_move_unit_height = unit_height
	_allow_input = Direction.NONE

func setup_scale(x: float, y: float) -> void:
	scale.x = x
	scale.y = y
	_move_unit_width *= x
	_move_unit_height *= y

func set_allow_input(direction: int) -> void:
	_allow_input = direction

func clear_allow_input() -> void:
	_allow_input = Direction.NONE

@onready var sprite: Sprite2D = $Area2D/Sprite
@onready var border: Line2D = $Area2D/Border
@onready var collision: CollisionShape2D = $Area2D/Collision
var _source_position: Vector2
var _move_unit_width: float
var _move_unit_height: float
var _allow_input: int = Direction.NONE

var _mouse_drag: bool

var pos_x: int
var pos_y: int
var original_index: int
