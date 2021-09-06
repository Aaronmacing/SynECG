//
//  SynWaterUploadManager.m
//  SynECG
//
//  Created by LiangXiaobin on 2016/10/5.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import "SynWaterUploadManager.h"
#import "RequestManager.h"
#import "SynConstant.h"
#import "SDBManager.h"
#import "SynECGLibSingleton.h"
#import "ECGErrorCodeUpload.h"
#import "SynECGUtils.h"


@interface SynWaterUploadManager ()
{
    FMDatabaseQueue *queue;
    dispatch_queue_t upQueue;
}
@end

@implementation SynWaterUploadManager
+ (instancetype)sharedInstance
{
    static SynWaterUploadManager * sharedInstance = nil;
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
        queue = [SDBManager defaultDBManager].queue;
        _updating = NO;
        _reUpdate = NO;
        _upNum = 0;
        upQueue = dispatch_queue_create("waterUp", DISPATCH_QUEUE_CONCURRENT);
        
    }
    return self;
}

- (void)uploadWaterWithCategory:(NSString *)category in:(FMDatabase *)db
{

        NSString *query = [NSString stringWithFormat:@"select * from %@ where alert_mark_category = '%@'",WATER_TABLE,category];
        FMResultSet *rs = [db executeQuery:query];
        NSString *alert_mark_id = [[NSString alloc]init];
        NSString *alert_id = [[NSString alloc]init];
        NSString *record_id = [[NSString alloc]init];
        NSInteger alert_mark_level = 0;
        NSInteger seq_no = 0;
        NSInteger duration_msec = 0;
    
        long long alert_unixTime = 0;
    
        NSString *alert_mark_category = [[NSString alloc]init];;
        while ([rs next]) {
            
            alert_mark_id = [rs stringForColumn:@"alert_mark_id"];
            alert_id = [rs stringForColumn:@"alert_id"];
            alert_mark_category = [rs stringForColumn:@"alert_mark_category"];
            alert_mark_level = [rs intForColumn:@"alert_mark_level"];
            seq_no = [rs intForColumn:@"seq_no"];
            duration_msec = [rs intForColumn:@"duration_msec"];
            record_id = [rs stringForColumn:@"record_id"];
            alert_unixTime = [rs longLongIntForColumn:@"occur_unixtime"];
            
        }
        
        if (alert_id.length > 0) {
            
            
            if ([SynECGLibSingleton sharedInstance].record_id.length > 0) {
                
                //WATER_TABLE
                BOOL save = [db executeUpdate:@"INSERT INTO wateruploadnew (user_id, target_id, record_id, alert_mark_id, alert_id, alert_mark_level, seq_no, duration_msec, alert_mark_category,alert_occur_unixtime) VALUES (?,?,?,?,?,?,?,?,?,?);",[SynECGLibSingleton sharedInstance].user_id,[SynECGLibSingleton sharedInstance].target_id,record_id,alert_mark_id,alert_id,@(alert_mark_level),@(seq_no),@(duration_msec),alert_mark_category,@(alert_unixTime)];
                if (save) {
                    //上传
                    [self uploadEnergyMessageToSever];
                }
             

            }
            
            
        }
}


/**
 *  上传至服务器端
 */
