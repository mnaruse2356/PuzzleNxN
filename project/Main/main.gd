#
# Copyright (c) 2024 NARUSE Masahiro
# This software is released under the MIT License, see License.
#
class_name Main
extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	confirmDialog = ConfirmDialog
	confirmDialog.connect("confirmed", _on_confirm_dialog_confirmed)
	_setup_window()
	_apply_unit_size()
	_setup_puzzle()
	$GiveUpButton.visible = false

func _process(delta: float) -> void:
	_elapsed_delta = delta
	pass

func _notification(what: int) -> void:
	match what:
		Node.NOTIFICATION_WM_GO_BACK_REQUEST:
			if confirmDialog.visible:
				confirmDialog.hide()
			else:
				if $GiveUpButton.is_visible_in_tree():
					confirmDialog.setup_contents(ConfirmDialog.Contents.GIVEUP)
					confirmDialog.popup_centered()
				elif $Menu/BackButton.is_visible_in_tree():
					confirmDialog.setup_contents(ConfirmDialog.Contents.SELECTMENU)
					confirmDialog.popup_centered()

func _on_start_button_pressed() -> void:
	$Menu.visible = false
	await _start_puzzle()
	$GiveUpButton.visible = true

func _on_item_moved_neighbour(item: Item):
	_clear_movable_items()
	_moved_play_item(item.pos_x, item.pos_y)
	if _judge_win():
		_exit_puzzle(true)
	else:
		_setup_movable_items()

func _on_divide_slider_drag_ended(value_changed: bool):
	if value_changed:
		divide_num = round($Menu/DivideSlider.value)
		for item in play_items:
			item.queue_free()
		play_items.clear()
		_apply_unit_size()
		_setup_puzzle()

func _on_give_up_button_pressed() -> void:
	confirmDialog.setup_contents(confirmDialog.Contents.GIVEUP)
	confirmDialog.popup_centered()

func _on_confirm_dialog_confirmed() -> void:
	match confirmDialog.dialogContents:
		confirmDialog.Contents.GIVEUP:
			_give_up_puzzle()
		confirmDialog.Contents.SELECTMENU:
			texture = null
			queue_free()
			get_node("/root/SelectMenu").visible = true

func _on_back_button_pressed() -> void:
	confirmDialog.setup_contents(confirmDialog.Contents.SELECTMENU)
	confirmDialog.popup_centered()

func _setup_window() -> void:
	var window_size = get_window().size
	var window_aspect = float(window_size.y) / float(window_size.x)
	var content_size = get_window().content_scale_size
	var content_aspect = float(content_size.y) / float(content_size.x)
	if content_aspect < window_aspect:
		position.y = position.y * window_aspect / content_aspect
	elif content_aspect > window_aspect:
		position.x = position.x * content_aspect / window_aspect 

func _apply_unit_size() -> void:
	unit_size = size_square / float(divide_num)

func _setup_puzzle() -> void:
	play_items.resize(divide_num * divide_num)
	for y in divide_num:
		for x in divide_num:
			var item = ITEM_SCENE.instantiate()
			add_child(item)
			item.moved_neighbour.connect(_on_item_moved_neighbour)
			var index = _calc_index(x, y)
			item.original_index = index
			play_items[index] = item
			item.setup(texture, divide_num, x, y)
			_set_item_position(item, x, y)
			var region = item.sprite.get_region_rect()
			item.setup_scale(unit_size / region.size.x, unit_size / region.size.y)

func _destroy_puzzle_items() -> void:
	for item in play_items:
		item.queue_free()
	play_items.clear()

func _start_puzzle():
	await _remove_1st_item()
	await _shuffle(divide_num * divide_num * divide_num * divide_num / 4)
	_setup_movable_items()

func _give_up_puzzle():
	_clear_movable_items()
	var size = play_items.size()
	var index = 0
	while index < size:
		var item = play_items[index]
		var original_index = item.original_index
		if (original_index == index):
			var pos = _calc_pos_from_index(original_index)
			item.pos_x = pos.x
			item.pos_y = pos.y
			_set_item_position(item, pos.x, pos.y)
			index += 1
		else:
			var swapItem = play_items[original_index]
			play_items[original_index] = item
			play_items[index] = swapItem
	_setup_initial_emptyPos()
	_exit_puzzle(false)

func _exit_puzzle(item_fade: bool):
	$Menu.visible = true
	$GiveUpButton.visible = false
	var item = play_items[_calc_index(empty_x, empty_y)]
	if item_fade:
		await _fade_in(item, 0.25)
	else:
		item.modulate.a = 1.0
		item.visible = true

func _remove_1st_item():
	_setup_initial_emptyPos()
	var item = play_items[_calc_index(empty_x, empty_y)]
	await _move_down(item, 0.4)
	await _fade_out(item, 0.1)
	_set_item_position(item, empty_x, empty_y)

