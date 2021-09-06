//
//  SynAlarmUploadManager.m
//  SynECG
//
//  Created by LiangXiaobin on 2016/10/5.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import "SynAlarmUploadManager.h"
#import "RequestManager.h"
#import "SynConstant.h"
#import "SynECGLibSingleton.h"
#import "ECGErrorCodeUpload.h"
#import "SynECGUtils.h"


@interface SynAlarmUploadManager()
{
    FMDatabaseQueue *queue;
    dispatch_queue_t upQueue;
}
@end

@implementation SynAlarmUploadManager
+ (instancetype)sharedInstance
{
    static SynAlarmUploadManager * sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        _updating = NO;
        _reupdate = NO;
        _upNum = 0;
        queue = [SDBManager defaultDBManager].queue;
        upQueue = dispatch_queue_create("aletUp", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

//保存告警
- (void)saveAlertWithAlarmId:(NSString *)alarm_id start_alarm_id:(NSString *)start_alarm_id occur_unixtime:(long long)occur_unixtime alert_type:(NSString *)alert_type alert_category:(NSString *)alert_category alarm_level:(NSInteger)alarm_level alarm_flag:(NSInteger)alarm_flag in:(FMDatabase *)db
{
    
    //ALARM_UPLOAD_TABLE
    
    
    if ([SynECGLibSingleton sharedInstance].record_id.length > 0) {
     
        BOOL save = [db executeUpdate:@"INSERT INTO alarmupload (user_id, target_id, record_id, alarm_id, start_alarm_id, occur_unixtime,alert_type,alert_category,alarm_level,alarm_flag) VALUES (?,?,?,?,?,?,?,?,?,?);",[SynECGLibSingleton sharedInstance].user_id,[SynECGLibSingleton sharedInstance].target_id,[SynECGLibSingleton sharedInstance].record_id,alarm_id,start_alarm_id,@(occur_unixtime),alert_type,alert_category,@(alarm_level),@(alarm_flag)];
        
        if (save) {
            
            [self uploadAlertMessageToSever];
            
            if (alarm_flag == 1) {
                
                NSString *updateSql = [NSString stringWithFormat:
                                       @"UPDATE %@ SET %@ = '%@', %@ = '%@' WHERE start_alarm_id = '%@'",ALARM_TABLE,@"alarm_id",alarm_id,@"alarm_flag",@(alarm_flag),start_alarm_id];
                [db executeUpdate:updateSql];
            }
        }

    }
}



- (void)uploadAlertMessageToSever
{
    if ([RequestManager isNetworkReachable] == YES && self.updating == NO && [SynECGLibSingleton sharedInstance].loginIn == YES)
    {
            BlockWeakSelf(self);
        self.updating = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                        
                        
                        //取数量
                        NSString *numQuery  = [NSString stringWithFormat:@"select count(*) from %@ where target_id = '%@'",ALARM_UPLOAD_TABLE,[SynECGLibSingleton sharedInstance].target_id];
                        NSUInteger num = [db intForQuery:numQuery];
                        
                        
                        //查询一条
                        NSString *query = [NSString stringWithFormat:@"select * from %@ where target_id = '%@' ORDER by id limit 0,1",ALARM_UPLOAD_TABLE,[SynECGLibSingleton sharedInstance].target_id];
                        FMResultSet *rs = [db executeQuery:query];
                        NSString *user_id = [[NSString alloc]init];
                        NSString *target_id = [[NSString alloc]init];
                        NSString *record_id = [[NSString alloc]init];
                        NSString *alert_id = [[NSString alloc]init];
                        NSString *start_alert_id = [[NSString alloc]init];
                        NSString *alert_type = [[NSString alloc]init];
                        NSString *alert_category = [[NSString alloc]init];
                        NSInteger alert_flag = 0;
                        long long occur_unixtime = 0;
                        NSInteger alert_level = 0;
                        
                        
                        
                        while ([rs next])
                        {
                            
                            user_id = [rs stringForColumn:@"user_id"];
                            target_id = [rs stringForColumn:@"target_id"];
                            record_id = [rs stringForColumn:@"record_id"];
                            alert_id = [rs stringForColumn:@"alarm_id"];
                            start_alert_id = [rs stringForColumn:@"start_alarm_id"];
                            alert_type = [rs stringForColumn:@"alert_type"];
                            alert_category = [rs stringForColumn:@"alert_category"];
                            
                            alert_flag = [rs intForColumn:@"alarm_flag"];
                            alert_level = [rs intForColumn:@"alarm_level"];
                            occur_unixtime = [rs longLongIntForColumn:@"occur_unixtime"];
                            
                        }
                    
                    if (num > 0) {
                        
                        if (num > 1) {
                            
                            self->_reupdate = YES;
                        }
                        else
                        {
                            self->_reupdate = NO;
                        }
                        
                        if (record_id.length > 0 && alert_category.length > 0)
                        {
                            NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
                            [dic setObject:user_id forKey:@"user_id"];
                            [dic setObject:target_id forKey:@"target_id"];
                            [dic setObject:record_id forKey:@"record_id"];
                            [dic setObject:alert_id forKey:@"alert_id"];
                            [dic setObject:start_alert_id forKey:@"start_alert_id"];
                            [dic setObject:alert_type forKey:@"alert_type"];
                            [dic setObject:alert_category forKey:@"alert_category"];
                            [dic setObject:@(alert_flag) forKey:@"alert_flag"];
                            [dic setObject:@(occur_unixtime) forKey:@"occur_unixtime"];
                            [dic setObject:@(alert_level) forKey:@"alert_level"];
                            
                            [weakSelf uploadBreathMessageToSeverWithModel:dic];
                            
                        }
                        else
                        {
                            [weakSelf deleteNewMessageWithType:alert_id];
                        }
                    }
                    else
                    {
                        weakSelf.updating = NO;
                    }

                        
                    }];
            });
    }
    else
    {
    }

}

