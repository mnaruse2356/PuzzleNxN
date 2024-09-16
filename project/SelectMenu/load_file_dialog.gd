#
# Copyright (c) 2024 NARUSE Masahiro
# This software is released under the MIT License, see License.
#
class_name LoadFileDialog
extends FileDialog

signal image_loaded(image: Image)

func _ready() -> void:
	match OS.get_name():
		"Android":
			_os_type = OSType.ANDROID
			if Engine.has_singleton(ANDROID_PLUGIN_NAME):
				_plugin = Engine.get_singleton(ANDROID_PLUGIN_NAME)
			else:
				print("Could not load plugin: ", ANDROID_PLUGIN_NAME)
			if _plugin:
				_plugin.connect("image_request_completed", _on_android_image_request_completed)
				_plugin.connect("error", _on_android_error)
				_plugin.connect("permission_not_granted_by_user", _on_android_permission_not_granted_by_user)
				var option: Dictionary = {}
				option["auto_rotate_image"] = true
				option["image_format"] = "jpg"
				_plugin.setOptions(option)
		"iOS":
			_os_type = OSType.IOS
			if Engine.has_singleton(IOS_PLUGIN_NAME):
				_plugin = Engine.get_singleton(IOS_PLUGIN_NAME)
			else:
				print("Could not load plugin: ", IOS_PLUGIN_NAME)
			if _plugin:
				_plugin.connect("image_picked", _on_ios_image_picked)
		"Web":
			_os_type = OSType.WEB
			_plugin = HTML5FileDialog.new()
			if _plugin:
				_plugin.connect("file_selected", _on_html5_file_selected)
				_plugin.filters = ["image/jpeg"]
				_plugin.file_mode = HTML5FileDialog.FileMode.OPEN_FILE
				add_child(_plugin)

func open_dialog() -> void:
	match _os_type:
		OSType.ANDROID:
			_plugin.getGalleryImage()
			pass
		OSType.IOS:
			_plugin.present()
		OSType.WEB:
			_plugin.show()
		OSType.OTHER:
			current_dir = OS.get_system_dir(OS.SystemDir.SYSTEM_DIR_PICTURES)
			popup_centered()

func get_os_type() -> int:
	return _os_type

func _on_android_image_request_completed(dict: Dictionary) -> void:
	var image_buffer = dict.values()[0]
	var image = Image.new()
	var error = image.load_jpg_from_buffer(image_buffer)
	if error == Error.OK:
		image_loaded.emit(image)
	else:
		print("can't load jpeg image")

func _on_android_error(err: String) -> void:
	OS.alert(err, "Error!")

func _on_android_permission_not_granted_by_user(permission: String) -> void:
	var text = "%s\npermission is necessary." % permission
	OS.alert(text, "Alert!")
	_plugin.resendPermission()

func _on_ios_image_picked(image: Image) -> void:
	image_loaded.emit(image)

func _on_html5_file_selected(file: HTML5FileHandle):
	var binary = await file.as_buffer()
	if (binary == null):
		return
	var image = Image.new()
	if image.load_jpg_from_buffer(binary) == Error.OK:
		if OS.has_feature("web_android"):
			var image_size = image.get_size()
			if (image_size.x > 4096):
				if (image_size.y > image_size.x):
					image.resize(image_size.x * 4096 / image_size.y, 4096)
				else:
					image.resize(4096, image_size.y * 4096 / image_size.x)
			elif (image_size.y > 4096):
				image.resize(image_size.x * 4096 / image_size.y, 4096)
		image_loaded.emit(image)
	else:
		OS.alert("can't load jpeg image")


func _on_file_selected(path: String) -> void:
	var image = Image.load_from_file(path)
	if image == null:
		print("can't open file: %s" % path)
	else:
		image_loaded.emit(image)

const ANDROID_PLUGIN_NAME = "GodotGetImage"
const IOS_PLUGIN_NAME = "PHPhotoPicker"

enum OSType {
	ANDROID,
	IOS,
	WEB,
	OTHER
}
var _os_type: OSType = OSType.OTHER
var _plugin