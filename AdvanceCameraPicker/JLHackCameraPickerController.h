//
//  JLHackCameraPickerController.h
//  Camera
//
//  Created by jimneylee on 11-3-21.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum _SourceType{
	SourceType_Camera,
	SourceType_PhotoLibray
}SourceType;

@protocol JLHackCameraPickerDelegate;
@interface JLHackCameraPickerController : UIViewController

@property(nonatomic, weak) id<JLHackCameraPickerDelegate> pickerDelegate;
@property(nonatomic, assign) BOOL allowsEditing;
@property(nonatomic, assign) SourceType sourceType;
@property(nonatomic, retain) UIImage *selectedImage;

- (id)initWithCameraEditable:(BOOL)editable;
- (id)initWithPhotoLibraryEditable:(BOOL)editable;
- (void)showPicker;
@end

@protocol JLHackCameraPickerDelegate<NSObject>

- (void)didPickPhoto:(UIImage*)photo;

@optional
- (void)didCancelPick;

@end

