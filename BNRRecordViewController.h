//
//  BNRRecordViewController.h
//  VideoFun
//
//  Created by LazE on 6/3/14.
//  Copyright (c) 2014 BabyJeff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface BNRRecordViewController : UIViewController
{
    bool isRecording;
    bool isPlaying;
}

@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIView *videoView;
@property (weak, nonatomic) IBOutlet UIView *camView;
@property (weak, nonatomic) IBOutlet UIView *playbackView;
@property (weak, nonatomic) IBOutlet UIView *playbackVideoView;


@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *videoButton;


@property (weak, nonatomic) AVPlayer *videoPlayer;
@property (weak, nonatomic) AVPlayer *playbackPlayer;
@property (weak, nonatomic) AVPlayer *playbackVideoPlayer;

@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureMovieFileOutput *captureVideoOutput;

@property (strong, nonatomic) NSString *videoPath;


@end
