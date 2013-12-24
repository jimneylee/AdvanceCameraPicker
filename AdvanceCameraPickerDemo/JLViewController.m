//
//  JLViewController.m
//  CustomCameraTakeTest
//
//  Created by ccjoy-jimneylee on 13-12-18.
//  Copyright (c) 2013年 jimneylee. All rights reserved.
//

#import "JLViewController.h"
#import "JLHackCameraPickerController.h"
#import "JLCustomCameraPickerController.h"
#import "UIViewAdditions.h"

@interface JLViewController ()<JLHackCameraPickerDelegate, JLCustomCameraPickerDelegate>
@property (nonatomic, strong) UIImageView* photoPreviewImageView;
@property (nonatomic, strong) UIViewController* currentPicker;
@property (nonatomic, strong) UINavigationController* currentNaviController;
@end

@implementation JLViewController

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UIViewController

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad
{
    [super viewDidLoad];

    UIImageView* photoPreviewImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 320.f)];
    photoPreviewImageView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:photoPreviewImageView];
    self.photoPreviewImageView = photoPreviewImageView;
    
    UIButton* hackCameraBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
    [hackCameraBtn setTitle:@"HACK TAKE" forState:UIControlStateNormal];
    [hackCameraBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [hackCameraBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:25.f]];
    [hackCameraBtn addTarget:self action:@selector(showHackCameraPicker) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:hackCameraBtn];
    hackCameraBtn.center = CGPointMake(self.view.bounds.size.width / 2, photoPreviewImageView.bottom + 40.f);
    
    UIButton* customCameraBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];
    [customCameraBtn setTitle:@"CUSTOM TAKE" forState:UIControlStateNormal];
    [customCameraBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [customCameraBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:25.f]];
    [customCameraBtn addTarget:self action:@selector(showCustomCameraPicker)
              forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:customCameraBtn];
    customCameraBtn.center = CGPointMake(self.view.bounds.size.width / 2, hackCameraBtn.bottom + 40.f);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

//////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)showHackCameraPicker
{
    JLHackCameraPickerController* picker = [[JLHackCameraPickerController alloc] initWithCameraEditable:YES];
    UINavigationController* navi = [[UINavigationController alloc] initWithRootViewController:picker];
    picker.pickerDelegate = self;
    [self presentViewController:navi animated:NO completion:^{
        [picker showPicker];
    }];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)showCustomCameraPicker
{
    // TODO: editable
    JLCustomCameraPickerController* picker = [[JLCustomCameraPickerController alloc] init];
    picker.pickerDelegate = self;
    [self presentViewController:picker animated:NO completion:^{
    }];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma - JLCustomCameraPickerDelegate

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didPickPhoto:(UIImage*)photo
{
    self.photoPreviewImageView.image = photo;
    [self dismissViewControllerAnimated:NO completion:^{
    }];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didCancelPick
{
    [self dismissViewControllerAnimated:NO completion:^{
    }];
}

@end
