//
//  BYQuickShotView.h
//  QuickShotView
//
//  Created by Dario Lass on 22.03.13.
//  Copyright (c) 2013 Bytolution. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol BYQuickShotViewDelegate <NSObject>

- (void)didTakeSnapshot:(UIImage*)img;
- (void)didDiscardLastImage;

@end

@interface BYQuickShotView : UIView 

@property (nonatomic, weak) id <BYQuickShotViewDelegate> delegate;
@property (nonatomic, strong) UIImageView *imagePreView;

- (void)captureImage;

// jimneylee add these public methods
- (AVCaptureFlashMode)changeFlashMode;
- (AVCaptureDevicePosition)changePosition;
- (void)captureSessionStartRunning;
- (void)captureSessionStopRunning;

@end
