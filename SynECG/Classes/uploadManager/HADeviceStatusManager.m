//
//  HADeviceStatusManager.m
//  SynECG
//
//  Created by LiangXiaobin on 16/7/7.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import "HADeviceStatusManager.h"
#import "SynECGLibSingleton.h"
#import "RequestManager.h"
#import "SynConstant.h"
#import "SynECGUtils.h"
#import "NSString+EnumSynEcg.h"
#import "SDBManager.h"
#import "ECGErrorCodeUpload.h"

@interface HADeviceStatusManager ()
{
    FMDatabaseQueue *queue;
    dispatch_queue_t upQueue;
}

@end

@implementation HADeviceStatusManager
+ (instancetype)sharedInstance
{
    static HADeviceStatusManager * sharedInstance = nil;
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
        _reUpdate = NO;
        _upNum = 0;
        queue = [SDBManager defaultDBManager].queue;
        upQueue = dispatch_queue_create("upStatus", DISPATCH_QUEUE_CONCURRENT);
       
    }
    return self;
}

- (void)uploadStatusMessage
{
    if ([RequestManager isNetworkReachable] == YES && self.updating == NO && [SynECGLibSingleton sharedInstance].loginIn == YES)
    {
        self.updating = YES;
          BlockWeakSelf(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    
                    NSString *targetId = [[NSString alloc]init];
                    NSString *recordId = [[NSString alloc]init];
                    NSString *deviceId = [[NSString alloc]init];
                    NSString *deviceStatus = [[NSString alloc]init];
                    NSString *lastStatus = [[NSString alloc]init];
                    NSString *startTime = [[NSString alloc]init];
                    long long time = 0;
                    NSString *json = [[NSString alloc]init];
                    
                    
                    
                    NSString *numQuery  = [NSString stringWithFormat:@"select count(*) from %@",STATUS_TABLE];
                    NSUInteger num = [db intForQuery:numQuery];
                    //查询一条
                    NSString *query = [NSString stringWithFormat:@"select * from %@ ORDER by id limit 0,1",STATUS_TABLE];
                    FMResultSet *rs1 = [db executeQuery:query];
                    
                    
                    while ([rs1 next]) {

                        targetId = [rs1 stringForColumn:@"targetId"];
                        recordId = [rs1 stringForColumn:@"recordId"];
                        deviceId = [rs1 stringForColumn:@"deviceId"];
                        deviceStatus = [rs1 stringForColumn:@"deviceStatus"];
                        startTime = [rs1 stringForColumn:@"startTime"];
                        lastStatus = [rs1 stringForColumn:@"oldDeviceStatus"];
                        time = (NSInteger)[rs1 longLongIntForColumn:@"occurUnixTime"];
                        json = [rs1 stringForColumn:@"dataIndexVo"];
                        
                    }
                    
                    if (num > 0)
                    {
                        if (num > 1) {
                            weakSelf.reUpdate = YES;
                        }
                        else
                        {
                            weakSelf.reUpdate = NO;
                        }
                        
                        
                        if(targetId.length > 0 && deviceId.length > 0 && startTime.length > 0 && time > 0)
                        {
                            NSDictionary *dic = [SynECGUtils dictionaryWithJsonString:json];
                            
                            NSDictionary *params = @{
                                                     @"recordId":recordId,
                                                     @"deviceId":deviceId,
                                                     @"deviceStatus":[@"" deviceStatusTypeStringFromEventType:deviceStatus],
                                                     @"startTime":startTime,
                                                     @"lastStatus":[@"" deviceStatusTypeStringFromEventType:lastStatus],
                                                     @"targetId":targetId,
                                                     @"occurUnixTime":@(time),
                                                     @"dataIndexVo":dic
                                                     };
                            [weakSelf uploadStatusMessagewithModel:params];
                        }
                        else
                        {
                            //数据不完整
                              [weakSelf deleteNewMessageByDB:db];
                        }
                    }
                    else
                    {

                            weakSelf.updating = NO;
                    }
                    
                    
                }];
        });
        
    }
}

- (void)uploadStatusMessagewithModel:(NSDictionary *)model
{
        BlockWeakSelf(self);
        [[RequestManager sharedInstance]postParameters:model Url:DEVICE_STATUS_URL sucessful:^(id obj) {
            
            weakSelf.upNum = 0;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
               
                 [weakSelf deleteNewMessage];
            });

        } failure:^(id obj) {
            
            NSLog(@"%@",obj);
            
            
            if ([obj[@"result"][@"errorCode"] integerValue] == 1 || [obj[@"result"][@"errorCode"] integerValue] == 10002) {
                
                [weakSelf deleteNewMessage];
                
            }
            else if([obj[@"result"][@"errorCode"] integerValue] == 8888 || [obj[@"result"][@"errorCode"] integerValue] == 911)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    [weakSelf uploadStatusMessagewithModel:model];
                });
            }
            else if([obj[@"result"][@"errorCode"] integerValue] == 9999 || [obj[@"result"][@"errorCode"] integerValue] == 2 || [obj[@"result"][@"errorCode"] integerValue] == 111)
            {
                weakSelf.updating = NO;
            }
            else
            {
                if (weakSelf.upNum <= 3) {
                    
                    [self uploadStatusMessagewithModel:model];
                }
                else
                {
                    [self deleteNewMessage];
                }
            }
            
           
                
            NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
            
            NSTimeInterval tv = [[NSDate date]  timeIntervalSince1970];
            
            long long timesp = (long long)(tv * 1000 - 500);
            
            [params setObject:DEVICE_STATUS_URL forKey:@"reqUrl"];
            [params setObject:@"statusUpload" forKey:@"reqType"];
            [params setObject:[SynECGUtils convertToJSONData:model] forKey:@"reqParams"];
            [params setObject:@(timesp) forKey:@"createdTime"];
            [params setObject:@(timesp) forKey:@"execTime"];
            [params setObject:obj[@"result"] forKey:@"rtnResult"];
            
            
            [[ECGErrorCodeUpload sharedInstance]uploadErrorMessageWith:params];
                
    
            weakSelf.upNum ++;
        }];


}



- (void)deleteNewMessage
{
    //STATUS_TABLE
    
    BlockWeakSelf(self);
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {

        [weakSelf deleteNewMessageByDB:db];

    }];
}

- (void)deleteNewMessageByDB:(FMDatabase *)db
{
    NSString *query = [NSString stringWithFormat:@"DELETE FROM %@ ORDER by id limit 0,1",STATUS_TABLE];
    BOOL succeed = [db executeUpdate:query];
    if (succeed) {
        
        self.updating = NO;
        if (self.reUpdate == YES) {
            [self uploadStatusMessage];
        }
    }
    else
    {
        [self deleteNewMessageByDB:db];
    }
}


@end