- (void)uploadEnergyMessageToSever
{
    if ([RequestManager isNetworkReachable] == YES && self.updating == NO && [SynECGLibSingleton sharedInstance].loginIn == YES)
    {
    
        self.updating = YES;
           BlockWeakSelf(self);
            dispatch_async(dispatch_get_main_queue(), ^{
    
                
                [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                   //取数量
                   NSString *numQuery  = [NSString stringWithFormat:@"select count(*) from %@",WATER_UPLOAD_TABLE];
                   NSUInteger num = [db intForQuery:numQuery];
                   //查询一条
                   NSString *query = [NSString stringWithFormat:@"select * from %@ ORDER by id LIMIT 0,1",WATER_UPLOAD_TABLE];
                   FMResultSet *rs = [db executeQuery:query];
                   
                   NSString *user_id = [[NSString alloc]init];
                   NSString *target_id = [[NSString alloc]init];
                   NSString *record_id = [[NSString alloc]init];
                   NSString *alert_mark_id = [[NSString alloc]init];
                   NSString *alert_id = [[NSString alloc]init];
                   NSInteger alert_mark_level = 0;
                   NSInteger seq_no = 0;
                   NSInteger duration_msec = 0;
                   long long alert_occur_unixtime = 0;
                   NSString *alert_mark_category = [[NSString alloc]init];;
                   
                   while ([rs next]) {
                       
                       user_id= [rs stringForColumn:@"user_id"];
                       target_id = [rs stringForColumn:@"target_id"];
                       record_id = [rs stringForColumn:@"record_id"];
                       alert_mark_id = [rs stringForColumn:@"alert_mark_id"];
                       alert_id = [rs stringForColumn:@"alert_id"];
                       alert_mark_category = [rs stringForColumn:@"alert_mark_category"];
                       alert_mark_level = [rs intForColumn:@"alert_mark_level"];
                       seq_no = [rs intForColumn:@"seq_no"];
                       duration_msec = [rs intForColumn:@"duration_msec"];
                       alert_occur_unixtime = [rs longLongIntForColumn:@"alert_occur_unixtime"];
                   }
                   
                   if (num >  0) {
                       
                       if (num > 1) {
                           weakSelf.reUpdate = YES;
                       }
                       else
                       {
                           weakSelf.reUpdate = NO;
                       }
                       NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
                       [dic setObject:@(alert_mark_level) forKey:@"alert_mark_level"];
                       [dic setObject:user_id forKey:@"user_id"];
                       [dic setObject:target_id forKey:@"target_id"];
                       [dic setObject:record_id forKey:@"record_id"];
                       [dic setObject:alert_mark_id forKey:@"alert_mark_id"];
                       [dic setObject:alert_id forKey:@"alert_id"];
                       [dic setObject:@(seq_no) forKey:@"seq_no"];
                       [dic setObject:@(duration_msec) forKey:@"duration_msec"];
                       [dic setObject:alert_mark_category forKey:@"alert_mark_category"];
                       [dic setObject:@(alert_occur_unixtime) forKey:@"alert_occur_unixtime"];
                       [weakSelf uploadEnergyMessageToSeverWithModel:dic];
                       
                   }
                   else
                   {
                       weakSelf.updating = NO;
                   }

               }];
            });
    }
}

- (void)uploadEnergyMessageToSeverWithModel:(NSDictionary *)model
{
    BlockWeakSelf(self);
    
    [[RequestManager sharedInstance]postParameters:model Url:WATER_UPLOAD_URL sucessful:^(id obj) {

        weakSelf.upNum = 0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

            [weakSelf deleteNewMessageWithId:model[@"alert_id"] num:model[@"seq_no"]];
        });
        
    } failure:^(id obj) {
        
        if ([obj[@"result"][@"errorCode"] integerValue] == 1) {
            
            [weakSelf deleteNewMessageWithId:model[@"alert_id"] num:model[@"seq_no"]];
        }
        else if([obj[@"result"][@"errorCode"] integerValue] == 8888 || [obj[@"result"][@"errorCode"] integerValue] == 911)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [weakSelf uploadEnergyMessageToSeverWithModel:model];
            });
        }
        else if([obj[@"result"][@"errorCode"] integerValue] == 9999 || [obj[@"result"][@"errorCode"] integerValue] == 2 || [obj[@"result"][@"errorCode"] integerValue] == 111)
        {

            weakSelf.updating = NO;
        }
        else
        {
            if (weakSelf.upNum <= 3) {
                [self uploadEnergyMessageToSeverWithModel:model];
            }
            else
            {
                [weakSelf deleteNewMessageWithId:model[@"alert_id"] num:model[@"seq_no"]];
            }
        }
        
        
            
        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
        
        NSTimeInterval tv = [[NSDate date]  timeIntervalSince1970];
        
        long long timesp = (long long)(tv * 1000 - 500);
        
        [params setObject:WATER_UPLOAD_URL forKey:@"reqUrl"];
        [params setObject:@"waterUpload" forKey:@"reqType"];
        [params setObject:[SynECGUtils convertToJSONData:model] forKey:@"reqParams"];
        [params setObject:@(timesp) forKey:@"createdTime"];
        [params setObject:@(timesp) forKey:@"execTime"];
        [params setObject:obj[@"result"] forKey:@"rtnResult"];
        
        
        [[ECGErrorCodeUpload sharedInstance]uploadErrorMessageWith:params];
            

        weakSelf.upNum ++;
    }];

}


/**
 *  根据时间删除上传数据库中的数据
 */

- (void)deleteNewMessageWithId:(NSString *)alertId num:(NSNumber *)seq_no
{
    //WATER_UPLOAD_TABLE
    BlockWeakSelf(self);
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    
        [weakSelf deleteNewMessageWithDB:db Id:alertId num:seq_no];
    }];
    
}

- (void)deleteNewMessageWithDB:(FMDatabase *)db Id:(NSString *)alertId num:(NSNumber *)seq_no
{
    BOOL succeed = [db executeUpdate:@"DELETE FROM wateruploadnew ORDER by id LIMIT 0,1"];
    if (succeed) {
        
        self.updating = NO;
        if (self.reUpdate == YES) {
            [self uploadEnergyMessageToSever];
        }
    }
    else
    {
        [self deleteNewMessageWithDB:db Id:alertId num:seq_no];
    }
}


@end
