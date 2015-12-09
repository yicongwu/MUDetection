//
//  ViewController.m
//  MUDetection
//
//  Created by kid on 11/20/15.
//  Copyright © 2015 kid. All rights reserved.
//

#import "ViewController.h"
#import "SMKDetectionCamera.h"
#import <GPUImage/GPUImage.h>
#include <stdlib.h>
using namespace cv;

@interface ViewController () {
    // Setup the view (this time using GPUImageView)
    GPUImageView *cameraView_;
    SMKDetectionCamera *detector_; // Detector that should be used
    UIView *faceFeatureTrackingView_; // View for showing bounding box around the face
    CGAffineTransform cameraOutputToPreviewFrameTransform_;
    CGAffineTransform portraitRotationTransform_;
    CGAffineTransform texelToPixelTransform_;
    cv::Mat imageframe;
    GPUImageRawDataOutput *rawDataOutput;
    cv::Mat RGface;
    Ptr<FaceRecognizer> model;
    vector<Mat> images;
    vector<int> labels;
    int idnum;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString* imagePath2 = [[NSBundle mainBundle]
                            pathForResource:@"RGuser" ofType:@"JPG"];
    UIImage* imgFromUrl2=[[UIImage alloc]initWithContentsOfFile:imagePath2];
    
    cv::Mat RGimage,gray;
    UIImageToMat(imgFromUrl2,RGimage);
    cv::Rect faceRec;
    
    cv::cvtColor(RGimage, gray, CV_BGR2GRAY); // Convert to grayscale
    cv::Mat im = gray;
    cv::Mat display_im=RGimage;
    
    vector<cv::Rect> faces;
    equalizeHist( im, im );
    NSDictionary *detectorOptions = @{ CIDetectorAccuracy : CIDetectorAccuracyLow };
    CIDetector *faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    
    // 5. Apply the image through the face detector
    NSArray *features = [faceDetector featuresInImage:[CIImage imageWithCGImage: [imgFromUrl2 CGImage]]];
    for(CIFaceFeature* faceFeature in features)
    {
        CGRect rec=faceFeature.bounds;
        faceRec.x=rec.origin.x;
        faceRec.y=640-rec.origin.y-rec.size.height;
        faceRec.width=rec.size.width;
        faceRec.height=rec.size.height;
    }
    
    // get sample face region
    //Mat faceROI=gray(faces[0]);
    Mat faceROI=gray(faceRec);
    RGface=faceROI;
    
    images.push_back(RGface);
    labels.push_back(0);
    
    model = createLBPHFaceRecognizer();
    model->set("threshold",70.0);
    model->train(images,labels);
    
    // Setup GPUImageView (not we are not using UIImageView here).........
    cameraView_ = [[GPUImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height)];
    
