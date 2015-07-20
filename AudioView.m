//
//  AudioView.m
//  AudioDemo
//
//  Created by 张兆健 on 15/6/10.
//  Copyright (c) 2015年 ZZJ. All rights reserved.
//

#import "AudioView.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "VoiceConverter.h"

#define kProgressStep   0.1

@interface AudioView() <AVAudioPlayerDelegate,UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *tenNum;
@property (weak, nonatomic) IBOutlet UIImageView *singleNum;
@property (weak, nonatomic) IBOutlet UIImageView *tenthNum;
@property (weak, nonatomic) IBOutlet UIImageView *percentileNum;
@property (weak, nonatomic) IBOutlet UILabel *totalNum;
@property (weak, nonatomic) IBOutlet UILabel *startNum;
@property (weak, nonatomic) IBOutlet UIButton *myRecord;

@property (nonatomic,strong) AVAudioRecorder *recoder;
@property (nonatomic,strong) AVAudioPlayer *player;
@property (nonatomic,strong) AVAudioSession *session;
@property (nonatomic,strong) AVPlayer *webPlayer;
@property (nonatomic,strong) AVPlayerItem *playerItem;
@property (weak, nonatomic) IBOutlet UISlider *myProgress;

@property (nonatomic,copy) NSString *tmpPath;
@property (nonatomic,copy) NSString *tmpAmrPath;
@property (weak, nonatomic) IBOutlet UIButton *removeBtn;
@property (retain, nonatomic) IBOutlet UIButton *finishBtn;

@property (nonatomic,assign) float audioTime;

@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,strong) NSTimer *volumeTimer;
@property (weak, nonatomic) IBOutlet UIView *bg;
@property (nonatomic,strong) UIView *volumeBg;
@property (nonatomic,strong) NSMutableArray *volumeList;

@property (nonatomic,assign) kAudioType audioType;
@property (nonatomic,assign) BOOL isWebAudioPlaying;
@property (nonatomic,strong) UILabel *title;
@property (nonatomic,copy) NSString *webPlayerUrl;

@end

@implementation AudioView

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self = [[[NSBundle mainBundle] loadNibNamed:@"AudioView" owner:nil options:nil] lastObject];
        self.bg.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
        //self.bg.center = self.center;
        //[self recoderSetting];
        self.audioType = kAudioTypeRecoder;
        self.isRecorded = NO;
        self.volumeBg = [[UIView alloc] initWithFrame:CGRectMake(30, 330, 424, 16)];
        self.volumeBg.backgroundColor = [UIColor clearColor];
        [self.bg addSubview:self.volumeBg];
        [self initVolumeView];
        self.title = [[UILabel alloc] init];
        self.title.bounds = CGRectMake(0, 0, 200, 40);
        self.title.center = CGPointMake(242.5, 25);
        [self.title setFont:[UIFont systemFontOfSize:28]];
        self.title.textAlignment = NSTextAlignmentCenter;
        self.title.text = @"录制声音";
        [self.title setTextColor:[UIColor whiteColor]];
        [self.bg addSubview:self.title];
        UIButton *cancel = [[UIButton alloc] initWithFrame:CGRectMake(448, 5, 32, 32)];
        //[cancel setTitle:@"返回" forState:UIControlStateNormal];
        [cancel setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
        [self.bg addSubview:cancel];
        [cancel addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)cancelAction {
    if (self.recoder) {
        [self.recoder pause];
        self.recoder = nil;
    }
    if (self.webPlayer) {
        [self.webPlayer pause];
        self.webPlayer = nil;
    }
    
    if ([self.delegate respondsToSelector:@selector(cancelAction)]) {
        [self.delegate cancelAction];
    }
}

- (void)initVolumeView {
    self.volumeList = [NSMutableArray array];
    for (int i=0; i < 11; i++) {
        UIImageView *volume = [[UIImageView alloc] initWithFrame:CGRectMake(39*i, 0, 34, 16)];
        [self.volumeBg addSubview:volume];
        [self.volumeList addObject:volume];
    }
    [self clearVolume];
}

- (void)clearVolume {
    for (UIImageView *volume in self.volumeList) {
        volume.image = [UIImage imageNamed:@"background_vumeter"];
    }
}

- (void)setRecoderName:(NSString *)recoderName {
    _recoderName = recoderName;
    self.tmpAmrPath = nil;
    self.tmpAmrPath = [NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"%@.amr",recoderName]];
    self.tmpPath = [NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"%@.wav",recoderName]];
    [self recoderSetting];
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.tmpPath]) {
        [self initPlayer];
        self.isRecorded = YES;
    }
}

