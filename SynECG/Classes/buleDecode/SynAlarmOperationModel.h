//
//  SynAlarmOperationModel.h
//  SynECG
//
//  Created by LiangXiaobin on 2016/9/29.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynECGBlueManager.h"
#import "SDBManager.h"

@interface SynAlarmOperationModel : NSObject
//开始时间
@property(nonatomic,assign)NSInteger startTime;
//室上性早搏
@property(nonatomic,assign)BOOL SVEB0;
@property(nonatomic,assign)BOOL SVEB1;
//室性早搏
@property(nonatomic,assign)BOOL VEB0;
@property(nonatomic,assign)BOOL VEB1;
@property(nonatomic,assign)BOOL VEB2;
@property(nonatomic,assign)BOOL VEB3;

@property(nonatomic,assign)NSInteger starA;
@property(nonatomic,assign)NSInteger starV;


//心动类型
@property(nonatomic,assign)NSInteger beatType;

@property(nonatomic,retain)NSString *unsinusType;

@property(nonatomic,copy)NSMutableArray *sinusArray;
@property(nonatomic,copy)NSMutableArray *unsinusArray;

@property(nonatomic,copy)NSMutableArray *hourAArray;
@property(nonatomic,copy)NSMutableArray *hourVArray;
@property(nonatomic,copy)NSMutableArray *minuteAArray;
@property(nonatomic,copy)NSMutableArray *minuteVArray;

@property(nonatomic,assign)NSInteger interval_time;


@property(nonatomic,assign)BOOL needMore;



+ (instancetype)sharedInstance;

- (void)eventWithType:(NSInteger)type duration:(float )duration withPosition:(NSInteger)position rr:(NSInteger)rr;

//按照时间检索数据库
- (void)retrieveBatabaseSelectForAlertFromTime:(NSInteger)timesep;

- (void)savePrematureBeatAlarmWithTime:(long long)time type:(NSString *)type category:(NSString *)category level:(NSInteger)level flag:(NSInteger)flag duration:(NSInteger)duration in:(FMDatabase *)db;

- (void)retrieveBatabaseSelectForFastOrSlowAlertFromTime:(long long)timesep;

- (void)retrieveAlarmFromPosition:(NSInteger )position type:(NSString *)anntyp;
//按照时间检索数据库RR
- (void)retrieveRRBatabaseSelectForAlertFromPosition:(NSInteger)position;
//新的
- (void)retrieveRRFromPosition:(NSInteger)position ann:(NSString *)ann;

- (void)closeAllAlert;
@end
