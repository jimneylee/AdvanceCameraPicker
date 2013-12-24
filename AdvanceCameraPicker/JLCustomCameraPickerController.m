//
//  JLCustomCameraPickerController.m
//  JLCustomCameraPickerController
//
//  Created by jimneylee on 13-12-18.
//  Copyright (c) 2013年 jimneylee. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <QuartzCore/QuartzCore.h>
#import "JLCustomCameraPickerController.h"
#import "UIViewAdditions.h"
#import "BYQuickShotView.h"
#ifndef IOS_7_X
#define IOS_7_X (([[UIDevice currentDevice].systemVersion floatValue] > 6.99))
#endif
@interface JLCustomCameraPickerController ()<UINavigationControllerDelegate,
UIImagePickerControllerDelegate, BYQuickShotViewDelegate>

@property (nonatomic, strong) UIButton* flashButton;
@property (nonatomic, strong) UIButton* positionButton;
@property (nonatomic, strong) UIButton* cameraButton;
@property (nonatomic, strong) UIButton* cancelButton;
@property (nonatomic, strong) UIButton* photoButton;
@property (nonatomic, strong) UIButton* selectButton;
@property (nonatomic, strong) UIButton* retakeButton;

@property (nonatomic, strong) BYQuickShotView *quickShotView;
@property (nonatomic, strong) UIImage* selectedPhoto;
@end