- (void)recoderSetting {
    NSURL *tmpUrl = [NSURL fileURLWithPath:self.tmpPath];
    NSDictionary *recordSetting = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   [NSNumber numberWithFloat: 8000],AVSampleRateKey, //采样率
                                   [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,
                                   [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,//采样位数 默认 16
                                   [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,//通道的数目
                                   [NSNumber numberWithInt:AVAudioQualityHigh],
                                   AVEncoderAudioQualityKey,
                                   nil];
    
    [self initSessionWithCategory:AVAudioSessionCategoryPlayAndRecord];
    
    self.recoder = [[AVAudioRecorder alloc] initWithURL:tmpUrl settings:recordSetting error:nil];
    self.recoder.meteringEnabled = YES;
}

- (void)initSessionWithCategory:(NSString *)category {
    self.session = [AVAudioSession sharedInstance];
    NSError *sessionError;
    [self.session setCategory:category error:&sessionError];
    
    if(self.session == nil)
        NSLog(@"Error creating session: %@", [sessionError description]);
    else
        [self.session setActive:YES error:nil];
}

- (void)addTimer {
    if (self.timer != nil) {
        return;
    }
    self.timer = [NSTimer scheduledTimerWithTimeInterval:kProgressStep target:self selector:@selector(addTime) userInfo:nil repeats:YES];
}

- (void)removeTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)addVolumeTimer {
    if (self.volumeTimer != nil) {
        return;
    }
    self.volumeTimer = [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(reflashVolume) userInfo:nil repeats:YES];
}

- (void)removeVolumeTimer {
    if (self.volumeTimer) {
        [self.volumeTimer invalidate];
        self.volumeTimer = nil;
    }
    [self clearVolume];
}

- (void)setVolumeImageTo:(NSInteger)index {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeVolumeTimer];
        [self clearVolume];
        for (int i=0; i < index; i++) {
            UIImageView *volume = [self.volumeList objectAtIndex:i];
            volume.image = [UIImage imageNamed:@"icon_vumeter"];
        }
        [self addVolumeTimer];
    });
}

- (void)reflashVolume {
    [self.recoder updateMeters];//刷新音量数据
    //获取音量的平均值  [recorder averagePowerForChannel:0];
    //音量的最大值  [recorder peakPowerForChannel:0];
    
    //double lowPassResults = pow(10, (0.05 * [self.recoder peakPowerForChannel:0]));
    //double lowPassResults = pow(10, (0.5 * [self.recoder averagePowerForChannel:0]));
    double lowPassResults = fabs([self.recoder peakPowerForChannel:0]);
    
    
    
    if (40.0 > lowPassResults  && lowPassResults > 30.0) {
        [self setVolumeImageTo:1];
    } else if (25.0 < lowPassResults && lowPassResults <= 30.0) {
        [self setVolumeImageTo:2];
    } else if (20.0 < lowPassResults && lowPassResults <= 25.0) {
        [self setVolumeImageTo:3];
    } else if (15.0 < lowPassResults && lowPassResults <= 20.0) {
        [self setVolumeImageTo:4];
    } else if (12.0 < lowPassResults && lowPassResults <= 15.0) {
        [self setVolumeImageTo:5];
    } else if (9.0 < lowPassResults && lowPassResults <= 12.0) {
        [self setVolumeImageTo:6];
    } else if (6.0 < lowPassResults && lowPassResults <= 9.0) {
        [self setVolumeImageTo:7];
    } else if (3.0 < lowPassResults && lowPassResults <= 6.0) {
        [self setVolumeImageTo:8];
    } else if (2.0 < lowPassResults && lowPassResults <= 3.0) {
        [self setVolumeImageTo:9];
    } else if (1.0 < lowPassResults && lowPassResults <= 2.0) {
        [self setVolumeImageTo:10];
    } else if (lowPassResults < 1.0 ) {
        [self setVolumeImageTo:11];
    } else {
        [self clearVolume];
    }
}

- (void)addTime {
    self.audioTime += kProgressStep;
}

- (void)setAudioTime:(float)audioTime {
    _audioTime = audioTime;
    if (self.audioType == kAudioTypeRecoder && !self.isRecorded && self.totalTime>0) {
        int time = self.totalTime-audioTime;
        if (time <= 0) {
            self.myRecord.selected = !self.myRecord.selected;
            [self recoderStop];
        }
        [self setMinutes:time/60];
        [self setSeconds:time%60];
    } else {
        [self setMinutes:_audioTime/60];
        [self setSeconds:(int)audioTime%60];
    }
    if (self.isRecorded) {
        self.myProgress.value = audioTime;
    }
}

- (void)setMinutes:(NSInteger)minute {
    long ten = minute/10;
    long one = minute%10;
    [self.tenNum setImage:[UIImage imageNamed:[NSString stringWithFormat:@"number_%li",ten]]];
    [self.singleNum setImage:[UIImage imageNamed:[NSString stringWithFormat:@"number_%li",one]]];
}

