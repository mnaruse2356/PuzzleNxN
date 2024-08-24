//
//  ph_photo_picker.h
//  PHPhotoPicker
//
//  Created by Naruse Masahiro on 2024/08/23.
//

#ifndef ph_photo_picker_h
#define ph_photo_picker_h

#include "core/version.h"

#if VERSION_MAJOR == 4
#include "core/io/image.h"
#include "core/object/object.h"
#else
#include "core/image.h"
#include "core/object.h"
#endif


#ifdef __OBJC__
@class PHPhotoPickerImplement;
#else
typedef void PHPhotoPickerImplement;
#endif

class PHPhotoPicker : public Object {
    GDCLASS(PHPhotoPicker, Object);
    
    static void _bind_methods();
    
    PHPhotoPickerImplement *photoPicker;
    
public:
    PHPhotoPicker();
    ~PHPhotoPicker();

    static PHPhotoPicker *get_singleton();

    void present();
    void select_image(Ref<Image> image);
};

#endif /* ph_photo_picker_implementation_h */
