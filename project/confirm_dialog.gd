#
# Copyright (c) 2024 NARUSE Masahiro
# This software is released under the MIT License, see License.
#
extends ConfirmationDialog

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_theme_constant_override("buttons_min_height", 40)
	add_theme_constant_override("buttons_min_width", 96)
	pass

func setup_contents(contents: Contents) -> void:
	match contents:
		Contents.GIVEUP:
			dialog_text = tr("TEXT_GIVEUP")
		Contents.SELECTMENU:
			dialog_text = tr("TEXT_BACK_TO_MENU")
		Contents.QUIT:
			dialog_text = tr("TEXT_QUIT")
	dialogContents = contents

var dialogContents: Contents
enum Contents{
	GIVEUP,
	SELECTMENU,
	QUIT
}
