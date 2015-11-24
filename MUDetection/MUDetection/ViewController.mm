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

const Scalar YELLOW = Scalar(0,255,255);
const Scalar GREEN = Scalar(0,255,0);

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
    videoCamera.rotateVideo = YES;
    //videoCamera.recordVideo = YES;
    [videoCamera start];
}

//===============================================================================================

- (void)processImage:(cv::Mat &)image{
    
    // You can apply your OpenCV code HERE!!!!!
    // If you want, you can ignore the rest of the code base here, and simply place
    // your OpenCV code here to process images.
    cv::CascadeClassifier face_cascade; // Cascade classifier for detecting the face
    //cv::CascadeClassifier eye_cascade;
    cv::CascadeClassifier mouth_cascade;
    
    NSString* cascadePath1 = [[NSBundle mainBundle]
                              pathForResource:@"haarcascade_frontalface_alt" ofType:@"xml"];
    face_cascade.load([cascadePath1 UTF8String]);
    /*
    NSString* cascadePath2 = [[NSBundle mainBundle]
                              pathForResource:@"haarcascade_eye" ofType:@"xml"];
    eye_cascade.load([cascadePath2 UTF8String]);
    */
    NSString* cascadePath3 = [[NSBundle mainBundle]
                              pathForResource:@"haarcascade_mcs_mouth" ofType:@"xml"];
    mouth_cascade.load([cascadePath3 UTF8String]);


    cv::Mat cvImage=image;
    cv::Mat gray;
    cv::cvtColor(cvImage, gray, CV_RGBA2GRAY); // Convert to grayscale
    cv::Mat im = gray;
    cv::Mat display_im=cvImage;
    
    vector<cv::Rect> faces;
    Mat frame_gray=im;
    //equalizeHist( frame_gray, frame_gray );
    std::cout<<frame_gray.cols<<" "<<frame_gray.rows<<std::endl;
    face_cascade.detectMultiScale( frame_gray, faces, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE,cv::Size(50, 100) );
    std::cout << "Detected " << faces.size() << " faces!!!! " << std::endl;
    for( int i = 0; i < faces.size(); i++ )
    {
        cv::Point center( faces[i].x + faces[i].width*0.5, faces[i].y + faces[i].height*0.5 );
        rectangle(display_im, faces[i], YELLOW);
        faces[i].y = int(faces[i].y+faces[i].width*0.5);
        faces[i].height = int(faces[i].height*0.5);
        Mat faceROI = frame_gray( faces[i] );
        /*
        vector<cv::Rect> eyes;
        eye_cascade.detectMultiScale( faceROI, eyes, 1.1, 2, 0 |CV_HAAR_SCALE_IMAGE, cv::Size(5, 20) );
        std::cout << "Detected " << eyes.size() << " eyes!!!! " << std::endl;
        for( int j = 0; j < eyes.size(); j++ )
        {
            cv::Point center( faces[i].x + eyes[j].x + eyes[j].width*0.5, faces[i].y + eyes[j].y + eyes[j].height*0.5 );
            int radius = cvRound( (eyes[j].width + eyes[i].height)*0.25 );
            circle( display_im, center, radius, GREEN, 4, 8, 0 );
        }
        */
        vector<cv::Rect> mouths;
        mouth_cascade.detectMultiScale( faceROI, mouths, 1.1, 2, 0 |CV_HAAR_SCALE_IMAGE, cv::Size(30, 50) );
        std::cout << "Detected " << mouths.size() << " mouths!!!! " << std::endl;
        if  (mouths.size()>0)
        {
            cv::Point p1( faces[i].x + mouths[0].x , faces[i].y + mouths[0].y );
            cv::Point p2( faces[i].x + mouths[0].x + mouths[0].width, faces[i].y + mouths[0].y + mouths[0].height);
            
            /*
            int radius = cvRound( (mouths[j].width + mouths[i].height)*0.25 );
            circle( display_im, center, radius, GREEN, 4, 8, 0 );
            */
            rectangle(display_im, p1,p2, GREEN);
        }

    }
    
    image =display_im;


    //  [takephotoButton_ setHidden:true]; [goliveButton_ setHidden:false]; // Switch visibility of buttons
}

//===============================================================================================
// Standard memory warning component added by Xcode
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end