//
//  ViewController.m
//  AudioDemo
//
//  Created by 张兆健 on 15/6/10.
//  Copyright (c) 2015年 ZZJ. All rights reserved.
//

#import "ViewController.h"
#import "AudioView.h"

@interface ViewController ()<AudioViewDelegate>

@property (nonatomic,strong) UIView *bgView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)singleTap {
    [self.bgView removeFromSuperview];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)pressAudio:(id)sender {
    self.bgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.bgView.backgroundColor = [UIColor clearColor];
    AudioView *audio = [[AudioView alloc] init];
    [audio initRecordUrl:@"http://192.168.1.51:808/123456.mp3"];
    //[audio initRecordUrl:@"https://ilearn.blob.core.chinacloudapi.cn/student/2068/96294323-1e5d-443c-b08c-fb4a9bca5efa.mp3?sv=2014-02-14&sr=b&sig=eSkFcofXzTGdWw1Cj%2BKjRpvKgxDaUcayARjY6jGXIhk%3D&se=2015-07-13T04%3A47%3A32Z&sp=r"];
    //[audio initRecordUrl:@"https://ilearn.blob.core.chinacloudapi.cn/media/3/140f8aaa-31b8-44c8-bdf9-4824b29a3f84.mp3?sv=2014-02-14&sr=b&sig=SZrekPCaMkgA3s%2Fw06FEy8aal7rPbvbdw55TWYz%2BtgQ%3D&se=9999-12-31T15%3A59%3A59Z&sp=r"];
    [self.bgView addSubview:audio];
    audio.center = self.bgView.center;
    audio.delegate = self;
    [self.view addSubview:self.bgView];
}

- (void)disMissAudioView {
    [self.bgView removeFromSuperview];
    self.bgView = nil;
}

- (void)cancelAction {
    [self.bgView removeFromSuperview];
    self.bgView = nil;
}

@end