func _shuffle(num: int):
	const MOVE_SPEED = 0.01
	var directions: Array
	var direction = Direction.NONE
	var same_direction_num: int = 0
	var same_direction_add_limit = divide_num / 2 - 1
	while num > 0:
		directions.clear()
		if (empty_x > 0 && direction != Direction.LEFT):
			directions.append(Direction.RIGHT)
			if (direction == Direction.RIGHT && same_direction_num < same_direction_add_limit):
				directions.append(Direction.RIGHT)
		if (empty_x < divide_num - 1 && direction != Direction.RIGHT):
			directions.append(Direction.LEFT)
			if (direction == Direction.LEFT && same_direction_num < same_direction_add_limit):
				directions.append(Direction.LEFT)
		if (empty_y > 0 && direction != Direction.UP):
			directions.append(Direction.DOWN)
			if (direction == Direction.DOWN && same_direction_num < same_direction_add_limit):
				directions.append(Direction.DOWN)
		if (empty_y < divide_num - 1 && direction != Direction.DOWN):
			directions.append(Direction.UP)
			if (direction == Direction.UP && same_direction_num < same_direction_add_limit):
				directions.append(Direction.UP)
		var decide_direction = directions[randi_range(0, directions.size() - 1)]
		if decide_direction == direction:
			same_direction_num += 1
		else:
			same_direction_num = 0
		direction = decide_direction
		var x = empty_x
		var y = empty_y
		match direction:
			Direction.UP:
				y += 1
				var item = _get_play_item(x, y)
				await _move_up(item, MOVE_SPEED)
			Direction.DOWN:
				y -= 1
				var item = _get_play_item(x, y)
				await _move_down(item, MOVE_SPEED)
			Direction.LEFT:
				x += 1
				var item = _get_play_item(x, y)
				await _move_left(item, MOVE_SPEED)
			Direction.RIGHT:
				x -= 1
				var item = _get_play_item(x, y)
				await _move_right(item, MOVE_SPEED)
		_moved_play_item(x, y)
		num -= 1

func _setup_movable_items() -> void:
	if (empty_x > 0):
		var item = _get_play_item(empty_x - 1, empty_y)
		item.set_allow_input(Direction.RIGHT)
	if (empty_x < divide_num - 1):
		var item = _get_play_item(empty_x + 1, empty_y)
		item.set_allow_input(Direction.LEFT)
	if (empty_y > 0):
		var item = _get_play_item(empty_x, empty_y - 1)
		item.set_allow_input(Direction.DOWN)
	if (empty_y < divide_num - 1):
		var item = _get_play_item(empty_x, empty_y + 1)
		item.set_allow_input(Direction.UP)

func _clear_movable_items() -> void:
	if (empty_x > 0):
		var item = _get_play_item(empty_x - 1, empty_y)
		item.clear_allow_input()
	if (empty_x < divide_num - 1):
		var item = _get_play_item(empty_x + 1, empty_y)
		item.clear_allow_input()
	if (empty_y > 0):
		var item = _get_play_item(empty_x, empty_y - 1)
		item.clear_allow_input()
	if (empty_y < divide_num - 1):
		var item = _get_play_item(empty_x, empty_y + 1)
		item.clear_allow_input()


func _move_up(item: Node2D, time: float):
	var target = item.position
	target.y -= unit_size
	await _move_item(item, target, time)

func _move_down(item: Node2D, time: float):
	var target = item.position
	target.y += unit_size
	await _move_item(item, target, time)

func _move_left(item: Node2D, time: float):
	var target = item.position
	target.x -= unit_size
	await _move_item(item, target, time)

func _move_right(item: Node2D, time: float):
	var target = item.position
	target.x += unit_size
	await _move_item(item, target, time)

func _move_item(item: Node2D, target: Vector2, time: float):
	var src_pos = item.position
	var velocity: Vector2 = (target - src_pos) / time
	var remain = time
	while remain > 0:
		var elapsed = await _wait_next_process()
		item.position += velocity * elapsed
		remain -= elapsed
	item.position = target

func _fade_out(item: Node2D, time: float):
	var revert_time = 1.0 / time
	var remain = time
	item.modulate.a = 1.0
	while remain > 0:
		var elapsed = await _wait_next_process()
		remain -= elapsed
		item.modulate.a = remain * revert_time
	item.visible = false

func _fade_in(item: Node2D, time: float):
	var revert_time = 1.0 / time
	var remain = time
	item.visible = true
	item.modulate.a = 0.0
	while remain > 0:
		var elapsed = await _wait_next_process()
		remain -= elapsed
		item.modulate.a = 1.0 - remain * revert_time
	item.modulate.a = 1.0

func _set_item_position(item: Node2D, x: int, y: int) -> void:
	var offset: float = size_square * 0.5 - unit_size * 0.5
	item.position.x = unit_size * x - offset
	item.position.y = unit_size * y - offset

func _wait_next_process() -> float:
	await get_tree().process_frame
	return _elapsed_delta

func _get_play_item(x: int, y: int) -> Item:
	return play_items[_calc_index(x, y)]

func _moved_play_item(from_x: int, from_y: int):
	var from_index = _calc_index(from_x, from_y)
	var empty_index = _calc_index(empty_x, empty_y)
	var tmp = play_items[empty_index]
	play_items[empty_index] = play_items[from_index]
	play_items[empty_index].pos_x = empty_x
	play_items[empty_index].pos_y = empty_y
	play_items[from_index] = tmp
	play_items[from_index].pos_x = from_x
	play_items[from_index].pos_y = from_y
	empty_x = from_x
	empty_y = from_y

func _calc_index(x: int, y: int) -> int:
	assert(0 <= x && x < divide_num)
	assert(0 <= y && y < divide_num)
	return y * divide_num + x

func _calc_pos_from_index(index: int) -> Vector2i:
	assert(index < divide_num * divide_num)
	var vec2: Vector2i
	vec2.y = index / divide_num
	vec2.x = index - vec2.y * divide_num
	return vec2

func _judge_win() -> bool:
	var n = play_items.size() - 1
	while n > 0:
		if (n != play_items[n].original_index):
			return false
		n -= 1
	return true

func _setup_initial_emptyPos() -> void:
	empty_y = divide_num - 1
	empty_x = divide_num / 2


var texture: Texture2D
@export var divide_num: int
@export var size_square: float
const ITEM_SCENE = preload("res://Main/item.tscn")

var play_items: Array[Item]
var unit_size: float
var _elapsed_delta: float

var empty_x: int
var empty_y: int

var confirmDialog