- (void)uploadBreathMessageToSeverWithModel:(NSDictionary *)model
{

        BlockWeakSelf(self);
        [[RequestManager sharedInstance]postParameters:model Url:ALARM_UPLOAD_URL sucessful:^(id obj) {
            weakSelf.upNum = 0;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
                [weakSelf deleteNewMessageWithType:model[@"alert_id"]];
            });
            
        } failure:^(id obj) {
            NSLog(@"%@",obj);
            if ([obj  [@"result"][@"errorCode"] integerValue] == 1) {
                
                [weakSelf deleteNewMessageWithType:model[@"alert_id"]];
            }
            else if([obj[@"result"][@"errorCode"] integerValue] == 8888 || [obj[@"result"][@"errorCode"] integerValue] == 911 )
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    [weakSelf uploadBreathMessageToSeverWithModel:model];
                });
            }
            else if([obj[@"result"][@"errorCode"] integerValue] == 9999 || [obj[@"result"][@"errorCode"] integerValue] == 2 || [obj[@"result"][@"errorCode"] integerValue] == 111)
            {
                weakSelf.updating = NO;
            }
            else
            {
                if (weakSelf.upNum <= 3 ) {
                    
                    [self uploadBreathMessageToSeverWithModel:model];
                }
                else
                {
                    [weakSelf deleteNewMessageWithType:model[@"alert_id"]];
                }
            }

            
           
                
            NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
            
            NSTimeInterval tv = [[NSDate date]  timeIntervalSince1970];
            
            long long timesp = (long long)(tv * 1000 - 500);
            
            [params setObject:ALARM_UPLOAD_URL forKey:@"reqUrl"];
            [params setObject:@"alarmUpload" forKey:@"reqType"];
            [params setObject:[SynECGUtils convertToJSONData:model] forKey:@"reqParams"];
            [params setObject:@(timesp) forKey:@"createdTime"];
            [params setObject:@(timesp) forKey:@"execTime"];
            [params setObject:obj[@"result"] forKey:@"rtnResult"];
            
            
            [[ECGErrorCodeUpload sharedInstance]uploadErrorMessageWith:params];
                
 
            weakSelf.upNum ++;

        }];

}


- (void)deleteNewMessageWithType:(NSString *)type
{
    //ALARM_UPLOAD_TABLE
    BlockWeakSelf(self);
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
       
        [weakSelf deleteNewMessageWithDB:db Type:type];
    }];
}


- (void)deleteNewMessageWithDB:(FMDatabase *)db Type:(NSString *)type
{
    BOOL succeed = [db executeUpdate:@"DELETE FROM alarmupload ORDER by id limit 0,1"];
    if (succeed) {
        
        self.updating = NO;
       
        if (_reupdate == YES) {
         
             [self uploadAlertMessageToSever];
        }
        
    }
    else
    {
        [self deleteNewMessageWithDB:db Type:type];
    }

}



@end
