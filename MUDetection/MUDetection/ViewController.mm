//
//  ViewController.m
//  MUDetection
//
//  Created by kid on 11/20/15.
//  Copyright © 2015 kid. All rights reserved.
//

#import "ViewController.h"

// Include stdlib.h and std namespace so we can mix C++ code in here
#include <stdlib.h>
using namespace cv;

const Scalar RED = Scalar(255,0,0);
const Scalar PINK = Scalar(255,130,230);
const Scalar BLUE = Scalar(0,0,255);
const Scalar LIGHTBLUE = Scalar(160,255,255);
const Scalar GREEN = Scalar(0,255,0);
const Scalar WHITE = Scalar(255,255,255);

@interface ViewController()
{
    UIImageView *liveView_; // Live output from the camera
    CvVideoCamera *videoCamera;
}

@end

@implementation ViewController


//===============================================================================================
// Setup view for excuting App
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    // 1. Setup the your OpenCV view, so it takes up the entire App screen......
    int view_width = self.view.frame.size.width;
    int view_height = (640*view_width)/480; // Work out the viw-height assuming 640x480 input
    int view_offset = (self.view.frame.size.height - view_height)/2;
    liveView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, view_offset, view_width, view_height)];
    [self.view addSubview:liveView_]; // Important: add liveView_ as a subview
    liveView_.hidden=false;
    
    videoCamera = [[CvVideoCamera alloc] initWithParentView:liveView_];
    videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    videoCamera.defaultFPS = 30;
    videoCamera.grayscaleMode = NO;
    videoCamera.delegate = self;
    [videoCamera start];
}

//===============================================================================================

- (void)processImage:(cv::Mat &)image{
    
    
    
    /*
    // You can apply your OpenCV code HERE!!!!!
    // If you want, you can ignore the rest of the code base here, and simply place
    // your OpenCV code here to process images.
    cv::CascadeClassifier face_cascade; // Cascade classifier for detecting the face
    cv::CascadeClassifier eye_cascade;
    
    NSString* cascadePath1 = [[NSBundle mainBundle]
                              pathForResource:@"haarcascade_frontalface_alt" ofType:@"xml"];
    face_cascade.load([cascadePath1 UTF8String]);
    
    NSString* cascadePath2 = [[NSBundle mainBundle]
                              pathForResource:@"haarcascade_eye" ofType:@"xml"];
    eye_cascade.load([cascadePath2 UTF8String]);
    
    
    cv::Mat cvImage=image;
    cvImage= cvImage.t();
    cv::Mat gray; cv::cvtColor(cvImage.clone(), gray, CV_RGBA2GRAY); // Convert to grayscale
    cv::Mat im = gray.clone();
    cv::Mat display_im=cvImage.clone();
    
    vector<cv::Rect> faces;
    Mat frame_gray=im.clone();
    equalizeHist( frame_gray, frame_gray );
    std::cout<<frame_gray.cols<<" "<<frame_gray.rows<<std::endl;
    face_cascade.detectMultiScale( frame_gray, faces, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE,cv::Size(30, 100) );
    std::cout << "Detected " << faces.size() << " faces!!!! " << std::endl;
    for( int i = 0; i < faces.size(); i++ )
    {
        cv::Point center( faces[i].x + faces[i].width*0.5, faces[i].y + faces[i].height*0.5 );
        rectangle(display_im, faces[i], RED);
        
        Mat faceROI = frame_gray( faces[i] );
        vector<cv::Rect> eyes;
        
        eye_cascade.detectMultiScale( faceROI, eyes, 1.1, 2, 0 |CV_HAAR_SCALE_IMAGE, cv::Size(5, 20) );
        std::cout << "Detected " << eyes.size() << " eyes!!!! " << std::endl;
        for( int j = 0; j < eyes.size(); j++ )
        {
            cv::Point center( faces[i].x + eyes[j].x + eyes[j].width*0.5, faces[i].y + eyes[j].y + eyes[j].height*0.5 );
            int radius = cvRound( (eyes[j].width + eyes[i].height)*0.25 );
            circle( display_im, center, radius, GREEN, 4, 8, 0 );
        }
    }
    image =display_im.t();
    */
    // Special part to ensure the image is rotated properly when the image is converted back
    //  [takephotoButton_ setHidden:true]; [goliveButton_ setHidden:false]; // Switch visibility of buttons
    
}

//===============================================================================================
// Standard memory warning component added by Xcode
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end