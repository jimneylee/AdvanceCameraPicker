//
//  BYQuickShotView.m
//  QuickShotView
//
//  Created by Dario Lass on 22.03.13.
//  Copyright (c) 2013 Bytolution. All rights reserved.
//

#import "BYQuickShotView.h"
#import <CoreMedia/CoreMedia.h>
#import <QuartzCore/QuartzCore.h>

@interface BYQuickShotView ()

- (void)prepareSession;
- (AVCaptureDevice*)rearCamera;
- (CGRect)previewLayerFrame;
- (UIImage*)cropImage:(UIImage*)imageToCrop;
- (void)animateFlash;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;

@end

#define PREVIEW_LAYER_INSET 8
#define PREVIEW_LAYER_EDGE_RADIUS 10
#define BUTTON_SIZE 50

@implementation BYQuickShotView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // jimenylee close it ,no use
        //[self prepareSession];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (UIImageView *)imagePreView
{
    if (!_imagePreView) {
        _imagePreView = [[UIImageView alloc]init];
        _imagePreView.layer.cornerRadius = PREVIEW_LAYER_EDGE_RADIUS - 1;
        _imagePreView.layer.masksToBounds = YES;
        _imagePreView.frame = self.previewLayerFrame;
        _imagePreView.userInteractionEnabled = NO;
        _imagePreView.backgroundColor = [UIColor clearColor];
        [self addSubview:_imagePreView];
    }
    return _imagePreView;
}

- (CGRect)previewLayerFrame
{
    CGRect layerFrame = self.bounds;

    layerFrame.origin.x += PREVIEW_LAYER_INSET;
    layerFrame.origin.y += PREVIEW_LAYER_INSET;
    layerFrame.size.width -= PREVIEW_LAYER_INSET * 2;
    layerFrame.size.height -= PREVIEW_LAYER_INSET * 2;
    
    return layerFrame;
}

//This method returns the AVCaptureDevice we want to use as an input for our AVCaptureSession

- (AVCaptureDevice *)rearCamera {
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice;
    for (AVCaptureDevice *device in videoDevices)
    {
        if (device.position == AVCaptureDevicePositionBack)
        {
            captureDevice = device;
        }
    }
    return captureDevice;
}

// if we want to add a shadow without drawing out of bounds we have to slightly resize the AVCaptureVideoPreviewLayer
// and this method returns trhe frame we need to achieve this



- (void)prepareSession
{
    NSLog(@"%@", self.captureSession);
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    //capture session setup
    AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.rearCamera error:nil];
    AVCaptureStillImageOutput *newStillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    AVVideoCodecJPEG, AVVideoCodecKey,
                                    nil];
    [newStillImageOutput setOutputSettings:outputSettings];
    
    AVCaptureSession *newCaptureSession = [[AVCaptureSession alloc] init];
    newCaptureSession.sessionPreset = AVCaptureSessionPresetPhoto;//jimneylee fix this
    
    if ([newCaptureSession canAddInput:newVideoInput]) {
        [newCaptureSession addInput:newVideoInput];
    }
    
    if ([newCaptureSession canAddOutput:newStillImageOutput]) {
        [newCaptureSession addOutput:newStillImageOutput];
        self.stillImageOutput = newStillImageOutput;
        self.captureSession = newCaptureSession;
    }
    // -startRunning will only return when the session started (-> the camera is then ready)
    dispatch_queue_t layerQ = dispatch_queue_create("layerQ", NULL);
    dispatch_async(layerQ, ^{
        [self.captureSession startRunning];
        AVCaptureVideoPreviewLayer *prevLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
        prevLayer.frame = self.previewLayerFrame;
        prevLayer.masksToBounds = YES;
        prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        prevLayer.cornerRadius = PREVIEW_LAYER_EDGE_RADIUS;
        //to make sure were not modifying the UI on a thread other than the main thread, use dispatch_async w/ dispatch_get_main_queue
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.layer insertSublayer:prevLayer atIndex:0];
        });
    }); 
}

#pragma mark - Public
- (void)captureSessionStartRunning
{
    [self.captureSession startRunning];
}

- (void)captureSessionStopRunning
{
    [self.captureSession stopRunning];
}

- (AVCaptureFlashMode)changeFlashMode
{
    AVCaptureDevice* device = self.rearCamera;
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] && [device hasFlash]) {
        [device lockForConfiguration:nil];
        if(AVCaptureFlashModeOff == [device flashMode]) {
            [device setFlashMode:AVCaptureFlashModeAuto];
        }
        else if(AVCaptureFlashModeAuto == [device flashMode]) {
            [device setFlashMode:AVCaptureFlashModeOn];
        }
        else {
            [device setFlashMode:AVCaptureFlashModeOff];
        }
        [device unlockForConfiguration];
    }
    return device.flashMode;
}

