//
//  SynWaveformManager.h
//  SynECG
//
//  Created by LiangXiaobin on 2018/3/14.
//  Copyright © 2018年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM (NSInteger, SynWFState){
    SynWFStateNoFile = 0,
    SynWFStateOver = 1,
    SynWFStateOpenError = 2
};


@protocol SynWaveformManagerDelegate <NSObject>

@optional
//文件状态
-(void)syn_waveformStateChangedTo:(enum SynWFState)state;

//数据：
-(void)syn_waveformData:(NSArray *)ecgArray;

@end



@interface SynWaveformManager : NSObject
@property(nonatomic,weak)id<SynWaveformManagerDelegate>delegate;

/**
 *  初始化
 */

+ (instancetype)sharedInstance;

/**
 *  根据recordId开启文件
 */
- (void)openFileWithRecordId:(NSString *)recordId;


/**
 *  根据recordId关闭文件，退出时调用
 */
- (void)closeFile;

/**
 *  在开启文件的情况下跳到某点
 */
- (void)jumpToPoint:(NSInteger)point;

/**
 *  开启自动
 */
- (void)openAutoPlay;

/**
 *  关闭自动
 */
- (void)closeAutoPlay;

/**
 *  文件长度
 */
- (NSInteger)getFileLength;

/**
 *  移除过期文件
 */
- (void)deleteECGFilesOutDays:(NSInteger)days;


/**
 获取文件大小

 @return 大小
 */
- (unsigned long long)getFileSize;
/**
 *  移除全部文件
 */
- (void)deleteECGFiles;
- (NSData *)getEcgData:(NSInteger)percent;

@end