    // Set the face detector to be used
    detector_ = [[SMKDetectionCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    [detector_ setOutputImageOrientation:UIInterfaceOrientationPortrait]; // Set to portrait
    cameraView_.fillMode = kGPUImageFillModePreserveAspectRatio;
    rawDataOutput=[[GPUImageRawDataOutput alloc] initWithImageSize:CGSizeMake(480, 640) resultsInBGRAFormat:YES];
    [detector_ addTarget:cameraView_];
    [detector_ addTarget:rawDataOutput];
    // Important: add as a subview
    [self.view addSubview:cameraView_];
    // Setup the face box view
    [self setupFaceTrackingViews];
    [self calculateTransformations];
    
    // Set the block for running face detector
    [detector_ beginDetecting:kFaceFeatures | kMachineAndFaceMetaData
                    codeTypes:@[AVMetadataObjectTypeQRCode]
           withDetectionBlock:^(SMKDetectionOptions detectionType, NSArray *detectedObjects, CGRect clapOrRectZero) {
               // Check if the kFaceFeatures have been discovered
               if (detectionType & kFaceFeatures) {
                   [self updateFaceFeatureTrackingViewWithObjects:detectedObjects];
               }
           }];
    
    
    __unsafe_unretained GPUImageRawDataOutput * weakOutput = rawDataOutput;
    [rawDataOutput setNewFrameAvailableBlock:^{
        [weakOutput lockFramebufferForReading];
        GLubyte *outputBytes = [weakOutput rawBytesForImage];
        cv::Mat abc(640,480,CV_8UC4,outputBytes);
        imageframe=abc;
        [weakOutput unlockFramebufferAfterReading];
    }];
    
    // Finally start the camera
    [detector_ startCameraCapture];
    
}

// Set up the view for facetracking
- (void)setupFaceTrackingViews
{
    faceFeatureTrackingView_ = [[UIView alloc] initWithFrame:CGRectZero];
    faceFeatureTrackingView_.layer.borderColor = [[UIColor redColor] CGColor];
    faceFeatureTrackingView_.layer.borderWidth = 3;
    faceFeatureTrackingView_.backgroundColor = [UIColor clearColor];
    faceFeatureTrackingView_.hidden = YES;
    faceFeatureTrackingView_.userInteractionEnabled = NO;
    [self.view addSubview:faceFeatureTrackingView_]; // Add as a sub-view
}

// Update the face feature tracking view
- (void)updateFaceFeatureTrackingViewWithObjects:(NSArray *)objects
{
    if (!objects.count) {
        faceFeatureTrackingView_.hidden = YES;
    }
    else {
        CIFaceFeature * feature = objects[0];
        CGRect face = feature.bounds;
        
        //change CI rec to Cv Rect
        cv::Rect faceRec;
        faceRec.x=face.origin.y;
        faceRec.y=face.origin.x;
        faceRec.width=face.size.width;
        faceRec.height=face.size.height;
        //std::cout<<face.origin.x<<" "<<face.origin.y<<std::endl;
        Mat gray;
        cv::cvtColor(imageframe, gray, CV_BGRA2GRAY);
        //extract face region
        Mat faceROI=gray(faceRec);
        //face recognition: predict process
        int predicted_label = -1;
        double predicted_confidence;
        // Get the prediction and associated confidence from the model
        model->predict(faceROI, predicted_label, predicted_confidence);
        //std::cout<<predicted_label<<std::endl;
        std::cout<<predicted_confidence<<std::endl;
        
        
        
        face = CGRectApplyAffineTransform(face, portraitRotationTransform_);
        face = CGRectApplyAffineTransform(face, cameraOutputToPreviewFrameTransform_);
        faceFeatureTrackingView_.frame = face;
        faceFeatureTrackingView_.hidden = NO;
        
        
        // Finally check if I smile (change the color)
        if(predicted_label!=-1) {
            faceFeatureTrackingView_.layer.borderColor = [[UIColor blueColor] CGColor];
        }
        else {
            faceFeatureTrackingView_.layer.borderColor = [[UIColor redColor] CGColor];
        }
    }
}

// Calculate transformations for displaying output on the screen
- (void)calculateTransformations
{
    NSInteger outputHeight = [[detector_.captureSession.outputs[0] videoSettings][@"Height"] integerValue];
    NSInteger outputWidth = [[detector_.captureSession.outputs[0] videoSettings][@"Width"] integerValue];
    
    if (UIInterfaceOrientationIsPortrait(detector_.outputImageOrientation)) {
        // Portrait mode, swap width & height
        NSInteger temp = outputWidth;
        outputWidth = outputHeight;
        outputHeight = temp;
    }
    
    // Use self.view because self.cameraView is not resized at this point (if 3.5" device)
    CGFloat viewHeight = self.view.frame.size.height;
    CGFloat viewWidth = self.view.frame.size.width;
    
    // Calculate the scale and offset of the view vs the camera output
    // This depends on the fillmode of the GPUImageView
    CGFloat scale;
    CGAffineTransform frameTransform;
    switch (cameraView_.fillMode) {
        case kGPUImageFillModePreserveAspectRatio:
            scale = MIN(viewWidth / outputWidth, viewHeight / outputHeight);
            frameTransform = CGAffineTransformMakeScale(scale, scale);
            frameTransform = CGAffineTransformTranslate(frameTransform, -(outputWidth * scale - viewWidth)/2, -(outputHeight * scale - viewHeight)/2 );
            break;
        case kGPUImageFillModePreserveAspectRatioAndFill:
            scale = MAX(viewWidth / outputWidth, viewHeight / outputHeight);
            frameTransform = CGAffineTransformMakeScale(scale, scale);
            frameTransform = CGAffineTransformTranslate(frameTransform, -(outputWidth * scale - viewWidth)/2, -(outputHeight * scale - viewHeight)/2 );
            break;
        case kGPUImageFillModeStretch:
            frameTransform = CGAffineTransformMakeScale(viewWidth / outputWidth, viewHeight / outputHeight);
            break;
    }
    cameraOutputToPreviewFrameTransform_ = frameTransform;
    
    // In portrait mode, need to swap x & y coordinates of the returned boxes
    if (UIInterfaceOrientationIsPortrait(detector_.outputImageOrientation)) {
        // Interchange x & y
        portraitRotationTransform_ = CGAffineTransformMake(0, 1, 1, 0, 0, 0);
    }
    else {
        portraitRotationTransform_ = CGAffineTransformIdentity;
    }
    
    // AVMetaDataOutput works in texels (relative to the image size)
    // We need to transform this to pixels through simple scaling
    texelToPixelTransform_ = CGAffineTransformMakeScale(outputWidth, outputHeight);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
