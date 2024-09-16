//
//  ph_photo_picker_module.cpp
//  PHPhotoPicker
//
//  Copyright (c) 2024 NARUSE Masahiro
//  This software is released under the MIT License, see License.
//

#include "ph_photo_picker_module.h"

#include "core/version.h"

#if VERSION_MAJOR == 4
#include "core/config/engine.h"
#else
#include "core/engine.h"
#endif

#include "ph_photo_picker.h"

PHPhotoPicker *plugin;

void godot_phphotopicker_init() {
    plugin = memnew(PHPhotoPicker);
    Engine::get_singleton()->add_singleton(Engine::Singleton("PHPhotoPicker", plugin));
}

void godot_phphotopicker_deinit() {
    if (plugin) {
       memdelete(plugin);
   }
}
