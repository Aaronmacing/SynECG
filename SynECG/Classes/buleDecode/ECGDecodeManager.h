//
//  ECGDecodeManager.h
//  SynECG
//
//  Created by LiangXiaobin on 16/6/30.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol ECGDecodeManagerDelegate <NSObject>

/**
 RR数据
 @param rr rr
 */
- (void)syn_ecgDecodeMessageOnRRValue:(NSArray *)rr;
/**
 *  实时心率
 */
- (void)syn_ecgDecodeMessageOnHRValue:(NSDictionary *)hrValue;
/**
 *  hrv数据
 */
- (void)syn_ecgDecodeMessageOnHRVValue:(NSDictionary*)hrvValue;
/**
 *  实时姿态数据
 */
- (void)syn_ecgDecodeMessageOnActivityValue:(NSDictionary *)activityValue;
/**
 *  呼吸数据
 */
- (void)syn_ecgDecodeMessageOnBreathValue:(NSDictionary *)breathValue;
/**
 *  异常数据
 */
- (void)syn_ecgDecodeMessageOnEventValue:(NSDictionary *)eventValue;

/**
 *  心电数据
 */
- (void)syn_ecgDecodeMessageOnECG:(NSData *)ecgArray;

/**
 *  补偿进度
 */
- (void)syn_ecgDecodeMessageOnPercentage:(NSInteger)percentage andSpendTime:(NSInteger)st andV:(float)v andUnfinishTime:(NSInteger)ufTime;

@end




@interface ECGDecodeManager : NSObject
//事件处理队列
@property(nonatomic,strong)dispatch_queue_t eventQueue;
//RR处理队列
@property(nonatomic,strong)dispatch_queue_t annQueue;
//energy处理队列
@property(nonatomic,strong)dispatch_queue_t enengyQueue;
////breath处理队列
//@property(nonatomic,strong)dispatch_queue_t breathQueue;


////breath处理队列
@property(nonatomic,strong)dispatch_queue_t eventTempQueue;

//心率数据处理队列
@property(nonatomic,strong)dispatch_queue_t hrQueue;

@property(nonatomic,strong)dispatch_queue_t ecgQueue;


@property(nonatomic,assign)NSInteger nowPosition;


@property(nonatomic,assign)NSInteger time_flag;
@property(nonatomic,assign)NSInteger p15;
@property(nonatomic,assign)NSInteger p30;
@property(nonatomic,assign)NSInteger p60;

@property(nonatomic,assign)NSInteger rrp;

@property(nonatomic,retain)NSMutableData *eventTempData;

@property(nonatomic,assign)NSInteger rrNUm;
@property(nonatomic, assign)BOOL compensate;

@property(nonatomic,assign)NSInteger parseing;

@property(nonatomic,copy)NSMutableArray *tempArray;
@property(nonatomic,copy)NSMutableArray *maxAndMinArray;
@property(nonatomic,strong)NSMutableArray *totalArray;
@property(nonatomic,weak)id<ECGDecodeManagerDelegate> delegate;

@property(nonatomic,assign)NSInteger sinusStart;
@property(nonatomic,assign)NSInteger unsinusStart;
@property(nonatomic,retain)NSString *unsinusType;

@property(nonatomic,copy)NSMutableArray *sinusArray;

@property(nonatomic,assign)BOOL needReturn;

+ (instancetype)sharedInstance;

- (void)loadSECGMessageFromData:(NSData *)date;
//解析ECG数据
- (void)loadECGMessageFromData:(NSData *)date;

//及时心跳数据
- (void )loadHeartRateDataWithData:(NSData *)message;

//蓝牙4.2的数据解析
//新的事件数据
- (void)loadNewEventDataFromData:(NSData *)message;
//新的ann数据
- (void)loadNewRRDataFromData:(NSData *)message;
//新的呼吸能量数据
- (void)loadNewBreathDataFromData:(NSData *)message;
//上传百分比
- (void)loadNewinfoDataFromData:(NSData *)message;
//v2的能量数据
- (void)loadNewEnergyDataFromData:(NSData *)message;

//V5的ACT
- (void)loadAct_V5DataWithData:(NSData *)message;

-(void)loadEvtRecordDataFromData:(NSData *)message andIndex:(NSInteger)index;
-(void)loadAnntRecordDataFromData:(NSData *)message andIndex:(NSInteger)index;
- (void)loadEcgtRecordDataFromData:(NSData *)message andIndex:(NSInteger)index;
@property (nonatomic, assign)NSInteger ecg;
@property (nonatomic, assign)NSInteger ann;
@property (nonatomic, assign)NSInteger event;

@end