- (AVCaptureDevicePosition)changePosition
{
    AVCaptureDevicePosition position = AVCaptureDevicePositionBack;
    NSArray *inputs = self.captureSession.inputs;
    for ( AVCaptureDeviceInput *input in inputs )
    {
        AVCaptureDevice *device = input.device;
        if ([device hasMediaType:AVMediaTypeVideo])
        {
            AVCaptureDevicePosition position = device.position;
            AVCaptureDevice *newCamera = nil;
            AVCaptureDeviceInput *newInput = nil;
            
            if (position == AVCaptureDevicePositionFront) {
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
                position = AVCaptureDevicePositionBack;
            }
            else {
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
                position = AVCaptureDevicePositionFront;
            }
            device = newCamera;
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            [self.captureSession beginConfiguration];
            [self.captureSession removeInput:input];
            [self.captureSession addInput:newInput];
            [self.captureSession commitConfiguration];
            break;
        }
    }
    return position;
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if (device.position == position)
        {
            return device;
        }
    }
    return nil;
}

- (void)captureImage
{
    //Before we can take a snapshot, we need to determine the specific connection to be used
    
    NSArray *connections = [self.stillImageOutput connections];
    AVCaptureConnection *stillImageConnection;
    for ( AVCaptureConnection *connection in connections ) {
		for ( AVCaptureInputPort *port in [connection inputPorts] ) {
			if ( [[port mediaType] isEqual:AVMediaTypeVideo] ) {
				stillImageConnection = connection;
			}
		}
	}
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                       completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                           UIImage *capturedImage;
                                                           if (imageDataSampleBuffer != NULL) {
                                                               // as for now we only save the image to the camera roll, but for reusability we should consider implementing a protocol
                                                               // that returns the image to the object using this view
                                                               NSData *imgData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                               capturedImage = [UIImage imageWithData:imgData];
                                                            }
                                                           UIImage *croppedImg = [self cropImage:capturedImage];
                                                           self.imagePreView.image = croppedImg;
                                                           [self.delegate didTakeSnapshot:croppedImg];
                                                           [self animateFlash];
                                                        }];
}

#if 0//jimneylee close
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.imagePreView.image) {
        [self captureImage];
    } else {
        [self.delegate didDiscardLastImage];
        self.imagePreView.image = nil;
    }
}
#endif

#pragma mark - Private
- (void)animateFlash {
    UIView *flashView = [[UIView alloc]initWithFrame:self.previewLayerFrame];
    flashView.backgroundColor = [UIColor whiteColor];
    flashView.layer.masksToBounds = YES;
    flashView.layer.cornerRadius = PREVIEW_LAYER_EDGE_RADIUS;
    [self addSubview:flashView];
    [UIView animateWithDuration:0.2 delay:0.1 options:kNilOptions animations:^{
        flashView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [flashView removeFromSuperview];
    }];
}

- (UIImage *)cropImage:(UIImage *)imageToCrop {
    CGSize size = [imageToCrop size];
    int padding = 0;
    int pictureSize;
    int startCroppingPosition;
    if (size.height > size.width) {
        pictureSize = size.width - (2.0 * padding);
        startCroppingPosition = (size.height - pictureSize) / 2.0;
    } else {
        pictureSize = size.height - (2.0 * padding);
        startCroppingPosition = (size.width - pictureSize) / 2.0;
    }
    CGRect cropRect = CGRectMake(startCroppingPosition, padding, pictureSize, pictureSize);
    CGImageRef imageRef = CGImageCreateWithImageInRect([imageToCrop CGImage], cropRect);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:imageToCrop.imageOrientation];
    return newImage;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGFloat minx = CGRectGetMinX(self.previewLayerFrame), midx = CGRectGetMidX(self.previewLayerFrame), maxx = CGRectGetMaxX(self.previewLayerFrame);
    CGFloat miny = CGRectGetMinY(self.previewLayerFrame), midy = CGRectGetMidY(self.previewLayerFrame), maxy = CGRectGetMaxY(self.previewLayerFrame);
    CGContextMoveToPoint(c, minx, midy);
    CGContextAddArcToPoint(c, minx, miny, midx, miny, PREVIEW_LAYER_EDGE_RADIUS);
    CGContextAddArcToPoint(c, maxx, miny, maxx, midy, PREVIEW_LAYER_EDGE_RADIUS);
    CGContextAddArcToPoint(c, maxx, maxy, midx, maxy, PREVIEW_LAYER_EDGE_RADIUS);
    CGContextAddArcToPoint(c, minx, maxy, minx, midy, PREVIEW_LAYER_EDGE_RADIUS); 
    CGContextClosePath(c);
    CGContextSetShadow(c, CGSizeMake(0, 0), 6);
    CGContextSetLineWidth(c, 4);
    CGContextSetStrokeColorWithColor(c, [[UIColor whiteColor] CGColor]);
    CGContextDrawPath(c, kCGPathFillStroke);
}

@end
