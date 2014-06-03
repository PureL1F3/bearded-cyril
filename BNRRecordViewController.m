//
//  BNRRecordViewController.m
//  VideoFun
//
//  Created by LazE on 6/3/14.
//  Copyright (c) 2014 BabyJeff. All rights reserved.
//

#import "BNRRecordViewController.h"

#pragma mark PassTouch

@interface BNRRecordViewController ()

@end

@implementation BNRRecordViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        isRecording = false;
        isPlaying = false;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"Anna.mov"];
        self.videoPath = filePath;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.contentView];
    self.scrollView.contentSize = self.contentView.frame.size;
    
    
    [self.videoButton addTarget:self action:@selector(touchBegan:withEvent:) forControlEvents: UIControlEventTouchDown];
    [self.videoButton addTarget:self action:@selector(touchesEnded:withEvent:) forControlEvents: UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    
    [self setupVideoCaptureSession];
    [self setupVideoPlayer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)recordVideo:(id)sender
{

    if(isRecording)
    {
        [self stopRecording];
    }
    else
    {
        [self startRecording];
    }
}

- (void)startRecording
{
    NSLog(@"Start recording");
    isRecording = true;
    [self.recordButton setTitle:@"Stop" forState:UIControlStateNormal];
    
    
    [self.session beginConfiguration];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.videoPath])
    {
        NSError *error;
        if ([fileManager removeItemAtPath:self.videoPath error:&error] == NO)
        {
        }
    }
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:self.videoPath];
    [self.captureVideoOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
    
    [self.videoPlayer play];
}

- (void)stopRecording
{
    NSLog(@"Stop recording");
    isRecording = false;
    [self.recordButton setTitle:@"Record" forState:UIControlStateNormal];

    [self.videoPlayer pause];
    [self.videoPlayer seekToTime:kCMTimeZero];
    
    [self.captureVideoOutput stopRecording];
}

- (void)touchBegan:(UIButton *)control withEvent:(UIEvent *)event {
    [self beginUseVideoInRecording];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self endUseVideoInRecording];
}

- (void)beginUseVideoInRecording
{
    NSLog(@"Start use video now");
}
- (void)endUseVideoInRecording
{
    NSLog(@"End use video now");
}

- (IBAction)playbackRecording:(id)sender
{
    NSLog(@"playback");
    if(isPlaying)
    {
        [self stopPlayback];
        
    }
    else
    {
        [self startPlayback];
    }
}

- (void)startPlayback
{
    NSLog(@"Starting playback");
    isPlaying = true;
    [self.playButton setTitle:@"Stop" forState:UIControlStateNormal];
    
    [self setupPlaybackPlayer];
    [self.playbackPlayer play];
}

- (void)stopPlayback
{
    NSLog(@"Stopping playback");
    isPlaying = false;
    [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    
    [self.playbackPlayer pause];
    [self.playbackPlayer seekToTime:kCMTimeZero];
}


- (void)setupVideoCaptureSession
{
    self.session = [[AVCaptureSession alloc] init];
    [self.session beginConfiguration];
    
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        self.session.sessionPreset = AVCaptureSessionPreset640x480;
    }

    NSError *error;
    for(AVCaptureDevice *device in [AVCaptureDevice devices])
    {
        if([device hasMediaType:AVMediaTypeVideo] && ([device position] == AVCaptureDevicePositionFront))
        {
            AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
            if([self.session canAddInput:videoInput])
            {
                [self.session addInput:videoInput];
            }
        }
        if([device hasMediaType:AVMediaTypeAudio])
        {
            AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
            if([self.session canAddInput:audioInput])
            {
                [self.session addInput:audioInput];
            }
        }
    }
    
    AVCaptureVideoDataOutput *videoDataOutput = [AVCaptureVideoDataOutput new];
    [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
    if([self.session canAddOutput:videoDataOutput])
    {
        [self.session addOutput:videoDataOutput];
    }
    
    
    self.captureVideoOutput = [[AVCaptureMovieFileOutput alloc] init];
    if([self.session canAddOutput:self.captureVideoOutput])
    {
        [self.session addOutput:self.captureVideoOutput];
    }
    AVCaptureConnection *CaptureConnection = [self.captureVideoOutput connectionWithMediaType:AVMediaTypeVideo];

    
    [self.session commitConfiguration];
    [self.session startRunning];
    CALayer *cameraLayer = self.camView.layer;
    AVCaptureVideoPreviewLayer *capturePreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    capturePreviewLayer.frame = self.camView.bounds;
    capturePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [cameraLayer addSublayer:capturePreviewLayer];
}

- (void)setupVideoPlayer
{
    NSURL *videoURL = [[NSBundle mainBundle] URLForResource:@"video" withExtension:@"mp4"];
    self.videoPlayer = [AVPlayer playerWithURL:videoURL];
    CALayer *videoLayer = self.videoView.layer;
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.videoPlayer];
    playerLayer.frame = self.videoView.bounds;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [videoLayer addSublayer:playerLayer];
}

- (void)setupPlaybackPlayer
{
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:self.videoPath];
    self.playbackPlayer = [AVPlayer playerWithURL:outputURL];
    CALayer *videoLayer = self.playbackView.layer;
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.playbackPlayer];
    playerLayer.frame = self.playbackView.bounds;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [videoLayer addSublayer:playerLayer];
}
@end
