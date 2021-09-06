//
//  HeartBeatModel.m
//  SynECG
//
//  Created by LiangXiaobin on 2017/4/1.
//  Copyright © 2017年 LiangXiaobin. All rights reserved.
//

#import "HeartBeatModel.h"
#import "NSString+EnumSynEcg.h"
#import "SynECGLibSingleton.h"
#import "RequestManager.h"
#import "SynConstant.h"
#import "SynECGUtils.h"
#import "SDBManager.h"

@implementation HeartBeatModel
+ (instancetype)sharedInstance
{
    static HeartBeatModel * sharedInstance = nil;
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
        _num = 0;
    }
    return self;
}

- (void)uploadStatusMessage
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[SDBManager defaultDBManager].queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            
            NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
            NSString *old =  [user objectForKey:@"oldDeviceStatus"];
            
            if (!old) {
                old = @"0";
            }
            NSTimeInterval tv = [[NSDate date]  timeIntervalSince1970];
            long long timeSp = (long long)(tv * 1000);
            NSString *time = [SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss"];
            
            NSInteger rr = 0;
            NSInteger ecg = 0;
            NSInteger event = 0;
            rr = [self queryTable:TOTAL_TABLE Column:@"ann" inDB:db];
            ecg = [self queryTable:TOTAL_TABLE Column:@"ecg" inDB:db];
            event = [self queryTable:TOTAL_TABLE Column:@"event" inDB:db];
            
            
            NSMutableDictionary *new = [[NSMutableDictionary alloc]init];
            [new setObject:@(rr) forKey:@"beatIndex"];
            [new setObject:@(ecg) forKey:@"ecgDataIndex"];
            [new setObject:@(event) forKey:@"eventIndex"];
            //[SynECGUtils getDateStringWithDate:ssDate WithFormat:@"yyyy-MM-dd HH:mm:ss"];
            
            NSDictionary *params = @{
                                     @"recordId":[SynECGLibSingleton sharedInstance].record_id,
                                     @"deviceId":[SynECGLibSingleton sharedInstance].deviceId,
                                     @"deviceStatus":[@"" deviceStatusTypeStringFromEventType:[NSString stringWithFormat:@"%ld",(long)[SynECGLibSingleton sharedInstance].typeNum]],
                                     @"startTime":time,
                                     @"lastStatus":[@"" deviceStatusTypeStringFromEventType:old],
                                     @"targetId":[SynECGLibSingleton sharedInstance].target_id,
                                     @"occurUnixTime":@(timeSp),
                                     @"dataIndexVo":new
                                     };
           
                [[RequestManager sharedInstance]postParameters:params Url:DEVICE_STATUS_URL sucessful:^(id obj) {
                    
                    
                } failure:^(id obj) {
                    
                    NSLog(@"%@",obj[@"result"][@"message"]);
                    NSLog(@"%@",obj);
                    NSLog(@"up timestatus er");
                }];

        }];
        
        
    });
}

- (NSInteger)queryTable:(NSString *)tableName  Column:(NSString *)columnName inDB:(FMDatabase *)db
{
    
    NSString *query = [NSString stringWithFormat:@"select * from %@",tableName];
    FMResultSet *rs = [db executeQuery:query];
    NSInteger rr = 0;
    while ([rs next]) {
        rr = (NSInteger)[rs longLongIntForColumn:columnName];
    }
    return rr;
}


- (void)searchFromRecord:(NSString *)recordId In:(FMDatabase *)db;
{
    NSString *numQuery1  = [NSString stringWithFormat:@"select count(*) from %@ where recordId = '%@'",HR_UPLOAD_TABLE,recordId];
     NSString *numQuery2  = [NSString stringWithFormat:@"select count(*) from %@ where record_id = '%@'",RR_UPLOAD_TABLE,recordId];
     NSString *numQuery3  = [NSString stringWithFormat:@"select count(*) from %@ where record_id = '%@'",EVENT_UPLOAD_TABLE,recordId];
    
    NSUInteger num1 = [db intForQuery:numQuery1];
    NSUInteger num2 = [db intForQuery:numQuery2];
    NSUInteger num3 = [db intForQuery:numQuery3];
    
    if (num1 + num2 + num3 == 0) {
        
        [self reCreatReportWithRecordId:recordId];
    }
}


- (void)reCreatReportWithRecordId:(NSString *)recordid
{
    _num ++;
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    [dic setObject:recordid forKey:@"recordId"];
    [[RequestManager sharedInstance]postParameters:dic Url:[NSString stringWithFormat:@"platform/app/records/%@/rebuild-report",recordid] sucessful:^(id obj) {
        self.num = 0;
        [self deleteMessageByRecord:recordid];
        
    } failure:^(id obj) {
        
        if (self.num == 1 || self.num == 2) {
            
            [self reCreatReportWithRecordId:recordid];
        }
        else
        {
            [self deleteMessageByRecord:recordid];
        }
        
    }];
}


- (void)deleteMessageByRecord:(NSString *)recordId
{
    [[SDBManager defaultDBManager].queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        [db executeUpdate:@"DELETE FROM record_list ORDER by id limit 0,1"];
        
    }];
}
    

@end
