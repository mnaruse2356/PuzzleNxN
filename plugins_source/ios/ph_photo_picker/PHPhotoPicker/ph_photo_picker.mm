//
//  ph_photo_picker.mm
//  PHPhotoPicker
//
//  Copyright (c) 2024 NARUSE Masahiro
//  This software is released under the MIT License, see License.
//

#include "ph_photo_picker.h"

#import <Foundation/Foundation.h>
#import <PhotosUI/PhotosUI.h>

#if VERSION_MAJOR == 4
#import "platform/ios/app_delegate.h"
#import "platform/ios/view_controller.h"
#else
#import "platform/iphone/app_delegate.h"
#import "platform/iphone/view_controller.h"
#endif

PHPhotoPicker *instance;

@interface PHPhotoPickerImplement : NSObject<PHPickerViewControllerDelegate>
@end

@implementation PHPhotoPickerImplement
- (void)picker:(PHPickerViewController *)picker
didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    PHPickerResult *result = results.firstObject;
    if (result != nil) {
        NSItemProvider *provider = result.itemProvider;
        [provider loadObjectOfClass:[UIImage class] completionHandler:^(__kindof id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error) {
            if ([object isKindOfClass:[UIImage class]])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self loadImageToGodot:(UIImage*)object];
                });
            }
        }];
    }
}

- (void)loadImageToGodot:(UIImage *)image {
    CGImageRef cgImage = [[self class] newRGBA8CGImageFromUIImage:image];
    
    if (cgImage) {
        CGDataProviderRef provider = CGImageGetDataProvider(cgImage);
        CFDataRef bmp = CGDataProviderCopyData(provider);
        const unsigned char *data = CFDataGetBytePtr(bmp);
        CFIndex length = CFDataGetLength(bmp);
        
        if (data) {
            Ref<Image> img;
            
#if VERSION_MAJOR == 4
            Vector<uint8_t> img_data;
            img_data.resize(length);
            uint8_t* w = img_data.ptrw();
            memcpy(w, data, length);
            
            img.instantiate();
            img->set_data(image.size.width * image.scale, image.size.height * image.scale, 0, Image::FORMAT_RGBA8, img_data);
#else
            PoolVector<uint8_t> img_data;
            img_data.resize(length);
            PoolVector<uint8_t>::Write w = img_data.write();
            memcpy(w.ptr(), data, length);
            
            img.instance();
            img->create(image.size.width * image.scale, image.size.height * image.scale, 0, Image::FORMAT_RGBA8, img_data);
#endif
            PHPhotoPicker::get_singleton()->select_image(img);
        }
        CFRelease(bmp);
        CGImageRelease(cgImage);
    }
}

- (void)present{
    _weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _strongify(self);
        
        UIViewController *root_controller = [[UIApplication sharedApplication] delegate].window.rootViewController;

        if (!root_controller) {
            return;
        }
        
        PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
        config.selectionLimit = 1;
        config.filter = [PHPickerFilter imagesFilter];
        config.preferredAssetRepresentationMode = PHPickerConfigurationAssetRepresentationModeCurrent;
        PHPickerViewController *pickerViewController = [[PHPickerViewController alloc] initWithConfiguration: config];
        pickerViewController.delegate = self;
        
        [root_controller presentViewController:pickerViewController animated:YES completion:nil];
    });
}

+ (CGImageRef)newRGBA8CGImageFromUIImage:(UIImage *)image {
    size_t bitsPerPixel = 32;
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = bitsPerPixel / bitsPerComponent;
    
    size_t width = image.size.width;
    size_t height = image.size.height;
    UIImageOrientation orientation = image.imageOrientation;
    
    size_t bytesPerRow = width * bytesPerPixel;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (!colorSpace) {
        NSLog(@"Error allocating color space RGB");
        return NULL;
    }
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (orientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, width, height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (orientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast);
    
    CGImageRef newCGImage = NULL;
    
    if (!context) {
        NSLog(@"Bitmap context not created");
    } else {
        
        CGContextConcatCTM(context, transform);
        
        switch (orientation) {
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                CGContextDrawImage(context, CGRectMake(0, 0, height, width), [image CGImage]);
                break;
            default:
                CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
                break;
        }
        
        newCGImage = CGBitmapContextCreateImage(context);
    }
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    return newCGImage;
}
@end


PHPhotoPicker *PHPhotoPicker::get_singleton() {
    return instance;
}

void PHPhotoPicker::_bind_methods() {
    ClassDB::bind_method(D_METHOD("present"), &PHPhotoPicker::present);

    ADD_SIGNAL(MethodInfo("image_picked", PropertyInfo(Variant::OBJECT, "image")));
}

PHPhotoPicker::PHPhotoPicker() {
    instance = this;
    photoPicker = [[PHPhotoPickerImplement alloc] init];
}

PHPhotoPicker::~PHPhotoPicker() {
    instance = NULL;
    photoPicker = nil;
}

void PHPhotoPicker::present() {
    [photoPicker present];
}

void PHPhotoPicker::select_image(Ref<Image> image) {
    emit_signal("image_picked", image);
}
