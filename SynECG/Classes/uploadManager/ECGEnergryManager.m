//
//  ECGEnergryManager.m
//  SynECG
//
//  Created by LiangXiaobin on 16/7/4.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import "ECGEnergryManager.h"
#import "SynECGLibSingleton.h"
#import "RequestManager.h"
#import "SynConstant.h"
#import "SynECGUtils.h"
#import "ECGErrorCodeUpload.h"
#import "SportDataManager.h"

@interface ECGEnergryManager ()
{
    FMDatabaseQueue *queue;
    dispatch_queue_t upQueue;
}
@end

@implementation ECGEnergryManager
+ (instancetype)sharedInstance
{
    static ECGEnergryManager * sharedInstance = nil;
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
        _updatimg = NO;
        _reUpdate = NO;
        _upNum = 0;
        queue = [SDBManager defaultDBManager].queue;
        upQueue = dispatch_queue_create("upEnergyqueue", DISPATCH_QUEUE_CONCURRENT);
        
    }
    return self;
}

- (void)uploadEnergryMessageIn:(FMDatabase *)db
{
    
            
    NSString *query1 = [NSString stringWithFormat:@"select * from %@",ENERGY_TABLE];
    FMResultSet *rs1 = [db executeQuery:query1];
    
    NSMutableArray *keyNo = [[NSMutableArray alloc]init];
    NSMutableArray *activity_type =  [[NSMutableArray alloc]init];
    NSMutableArray *step =  [[NSMutableArray alloc]init];
    NSMutableArray *kcal =  [[NSMutableArray alloc]init];
    
    while ([rs1 next]) {
        
        [keyNo addObject:@([rs1 longLongIntForColumn:@"keyNo"])];
        [kcal addObject: @([rs1 longLongIntForColumn:@"kcal"])];
        [activity_type addObject: [rs1 stringForColumn:@"activity_type"]];
        [step addObject: @([rs1 longLongIntForColumn:@"step"])];
    }
    [rs1 close];
    if (keyNo.count > 0) {
        
        
        long long occur_datetime = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:[keyNo[0] integerValue] * 1000];
        NSMutableDictionary *dic1 = [[NSMutableDictionary alloc]init];
        NSMutableDictionary *dic2 = [[NSMutableDictionary alloc]init];
        
        [dic1 setObject:[SynECGLibSingleton sharedInstance].user_id forKey:@"userId"];
        [dic1 setObject:[SynECGLibSingleton sharedInstance].record_id forKey:@"recordId"];
        [dic1 setObject:@(occur_datetime) forKey:@"occurTime"];
        [dic1 setObject:activity_type forKey:@"list"];
        
        [dic2 setObject:[SynECGLibSingleton sharedInstance].user_id forKey:@"userId"];
        [dic2 setObject:[SynECGLibSingleton sharedInstance].record_id forKey:@"recordId"];
        [dic2 setObject:@(occur_datetime) forKey:@"occurTime"];
        
        
        NSMutableArray *array = [[NSMutableArray alloc]init];
        
        for (int i = 0; i < step.count; i++) {
            
            NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
            [dic setObject:step[i] forKey:@"step"];
            [dic setObject:kcal[i] forKey:@"cal"];
            
            [array addObject:dic];
            
        }
        [dic2 setObject:array forKey:@"list"];
        
        
        NSString *params1 = [SynECGUtils convertToJSONData:dic1];
        NSString *params2 = [SynECGUtils convertToJSONData:dic2];
        
        
        NSString *sql1 = [NSString stringWithFormat:@"INSERT INTO %@ (user_id, paras, urlstr) VALUES (?, ?, ?);",ENERGY_UPLOAD_TABLE];
        [db executeUpdate:sql1,[SynECGLibSingleton sharedInstance].user_id,params1,SPOTRS_TYPE_UPLOAD_URL];
        [db executeUpdate:sql1,[SynECGLibSingleton sharedInstance].user_id,params2,ENERGY_UPLOAD_URL];
        
        [self deleteOldMessageFrom:db];
        [self uploadEnergyMessageToSever];
        
    }

}

/**
 *  上传至服务器端
 */