@implementation JLCustomCameraPickerController

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIViewController

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    
    return self;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    self.quickShotView = [[BYQuickShotView alloc]init];
    self.quickShotView.frame = CGRectMake(0, 0, self.view.width, self.view.width);
    self.quickShotView.center = self.view.center;
    self.quickShotView.delegate = self;
    [self.view addSubview:self.quickShotView];
    
    [self setupBottomBar];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.navigationController setNavigationBarHidden:YES];
    
    [self retakeAction];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self.navigationController setNavigationBarHidden:NO];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Self init

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setupBottomBar {
    
    CGFloat kBtnWidth = 60.f;
    CGFloat kBtnheight = 30.f;
    CGFloat kBarHeight = 64.f;
    CGFloat kSideMargin = 20.f;

    // top bar
    UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, kBarHeight)];
    topBar.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.8f];
    [self.view addSubview:topBar];
    
    self.flashButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kBtnWidth, kBtnheight)];
    [self.flashButton setImage:[UIImage imageNamed:@"flash-off.png"] forState:UIControlStateNormal];
    [self.flashButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.flashButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.flashButton addTarget:self action:@selector(switchFlashAction) forControlEvents:UIControlEventTouchUpInside];
    self.flashButton.left = kSideMargin;
    self.flashButton.centerY = topBar.height / 2;
    [topBar addSubview:self.flashButton];
    
    self.positionButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kBtnWidth, kBtnheight)];
    [self.positionButton setImage:[UIImage imageNamed:@"front-camera.png"] forState:UIControlStateNormal];
    [self.positionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.positionButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    self.positionButton.right = self.view.width - kSideMargin;
    self.positionButton.centerY = topBar.height / 2;
    [self.positionButton addTarget:self action:@selector(switchPositionAction) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:self.positionButton];
    
    // bottom bar
    UIView *bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height - kBarHeight,
                                                                 self.view.width, kBarHeight)];
    bottomBar.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.8f];
    [self.view addSubview:bottomBar];
    
    self.cameraButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kBtnWidth, kBtnheight)];
    self.cameraButton.center = CGPointMake(bottomBar.width*.5, bottomBar.height*.5);
    [self.cameraButton setTitle:@"拍照" forState:UIControlStateNormal];
    [self.cameraButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.cameraButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.cameraButton addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
    [bottomBar addSubview:self.cameraButton];
    
    self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kBtnWidth, kBtnheight)];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.cancelButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.cancelButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    self.cancelButton.left = kSideMargin;
    self.cancelButton.centerY = bottomBar.height / 2;
    [bottomBar addSubview:self.cancelButton];
    self.cancelButton.hidden = NO;
    
    self.photoButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kBtnWidth, kBtnheight)];
    [self.photoButton setTitle:@"图库" forState:UIControlStateNormal];
    [self.photoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.photoButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.photoButton addTarget:self action:@selector(pickPhotoAction) forControlEvents:UIControlEventTouchUpInside];
    self.photoButton.right = self.view.width - kSideMargin;
    self.photoButton.centerY = bottomBar.height / 2;
    [bottomBar addSubview:self.photoButton];
    self.photoButton.hidden = NO;
    
    self.retakeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kBtnWidth, kBtnheight)];
    [self.retakeButton setTitle:@"重拍" forState:UIControlStateNormal];
    [self.retakeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.retakeButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    self.retakeButton.left = kSideMargin;
    self.retakeButton.centerY = bottomBar.height / 2;
    [self.retakeButton addTarget:self action:@selector(retakeAction) forControlEvents:UIControlEventTouchUpInside];
    [bottomBar addSubview:self.retakeButton];
    self.retakeButton.hidden = YES;
    
    self.selectButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kBtnWidth, kBtnheight)];
    [self.selectButton setTitle:@"选取" forState:UIControlStateNormal];
    [self.selectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.selectButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    self.selectButton.right = self.view.width - kSideMargin;
    self.selectButton.centerY = bottomBar.height / 2;
    [self.selectButton addTarget:self action:@selector(selectAction) forControlEvents:UIControlEventTouchUpInside];
    [bottomBar addSubview:self.selectButton];
    self.selectButton.hidden = YES;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)changeBottomButtonsToSelectStatus
{
    self.selectButton.hidden = NO;
    self.retakeButton.hidden = NO;
    
    self.cancelButton.hidden = YES;
    self.photoButton.hidden = YES;
    self.cameraButton.hidden = YES;
    self.flashButton.hidden = YES;
    self.positionButton.hidden = YES;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)changeBottomButtonsToTakeStatus
{
    self.selectButton.hidden = YES;
    self.retakeButton.hidden = YES;
    
    self.cancelButton.hidden = NO;
    self.photoButton.hidden = NO;
    self.cameraButton.hidden = NO;
    self.flashButton.hidden = NO;
    self.positionButton.hidden = NO;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Action

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)switchFlashAction
{
    [self.flashButton setEnabled:NO];
    AVCaptureFlashMode flashMode = [self.quickShotView changeFlashMode];
    if(flashMode == AVCaptureFlashModeOff) {
        [self.flashButton setImage:[UIImage imageNamed:@"flash-off.png"] forState:UIControlStateNormal];
    }
    else if(flashMode == AVCaptureFlashModeAuto) {
        [self.flashButton setImage:[UIImage imageNamed:@"flash-auto.png"] forState:UIControlStateNormal];
    }
    else {
        [self.flashButton setImage:[UIImage imageNamed:@"flash-on.png"] forState:UIControlStateNormal];
    }
    [self.flashButton setEnabled:YES];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)switchPositionAction
{
    [self.positionButton setEnabled:NO];
    AVCaptureDevicePosition position = [self.quickShotView changePosition];
    NSLog(@"position: %d", position);
    [self.positionButton setEnabled:YES];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)backAction
{
    [self.quickShotView captureSessionStopRunning];
    if ([self.pickerDelegate respondsToSelector:@selector(didCancelPick)]) {
        [self.pickerDelegate didCancelPick];
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)takePhoto
{
    [self.quickShotView captureImage];
    [self.quickShotView captureSessionStopRunning];
    [self changeBottomButtonsToSelectStatus];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)pickPhotoAction
{
    [self.quickShotView captureSessionStopRunning];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.mediaTypes = [NSArray arrayWithObject:(NSString*)kUTTypeImage];
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePickerController.allowsEditing = YES;
        imagePickerController.delegate = self;
        imagePickerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        // show status bar
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [self presentViewController:imagePickerController animated:YES
                         completion:^{
                             
                         }];
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)selectAction
{
    [self.quickShotView captureSessionStopRunning];
    if ([self.pickerDelegate respondsToSelector:@selector(didPickPhoto:)]) {
        [self.pickerDelegate didPickPhoto:self.selectedPhoto];
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)retakeAction
{
    [self changeBottomButtonsToTakeStatus];
    [self.quickShotView captureSessionStartRunning];
    self.quickShotView.imagePreView.image = nil;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIImagePickerControllerDelegate

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info{
    [picker dismissViewControllerAnimated:NO completion:NULL];
    NSString *const kPublicImageType = @"public.image";
	NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
	if ([mediaType isEqualToString:kPublicImageType]) {
        UIImage* photo = [info objectForKey:UIImagePickerControllerEditedImage];
        self.selectedPhoto = photo;
        [self selectAction];
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:^{
        [self.quickShotView captureSessionStartRunning];
    }];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - BYQuickShotViewDelegate

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didTakeSnapshot:(UIImage *)img {
    self.selectedPhoto = img;
    [self changeBottomButtonsToSelectStatus];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didDiscardLastImage {
}

@end
