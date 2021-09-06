//
//  HAEventManager.m
//  SynECG
//
//  Created by LiangXiaobin on 16/7/5.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import "HAEventManager.h"
#import "SynECGLibSingleton.h"
#import "RequestManager.h"
#import "SynConstant.h"
#import "SynECGUtils.h"
#import "ECGErrorCodeUpload.h"


@interface HAEventManager ()
{
    FMDatabaseQueue *queue;
    dispatch_queue_t upQueue;
    
}
@end

@implementation HAEventManager

+ (instancetype)sharedInstance
{
    static HAEventManager * sharedInstance = nil;
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
        upQueue = dispatch_queue_create("eventUp", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}


- (void)uploadEventMessageIn:(FMDatabase *)db
{

        NSString *query1 = [NSString stringWithFormat:@"select * from %@ ORDER by id desc LIMIT 0,1",EVENT_TABLE];
        FMResultSet *rs1 = [db executeQuery:query1];
        NSString *event = [[NSString alloc]init];
        int duration = 0;
        long long int occur_unixtime = 0;
        NSString *event_type = [[NSString alloc]init];
        int position = 0;
        
        while ([rs1 next]) {
            
            duration = [rs1 intForColumn:@"duration"];
            occur_unixtime = [rs1 longLongIntForColumn:@"occur_unixtime"];
            event = [rs1 stringForColumn:@"eventData"];
            position = [rs1 intForColumn:@"position"];
            event_type = [rs1 stringForColumn:@"event_type"];
        }
        
        if (occur_unixtime > 0 && [SynECGLibSingleton sharedInstance].record_id.length > 0)
        {
            [db executeUpdate:@"INSERT INTO eventupload (user_id, target_id, record_id, duration, occur_unixtime, event_type,eventData,position) VALUES (?, ?, ?, ?, ?, ?, ?,?);",[SynECGLibSingleton sharedInstance].user_id,[SynECGLibSingleton sharedInstance].target_id,[SynECGLibSingleton sharedInstance].record_id,@(duration),@(occur_unixtime),event_type,event,@(position)];
            [self deleteOldMessageFromDB:db time:(NSInteger)occur_unixtime];
            [self uploadEventMessageToSever];
            
        }
}

- (void)uploadEventMessageToSever
{

    if ([RequestManager isNetworkReachable] == YES && self.updating == NO && [SynECGLibSingleton sharedInstance].loginIn == YES) {
        
        self.updating = YES;
        BlockWeakSelf(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
                //取数量
                NSString *numQuery  = [NSString stringWithFormat:@"select count(*) from %@",EVENT_UPLOAD_TABLE];
                NSUInteger num = [db intForQuery:numQuery];
                
                //查询一条
                NSString *query = [NSString stringWithFormat:@"select * from %@ ORDER by id limit 0,1",EVENT_UPLOAD_TABLE];
                FMResultSet *rs1 = [db executeQuery:query];
                NSString *event = [[NSString alloc]init];
                NSString *target_id = [[NSString alloc]init];
                NSString *user_id = [[NSString alloc]init];
                NSString *record_id = [[NSString alloc]init];
                
                while ([rs1 next]) {
                    
                    event = [rs1 stringForColumn:@"eventData"];
                    user_id = [rs1 stringForColumn:@"user_id"];
                    target_id = [rs1 stringForColumn:@"target_id"];
                    record_id = [rs1 stringForColumn:@"record_id"];
                    
                }
                if (record_id.length > 0 && event.length > 0)
                {
                    
                    if (num > 1) {
                        
                        self->_reupdate = YES;
                    }
                    else
                    {
                        self->_reupdate = NO;
                    }
                    
                    
                    NSDictionary *dictionary = [SynECGUtils dictionaryWithJsonString:event];
                    
                    
                    NSMutableDictionary  * dic = [[NSMutableDictionary alloc]initWithDictionary:dictionary];
                    
                    [dic setObject:user_id forKey:@"user_id"];
                    [dic setObject:target_id forKey:@"target_id"];
                    [dic setObject:record_id forKey:@"record_id"];
                    [dic setObject:@"" forKey:@"geo_info"];
                    [dic setObject:[SynECGUtils uuidString] forKey:@"event_id"];
                    [weakSelf uploadEventMessageToSeverWithModel:dic];
                
                }
                else
                {
                    if (event.length > 0 || user_id.length > 0) {
                     
                        [self deleteNewMessage];
                    }
                    else
                    {
                         weakSelf.updating = NO;
                    }
                }

            }];
        });
        
    }
    else
    {
    }
    
}

- (void)uploadEventMessageToSeverWithModel:(NSMutableDictionary *)model
{
    BlockWeakSelf(self);
    [[RequestManager sharedInstance]postParameters:model Url:EVENT_UPLOAD_URL sucessful:^(id obj) {
    
        weakSelf.upNum = 0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
             [weakSelf deleteNewMessage];
            
        });
        
    } failure:^(id obj) {

        if ([obj[@"result"][@"errorCode"] integerValue] == 1) {
            
            [weakSelf deleteNewMessage];
            
        }
        else if([obj[@"result"][@"errorCode"] integerValue] == 8888 || [obj[@"result"][@"errorCode"] integerValue] == 911)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [weakSelf uploadEventMessageToSeverWithModel:model];
            });
        }
        else if([obj[@"result"][@"errorCode"] integerValue] == 9999 || [obj[@"result"][@"errorCode"] integerValue] == 2 || [obj[@"result"][@"errorCode"] integerValue] == 111)
        {

            weakSelf.updating = NO;
            
        }
        else
        {
            if (weakSelf.upNum <= 3) {
                
                [self uploadEventMessageToSeverWithModel:model];
            }
            else
            {
                [weakSelf deleteNewMessage];
            }
        }
        
        
            
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        
        
        NSTimeInterval tv = [[NSDate date]  timeIntervalSince1970];
        
        long long timesp = (long long)(tv * 1000 - 500);
        
        [params setObject:EVENT_UPLOAD_URL forKey:@"reqUrl"];
        [params setObject:@"eventUpload" forKey:@"reqType"];
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
    BlockWeakSelf(self);
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        
        [weakSelf deleteMessageFromDB:db];
        
    }];
}





- (void)deleteMessageFromDB:(FMDatabase *)db
{
    
    BOOL suceed = [db executeUpdate:@"DELETE FROM eventupload ORDER by id limit 0,1"];
    
    if (suceed) {
     
        self.updating = NO;
        
        if (_reupdate == YES) {
         
             [self uploadEventMessageToSever];
        }
    }
    else
    {

        [self deleteMessageFromDB:db];
    }
}

- (void)deleteOldMessageFromDB:(FMDatabase *)db time:(NSInteger )time
{
    [db executeUpdate:@"DELETE FROM event WHERE occur_unixtime < ?",@(time - 5400000)];
}





@end
