//
//  CameraViewController.m
//  Camera
//
//  Created by jimneylee on 11-3-21.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "JLHackCameraPickerController.h"
#import "UIViewAdditions.h"
#import <MobileCoreServices/UTCoreTypes.h>

#ifndef IOS_7_X
#define IOS_7_X (([[UIDevice currentDevice].systemVersion floatValue] > 6.99))
#endif

@interface JLHackCameraPickerController()<UINavigationControllerDelegate,
UIImagePickerControllerDelegate, UIActionSheetDelegate>
@property (nonatomic, strong) UIButton *retakeBtn;
@property(nonatomic, retain) UIImagePickerController *photoPicker;
@property(nonatomic, retain) UIImagePickerController *cameraPicker;
@property(nonatomic, retain) UIImagePickerController *currentPicker;

- (void)showCameraImagePicker;
- (void)showPhotoLibraryPicker;

// new find camera btn method
- (void)modifyInView:(UIView*)aView;
- (UIView*)findView:(UIView*)aView withName:(NSString*)name;
- (UIView*)findCamControlsLayerView:(UIView*)view;
- (void)retakePhoto;
@end

@implementation JLHackCameraPickerController

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIViewController

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithCameraEditable:(BOOL)editable
{
	self = [super init];
    if (self) {
		_allowsEditing = editable;
		_sourceType = SourceType_Camera;
    }
    return self;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithPhotoLibraryEditable:(BOOL)editable
{
	self = [super init];
    if (self) {
		_allowsEditing = editable;
		_sourceType = SourceType_PhotoLibray;
    }
    return self;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIView

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad
{
    [super viewDidLoad];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
	[self.navigationController setNavigationBarHidden:YES];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
	[self.navigationController setNavigationBarHidden:NO];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showPicker
{
    if (SourceType_Camera == self.sourceType) {
        [self showCameraImagePicker];
    }
    else {
        [self showPhotoLibraryPicker];
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showCameraImagePicker
{
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
		imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
		imagePickerController.allowsEditing = _allowsEditing;
		imagePickerController.delegate = self;
		imagePickerController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		[self presentViewController:imagePickerController animated:YES completion:NULL];
		
		self.cameraPicker = imagePickerController;
		self.currentPicker = self.cameraPicker;
	}	
	else {
		[self showPhotoLibraryPicker];
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showPhotoLibraryPicker
{
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
		UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
		imagePickerController.mediaTypes = [NSArray arrayWithObject:(NSString*)kUTTypeImage];
		imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		imagePickerController.allowsEditing = _allowsEditing;
		imagePickerController.delegate = self;
		imagePickerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        if (self.presentedViewController != nil) {
			[self.presentedViewController presentViewController:imagePickerController animated:YES completion:NULL];
		}
		else {
            [self presentViewController:imagePickerController animated:YES completion:NULL];
		}
		self.photoPicker = imagePickerController;
		self.currentPicker = self.photoPicker;
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)retakePhoto
{
	[_retakeBtn sendActionsForControlEvents:UIControlEventTouchUpInside];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIImagePickerControllerDelegate

//////////////////////////////////////////////////////////////////////////////////////////////////////
NSString *const kPublicImageType = @"public.image";
NSString *const kCameraRollTitle = @"Camera Roll";

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)imagePickerController:(UIImagePickerController *)picker 
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
	//NSLog(@"type = %@ picker.title = %@", mediaType, picker.title);
	
	if ([mediaType isEqualToString:kPublicImageType]) {
		if (self.allowsEditing) {
			self.selectedImage = [info objectForKey:UIImagePickerControllerEditedImage];
		}
		else {
			self.selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
		}
        
        [self.currentPicker dismissViewControllerAnimated:NO completion:NULL];
		if (self.cameraPicker != nil) {
			[self.cameraPicker dismissViewControllerAnimated:NO completion:NULL];
		}
		[self.pickerDelegate didPickPhoto:self.selectedImage];
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[picker dismissViewControllerAnimated:NO completion:^{
        // 相片库
        if (self.photoPicker ==  picker) {
            if (self.cameraPicker != nil) {
                self.currentPicker = self.cameraPicker;
            }
            else {
                if ([self.pickerDelegate respondsToSelector:@selector(didCancelPick)]) {
                    [self.pickerDelegate didCancelPick];
                }
            }
        }
        else {
            if ([self.pickerDelegate respondsToSelector:@selector(didCancelPick)]) {
                [self.pickerDelegate didCancelPick];
            }
        }
    }];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UINavigationControllerDelegate

//////////////////////////////////////////////////////////////////////////////////////////////////////
NSString *const kPLUICameraViewControllerName = @"PLUICameraViewController";
- (void)navigationController:(UINavigationController *)navigationController
	  willShowViewController:(UIViewController *)viewController
					animated:(BOOL)animated
{
	if ([[[viewController class] description] isEqualToString:kPLUICameraViewControllerName]) {
		[self modifyInView:viewController.view];
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Hack Camera

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView*)findView:(UIView*)aView withName:(NSString*)name
{
	Class class = [aView class];
	NSString *desc = [class description];
	
	if ([name isEqualToString:desc]) {
		return aView;
	}
	
	for (__strong UIView *subview in aView.subviews) {
		subview = [self findView:subview withName:name];
		if (subview) {
			return subview;
		}
	}
	return nil;
}

NSString *const kPLCameraViewName = @"PLCameraView";
NSString *const kPLCropOverlayName = @"PLCropOverlay";
NSString *const kPLCropOverlayBottomBar = @"PLCropOverlayBottomBar";
NSString *const kPLCAMBottomBar = @"CAMBottomBar";
- (void)modifyInView:(UIView*)aView
{
    // 兼容ios7
    if (IOS_7_X) {
        UIView *PLCameraView = [self findView:aView withName:kPLCameraViewName];
        
        // PLCropOverlay PLCropOverlayBottomBar
        UIView *cropOverlay = [self findView:PLCameraView withName:kPLCropOverlayName];
        cropOverlay = cropOverlay;
        
        UIView *bottomBar = [self findView:PLCameraView withName:kPLCropOverlayBottomBar];
        // bottombar index:0 bottomview
        UIView *bottomBarBottomView = [bottomBar.subviews objectAtIndex:0];
        
        // 0->retake 1->use
        _retakeBtn =[bottomBarBottomView.subviews objectAtIndex:0];
        [_retakeBtn setTitle:@"重拍" forState:UIControlStateNormal];
        
        UIButton *useBtn = [bottomBarBottomView.subviews objectAtIndex:1];
        [useBtn setTitle:@"选取" forState:UIControlStateNormal];
        
        // bottombar index:1 topview
        UIView *camBottomBar = [self findView:PLCameraView withName:kPLCAMBottomBar];
        
        UIButton *cancelBtn = [camBottomBar.subviews objectAtIndex:1];
        [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        
        UIButton *photoBtn = [[UIButton alloc] initWithFrame:cancelBtn.bounds];
        [photoBtn setBackgroundColor:[UIColor clearColor]];
        [photoBtn setTitle:@"图库" forState:UIControlStateNormal];
        [photoBtn.titleLabel setFont:cancelBtn.titleLabel.font];
        [photoBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [photoBtn addTarget:self action:@selector(showPhotoLibraryPicker)
           forControlEvents:UIControlEventTouchUpInside];
        [photoBtn sizeToFit];
        
        CGFloat kCancelBtnLeftMargin = 15.f;
        CGFloat kCamBottomBarHeight = 72.f;
        photoBtn.right = [UIScreen mainScreen].applicationFrame.size.width - kCancelBtnLeftMargin;
        photoBtn.centerY = kCamBottomBarHeight / 2.f;
        [camBottomBar addSubview:photoBtn];
    }
    else {
        UIView *PLCameraView = [self findView:aView withName:kPLCameraViewName];
        
        // PLCropOverlay PLCropOverlayBottomBar
        UIView *cropOverlay = [self findView:PLCameraView withName:kPLCropOverlayName];
        cropOverlay = cropOverlay;
        UIView *bottomBar = [self findView:PLCameraView withName:kPLCropOverlayBottomBar];
        // bottombar index:0 bottomview
        UIView *bottomBarBottomView = [bottomBar.subviews objectAtIndex:0];
        
        // 0->retake 1->use
        _retakeBtn =[bottomBarBottomView.subviews objectAtIndex:0];
        [_retakeBtn setTitle:@"重拍" forState:UIControlStateNormal];
        
        UIButton *useBtn = [bottomBarBottomView.subviews objectAtIndex:1];
        [useBtn setTitle:@"选取" forState:UIControlStateNormal];
        
        // bottombar index:1 topview
        UIView *bottomBarTopView = [bottomBar.subviews objectAtIndex:1];
        
        // 0->camera 1->cancel 2->photo
        UIButton *takeBtn = [bottomBarTopView.subviews objectAtIndex:0];
        takeBtn = takeBtn;
        UIButton *cancelBtn = [bottomBarTopView.subviews objectAtIndex:1];
        [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        
        UIButton *photoBtn = [[UIButton alloc] initWithFrame:cancelBtn.bounds];
        UIImage* image = useBtn.currentBackgroundImage;
        [photoBtn setBackgroundImage:image forState:UIControlStateNormal];
        [photoBtn setTitle:@"图库" forState:UIControlStateNormal];
        [photoBtn.titleLabel setFont:useBtn.titleLabel.font];
        [photoBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [photoBtn addTarget:self action:@selector(showPhotoLibraryPicker) forControlEvents:UIControlEventTouchUpInside];
        photoBtn.center = CGPointMake([[UIScreen mainScreen] applicationFrame].size.width - cancelBtn.center.x,
                                      cancelBtn.center.y) ;
        [bottomBarTopView addSubview:photoBtn];
    }
}

// Return Image Picker’s Shoot button (the button that makes the photo).
- (UIControl*) getCamShutButton
{
	
	UIView *topView = [self findCamControlsLayerView:self.view];
	UIView *buttonsBar = [topView.subviews objectAtIndex:2];
	UIControl *btn = [buttonsBar.subviews objectAtIndex:1];
	
	return btn;
}

// Return Image Picker’s Retake button that appears after the user pressed Shoot.
- (UIControl*) getCamRetakeButton
{
	
	UIView *topView = [self findCamControlsLayerView:self.view];
	UIView *buttonsBar = [topView.subviews objectAtIndex:2];
	UIControl *btn = [buttonsBar.subviews objectAtIndex:0];
	
	return btn;
}

// Find the view that contains the camera controls (buttons)
- (UIView*)findCamControlsLayerView:(UIView*)view
{
	
	Class cl = [view class];
	NSString *desc = [cl description];
	if ([desc compare:@"PLCropOverlay"] == NSOrderedSame)
		return view;
	
	for (NSUInteger i = 0; i < [view.subviews count]; i++)
	{
		UIView *subView = [view.subviews objectAtIndex:i];
		subView = [self findCamControlsLayerView:subView];
		if (subView)
			return subView;
	}
	
	return nil;
}

@end