- (void)setSeconds:(NSInteger)second {
    long ten = second/10;
    long one = second%10;
    [self.tenthNum setImage:[UIImage imageNamed:[NSString stringWithFormat:@"number_%li",ten]]];
    [self.percentileNum setImage:[UIImage imageNamed:[NSString stringWithFormat:@"number_%li",one]]];
}

- (void)setIsRecorded:(BOOL)isRecorded {
    _isRecorded = isRecorded;
    if (_isRecorded) {
        [self.myRecord setImage:[UIImage imageNamed:@"btn_play_normal.9"] forState:UIControlStateNormal];
        [self.myRecord setImage:[UIImage imageNamed:@"btn_pause_normal.9"] forState:UIControlStateSelected];
        [self hideInfo:NO];
    } else {
        [self.myRecord setImage:[UIImage imageNamed:@"btn_record_normal.9"] forState:UIControlStateNormal];
        [self.myRecord setImage:[UIImage imageNamed:@"btn_stop_normal.9"] forState:UIControlStateSelected];
        [self hideInfo:YES];
    }
}

- (void)recoderStart {
    [self.session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [self.recoder prepareToRecord];
    self.audioTime = 0;
    [self.recoder record];
    [self addTimer];
    [self addVolumeTimer];
}

- (void)recoderStop {
    [self.recoder stop];
    NSURL *url = [NSURL fileURLWithPath:self.tmpPath];
    self.myRecordUrl = url;
    [self removeTimer];
    [self removeVolumeTimer];
    [self initPlayer];
}

- (void)initPlayer {
    self.isRecorded = YES;
    self.myProgress.value = 0.0;
    //self.myProgress.maximumValue = self.audioTime;
    self.myRecordUrl = [NSURL URLWithString:self.tmpPath];
    [self.session setCategory:AVAudioSessionCategoryPlayback error:nil];
    if (self.player == nil) {
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.myRecordUrl error:nil];
        self.player.delegate = self;
    }
    self.myProgress.maximumValue = self.player.duration;
    NSInteger audioTime = self.player.duration;
    self.totalNum.text = [NSString stringWithFormat:@"%@:%@",audioTime/60<10 ? [NSString stringWithFormat:@"0%li",audioTime/60] : [NSString stringWithFormat:@"%li",audioTime/60],audioTime%60<10 ? [NSString stringWithFormat:@"0%li",audioTime%60] : [NSString stringWithFormat:@"%li",audioTime%60]];
    self.audioTime = 0;
    NSLog(@"%@",self.tmpPath);
}

- (void)recoderPlay {
    //webAudio
    if (self.audioType == kAudioTypeLineAudio) {
        if (!self.isWebAudioPlaying) {
            [self.webPlayer play];
            float time = CMTimeGetSeconds([self.playerItem currentTime]);
            float time2 = CMTimeGetSeconds([self.playerItem duration]);
            NSLog(@"------ %f total: %f-------",time,time2);
            self.audioTime = self.myProgress.value;
            [self addTimer];
        } else {
            [self.webPlayer pause];
            [self removeTimer];
        }
        self.isWebAudioPlaying = !self.isWebAudioPlaying;
        return;
    }
    //Recoder
    if (self.player.playing) {
        [self.player pause];
        [self removeTimer];
        self.removeBtn.enabled = true;
    } else {
        [self.player play];
        [self addTimer];
        self.audioTime = self.player.currentTime;
        self.removeBtn.enabled = false;
    }
}

- (void)initRecordUrl:(NSString *)strUrl {
    if (strUrl == nil) {
        self.myRecordUrl = nil;
        return;
    }
    
    self.audioType = kAudioTypeLineAudio;
    self.webPlayerUrl = strUrl;
    [self initWebPlayer:strUrl];
    
    self.isWebAudioPlaying = false;
    self.isRecorded = YES;
    self.myProgress.value = 0.0;
    CMTime duration = self.playerItem.asset.duration;
    self.myProgress.maximumValue = CMTimeGetSeconds(duration);
    if (self.myProgress.maximumValue == 0) {
        self.myRecord.enabled = false;
    }
    NSInteger audioTime = self.myProgress.maximumValue;
    self.totalNum.text = [NSString stringWithFormat:@"%@:%@",audioTime/60<10 ? [NSString stringWithFormat:@"0%li",audioTime/60] : [NSString stringWithFormat:@"%li",audioTime/60],audioTime%60<10 ? [NSString stringWithFormat:@"0%li",audioTime%60] : [NSString stringWithFormat:@"%li",audioTime%60]];
    self.audioTime = 0;
    self.title.text = @"历史录音";
}

