extends Control

func _ready() -> void:
	_set_menu_trim_mode(false)
	confirmDialog = ConfirmDialog
	confirmDialog.connect("confirmed", _on_confirm_dialog_confirmed)

func _on_installed_image_1_gui_input(event: InputEvent) -> void:
	_on_installed_image_gui_input(event, $VBoxContainer/InstalledImage1)

func _on_installed_image_2_gui_input(event: InputEvent) -> void:
	_on_installed_image_gui_input(event, $VBoxContainer/InstalledImage2)

func _on_installed_image_gui_input(event: InputEvent, image: TextureRect) -> void:
	if event is InputEventMouseButton:
		if event.get_button_index() == MOUSE_BUTTON_LEFT:
			_change_main_scene(image.texture)

func _on_device_image_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.get_button_index() == MOUSE_BUTTON_LEFT:
			if $LoadFileDialog.get_os_type() == LoadFileDialog.OSType.WEB:
				$VBoxContainer.visible = false
				$LoadFileDialog.open_dialog()
				$VBoxContainer.visible = true
			else:
				$LoadFileDialog.open_dialog()


func _on_load_file_dialog_image_loaded(image: Image) -> void:
	var texture = ImageTexture.create_from_image(image)
	var trim_image = TRIM_IMAGE.instantiate()
	trim_image.set_texture(texture)
	add_child(trim_image)
	_set_menu_trim_mode(true)
	_edit_image = image
	_trim_image = trim_image

func _on_button_trim_ok_pressed() -> void:
	var rect = _trim_image.get_trim_rect()
	match _trim_image.rotate_num:
		1:
			_edit_image.rotate_90(ClockDirection.CLOCKWISE)
		2:
			_edit_image.rotate_180()
		3: 
			_edit_image.rotate_90(ClockDirection.COUNTERCLOCKWISE)
	var game_image = Image.create_empty(rect.size.x, rect.size.y, false, _edit_image.get_format())
	game_image.blit_rect(_edit_image, Rect2i(rect), Vector2i(0, 0))
	game_image.resize(SAVE_IMAGE_SIZE, SAVE_IMAGE_SIZE, Image.Interpolation.INTERPOLATE_CUBIC)
	_trim_image.queue_free()
	_change_main_scene(ImageTexture.create_from_image(game_image))
	_trim_image = null
	_edit_image = null
	_set_menu_trim_mode(false)

func _on_button_trim_back_pressed() -> void:
	confirmDialog.setup_contents(ConfirmDialog.Contents.SELECTMENU)
	confirmDialog.popup_centered()

func _on_confirm_dialog_confirmed() -> void:
	if visible:
		match confirmDialog.dialogContents:
			confirmDialog.Contents.SELECTMENU:
				_trim_image.queue_free()
				_trim_image = null
				_set_menu_trim_mode(false)
			confirmDialog.Contents.QUIT:
				get_tree().quit()

func _notification(what: int) -> void:
	if visible:
		match what:
			Node.NOTIFICATION_WM_GO_BACK_REQUEST:
				if confirmDialog.visible:
					confirmDialog.hide()
				else:
					if $TrimMenu/ButtonTrimBack.is_visible_in_tree():
						confirmDialog.setup_contents(confirmDialog.Contents.SELECTMENU)
						confirmDialog.popup_centered()
					else:
						confirmDialog.setup_contents(confirmDialog.Contents.QUIT)
						confirmDialog.popup_centered()


func _change_main_scene(texture: Texture2D) -> void:
	var main_scene = MAIN_SCENE.instantiate()
	main_scene.texture = texture
	get_tree().root.add_child(main_scene)
	visible = false

func _set_menu_trim_mode(trim: bool) -> void:
	$VBoxContainer.visible = !trim
	$TrimMenu.visible = trim

const MAIN_SCENE = preload("res://Main/main.tscn")
const TRIM_IMAGE = preload("res://SelectMenu/trim_image.tscn")
const SAVE_IMAGE_SIZE = 1024

var _trim_image: TrimImage
var _edit_image: Image

var confirmDialog
