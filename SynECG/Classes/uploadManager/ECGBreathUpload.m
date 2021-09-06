//
//  ECGBreathUpload.m
//  SynECG
//
//  Created by LiangXiaobin on 16/7/4.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import "ECGBreathUpload.h"
#import "SynECGLibSingleton.h"
#import "RequestManager.h"
#import "SynConstant.h"
#import "ECGErrorCodeUpload.h"
#import "SynECGUtils.h"

@interface ECGBreathUpload ()
{
    FMDatabaseQueue *queue;
    dispatch_queue_t breathUpQueue;
}
@end

@implementation ECGBreathUpload

+ (instancetype)sharedInstance
{
    static ECGBreathUpload * sharedInstance = nil;
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
        _upNum = 0;
        queue = [SDBManager defaultDBManager].queue;
        breathUpQueue = dispatch_queue_create("breathUp", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)uploadBreathMessageIn:(FMDatabase *)db
{
    
    if (self.inCreat == YES) {
        self.needCreat = YES;
        
    }
    else
    {
        self.inCreat = YES;
        NSString *numQuery  = [NSString stringWithFormat:@"select count(*) from %@",BREATH_TABLE];
        NSUInteger num = [db intForQuery:numQuery];
        
        
        if (num > 120) {
            
            self.needCreat = YES;
        }
        else if(num < 60 && self.lastMessage == NO)
        {
            self.inCreat = NO;
            return;
        }
        else
        {
            self.needCreat = NO;
        }
        NSString *query1 = [NSString stringWithFormat:@"select * from %@ ORDER by id limit 0,60",BREATH_TABLE];
        FMResultSet *rs1 = [db executeQuery:query1];
        NSMutableArray *indexArray = [[NSMutableArray alloc]init];
        NSMutableArray *valueArray = [[NSMutableArray alloc]init];
        NSMutableArray *timeArray = [[NSMutableArray alloc]init];
        NSString *record_id = [[NSString alloc]init];
        while ([rs1 next]) {
            @autoreleasepool {
                
                record_id = [rs1 stringForColumn:@"record_id"];
                NSInteger index = (NSInteger)[rs1 longLongIntForColumn:@"keyNo"];
                NSString *value = [rs1 stringForColumn:@"value"];
                NSString *time = [rs1 stringForColumn:@"occur_datetime"];
                
                [indexArray addObject:@(index)];
                [valueArray addObject:value];
                [timeArray addObject:time];
            }
        }
        if (valueArray.count > 0 && record_id.length > 0)
        {
            NSString *data =  [valueArray componentsJoinedByString:@","];
            [db executeUpdate:@"INSERT INTO breathupload1 (rsp_value, user_id, target_id, record_id, keyNo, occur_datetime, end_datetime) VALUES (?,?,?,?,?,?,?);",data,[SynECGLibSingleton sharedInstance].user_id,[SynECGLibSingleton sharedInstance].target_id,record_id,indexArray[0],timeArray[0],timeArray.lastObject];
            [self uploadBreathMessageToSever];
            [self deleteOldMessageIn:db];
            
            self.inCreat = NO;
            
        }
            
        
    }
}

- (void)uploadLatBreathIn:(FMDatabase *)db
{
    self.lastMessage = YES;
    
    [self uploadBreathMessageIn:db];
}



- (void)uploadBreathMessageToSever
{
    
    if ([RequestManager isNetworkReachable] == YES && !_uploading && [SynECGLibSingleton sharedInstance].loginIn == YES)
    {
        self.uploading = YES;
        
        BlockWeakSelf(self);
        dispatch_async(dispatch_get_main_queue(), ^{
        
            [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
                //取数量
                NSString *numQuery  = [NSString stringWithFormat:@"select count(*) from %@",BREATH_UPLOAD_TABLE];
                NSUInteger num = [db intForQuery:numQuery];
                //查询一条
                NSString *query = [NSString stringWithFormat:@"select * from %@ ORDER by id limit 0,1",BREATH_UPLOAD_TABLE];
                FMResultSet *rs = [db executeQuery:query];
                NSString *userId = [[NSString alloc]init];
                NSString *targetId = [[NSString alloc]init];
                NSString *recordId = [[NSString alloc]init];
                NSString *value_data = [[NSString alloc]init];
                NSString *time = [[NSString alloc]init];
                NSString *time1 = [[NSString alloc]init];
                while ([rs next]) {
                        userId = [rs stringForColumn:@"user_id"];
                        targetId = [rs stringForColumn:@"target_id"];
                        recordId = [rs stringForColumn:@"record_id"];
                        time = [rs stringForColumn:@"occur_datetime"];
                    time1 = [rs stringForColumn:@"end_datetime"];
                        value_data = [rs stringForColumn:@"rsp_value"];
                }

                if (num > 0) {
                    
                    if (num > 1)
                    {
                        weakSelf.reUpdate = YES;
                    }
                    else
                    {
                        weakSelf.reUpdate = NO;
                    }
                    
                    NSArray *strArray = [value_data componentsSeparatedByString:NSLocalizedString(@",", nil)];
                    NSMutableArray *value = [[NSMutableArray alloc]init];
                    for (int i = 0; i < strArray.count; i++) {
                        [value addObject:@([strArray[i] doubleValue])];
                    }

                    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
                    [dic setObject:userId forKey:@"userId"];
                    [dic setObject:recordId forKey:@"recordId"];
                    [dic setObject:@([self cTimestampFromString:time]) forKey:@"firstDataTime"];
                    [dic setObject:@([self cTimestampFromString:time1]) forKey:@"lastDataTime"];
                    [dic setObject:value forKey:@"arrayValues"];
                    [weakSelf uploadBreathMessageToSeverWithModel:dic];
                }
                else
                {
                      weakSelf.uploading = NO;
                }
            }];
        });

    }
    
}