- (void)initWebPlayer:(NSString *)strUrl {
    [self initSessionWithCategory:AVAudioSessionCategoryPlayback];
    AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:[NSURL URLWithString:strUrl] options:nil];
    self.playerItem = [[AVPlayerItem alloc] initWithAsset:urlAsset];
    self.webPlayer = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webPlayerDidPlayered) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    //[self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //[self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if([keyPath isEqualToString:@"status"])
    {
        //        NSLog(@"%@",change);
        
        AVPlayerItemStatus newPrice=[change[@"new"] intValue];
        if (newPrice == AVPlayerItemStatusReadyToPlay) {
            CMTime current = self.playerItem.currentTime;
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
        NSLog(@"Time Interval:%f",timeInterval);
    }
}

- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [self.playerItem loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.lastObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}


- (void)webPlayerDidPlayered {
    [self removeTimer];
    self.myProgress.value = 0.0;
    self.isWebAudioPlaying = false;
    [self.myRecord setSelected:NO];
    [self.webPlayer seekToTime:kCMTimeZero];
}

- (void)setMyRecordUrl:(NSURL *)myRecordUrl {
    _myRecordUrl = myRecordUrl;
    if (myRecordUrl == nil) {
        self.isRecorded = false;
    } else {
        self.isRecorded = true;
    }
}

- (IBAction)deleteBtnClick:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"您确定要删除这段录音吗？" delegate:self cancelButtonTitle:@"YES" otherButtonTitles:@"Cancel", nil];
    [alert show];
}

- (void)hideInfo:(BOOL)isShow {
    self.myProgress.hidden = isShow;
    self.totalNum.hidden = isShow;
    self.startNum.hidden = isShow;
    self.removeBtn.enabled = !isShow;
    self.volumeBg.hidden = !isShow;
    self.finishBtn.enabled = !isShow;
}

- (void)setAudioType:(kAudioType)audioType {
    _audioType = audioType;
    self.removeBtn.hidden = audioType==kAudioTypeLineAudio ? YES : NO;
    self.finishBtn.hidden = audioType==kAudioTypeLineAudio ? YES : NO;
}

- (IBAction)recordBtnClick:(id)sender {
    [self.myRecord setSelected:!self.myRecord.selected];
    if (!self.isRecorded) {
        if (self.myRecord.selected) {
            [self recoderStart];
        } else {
            [self recoderStop];
            self.isRecorded = true;
        }
    } else {
        [self recoderPlay];
    }
    
}

//上传音频
- (IBAction)finishBtnClick:(id)sender {
    if ([self.delegate respondsToSelector:@selector(disMissAudioView)]) {
        [self.delegate disMissAudioView];
        //把录制好的音频wav文件转成amr文件
        [VoiceConverter ConvertWavToAmr:self.tmpPath amrSavePath:self.tmpAmrPath];
        //可再这里做一些数据处理
    }
}
- (IBAction)progressChange:(id)sender {
    [self removeTimer];
    switch (self.audioType) {
        case kAudioTypeRecoder:
            [self.player pause];
            self.audioTime = self.myProgress.value;
            break;
        case kAudioTypeLineAudio:
        {
            [self.webPlayer pause];
            self.isWebAudioPlaying = NO;
            self.audioTime = self.myProgress.value;
        }
            break;
        default:
            break;
    }
    
    
}
- (IBAction)progressDidChange:(id)sender {
    self.myRecord.selected = NO;
    switch (self.audioType) {
        case kAudioTypeRecoder:
            self.player.currentTime = self.audioTime;
            [self recordBtnClick:nil];
            break;
        case kAudioTypeLineAudio:
        {
            CMTime time1 = [self.playerItem duration];
            time1.value = self.myProgress.value/self.myProgress.maximumValue*time1.value;
            if (self.webPlayer.currentItem != self.playerItem) {
                [self.webPlayer replaceCurrentItemWithPlayerItem:self.playerItem];
            }
            [self.webPlayer seekToTime:time1 completionHandler:^(BOOL finished) {
                if (finished) {
                    self.audioTime = CMTimeGetSeconds([self.playerItem currentTime]);
                    [self recordBtnClick:nil];
                }
            }];
        }
            break;
        default:
            break;
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (flag) {
        [player stop];
        self.removeBtn.enabled = true;
        [self removeTimer];
        self.audioTime = 0;
    }
    [self.myRecord setSelected:NO];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSError *error;
        BOOL tmp=[[NSFileManager defaultManager] removeItemAtPath:self.tmpPath error:&error];
        if (tmp != YES ) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"删除失败" message:[error localizedDescription]  delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
            [alert show];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"删除成功" message:[error localizedDescription]  delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
            [alert show];
            self.isRecorded = NO;
            self.player = nil;
            [self recoderSetting];
        }
    }
}


@end
