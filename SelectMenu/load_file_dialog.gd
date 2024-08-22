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
		"iOS":
			_os_type = OSType.IOS
			if Engine.has_singleton(IOS_PLUGIN_NAME):
				_plugin = Engine.get_singleton(IOS_PLUGIN_NAME)
			else:
				print("Could not load plugin: ", IOS_PLUGIN_NAME)
			if _plugin:
				_plugin.connect("image_picked", _on_ios_image_picked)
				_plugin.connect("permission_updated", _on_ios_permission_updated)
				

func open_dialog() -> void:
	match _os_type:
		OSType.ANDROID:
			_plugin.getGalleryImage()
			pass
		OSType.IOS:
			if _plugin.permission_status(_plugin.PERMISSION_TARGET_PHOTO_LIBRARY) != _plugin.PERMISSION_STATUS_ALLOWED:
				_plugin.request_permission(_plugin.PERMISSION_TARGET_PHOTO_LIBRARY)
			else:
				_ios_present_photo_picker()
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

func _on_ios_image_picked(image: Image) -> void:
	image_loaded.emit(image)

func _on_ios_permission_updated(target: int, status: int) -> void:
	if target == _plugin.PERMISSION_TARGET_PHOTO_LIBRARY:
			if status == _plugin.PERMISSION_STATUS_ALLOWED:
				_ios_present_photo_picker()

func _ios_present_photo_picker() -> void:
	_plugin.present(_plugin.SOURCE_PHOTO_LIBRARY)

func _on_file_selected(path: String) -> void:
	var image = Image.load_from_file(path)
	if image == null:
		print("can't open file: %s" % path)
	else:
		image_loaded.emit(image)


const ANDROID_PLUGIN_NAME = "GodotGetImage"
const IOS_PLUGIN_NAME = "PhotoPicker"

enum OSType {
	ANDROID,
	IOS,
	OTHER
}
var _os_type: OSType = OSType.OTHER
var _plugin