-(long long)cTimestampFromString:(NSString *)theTime{
    
    
    //装换为时间戳
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    //        NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"Asia/Beijing"];
    //        [formatter setTimeZone:timeZone];
    NSDate* dateTodo = [formatter dateFromString:theTime];
    
    NSTimeInterval tv = [dateTodo  timeIntervalSince1970];
    
    long long timesp = (long long)(tv * 1000);
    
    return timesp;
}





- (void)uploadBreathMessageToSeverWithModel:(NSDictionary *)model
{


    NSLog(@"%@",model);
        BlockWeakSelf(self);

        [[RequestManager sharedInstance]postParameters:model Url:BREATHING_UPLOAD_URL sucessful:^(id obj) {

            weakSelf.upNum = 0;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
               
                [weakSelf deleteNewMessageWithTime:model[@"occur_datetime"]];
            });
            
        } failure:^(id obj) {
            
            
            if ([obj[@"result"][@"errorCode"] integerValue] == 1) {
                
                [weakSelf deleteNewMessageWithTime:model[@"occur_datetime"]];
            }
            else if([obj[@"result"][@"errorCode"] integerValue] == 8888 || [obj[@"result"][@"errorCode"] integerValue] == 911)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    [weakSelf uploadBreathMessageToSeverWithModel:model];
                });
            }
            

            else if([obj[@"result"][@"errorCode"] integerValue] == 9999  || [obj[@"result"][@"errorCode"] integerValue] == 2 || [obj[@"result"][@"errorCode"] integerValue] == 111)
            {
                weakSelf.uploading = NO;
            }
            else
            {
                if (weakSelf.upNum <= 3 ) {
                    
                    [self uploadBreathMessageToSeverWithModel:model];
                }

                else
                {
                    [weakSelf deleteNewMessageWithTime:model[@"occur_datetime"]];
                }
            }
            
            
                
            NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
            
            NSTimeInterval tv = [[NSDate date]  timeIntervalSince1970];
            
            long long timesp = (long long)(tv * 1000 - 500);
            
            [params setObject:BREATHING_UPLOAD_URL forKey:@"reqUrl"];
            [params setObject:@"alarmUpload" forKey:@"reqType"];
            [params setObject:[SynECGUtils convertToJSONData:model] forKey:@"reqParams"];
            [params setObject:@(timesp) forKey:@"createdTime"];
            [params setObject:@(timesp) forKey:@"execTime"];
            [params setObject:obj[@"result"] forKey:@"rtnResult"];
            
            [[ECGErrorCodeUpload sharedInstance]uploadErrorMessageWith:params];
                
          
            weakSelf.upNum ++;

        }];
}


- (void)deleteNewMessageWithTime:(NSString *)time
{
    
    BlockWeakSelf(self);
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    
        [weakSelf deleteNewMessageWithDB:db time:time];
    }];
}

- (void)deleteNewMessageWithDB:(FMDatabase *)db time:(NSString *)time
{
    BOOL succed = [db executeUpdate:@"DELETE FROM breathupload1 ORDER by id limit 0,1"];
    
    if (succed) {
        
        self.uploading = NO;
        if (self.reUpdate == YES) {
            [self uploadBreathMessageToSever];
        }
    }
    else
    {
        [self deleteNewMessageWithDB:db time:time];
    }
}


- (void)deleteOldMessageIn:(FMDatabase *)db
{
  
        NSString *sqlstr = [NSString stringWithFormat:@"DELETE FROM %@ ORDER by id limit 0,60",BREATH_TABLE];
        BOOL succed = [db executeUpdate:sqlstr];
        if (!succed)
        {
            [self deleteOldMessageIn:db];
        }
    else
    {
        if (self.needCreat) {
            
            [self uploadBreathMessageIn:db];
        }
    }
}



@end
