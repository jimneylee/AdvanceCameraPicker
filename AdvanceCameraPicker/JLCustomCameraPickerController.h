//
//  JLCustomCameraPickerController.h
//  JLCustomCameraPickerController
//
//  Created by jimneylee on 13-12-18.
//  Copyright (c) 2013年 jimneylee. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>

@protocol JLCustomCameraPickerDelegate;
@interface JLCustomCameraPickerController : UIViewController

@property (nonatomic, weak) id<JLCustomCameraPickerDelegate> pickerDelegate;

@end

@protocol JLCustomCameraPickerDelegate <NSObject>

- (void)didPickPhoto:(UIImage*)photo;
- (void)didCancelPick;

@end