- (void)uploadEnergyMessageToSever
{
    if ([RequestManager isNetworkReachable] == YES && !_updatimg && [SynECGLibSingleton sharedInstance].loginIn == YES)
    {
        self.updatimg = YES;
        BlockWeakSelf(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
               
                NSString *numQuery  = [NSString stringWithFormat:@"select count(*) from %@ ",ENERGY_UPLOAD_TABLE];
                NSUInteger num = [db intForQuery:numQuery];
                NSString *query = [NSString stringWithFormat:@"select * from %@ ORDER by id limit 0,1",ENERGY_UPLOAD_TABLE];
                FMResultSet *rs = [db executeQuery:query];
                
                NSString *urlStr = [[NSString alloc]init];
                NSString *params = [[NSString alloc]init];
                
                while ([rs next])
                {
                    urlStr = [rs stringForColumn:@"urlStr"];
                    params = [rs stringForColumn:@"paras"];

                    
                }
                [rs close];
                if (num > 0) {
                    
                    if (num > 1) {
                        weakSelf.reUpdate = YES;
                    }
                    else
                    {
                        weakSelf.reUpdate = NO;
                    }
                    
                    [weakSelf uploadEnergyMessageToSeverWithModel:[SynECGUtils dictionaryWithJsonString:params] url:urlStr];
                }
                else
                {
                    weakSelf.updatimg = NO;
                }
            }];

        });
        
    }

}

- (void)uploadEnergyMessageToSeverWithModel:(NSDictionary *)model url:(NSString *)url
{
   
    NSLog(@"%@",model);
    NSLog(@"%@",url);
    
    
    
        BlockWeakSelf(self);
        [[RequestManager sharedInstance]postParameters:model Url:url  sucessful:^(id obj) {

            NSLog(@"%@",obj);
            
            weakSelf.upNum = 0;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
               
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                   
                    [weakSelf deleteNewMessageWithTime:@""];
                });
            });
            
        } failure:^(id obj) {
            
             NSLog(@"%@",obj);
            if ([obj[@"result"][@"errorCode"] integerValue] == 1) {
                
                [weakSelf deleteNewMessageWithTime:@""];
            }
            else if([obj[@"result"][@"errorCode"] integerValue] == 8888 || [obj[@"result"][@"errorCode"] integerValue] == 911)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    [weakSelf uploadEnergyMessageToSeverWithModel:model url:url];
                });
            }
            else if([obj[@"result"][@"errorCode"] integerValue] == 9999 || [obj[@"result"][@"errorCode"] integerValue] == 2 || [obj[@"result"][@"errorCode"] integerValue] == 111)
            {
                    weakSelf.updatimg = NO;
            }
            else
            {
                if (weakSelf.upNum <= 3) {
                    [weakSelf uploadEnergyMessageToSeverWithModel:model url:url];
                }
                else
                {
                    [weakSelf deleteNewMessageWithTime:@""];
                }
            }

            NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
            
            
            NSTimeInterval tv = [[NSDate date]  timeIntervalSince1970];
            
            long long timesp = (long long)(tv * 1000 - 500);
            
            [params setObject:url forKey:@"reqUrl"];
            [params setObject:@"energyUpload" forKey:@"reqType"];
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

- (void)deleteNewMessageWithTime:(NSString *)time
{
        //ENERGY_UPLOAD_TABLE

    BlockWeakSelf(self);
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
       
        [weakSelf deleteNewMessageWithDB:db Time:time];

    }];
}

- (void)deleteNewMessageWithDB:(FMDatabase *)db Time:(NSString *)time
{
    BOOL succeed = [db executeUpdate:@"DELETE FROM energyupload ORDER by id limit 0,1"];
    
    if (succeed) {
        self.updatimg = NO;
        if (self.reUpdate == YES) {
            [self uploadEnergyMessageToSever];
        }
    }
    else
    {
        [self deleteNewMessageWithDB:db Time:time];
    }
}

- (void)deleteOldMessageFrom:(FMDatabase *)db
{
    NSString *sql1 = [NSString stringWithFormat:@"DELETE FROM %@",ENERGY_TABLE];
    [db executeUpdate:sql1];
    
}


@end
