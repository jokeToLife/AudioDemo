//
//  AudioView.h
//  AudioDemo
//
//  Created by 张兆健 on 15/6/10.
//  Copyright (c) 2015年 ZZJ. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    kAudioTypeRecoder,
    kAudioTypeLineAudio
}kAudioType;

@protocol AudioViewDelegate <NSObject>

- (void)disMissAudioView;
- (void)cancelAction;

@end

@interface AudioView : UIView

@property (nonatomic,strong) NSURL *myRecordUrl;
@property (nonatomic,assign) BOOL isRecorded;
@property (nonatomic,copy) NSString *recoderName;
@property (nonatomic,assign) NSInteger totalTime;
@property (nonatomic,assign) id<AudioViewDelegate> delegate;

- (void)initRecordUrl:(NSString *)strUrl;

@end
