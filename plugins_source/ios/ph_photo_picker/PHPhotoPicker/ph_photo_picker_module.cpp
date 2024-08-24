//
//  ph_photo_picker_module.cpp
//  PHPhotoPicker
//
//  Created by Naruse Masahiro on 2024/08/23.
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
