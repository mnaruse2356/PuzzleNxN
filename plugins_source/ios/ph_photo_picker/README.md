Godot iOS PHPicker Plugin
====================================

iOS plugin for Godot 4.3.
Pick one image by [PHPickerViewController](https://developer.apple.com/documentation/photokit/phpickerviewcontroller).

## How to build plugin.
Download this source code.

Download godot source code (select branch you want to use) from https://github.com/godotengine/godot, and place godot/ folder.

run build script, output xcframework to `bin/`.
```bash
script/generate_xcframework.sh [debug|release|release_debug]
```

## Notice
Copyright 2024 (c) NARUSE Masahiro.
This software is released under the MIT License, see [LICENSE](../../../LICENSE)

This plugin is implemented with reference to [Godot PhotoPicker plugin in Godot iOS plugins](https://github.com/godotengine/godot-ios-plugins/tree/master/plugins/photo_picker).

