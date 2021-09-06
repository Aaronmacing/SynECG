//
//  SynAlarmUploadManager.h
//  SynECG
//
//  Created by LiangXiaobin on 2016/10/5.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDBManager.h"

@interface SynAlarmUploadManager : NSObject
@property(nonatomic,assign)BOOL updating;
@property(nonatomic,assign)BOOL reupdate;
@property(nonatomic,assign)NSInteger upNum;
+ (instancetype)sharedInstance;
- (void)uploadAlertMessageToSever;
- (void)saveAlertWithAlarmId:(NSString *)alarm_id start_alarm_id:(NSString *)start_alarm_id occur_unixtime:(long long)occur_unixtime alert_type:(NSString *)alert_type alert_category:(NSString *)alert_category alarm_level:(NSInteger)alarm_level alarm_flag:(NSInteger)alarm_flag in:(FMDatabase *)db;
@end
