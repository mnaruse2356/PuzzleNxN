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

func open_dialog() -> void:
	match _os_type:
		OSType.ANDROID:
			_plugin.getGalleryImage()
			pass
		OSType.OTHER:
			current_dir = OS.get_system_dir(OS.SystemDir.SYSTEM_DIR_PICTURES)
			popup_centered()


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

func _on_file_selected(path: String) -> void:
	var image = Image.load_from_file(path)
	if image == null:
		print("can't open file: %s" % path)
	else:
		image_loaded.emit(image)


const ANDROID_PLUGIN_NAME = "GodotGetImage"

enum OSType {
	ANDROID,
	OTHER
}
var _os_type: OSType = OSType.OTHER
var _plugin