/*
 Copyright 2015 OpenMarket Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <UIKit/UIKit.h>

// Customize UIView in order to display image defined with remote url. Zooming inside the image (Stretching) is supported.
@interface MXKImageView : UIView <UIScrollViewDelegate>

typedef void (^blockMXKImageView_onClick)(MXKImageView *imageView, NSString* title);

- (void)setImageURL:(NSString *)imageURL withImageOrientation:(UIImageOrientation)orientation andPreviewImage:(UIImage*)previewImage;

/**
 Toggle display to fullscreen.
 */
- (void)showFullScreen;

// Use this boolean to hide activity indicator during image downloading
@property (nonatomic) BOOL hideActivityIndicator;

// Information about the media represented by this image (image, video...)
@property (strong, nonatomic) NSDictionary *mediaInfo;

@property (strong, nonatomic) UIImage *image;

@property (nonatomic) BOOL stretchable;
@property (nonatomic, readonly) BOOL fullScreen;

// mediaManager folder where the image is stored
@property (nonatomic) NSString* mediaFolder;

// Let the user defines some custom buttons over the tabbar
- (void)setLeftButtonTitle :leftButtonTitle handler:(blockMXKImageView_onClick)handler;
- (void)setRightButtonTitle:rightButtonTitle handler:(blockMXKImageView_onClick)handler;

- (void)dismissSelection;

@end

