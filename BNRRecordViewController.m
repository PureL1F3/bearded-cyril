//
//  BNRRecordViewController.m
//  VideoFun
//
//  Created by LazE on 6/3/14.
//  Copyright (c) 2014 BabyJeff. All rights reserved.
//

#import "BNRRecordViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>

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
    
    [self createMergedVideo];
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
    
    [self setupPlaybackVideoPlayer];
    [self setupPlaybackPlayer];
    [self.playbackVideoPlayer play];
    [self.playbackPlayer play];
}

- (void)stopPlayback
{
    NSLog(@"Stopping playback");
    isPlaying = false;
    [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    
    [self.playbackVideoPlayer pause];
    [self.playbackVideoPlayer seekToTime:kCMTimeZero];

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
    self.videoPlayer.muted = YES;
    CALayer *videoLayer = self.videoView.layer;
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.videoPlayer];
    playerLayer.frame = self.videoView.bounds;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [videoLayer addSublayer:playerLayer];
}
- (void)setupPlaybackVideoPlayer
{
    NSURL *videoURL = [[NSBundle mainBundle] URLForResource:@"video" withExtension:@"mp4"];
    self.playbackVideoPlayer = [AVPlayer playerWithURL:videoURL];
    
    self.playbackVideoPlayer.muted = YES;
    CALayer *videoLayer = self.playbackVideoView.layer;
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.playbackVideoPlayer];
    playerLayer.frame = self.playbackVideoView.bounds;
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


- (void)createMergedVideo
{
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *firstTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    NSURL *videoURL = [[NSBundle mainBundle] URLForResource:@"video" withExtension:@"mp4"];
    AVAsset *firstAsset = [AVAsset assetWithURL:videoURL];
    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration) ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    AVMutableCompositionTrack *secondTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAsset *secondAsset = [AVAsset assetWithURL:videoURL];
    [secondTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration) ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    
    
    AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, firstAsset.duration);
    
    //We will be creating 2 AVMutableVideoCompositionLayerInstruction objects.Each for our 2 AVMutableCompositionTrack.here we are creating AVMutableVideoCompositionLayerInstruction for out first track.see how we make use of Affinetransform to move and scale our First Track.so it is displayed at the bottom of the screen in smaller size.(First track in the one that remains on top).
    AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
    CGAffineTransform Scale = CGAffineTransformMakeScale(0.7f,0.7f);
    CGAffineTransform Move = CGAffineTransformMakeTranslation(230,230);
    [FirstlayerInstruction setTransform:CGAffineTransformConcat(Scale,Move) atTime:kCMTimeZero];
    
    //Here we are creating AVMutableVideoCompositionLayerInstruction for out second track.see how we make use of Affinetransform to move and scale our second Track.
    AVMutableVideoCompositionLayerInstruction *SecondlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:secondTrack];
    CGAffineTransform SecondScale = CGAffineTransformMakeScale(1.2f,1.5f);
    CGAffineTransform SecondMove = CGAffineTransformMakeTranslation(0,0);
    [SecondlayerInstruction setTransform:CGAffineTransformConcat(SecondScale,SecondMove) atTime:kCMTimeZero];
    
    
    //Now we add our 2 created AVMutableVideoCompositionLayerInstruction objects to our AVMutableVideoCompositionInstruction in form of an array.
    MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,SecondlayerInstruction,nil];;
    
    //Now we create AVMutableVideoComposition object.We can add mutiple AVMutableVideoCompositionInstruction to this object.We have only one AVMutableVideoCompositionInstruction object in our example.You can use multiple AVMutableVideoCompositionInstruction objects to add multiple layers of effects such as fade and transition but make sure that time ranges of the AVMutableVideoCompositionInstruction objects dont overlap.
    AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
    MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
    MainCompositionInst.frameDuration = CMTimeMake(1, 30);
    MainCompositionInst.renderSize = CGSizeMake(640, 480);

    // Create a static date formatter so we only have to initialize it once.
    static NSDateFormatter *kDateFormatter;
    if (!kDateFormatter) {
        kDateFormatter = [[NSDateFormatter alloc] init];
        kDateFormatter.dateStyle = NSDateFormatterMediumStyle;
        kDateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    // Create the export session with the composition and set the preset to the highest quality.
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPreset640x480];
    // Set the desired output URL for the file created by the export process.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"Black.mp4"];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    
     NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath])
    {
        NSError *error;
        if ([fileManager removeItemAtPath:filePath error:&error] == NO)
        {
        }
    }
    exporter.outputURL = url;
    // Set the output file type to be a QuickTime movie.
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = MainCompositionInst;
    // Asynchronously export the composition to a video file and save this file to the camera roll once export completes.
//    [exporter exportAsynchronouslyWithCompletionHandler:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
////            if (exporter.status == AVAssetExportSessionStatusCompleted) {
////                ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
////                if ([assetsLibrary videoAtPathIsCompatibleWithSavedPhotosAlbum:exporter.outputURL]) {
////                    [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:exporter.outputURL completionBlock:NULL];
////                }
////            }
//            [self exportDidFinish:exporter];
//        });
//    }];
    
    [exporter exportAsynchronouslyWithCompletionHandler:^(void) {
        
            if (exporter.status == AVAssetExportSessionStatusCompleted) {
                 ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
                 if ([assetsLibrary videoAtPathIsCompatibleWithSavedPhotosAlbum:exporter.outputURL]) {
                     [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:exporter.outputURL completionBlock:NULL];
                 }
             }
        [self exportDidFinish:exporter];
        
    }];
}

-(void)exportDidFinish:(AVAssetExportSession*)session {
    
    NSLog(@"export method");
    NSLog(@"%i", session.status);
    NSLog(@"%@", session.error);
}
@end
