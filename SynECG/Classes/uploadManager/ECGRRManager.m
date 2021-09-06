//
//  ECGRRManager.m
//  SynECG
//
//  Created by LiangXiaobin on 16/7/4.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import "ECGRRManager.h"
#import "SynECGLibSingleton.h"
#import "RequestManager.h"
#import "SynConstant.h"
#import "SynECGUtils.h"
#import "ECGErrorCodeUpload.h"


@interface ECGRRManager ()
{
    FMDatabaseQueue *queue;
    dispatch_queue_t upQueue;
}
@end

@implementation ECGRRManager

+ (instancetype)sharedInstance
{
    static ECGRRManager * sharedInstance = nil;
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
        _uploading = NO;
        _reUpdate = NO;
        queue = [SDBManager defaultDBManager].queue;
        upQueue = dispatch_queue_create("annUpqueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}


- (void)uploadRRMessageIn:(FMDatabase *)db
{
    
              
       if ([SynECGLibSingleton sharedInstance].rrUpload_Index == 0) {
           NSString *query = [NSString stringWithFormat:@"select * from %@",TOTAL_TABLE];
           FMResultSet *rs = [db executeQuery:query];
           NSInteger rrUpload = 0;
           while ([rs next]) {
               rrUpload = (NSInteger)[rs longLongIntForColumn:@"rrUpload"];
           }
           [SynECGLibSingleton sharedInstance].rrUpload_Index = rrUpload;
       }

        NSInteger stat = 0;
        if ([SynECGLibSingleton sharedInstance].rrUpload_Index == 0) {
            
            stat = -1;
        }
        else
        {
            stat = [SynECGLibSingleton sharedInstance].rrUpload_Index;
        }


        NSString *query1 = [NSString stringWithFormat:@"select * from %@ where keyNo > %@",RR_TABLE,@(stat)];
       FMResultSet *rs1 = [db executeQuery:query1];
       NSMutableArray *indexArray = [[NSMutableArray alloc]init];
//           NSMutableArray *positionArray = [[NSMutableArray alloc]init];
       NSMutableArray *rrArray = [[NSMutableArray alloc]init];
       NSString *record_id = [[NSString alloc]init];
       while ([rs1 next]) {
           @autoreleasepool {
               
               if(rrArray.count <= 1000)
               {
                   record_id = [rs1 stringForColumn:@"record_id"];
                   
                   [indexArray addObject:@([rs1 longLongIntForColumn:@"keyNo"])];
//                       [positionArray addObject:@([rs1 longLongIntForColumn:@"position"])];
                   
                   NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
                   [dic setObject:[rs1 stringForColumn:@"ann" ] forKey:@"ann"];
                   [dic setObject:@([rs1 intForColumn:@"data" ]) forKey:@"pos"];
                   [dic setObject:[rs1 stringForColumn:@"extra" ] forKey:@"ext"];
                   [dic setObject:@([rs1 intForColumn:@"amp"]) forKey:@"amp"];
                   
                   [rrArray addObject:dic];
               }
               
           }
       }
       if (rrArray.count > 0 && [SynECGLibSingleton sharedInstance].record_id.length > 0) {
        
           
          BOOL succeed = [db executeUpdate:@"INSERT INTO rrupload (user_id, target_id, record_id, keyNo, occur_datetime, rrpeak_values, bpmVo) VALUES (?, ?, ?, ?, ?, ?, ?);",[SynECGLibSingleton sharedInstance].user_id,[SynECGLibSingleton sharedInstance].target_id,record_id,indexArray[0],[SynECGUtils setOccerTimeFromPastSeconds: [[rrArray.lastObject objectForKey:@"data"] integerValue] / 1000],[NSKeyedArchiver archivedDataWithRootObject:rrArray],[NSJSONSerialization dataWithJSONObject:[SynECGLibSingleton sharedInstance].heartRateMessage options:NSJSONWritingPrettyPrinted error:nil]];
           
           if (succeed) {
            
               NSString *updateSql = [NSString stringWithFormat:
                                      @"UPDATE %@ SET rrUpload = '%@' WHERE recordId = '%@'",TOTAL_TABLE,indexArray.lastObject,[SynECGLibSingleton sharedInstance].record_id];
               [db executeUpdate:updateSql];
               
               
               
               [SynECGLibSingleton sharedInstance].rrUpload_Index = [indexArray.lastObject integerValue];
               
               [self uploadRRMessageToSever];
//                   [self deleteOldMessageFrom:db num:[SynECGLibSingleton sharedInstance].rrUpload_Index];
           }
       }

}

- (void)uploadRRMessageToSever
{
    
    if ([RequestManager isNetworkReachable] == YES && !_uploading && [SynECGLibSingleton sharedInstance].loginIn == YES)
    {
        self.uploading = YES;
        BlockWeakSelf(self);
        dispatch_async(dispatch_get_main_queue(), ^{
        
            [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
               
                //取数量
                NSString *numQuery  = [NSString stringWithFormat:@"select count(*) from %@",RR_UPLOAD_TABLE];
                NSUInteger num = [db intForQuery:numQuery];
                //查询一条
                NSString *query = [NSString stringWithFormat:@"select * from %@ ORDER by id limit 0,1",RR_UPLOAD_TABLE];
                FMResultSet *rs = [db executeQuery:query];
                NSMutableArray *messageArray = [[NSMutableArray alloc]init];
                
                while ([rs next]) {
                    @autoreleasepool {
                        NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
                        [dic setObject:@([rs longLongIntForColumn:@"keyNo"]) forKey:@"idx"];
                        [dic setObject:[rs stringForColumn:@"user_id"] forKey:@"userId"];
                        [dic setObject:[rs stringForColumn:@"target_id"] forKey:@"targetId"];
                        [dic setObject:[rs stringForColumn:@"record_id"] forKey:@"recordId"];
                        [dic setObject:[rs stringForColumn:@"occur_datetime"] forKey:@"time"];
                        [dic setObject:[NSKeyedUnarchiver unarchiveObjectWithData:[rs dataForColumn:@"rrpeak_values"]] forKey:@"anns"];
                        [messageArray addObject:dic];
                    }
                }
                if (messageArray.count > 0) {
                    if (num > 1) {
                        weakSelf.reUpdate = YES;
                    }
                    else
                    {
                        weakSelf.reUpdate = NO;
                    }
                    
                    NSMutableDictionary *dic = messageArray[0];
                    NSArray * atp = [((NSArray *)dic[@"anns"])[0] allKeys];
                    if ([atp containsObject:@"data"] ) {
                        
                        [self deleteNewMessage];
                    }
                    else
                    {
                        [weakSelf uploadRRMessageToSeverwithModel:dic];
                    }
                }
                else
                {
                    weakSelf.uploading = NO;
                }
            }];
        });
    
    }
    
}

- (void)uploadRRMessageToSeverwithModel:(NSDictionary *)model
{
        BlockWeakSelf(self);
    
        [[RequestManager sharedInstance]postParameters:model Url:RRPEAK_UPLOAD_URL sucessful:^(id obj) {
            
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
                    
                    [weakSelf uploadRRMessageToSeverwithModel:model];
                });
            }
            else if([obj[@"result"][@"errorCode"] integerValue] == 9999 || [obj[@"result"][@"errorCode"] integerValue] == 2 || [obj[@"result"][@"errorCode"] integerValue] == 111)
            {

                weakSelf.uploading = NO;
                
            }
            else
            {
                if (weakSelf.upNum <= 3) {
                    
                    [self uploadRRMessageToSeverwithModel:model];
                }
                
                else
                {
                    [weakSelf deleteNewMessage];
                }
            }
   
                
            NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
            
            NSTimeInterval tv = [[NSDate date]  timeIntervalSince1970];
            
            long long timesp = (long long)(tv * 1000 - 500);
            
            [params setObject:RRPEAK_UPLOAD_URL forKey:@"reqUrl"];
            [params setObject:@"annUpload" forKey:@"reqType"];
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
        [weakSelf deleteNewMessageFrom:db];

    }];
}

- (void)deleteNewMessageFrom:(FMDatabase *)db
{
    BOOL succed = [db executeUpdate:@"DELETE FROM rrupload ORDER by id limit 0,1"];
    if (succed)
    {
        self.uploading = NO;
        if (self.reUpdate == YES) {
            [self uploadRRMessageToSever];
        }
    }
    else
    {
        [self deleteNewMessageFrom:db];
    }

}

- (void)deleteRRMessageFrom:(FMDatabase *)db num:(NSInteger )position
{
    [db executeUpdate:@"DELETE FROM rr_b1 WHERE position < ?",@(position - 1000000)];

}


- (void)deleteOldMessageFrom:(FMDatabase *)db num:(NSInteger )num
{
    [db executeUpdate:@"DELETE FROM rr_b1 WHERE keyNo < ?",@(num - 10000)];
}





@end
