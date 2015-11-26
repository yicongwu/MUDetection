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
const Scalar RED = Scalar(0,0,255);
const Scalar GREEN = Scalar(0,255,0);

@interface ViewController()
{
    UIImageView *liveView_; // Live output from the camera
    CvVideoCamera *videoCamera;
    cv::Mat RGface;
}

@end

@implementation ViewController


//===============================================================================================
// Setup view for excuting App
- (void)viewDidLoad {
    [super viewDidLoad];
    cv::CascadeClassifier face_cascade;
    NSString* cascadePath1 = [[NSBundle mainBundle]
                              pathForResource:@"haarcascade_frontalface_alt" ofType:@"xml"];
    face_cascade.load([cascadePath1 UTF8String]);
    
    NSString* imagePath2 = [[NSBundle mainBundle]
                            pathForResource:@"RGuser" ofType:@"JPG"];
    UIImage* imgFromUrl2=[[UIImage alloc]initWithContentsOfFile:imagePath2];
    
    cv::Mat RGimage,gray;
    UIImageToMat(imgFromUrl2,RGimage);
    RGimage=RGimage.t();

    cv::cvtColor(RGimage, gray, CV_BGR2GRAY); // Convert to grayscale
    cv::Mat im = gray;
    cv::Mat display_im=RGimage;
    
    vector<cv::Rect> faces;
    //equalizeHist( frame_gray, frame_gray );
    std::cout<<im.cols<<" "<<im.rows<<std::endl;
    face_cascade.detectMultiScale( im, faces, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE,cv::Size(50, 100) );
    std::cout << "Detected " << faces.size() << " faces!!!! " << std::endl;
    for( int i = 0; i < faces.size(); i++ )
    {
        rectangle(display_im, faces[i], YELLOW);
    }
    
    std::cout<<display_im.cols<<display_im.rows;
    
//display_im=display_im.t();
/*
    Mat faceROI=RGimage(faces[0]);
    RGface=faceROI;                    ///////////////
*/
    //RGface=RGimage2;
    
    
    // 1. Setup the your OpenCV view, so it takes up the entire App screen......
    int view_width = self.view.frame.size.width;
    int view_height = (640*view_width)/480; // Work out the viw-height assuming 640x480 input
    int view_offset = (self.view.frame.size.height - view_height)/2;
    liveView_ = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, view_offset, view_width, view_height)];
    [self.view addSubview:liveView_]; // Important: add liveView_ as a subview
    liveView_.hidden=false;
    
    //liveView_.image=imgFromUrl2;
  //  liveView_.image=MatToUIImage(display_im);
    
        
        
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
 
    
    
    //image=RGface;
    
    
    // You can apply your OpenCV code HERE!!!!!
    // If you want, you can ignore the rest of the code base here, and simply place
    // your OpenCV code here to process images.
    cv::CascadeClassifier face_cascade; // Cascade classifier for detecting the face
    cv::CascadeClassifier mouth_cascade;
    NSString* cascadePath1 = [[NSBundle mainBundle]
                              pathForResource:@"haarcascade_frontalface_alt" ofType:@"xml"];
    face_cascade.load([cascadePath1 UTF8String]);
    
    
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
    cv::Rect mainFace;
    int max=0;
    for( int i = 0; i < faces.size(); i++ )
    {
        if (i==0)
        {
            mainFace=faces[i];
            max=mainFace.height * mainFace.width;
        }
        else
        {
            if (max<(faces[i].height*faces[i].width))
            {
                mainFace=faces[i];
                max=mainFace.height * mainFace.width;
            }
        }
        cv::Point center( faces[i].x + faces[i].width*0.5, faces[i].y + faces[i].height*0.5 );
        rectangle(display_im, faces[i], YELLOW);
        std::cout<<faces[0].height<<faces[0].height;   ///////////////////////////////////////////////////
        faces[i].y = int(faces[i].y+faces[i].width*0.5);
        faces[i].height = int(faces[i].height*0.5);
        Mat faceROI = frame_gray( faces[i] );

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
    rectangle(display_im, mainFace, RED);
    
    image =display_im;
 //   image=RGface;
    


    //  [takephotoButton_ setHidden:true]; [goliveButton_ setHidden:false]; // Switch visibility of buttons
}

//===============================================================================================
// Standard memory warning component added by Xcode
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end