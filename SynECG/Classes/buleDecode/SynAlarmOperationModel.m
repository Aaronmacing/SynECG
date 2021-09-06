//
//  SynAlarmOperationModel.m
//  SynECG
//
//  Created by LiangXiaobin on 2016/9/29.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import "SynAlarmOperationModel.h"
#import "SynECGLibSingleton.h"
#import "SynECGUtils.h"
#import "SynAlarmUploadManager.h"
#import "SynWaterUploadManager.h"
#import "SynConstant.h"
#import "NSString+EnumSynEcg.h"
#import "ECGHRManager.h"

@interface SynAlarmOperationModel()
{
    FMDatabaseQueue *queue;
    dispatch_queue_t alertQueue1;
    dispatch_queue_t alertQueue2;
    dispatch_queue_t alertQueue3;
}
@end



@implementation SynAlarmOperationModel
+ (instancetype)sharedInstance
{
    static SynAlarmOperationModel * sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SynAlarmOperationModel alloc] init];
    });
    return sharedInstance;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationDidEnterBackgroundNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationDidEnterBackgroundNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CloseBlueth" object:nil];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _startTime = 0;
        _beatType = 0;
        _starA = 0;
        _starV = 0;
        queue = [SDBManager defaultDBManager].queue;
        alertQueue1 = dispatch_queue_create("getAlert1", DISPATCH_QUEUE_SERIAL);
        alertQueue2 = dispatch_queue_create("getAlert2", DISPATCH_QUEUE_SERIAL);
        alertQueue3 = dispatch_queue_create("getAlert3", DISPATCH_QUEUE_SERIAL);
        _SVEB0 = NO;
        _SVEB1 = NO;
        _VEB0 = NO;
        _VEB1 = NO;
        _VEB2 = NO;
        _VEB3 = NO;
        _needMore = NO;
        _hourAArray = [[NSMutableArray alloc]init];
        _hourVArray = [[NSMutableArray alloc]init];
        _minuteAArray = [[NSMutableArray alloc]init];
        _minuteVArray = [[NSMutableArray alloc]init];
        _interval_time = 90;
        _unsinusType = [[NSString alloc]init];
        _unsinusArray = [[NSMutableArray alloc]init];
        _sinusArray = [[NSMutableArray alloc]init];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:@"UIApplicationDidEnterBackgroundNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(comeHome:) name:@"UIApplicationDidEnterBackgroundNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeBlooth) name:@"CloseBlueth" object:nil];
    }
    return self;
}

//事件判断
- (void)eventWithType:(NSInteger)type duration:(float )duration withPosition:(NSInteger)position rr:(NSInteger)rr 
{
    
    dispatch_async(alertQueue1, ^{
       
        [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
           
            long long timeSep = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:[self tpFromPostion:position]];
            switch (type) {
                case 0:
                    break;
                case 1:
                    break;
                case 2:
                    break;
                case 3:
                    break;
                case 4:
                    break;
                case 5:
                    break;
                case 6:
                    break;
                case 7:
                    break;
                case 8:
                    break;
                case 9:
                    break;
                case 10:
                    break;
                case 11:
                    break;
                case 12:
                    break;
                case 13:
                    break;
                case 14:
                    break;
                case 15:
                    break;
                case 16:
                    break;
                case 17:
                {
                    //成对室早 （1）
                    
                    
                    [self saveAlarmWithTime:timeSep type:@"AL_PVEB" category:@"CAT_VEB" level:1 flag:2 duration:duration in:db];
                    
                    
                }
                    break;
                case 18:
                    break;
                case 19:
                    break;
                case 20:
                    break;
                case 21:
                    break;
                case 22:
                    break;
                case 23:
                    break;
                case 24:
                    break;
                case 25:
                    break;
                case 26:
                    break;
                case 27:
                    break;
                case 28:
                    break;
                case 29:
                    break;
                case 30:
                    break;
                case 31:
                    break;
                case 32:
                    break;
                case 33:
                    break;
                case 34:
                    break;
                case 35:
                    //ST段抬高
                {
                    
                    [self saveAlarmWithTime:timeSep type:@"AL_ST_ELEV" category:@"CAT_ST_ELEV" level:2 flag:0 duration:duration in:db];
                    
                    
                    
                }
                    break;
                case 36:
                {
                    //ST压低
                    
                    
                    [self saveAlarmWithTime:timeSep type:@"AL_ST_DEPR" category:@"CAT_ST_DEP" level:1 flag:0 duration:duration in:db];
                    
                    
                }
                    break;
                case 37:
                    break;
                case 38:
                    break;
                case 39:
                {
                    //ST段抬高
                    
                    
                    [self saveAlarmWithTime:timeSep type:@"AL_ST_ELEV" category:@"CAT_ST_ELEV" level:2 flag:1 duration:duration in:db];
                    
                    
                }
                    break;
                case 40:
                {
                    //ST 压低
                    
                    [self saveAlarmWithTime:timeSep type:@"AL_ST_DEPR" category:@"CAT_ST_DEP" level:1 flag:1 duration:duration in:db];
                    
                }
                    break;
                case 41:
                {
                    
                }
                    break;
                case 42:
                {
                    
                    [self saveAlarmWithTime:timeSep type:@"AL_PAUSE_L3" category:@"CAT_PAUSE" level:3 flag:0 duration:duration in:db];
                    
                }
                    break;
                case 43:
                {
                    
                    [self saveAlarmWithTime:timeSep type:@"AL_PAUSE_L3" category:@"CAT_PAUSE" level:3 flag:1 duration:duration in:db];
                    
                }
                    break;
                case 44:
                    break;
                case 45:
                    break;
                case 46:
                {
                    
                    [self saveAlarmWithTime:timeSep type:@"AL_PAUSE_L2" category:@"CAT_PAUSE" level:2 flag:2 duration:duration in:db];
                    
                }
                    break;
                default:
                    break;
            }

        }];
    });
}


- (void)closeAllAlert
{
    dispatch_async(alertQueue1, ^{
        [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
            
            
            self.SVEB0 = NO;
            self.SVEB1 = NO;
            self.VEB0 = NO;
            self.VEB1 = NO;
            self.VEB2 = NO;
            self.VEB3 = NO;
            self.beatType = 0;
            self.starA = 0;
            self.starV = 0;
            
            NSString *query = [NSString stringWithFormat:@"Select * From %@ where alarm_flag = '%@' order by id Desc limit 0,8", ALARM_TABLE,@(0)];
            FMResultSet *rs = [db executeQuery:query];
            
            NSMutableArray *array = [[NSMutableArray alloc]init];
            
            while ([rs next])
            {
                NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
                [dic setObject:[rs stringForColumn:@"user_id"] forKey:@"user_id"];
                [dic setObject:[rs stringForColumn:@"target_id"] forKey:@"target_id"];
                [dic setObject:[rs stringForColumn:@"record_id"] forKey:@"record_id"];
                [dic setObject:[rs stringForColumn:@"alarm_id"] forKey:@"alert_id"];
                [dic setObject:[rs stringForColumn:@"start_alarm_id"] forKey:@"start_alert_id"];
                [dic setObject:[rs stringForColumn:@"alert_type"] forKey:@"alert_type"];
                [dic setObject:[rs stringForColumn:@"alert_category"] forKey:@"alert_category"];
                [dic setObject:@([rs intForColumn:@"alarm_flag"]) forKey:@"alert_flag"];
                [dic setObject:@([rs longLongIntForColumn:@"occur_unixtime"]) forKey:@"occur_unixtime"];
                [dic setObject:@([rs intForColumn:@"alarm_level"]) forKey:@"alert_level"];
                
                [array addObject:dic];
                
            }
//            NSInteger past = [self queryTable:TOTAL_TABLE Column:@"ecg" inDB:db];
            [self.sinusArray addObjectsFromArray:self.unsinusArray];
            NSInteger model = [self.sinusArray.lastObject integerValue];
            
            
            
            long long recordTime = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:[self tpFromPostion:model]];
            for (int i = 0; i < array.count; i++) {
                NSDictionary *dic = array[i];
                
                [self savePrematureBeatAlarmWithTime:recordTime type:dic[@"alert_type"] category:dic[@"alert_category"] level:[dic[@"alert_level"] integerValue] flag:1 duration:0 in:db];;
            }
            
            [self.sinusArray removeAllObjects];
            [self.unsinusArray removeAllObjects];
            self.unsinusType = @"";
            
        }];
    });
}



//从时间戳查询
//总共就查一次
- (void)retrieveBatabaseSelectForFastOrSlowAlertFromTime:(NSInteger)timesep
{
    BlockWeakSelf(self);
    dispatch_async(alertQueue1, ^{
        
        [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            //前推两个
            NSString *query = [NSString stringWithFormat:@"select * from %@ where data >= '%@' and data <= '%@'",RR_TABLE,@(timesep - 15 * 1000),@(timesep)];
            FMResultSet *rs = [db executeQuery:query];
            
            NSMutableArray *annArray = [[NSMutableArray alloc]init];
            NSMutableArray *dataArray = [[NSMutableArray alloc]init];
            NSMutableArray *positionArray = [[NSMutableArray alloc]init];
            
            while ([rs next])
            {
                
                [dataArray addObject:[NSString stringWithFormat:@"%d",[rs intForColumn:@"data"]]];
                [annArray addObject:[rs stringForColumn:@"ann"]];
                [positionArray addObject:[NSString stringWithFormat:@"%d",[rs intForColumn:@"position"]]];
            }
            NSString *string = [annArray componentsJoinedByString:@","];
            
            
            if ([string containsString:@"A,A,A"]||[string containsString:@"V,V,V"])
            {
                
                NSInteger aNum = 0;
                NSInteger vNUm = 0;
                NSInteger startPosition = 0;
                NSString *nowType = [[NSString alloc]init];
                NSMutableArray *statusArray = [[NSMutableArray alloc]init];
                
                for (int i = 0; i < annArray.count; i++)
                {
                    if ([nowType isEqualToString:annArray[i]]) {
                        
                        if ([nowType isEqualToString:@"A"]) {
                            
                            aNum = aNum + 1;
                        }
                        else if ([nowType isEqualToString:@"V"]) {
                            
                            vNUm = vNUm + 1;
                        }
                        else
                        {
                        }
                    }
                    else
                    {
                        if (aNum >= 3 || vNUm >= 3) {
                            
                            if (aNum >= 3) {
                                [statusArray addObject:@[nowType,@(startPosition),@(aNum)]];
                            }
                            else
                            {
                                [statusArray addObject:@[nowType,@(startPosition),@(vNUm)]];
                            }
                            
                        }
                        
                        nowType = annArray[i];
                        if ([nowType isEqualToString:@"A"]) {
                            
                            startPosition = i;
                            aNum = 1;
                            vNUm = 0;
                        }
                        else if ([nowType isEqualToString:@"V"]) {
                            startPosition = i;
                            aNum = 0;
                            vNUm = 1;
                        }
                        else
                        {
                            nowType = @"";
                            aNum = 0;
                            vNUm = 0;
                        }
                        
                    }
                    
                }
                
                if (statusArray.count > 0)
                {
                    
                    NSInteger num = 0;
                    
                    for (int i = 0; i < statusArray.count; i++)
                    {
                        
                        NSArray *array = statusArray[i];
                        NSInteger start = [array[1] integerValue];
                        NSInteger length = [array[2] integerValue];
                        //算心率
                        NSInteger model0 = [positionArray[start] integerValue];
//                        if (start > 0) {

//                            model0 = [positionArray[start] integerValue];
                            length = length - 1;
//                        }
                        
                        NSInteger model1 = [positionArray[start + length] integerValue];
                        
                        NSInteger a = 60 * length * 256;
                        NSInteger b = (model1 - model0);
                        
                        NSInteger avg = a / b;
                        
                        if ([array[0] isEqualToString:@"A"])
                        {
                            
                            if (avg > 100) {
                                
                                num = num + 1;
                                
                             
                                if (avg >= 160) {
                                    
                                    //开始
                                    NSString *uuid1 = [SynECGUtils uuidString];
                                    NSString *uuid2 = [SynECGUtils uuidString];
                                    long long timeSep1 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:(model0 / 256)  * 1000];
                                    long long timeSep2 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:(model1 / 256)  * 1000];
                                    [weakSelf saveAlertWithAlarmId:uuid1 start_alarm_id:uuid1 occur_unixtime:timeSep1 alert_type:@"AL_SVT_L2" alert_category:@"CAT_SVT" alarm_level:2 alarm_flag:0 in:db];
                                    //修改水位线
                                    [weakSelf saveWaterWithAlertId:uuid1 occur_unixtime:timeSep1 update_unixtime:timeSep1 category:@"CAT_SVT" level:2 duration:0 type:@"AL_SVT_L2" flag:0 in:db];
                                    
                                    
                                    //结束
                                    [[SynAlarmUploadManager sharedInstance] saveAlertWithAlarmId:uuid2 start_alarm_id:uuid1 occur_unixtime:timeSep2 alert_type:@"AL_SVT_L2" alert_category:@"CAT_SVT" alarm_level:2 alarm_flag:1 in:db];
                                    
                                    //修改水位线
                                    [weakSelf saveWaterWithAlertId:uuid1 occur_unixtime:timeSep2 update_unixtime:timeSep2 category:@"CAT_SVT" level:2 duration:timeSep2 - timeSep1 type:@"AL_SVT_L2" flag:1 in:db];
                                    
                                }
                                else
                                {
                                    NSString *uuid1 = [SynECGUtils uuidString];
                                    NSString *uuid2 = [SynECGUtils uuidString];
                                    long long timeSep1 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:(model0 / 256)  * 1000];
                                    long long timeSep2 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:(model1 / 256)  * 1000];
                                    
                                    [weakSelf saveAlertWithAlarmId:uuid1 start_alarm_id:uuid1 occur_unixtime:timeSep1 alert_type:@"AL_SVT_L1" alert_category:@"CAT_SVT" alarm_level:1 alarm_flag:0 in:db];
                                    
                                    //修改水位线
                                    [weakSelf saveWaterWithAlertId:uuid1 occur_unixtime:timeSep1 update_unixtime:timeSep1 category:@"CAT_SVT" level:1 duration:0 type:@"AL_SVT_L1" flag:0  in:db];
                                    
                                    
                                    [[SynAlarmUploadManager sharedInstance] saveAlertWithAlarmId:uuid2 start_alarm_id:uuid1 occur_unixtime:timeSep2 alert_type:@"AL_SVT_L1" alert_category:@"CAT_SVT" alarm_level:1 alarm_flag:1 in:db];
                                    
                                    //修改水位线
                                    [weakSelf saveWaterWithAlertId:uuid1 occur_unixtime:timeSep2 update_unixtime:timeSep2 category:@"CAT_SVT" level:1 duration:timeSep2 - timeSep1 type:@"AL_SVT_L1" flag:1 in:db];
                                    
                                }
                                
                                
                            }
                        }
                        else
                        {
                            NSString *uuid1 = [SynECGUtils uuidString];
                            NSString *uuid2 = [SynECGUtils uuidString];
                            long long timeSep1 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:(model0 / 256)  * 1000];
                            long long timeSep2 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:(model1 / 256)  * 1000];
                            if(avg >= 180)
                            {
                                num = num + 1;
                                //开始
                                [weakSelf saveAlertWithAlarmId:uuid1 start_alarm_id:uuid1 occur_unixtime:timeSep1 alert_type:@"AL_VT_PARO" alert_category:@"CAT_VT" alarm_level:3 alarm_flag:0 in:db];
                                //修改水位线
                                [weakSelf saveWaterWithAlertId:uuid1 occur_unixtime:timeSep1 update_unixtime:timeSep1 category:@"CAT_VT" level:3 duration:0 type:@"AL_VT_PARO" flag:0 in:db];
                                
                                
                                //结束
                                [[SynAlarmUploadManager sharedInstance] saveAlertWithAlarmId:uuid2 start_alarm_id:uuid1 occur_unixtime:timeSep2 alert_type:@"AL_VT_PARO" alert_category:@"CAT_VT" alarm_level:3 alarm_flag:1 in:db];
                                
                                //修改水位线
                                [weakSelf saveWaterWithAlertId:uuid1 occur_unixtime:timeSep2 update_unixtime:timeSep2 category:@"CAT_VT" level:3 duration:timeSep2 - timeSep1 type:@"AL_VT_PARO" flag:1 in:db];
                                
                                
                                
                            }
                            else if(avg >= 160)
                            {
                                num = num + 1;
                                //开始
                                [weakSelf saveAlertWithAlarmId:uuid1 start_alarm_id:uuid1 occur_unixtime:timeSep1 alert_type:@"AL_VT" alert_category:@"CAT_VT" alarm_level:2 alarm_flag:0 in:db];
                                //修改水位线
                                [weakSelf saveWaterWithAlertId:uuid1 occur_unixtime:timeSep1 update_unixtime:timeSep1 category:@"CAT_VT" level:2 duration:0 type:@"AL_VT" flag:0 in:db];
                                
                                
                                //结束
                                [[SynAlarmUploadManager sharedInstance] saveAlertWithAlarmId:uuid2 start_alarm_id:uuid1 occur_unixtime:timeSep2 alert_type:@"AL_VT" alert_category:@"CAT_VT" alarm_level:2 alarm_flag:1 in:db];
                                
                                //修改水位线
                                [weakSelf saveWaterWithAlertId:uuid1 occur_unixtime:timeSep2 update_unixtime:timeSep2 category:@"CAT_VT" level:2 duration:timeSep2 - timeSep1 type:@"AL_VT" flag:1 in:db];
                                
                                
                            }
                            else
                            {
                                
                            }
                            
                            [weakSelf savePrematureBeatAlarmWithTime:timeSep1 type:@"AL_RVEB" category:@"CAT_VEB" level:2 flag:0 duration:0 in:db];
                            
                            
                            [weakSelf savePrematureBeatAlarmWithTime:timeSep2 type:@"AL_RVEB" category:@"CAT_VEB" level:2 flag:1 duration:timeSep2 - timeSep1 in:db];
                            
                        }
                    }
                    
                    
                    if (num > 0)
                    {
                        
                        
                        long long tmp = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:timesep];
                        if(weakSelf.beatType == 0)
                        {
                            
                        }
                        else if(weakSelf.beatType == 1)
                        {
                            
                            [weakSelf savePrematureBeatAlarmWithTime:tmp - 15000 type:@"AL_STACH_L2" category:@"CAT_STACH" level:2 flag:1 duration:0 in:db];
                            
                        }
                        else if(weakSelf.beatType == 2)
                        {
                            
                            [weakSelf savePrematureBeatAlarmWithTime:tmp - 15000 type:@"AL_STACH_L0" category:@"CAT_STACH" level:0 flag:1 duration:0 in:db];
                            
                        }
                        else if(weakSelf.beatType == 3)
                        {
                            [weakSelf savePrematureBeatAlarmWithTime:tmp - 15000 type:@"AL_SBRAD_L0" category:@"CAT_SBRAD" level:0 flag:1 duration:0 in:db];
                        }
                        else if(weakSelf.beatType == 4)
                        {
                            [weakSelf savePrematureBeatAlarmWithTime:tmp - 15000 type:@"AL_SBRAD_L1" category:@"CAT_SBRAD" level:1 flag:1 duration:0 in:db];
                        }
                        else if(weakSelf.beatType == 5)
                        {
                            [weakSelf savePrematureBeatAlarmWithTime:tmp - 15000 type:@"AL_SBRAD_L2" category:@"CAT_SBRAD" level:2 flag:1 duration:0 in:db];
                        }
                        else
                        {
                            
                        }
                        weakSelf.beatType = 0;
                        
                    }
                    else
                    {
                        [weakSelf retrieveBatabaseSelectSinusAlertFromTime:timesep withDB:db];
                    }
                    
                    
                    NSArray *last = statusArray.lastObject;
                    if([last[1] integerValue] + [last[2] integerValue] >= positionArray.count - 1)
                    {
                        weakSelf.needMore = NO;
                    }
                    else
                    {
                        weakSelf.needMore = YES;
                    }
                    
                }
                else
                {
                    
                    [weakSelf retrieveBatabaseSelectSinusAlertFromTime:timesep withDB:db];
                    
                }
            }
            else
            {
                [weakSelf retrieveBatabaseSelectSinusAlertFromTime:timesep withDB:db];
            }

            
            
        }];
        
    });
}


- (void)retrieveBatabaseSelectSinusAlertFromTime:(NSInteger)timesep withDB:(FMDatabase *)db
{
    NSString *query = [NSString stringWithFormat:@"select * from %@ where data >= '%@' and data <= '%@'",RR_TABLE,@(timesep - 60 * 1000),@(timesep)];
    FMResultSet *rs = [db executeQuery:query];
    
    NSMutableArray *positionArray = [[NSMutableArray alloc]init];
    
    while ([rs next])
    {
        [positionArray addObject:[NSString stringWithFormat:@"%d",[rs intForColumn:@"position"]]];
    }
    
    //算心率
    NSInteger model0 = [positionArray.firstObject integerValue];
    NSInteger model1 = [positionArray.lastObject integerValue];
    
    NSInteger a = 60 * (positionArray.count - 1) * 256;
    NSInteger b = (model1 - model0);
    
    NSInteger avg = a / b;
    long long timeSep2 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:(model1 / 256)  * 1000];
    
    if (avg >= 160)
    {

        if (_beatType == 1) {
            
            //更新
            [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_STACH_L2" category:@"CAT_STACH" level:2 flag:0 duration:0 in:db];
            
            
        }
        else
        {
            if (_beatType == 0) {

                //开始
                [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_STACH_L2" category:@"CAT_STACH" level:2 flag:0 duration:0 in:db];
            }
            else
            {
                //结束
                if(_beatType == 2)
                {
                    
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_STACH_L0" category:@"CAT_STACH" level:0 flag:1 duration:0 in:db];
                    
                }
                else if(_beatType == 3)
                {
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L0" category:@"CAT_SBRAD" level:0 flag:1 duration:0 in:db];
                }
                else if(_beatType == 4)
                {
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L1" category:@"CAT_SBRAD" level:1 flag:1 duration:0 in:db];
                }
                else if(_beatType == 5)
                {
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L2" category:@"CAT_SBRAD" level:2 flag:1 duration:0 in:db];
                }
                else
                {
                    
                }
                
                //开始
                [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_STACH_L2" category:@"CAT_STACH" level:2 flag:0 duration:0 in:db];
                
            }
        }
        
        _beatType = 1;
    }
    else if(avg >= 100)
    {
        
        if (_beatType == 2) {
            
            //更新
            [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_STACH_L0" category:@"CAT_STACH" level:0 flag:0 duration:0 in:db];
            
            
        }
        else
        {
            if (_beatType == 0)
            {
                
                //开始
                 [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_STACH_L0" category:@"CAT_STACH" level:0 flag:0 duration:0 in:db];
            }
            else
            {
                //结束
                if(_beatType == 1)
                {
                    
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_STACH_L2" category:@"CAT_STACH" level:2 flag:1 duration:0 in:db];
                    
                }
                else if(_beatType == 3)
                {
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L0" category:@"CAT_SBRAD" level:0 flag:1 duration:0 in:db];
                }
                else if(_beatType == 4)
                {
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L1" category:@"CAT_SBRAD" level:1 flag:1 duration:0 in:db];
                }
                else if(_beatType == 5)
                {
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L2" category:@"CAT_SBRAD" level:2 flag:1 duration:0 in:db];
                }
                else
                {
                    
                }

                //开始
                [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_STACH_L0" category:@"CAT_STACH" level:0 flag:0 duration:0 in:db];
                
            }
        }
        
        _beatType = 2;
        
    }
    else if(avg >= 60)
    {
        //结束
        if(_beatType == 0)
        {
            
        }
        else if(_beatType == 1)
        {
            
            [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_STACH_L2" category:@"CAT_STACH" level:2 flag:1 duration:0 in:db];
            
        }
        else if(_beatType == 2)
        {
            
            [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_STACH_L0" category:@"CAT_STACH" level:0 flag:1 duration:0 in:db];
            
        }
        else if(_beatType == 3)
        {
            [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L0" category:@"CAT_SBRAD" level:0 flag:1 duration:0 in:db];
        }
        else if(_beatType == 4)
        {
            [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L1" category:@"CAT_SBRAD" level:1 flag:1 duration:0 in:db];
        }
        else if(_beatType == 5)
        {
            [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L2" category:@"CAT_SBRAD" level:2 flag:1 duration:0 in:db];
        }
        else
        {
            
        }
        _beatType = 0;
    }
    else if(avg >= 50)
    {

        if (_beatType == 3) {
            
            //更新
            [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L0" category:@"CAT_SBRAD" level:0 flag:0 duration:0 in:db];
            
            
        }
        else
        {
            if (_beatType == 0)
            {
                
                //开始
                 [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L0" category:@"CAT_SBRAD" level:0 flag:0 duration:0 in:db];
            }
            else
            {
                //结束
                if(_beatType == 1)
                {
                    
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_STACH_L2" category:@"CAT_STACH" level:2 flag:1 duration:0 in:db];
                    
                }
                else if(_beatType == 2)
                {
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_STACH_L0" category:@"CAT_STACH" level:0 flag:1 duration:0 in:db];
                }
                else if(_beatType == 4)
                {
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L1" category:@"CAT_SBRAD" level:1 flag:1 duration:0 in:db];
                }
                else if(_beatType == 5)
                {
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L2" category:@"CAT_SBRAD" level:2 flag:1 duration:0 in:db];
                }
                else
                {
                    
                }
                
                
                //开始
                [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L0" category:@"CAT_SBRAD" level:0 flag:0 duration:0 in:db];
                
            }
        }
        
        _beatType = 3;

        
    }
    else if(avg >= 40)
    {
        if (_beatType == 4) {
            
            //更新
            [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L1" category:@"CAT_SBRAD" level:1 flag:0 duration:0 in:db];
            
        }
        else
        {
            if (_beatType == 0)
            {
                
                //开始
                [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L1" category:@"CAT_SBRAD" level:1 flag:0 duration:0 in:db];
            }
            else
            {
                //结束
                if(_beatType == 1)
                {
                    
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_STACH_L2" category:@"CAT_STACH" level:2 flag:1 duration:0 in:db];
                    
                }
                else if(_beatType == 2)
                {
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_STACH_L0" category:@"CAT_STACH" level:0 flag:1 duration:0 in:db];
                }
                else if(_beatType == 3)
                {
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L0" category:@"CAT_SBRAD" level:0 flag:1 duration:0 in:db];
                }
                else if(_beatType == 5)
                {
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L2" category:@"CAT_SBRAD" level:2 flag:1 duration:0 in:db];
                }
                else
                {
                    
                }
                
                
                //开始
                [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L1" category:@"CAT_SBRAD" level:1 flag:0 duration:0 in:db];
                
            }
        }
        
        _beatType = 4;
        
    }
    else
    {
        long long timeSep2 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:(model1 / 256)  * 1000];
        if (_beatType == 5) {
            
            //更新
            [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L2" category:@"CAT_SBRAD" level:2 flag:0 duration:0 in:db];
            
            
        }
        else
        {
            if (_beatType == 0)
            {
                
                //开始
                [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L2" category:@"CAT_SBRAD" level:2 flag:0 duration:0 in:db];
            }
            else
            {
                //结束
                if(_beatType == 1)
                {
                    
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_STACH_L2" category:@"CAT_STACH" level:2 flag:1 duration:0 in:db];
                    
                }
                else if(_beatType == 2)
                {
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_STACH_L0" category:@"CAT_STACH" level:0 flag:1 duration:0 in:db];
                }
                else if(_beatType == 3)
                {
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L0" category:@"CAT_SBRAD" level:0 flag:1 duration:0 in:db];
                }
                else if(_beatType == 4)
                {
                    [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L1" category:@"CAT_SBRAD" level:1 flag:1 duration:0 in:db];
                }
                else
                {
                    
                }

                //开始
                [self savePrematureBeatAlarmWithTime:timeSep2 - 15000 type:@"AL_SBRAD_L2" category:@"CAT_SBRAD" level:2 flag:0 duration:0 in:db];
                
            }
        }
        
        _beatType = 5;

    
    }

}




//按照时间检索数据库
- (void)retrieveBatabaseSelectForAlertFromTime:(NSInteger)timesep
{

    BlockWeakSelf(self);
    dispatch_async(alertQueue1, ^{
        
        [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            //事件有延迟所以前推进10s.
        long long timeSep2 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:timesep];
        
        NSInteger recordTime = timeSep2 - 10 * 1000;
    
        NSString *query1 = [NSString stringWithFormat:@"select count(*) from %@ where occur_unixtime > '%@' and  occur_unixtime < %@ and  event_type = '%@'",EVENT_TABLE,@(recordTime - 60 * 1000),@(recordTime),@"EVENT_PB_PAC_RC"];
        NSString *query2 = [NSString stringWithFormat:@"select count(*) from %@ where occur_unixtime > '%@' and  occur_unixtime < %@ and  event_type = '%@'",EVENT_TABLE,@(recordTime - 60 * 60 * 1000),@(recordTime),@"EVENT_PB_PAC_RC"];
        NSString *query3 = [NSString stringWithFormat:@"select count(*) from %@ where occur_unixtime > '%@' and  occur_unixtime < %@ and  event_type = '%@'",EVENT_TABLE,@(recordTime - 60 * 60 * 1000),@(recordTime),@"EVENT_PB_PVC_RC"];
        NSString *query4 = [NSString stringWithFormat:@"select count(*) from %@ where occur_unixtime > '%@' and  occur_unixtime < %@ and  event_type = '%@'",EVENT_TABLE,@(recordTime - 60 * 1000),@(recordTime),@"EVENT_PB_PVC_RC"];

            
        NSInteger num1 =  [db intForQuery:query1];
        NSInteger num2 =  [db intForQuery:query2];
        NSInteger num3 =  [db intForQuery:query3];
        NSInteger num4 =  [db intForQuery:query4];
    
        
        
            if (num1 > 5 || num2 > 30)
            {
                
                if (weakSelf.SVEB0 == YES) {
                 
                    weakSelf.SVEB0 = NO;
                    [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_SVEB_L0" category:@"CAT_SVEB" level:0 flag:1 duration:0 in:db];
                }
                
                if (weakSelf.SVEB1 == NO) {
                    [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_SVEB_L1" category:@"CAT_SVEB" level:1 flag:0 duration:0 in:db];
                    weakSelf.SVEB1 = YES;
                }
                else
                {
                    [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_SVEB_L1" category:@"CAT_SVEB" level:1 flag:0 duration:0 in:db];
                }
                
                
                
            }
            else
            {
                if (weakSelf.SVEB1 == YES) {
                    weakSelf.SVEB1 = NO;
                    [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_SVEB_L1" category:@"CAT_SVEB" level:1 flag:1 duration:0 in:db];
                }
                if (num1 > 0) {
                    if (weakSelf.SVEB0 == NO) {
                        weakSelf.SVEB0 = YES;
                        
        
                         [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_SVEB_L0" category:@"CAT_SVEB" level:0 flag:0 duration:0 in:db];
                    }
                    else
                    {
                        
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_SVEB_L0" category:@"CAT_SVEB" level:0 flag:0 duration:0 in:db];
                    }
                }
                else
                {
                    if (weakSelf.SVEB0 == YES) {
                        
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_SVEB_L0" category:@"CAT_SVEB" level:0 flag:1 duration:0 in:db];
                        weakSelf.SVEB0 = NO;
                    }
                }
            }
            
            
            if(num3 > 30 || num4 >= 5)
            {
                if (weakSelf.VEB3 == YES) {
                    weakSelf.VEB3 = NO;
                    [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L0" category:@"CAT_VEB" level:0 flag:1 duration:0 in:db];
                }
                if (weakSelf.VEB1 == YES) {
                    
                    weakSelf.VEB1 = NO;
                    [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L1" category:@"CAT_VEB" level:1 flag:1 duration:0 in:db];
                }
                
                if ([SynECGLibSingleton sharedInstance].averageHR >= 40 || [SynECGLibSingleton sharedInstance].averageHR == 0) {
                    
                    if (weakSelf.VEB0 == YES) {
                        
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_BRAD" category:@"CAT_VEB" level:3 flag:1 duration:0 in:db];
                        weakSelf.VEB0 = NO;
                    }

                    if (weakSelf.VEB2 == NO) {
                        weakSelf.VEB2 = YES;
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L2" category:@"CAT_VEB" level:2 flag:0 duration:0 in:db];
                    }
                    else
                    {
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L2" category:@"CAT_VEB" level:2 flag:0 duration:0 in:db];
                    }
                }
                else
                {
                    if (weakSelf.VEB0 == NO) {
                        weakSelf.VEB0 = YES;
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_BRAD" category:@"CAT_VEB" level:3 flag:0 duration:0 in:db];
                    }
                    else
                    {
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_BRAD" category:@"CAT_VEB" level:3 flag:0 duration:0 in:db];
                    }
                    
                    
                    if (weakSelf.VEB2 == YES) {
                        
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L2" category:@"CAT_VEB" level:2 flag:1 duration:0 in:db];
                        weakSelf.VEB2 = NO;
                    }
                }
            }
            else
            {
                if (weakSelf.VEB2 == YES) {
                 
                    weakSelf.VEB2 = NO;
                    [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L2" category:@"CAT_VEB" level:2 flag:1 duration:0 in:db];
                }
                if (weakSelf.VEB0 == YES) {
                    
                    [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_BRAD" category:@"CAT_VEB" level:3 flag:1 duration:0 in:db];
                    weakSelf.VEB0 = NO;
                }
                if (num3 > 5)
                {
                    if (weakSelf.VEB1 == NO) {
                        weakSelf.VEB1 = YES;
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L1" category:@"CAT_VEB" level:1 flag:0 duration:0 in:db];
                    }
                    else
                    {
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L1" category:@"CAT_VEB" level:1 flag:0 duration:0 in:db];
                    }
                }
                else
                {
                    if (weakSelf.VEB1 == YES) {
                        
                        weakSelf.VEB1 = NO;
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L1" category:@"CAT_VEB" level:1 flag:1 duration:0 in:db];
                    }
                }
                
                if (num4 > 0 ) {
                    if (weakSelf.VEB3 == NO) {
                        weakSelf.VEB3 = YES;
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L0" category:@"CAT_VEB" level:0 flag:0 duration:0 in:db];
                    }
                    else
                    {
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L0" category:@"CAT_VEB" level:0 flag:0 duration:0 in:db];
                    }
                }
            }
         }];
        
    });
}






#pragma mark------------通过标记位检查告警

- (void)retrieveAlarmFromPosition:(NSInteger )position type:(NSString *)anntype
{
    
    dispatch_async(alertQueue2, ^{
        
    if(self.unsinusArray.count == 2 && self.sinusArray.count > 0 && [self.unsinusType isEqualToString:@"V"] && [anntype isEqualToString:@"V"])
    {
        //连发室性早搏开始
        NSInteger model0 = [self.unsinusArray.firstObject integerValue];
        long long timeSep1 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:[self tpFromPostion:model0]];
        
        [self checkToSaveWithTime:timeSep1 type:@"AL_RVEB" category:@"CAT_VEB" level:2 flag:0 duration:0];
    }

    else if(self.unsinusArray.count == 3 && [self.unsinusType isEqualToString:@"V"] && ![anntype isEqualToString:@"V"])
    {
        //连发室性早搏结束
        self.interval_time = 0;
        NSInteger model0 = position;
        long long timeSep1 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:[self tpFromPostion:model0]];

        [self checkToSaveWithTime:timeSep1 type:@"AL_RVEB" category:@"CAT_VEB" level:2 flag:1 duration:0];


    }
    
    if (self.beatType == 0) {
        //当前无告警
        if([anntype isEqualToString:@"N"])
        {
            
            if(self.unsinusArray.count >= 3)
            {
                [self.sinusArray addObject:self.unsinusArray.lastObject];
                [self.sinusArray addObject:@(position)];
            }
            else if(self.unsinusArray.count > 0)
            {
                [self.sinusArray addObjectsFromArray:self.unsinusArray];
                [self.sinusArray addObject:@(position)];
            }
            else
            {
                [self.sinusArray addObject:@(position)];
            }
            
            
            
            [self.unsinusArray removeAllObjects];
            self.unsinusType = anntype;
            
            
            if (self.sinusArray.count > 0 && (position - [self.sinusArray[0] integerValue]) * 1000 / 256 >= 1000 * 60) {
                
                //算心率
                NSInteger modelt = [self.sinusArray[1] integerValue];
                NSInteger avg = [self getAvgBpmFromArray:self.sinusArray andType:self.unsinusType];
                long long timeSep1 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:[self tpFromPostion:modelt]];
                
                
                if (avg >= 160) {
                    
                    self.beatType = 1;
                    [self checkToSaveWithTime:timeSep1 type:@"AL_STACH_L2" category:@"CAT_STACH" level:2 flag:0 duration:0];
                }
                else if(avg >= 100)
                {
                    self.beatType = 2;
                    [self checkToSaveWithTime:timeSep1 type:@"AL_STACH_L0" category:@"CAT_STACH" level:0 flag:0 duration:0];
                }
                else if(avg >= 60)
                {
                }
                else if(avg >= 50)
                {
                    self.beatType = 3;
                    [self checkToSaveWithTime:timeSep1 type:@"AL_SBRAD_L0" category:@"CAT_SBRAD" level:0 flag:0 duration:0];
                }
                else if(avg >= 40)
                {
                    
                    self.beatType = 4;
                    [self checkToSaveWithTime:timeSep1 type:@"AL_SBRAD_L1" category:@"CAT_SBRAD" level:1 flag:0 duration:0];
                }
                else
                {
                    self.beatType = 5;
                    [self checkToSaveWithTime:timeSep1 type:@"AL_SBRAD_L2" category:@"CAT_SBRAD" level:2 flag:0 duration:0];
                }
                
                NSMutableArray *removeArray = [[NSMutableArray alloc]init];
                for (int i = 0; i < self.sinusArray.count; i++) {
                    
                    if((position - [self.sinusArray[i] integerValue]) * 1000 / 256 >= 1000 * 60)
                    {
                        [removeArray addObject:self.sinusArray[i]];
                    }
                }
                
                //循环修复
                [self.sinusArray removeObjectsInArray:removeArray];
            }
            else
            {
//                        [self.sinusArray addObject:@(position)];
            }
            
            
        }
        else
        {

            if ([self.unsinusType isEqualToString:anntype])
            {
                
                if (self.sinusArray.count > 0) {
                    
                    [self.unsinusArray insertObject:self.sinusArray.lastObject atIndex:0];
                }
                
                
                [self.unsinusArray addObject:@(position)];
                
                
                if (self.unsinusArray.count >= 4)
                {
                
                    
                    [self.sinusArray removeAllObjects];
                    //算心率
           
                    NSInteger modelt = [self.unsinusArray[1] integerValue];
                    NSInteger avg = [self getAvgBpmFromArray:self.unsinusArray andType:self.unsinusType];
                    long long timeSep1 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:[self tpFromPostion:modelt]];

                    if (avg >= 100)
                    {
                        
                        if (avg >= 160)
                        {
                            
                            if ([self.unsinusType isEqualToString:@"A"]) {
                                
                                self.beatType = 7;
                                [self checkToSaveWithTime:timeSep1 type:@"AL_SVT_L2" category:@"CAT_SVT" level:2 flag:0 duration:0];
                            }
                            else
                            {
                                
                                if (avg >= 180) {
                                    
                                    self.beatType = 9;
                                    [self checkToSaveWithTime:timeSep1 type:@"AL_VT_PARO" category:@"CAT_VT" level:3 flag:0 duration:0];
                                }
                                else
                                {
                                 
                                    self.beatType = 8;
                                    [self checkToSaveWithTime:timeSep1 type:@"AL_VT" category:@"CAT_VT" level:2 flag:0 duration:0];
                                }
                                
                                
                            }
                            
                            
                        }
                        else
                        {
                            if ([self.unsinusType isEqualToString:@"A"])
                            {
                                
                                self.beatType = 6;
                                [self checkToSaveWithTime:timeSep1 type:@"AL_SVT_L1" category:@"CAT_SVT" level:1 flag:0 duration:0];
                            }
   

                        }
                    }
                    //计算完了移除第一个数据；
                    [self.unsinusArray removeObjectAtIndex:0];
                
                    
            
                }
                else
                {
                    //新的长度不够;
                    if (self.sinusArray.count > 0) {
                        [self.unsinusArray removeObjectAtIndex:0];
                    }
                }

            }
            else
            {
                //新的A/V，之前有个什么东西--------
                self.unsinusType = anntype;
                
                [self.sinusArray addObjectsFromArray:self.unsinusArray];
                [self.unsinusArray removeAllObjects];
                [self.unsinusArray addObject:@(position)];

            }
        }
    }
    else
    {
        if ([anntype isEqualToString:@"N"])
        {
            
            if (self.beatType <= 5)
            {
                
                if (self.unsinusArray.count > 0) {
                    
                    [self.sinusArray addObjectsFromArray:self.unsinusArray];
                    [self.unsinusArray removeAllObjects];
                    self.unsinusType = anntype;
                }
                [self.sinusArray addObject:@(position)];
                
                
                if (self.sinusArray.count > 0 && (position - [self.sinusArray[0] integerValue]) * 1000 / 256 >= 1000 * 60)
                {
                    //算心率

                    NSInteger model1 = [self.sinusArray[self.sinusArray.count - 2] integerValue];
                    NSInteger avg = [self getAvgBpmFromArray:self.sinusArray andType:self.unsinusType];
                    long long timeSep1 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:[self tpFromPostion:model1]];

                    if (self.beatType == 1) {
                        
                        if (avg >= 160) {
                            
                        }
                        else
                        {
                            self.beatType = 0;
                            [self checkToSaveWithTime:timeSep1 type:@"AL_STACH_L2" category:@"CAT_STACH" level:2 flag:1 duration:0];
                        }
                        
                    }
                    else if (self.beatType == 2) {
                        
                        if (avg >= 100) {
                            
                        }
                        else
                        {
                            self.beatType = 0;
                            [self checkToSaveWithTime:timeSep1 type:@"AL_STACH_L0" category:@"CAT_STACH" level:0 flag:1 duration:0];
                        }
                    }
                    else if (self.beatType == 3) {
                        
                        if (avg >= 50 && avg < 60) {
                            
                        }
                        else
                        {
                            self.beatType = 0;
                            [self checkToSaveWithTime:timeSep1 type:@"AL_SBRAD_L0" category:@"CAT_SBRAD" level:0 flag:1 duration:0];
                        }
                        
                        
                    }
                    else if (self.beatType == 4) {
                        
                        if (avg >= 40 && avg < 50) {

                            
                        }
                        else
                        {
                            self.beatType = 0;
                            [self checkToSaveWithTime:timeSep1 type:@"AL_SBRAD_L1" category:@"CAT_SBRAD" level:1 flag:1 duration:0];
                        }
                    }
                    else if (self.beatType == 5) {
                        
                        if (avg < 40) {
                            
                        }
                        else
                        {
                            self.beatType = 0;
                            [self checkToSaveWithTime:timeSep1 type:@"AL_SBRAD_L2" category:@"CAT_SBRAD" level:2 flag:1 duration:0];
                        }
                    }
                    
                    if (self.beatType == 0) {
                        
                        [self.sinusArray removeObjectsInRange:NSMakeRange(0, self.sinusArray.count - 2)];
                        
                    }
                    else
                    {
                        NSMutableArray *removeArray = [[NSMutableArray alloc]init];
                        for (int i = 0; i < self.sinusArray.count; i++) {
                            
                            if((position - [self.sinusArray[i] integerValue]) * 1000 / 256 >= 1000 * 60)
                            {
                                [removeArray addObject:self.sinusArray[i]];
                            }
                        }
                        //循环修复
                        [self.sinusArray removeObjectsInArray:removeArray];
                    }

                }
            }
            else
            {
                NSInteger model0 = [self.unsinusArray.lastObject integerValue];
                long long timeSep1 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:[self tpFromPostion:model0]];
                
                if (self.beatType == 6) {
                    
                    [self checkToSaveWithTime:timeSep1 type:@"AL_SVT_L1" category:@"CAT_SVT" level:1 flag:1 duration:0];
                }
                else if (self.beatType == 7) {
                    
                    [self checkToSaveWithTime:timeSep1 type:@"AL_SVT_L2" category:@"CAT_SVT" level:2 flag:1 duration:0];
                }
                else if (self.beatType == 8) {
                    
                    [self checkToSaveWithTime:timeSep1 type:@"AL_VT" category:@"CAT_VT" level:2 flag:1 duration:0];
                }
                else if (self.beatType == 9) {
                    
                    [self checkToSaveWithTime:timeSep1 type:@"AL_VT_PARO" category:@"CAT_VT" level:3 flag:1 duration:0];
                }
                
                [self.sinusArray addObject:@(position)];
                [self.unsinusArray removeAllObjects];
                self.unsinusType = anntype;
                self.beatType = 0;
            }
        }
        else
        {

            if ([anntype isEqualToString:self.unsinusType])
            {

                [self.unsinusArray addObject:@(position)];
                
                if(self.sinusArray.count > 0)
                {
                    [self.unsinusArray insertObject:self.sinusArray.lastObject atIndex:0];
                }
                
                if (self.unsinusArray.count >= 4)
                {
                    if (self.beatType <= 5)
                    {
                        
                        NSInteger model0 = [self.sinusArray.lastObject integerValue];
                        long long timeSep1 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:[self tpFromPostion:model0]];
                        
                        if (self.beatType == 1) {
                            
                            
                            self.beatType = 0;
                            [self checkToSaveWithTime:timeSep1 type:@"AL_STACH_L2" category:@"CAT_STACH" level:2 flag:1 duration:0];
                            
                            
                        }
                        else if (self.beatType == 2) {
                            
                            
                            self.beatType = 0;
                            [self checkToSaveWithTime:timeSep1 type:@"AL_STACH_L0" category:@"CAT_STACH" level:0 flag:1 duration:0];
                            
                        }
                        else if (self.beatType == 3) {
                        
                            self.beatType = 0;
                            [self checkToSaveWithTime:timeSep1 type:@"AL_SBRAD_L0" category:@"CAT_SBRAD" level:0 flag:1 duration:0];
                        }
                        else if (self.beatType == 4) {
                            
                            self.beatType = 0;
                            [self checkToSaveWithTime:timeSep1 type:@"AL_SBRAD_L1" category:@"CAT_SBRAD" level:1 flag:1 duration:0];
                            
                        }
                        else if (self.beatType == 5) {

                            self.beatType = 0;
                            [self checkToSaveWithTime:timeSep1 type:@"AL_SBRAD_L2" category:@"CAT_SBRAD" level:2 flag:1 duration:0];
                            
                        }
                        [self.sinusArray removeAllObjects];
                        
                    
                        NSInteger modelt = [self.unsinusArray[1] integerValue];
                        NSInteger avg = [self getAvgBpmFromArray:self.unsinusArray andType:self.unsinusType];;
                        long long timeSep2 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:[self tpFromPostion:modelt]];
                        

                        
                        if (avg >= 100)
                        {
                            
                            if (avg >= 160)
                            {
                                
                                if ([self.unsinusType isEqualToString:@"A"]) {
                                    
                                    self.beatType = 7;
                                    [self checkToSaveWithTime:timeSep2 type:@"AL_SVT_L2" category:@"CAT_SVT" level:2 flag:0 duration:0];
                                }
                                else
                                {
                                    
                                    if (avg >= 180) {
                                        
                                        self.beatType = 9;
                                        [self checkToSaveWithTime:timeSep2 type:@"AL_VT_PARO" category:@"CAT_VT" level:3 flag:0 duration:0];
                                    }
                                    else
                                    {
                                        
                                        self.beatType = 8;
                                        [self checkToSaveWithTime:timeSep2 type:@"AL_VT" category:@"CAT_VT" level:2 flag:0 duration:0];
                                    }
                                    
                                    
                                }
                                
                                
                            }
                            else
                            {
                                if ([self.unsinusType isEqualToString:@"A"])
                                {
                                    
                                    self.beatType = 6;
                                    [self checkToSaveWithTime:timeSep2 type:@"AL_SVT_L1" category:@"CAT_SVT" level:1 flag:0 duration:0];
                                }
                                
                                
                            }
                            
                            //计算完了移除第一个数据；
                            [self.unsinusArray removeObjectAtIndex:0];
                        }

                    }
                    else
                    {
                        

                        NSInteger model1 = [self.unsinusArray.lastObject integerValue];
                        NSInteger avg = [self getAvgBpmFromArray:self.unsinusArray andType:self.unsinusType];;
                        NSInteger timeSep2 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:[self tpFromPostion:model1]];
                        
                      
                        
                        if(self.beatType == 6)
                        {
                            if (avg >= 100 && avg < 160) {
                                //更新
                                
                            }
                            else
                            {
                                self.beatType = 0;
                                [self.unsinusArray removeObjectsInRange:NSMakeRange(0, self.unsinusArray.count - 1)];
                                [self checkToSaveWithTime:timeSep2 type:@"AL_SVT_L1" category:@"CAT_SVT" level:1 flag:1 duration:0];
                            }
                        }
                        else if(self.beatType == 7)
                        {
                            if (avg >= 160) {
                                //更新
                                
                            }
                            else
                            {
                                self.beatType = 0;
                                [self.unsinusArray removeObjectsInRange:NSMakeRange(0, self.unsinusArray.count - 1)];
                                [self checkToSaveWithTime:timeSep2 type:@"AL_SVT_L2" category:@"CAT_SVT" level:2 flag:1 duration:0];
                            }
                        }
                        else if(self.beatType == 8)
                        {
                            if (avg >= 160 && avg < 180) {
                                //更新
                                
                            }
                            else
                            {
                                self.beatType = 0;
                                [self.unsinusArray removeObjectsInRange:NSMakeRange(0, self.unsinusArray.count - 1)];
                                [self checkToSaveWithTime:timeSep2 type:@"AL_VT" category:@"CAT_VT" level:2 flag:1 duration:0];
                            }
                        }
                        else if(self.beatType == 9)
                        {
                            if (avg >= 180)
                            {
                                //更新
                            }
                            else
                            {
                                self.beatType = 0;
                                [self.unsinusArray removeObjectsInRange:NSMakeRange(0, self.unsinusArray.count - 1)];
                                [self checkToSaveWithTime:timeSep2 type:@"AL_VT_PARO" category:@"CAT_VT" level:3 flag:1 duration:0];
                            }
                            
                        }

                    }
                    
                    if(self.unsinusArray.count >= 4)
                    {
                        [self.unsinusArray removeObjectAtIndex:0];
                    }
                    
                    
                }
                else
                {
                    if (self.sinusArray.count > 0)
                    {
                        [self.unsinusArray removeObjectAtIndex:0];
                    }
                }
            }
            else
            {
                //两个不相等
                if (self.beatType <= 5) {
                    
                    [self.sinusArray addObjectsFromArray:self.unsinusArray];
                    [self.unsinusArray removeAllObjects];
                    [self.unsinusArray addObject:@(position)];
                    self.unsinusType = anntype;
                    
                    
                    
                    if (self.sinusArray.count > 0 && (position - [self.sinusArray[0] integerValue]) * 1000 / 256 >= 1000 * 60)
                    {
                 
                        NSInteger model1 = [self.sinusArray[self.sinusArray.count - 2] integerValue];
                        NSInteger avg = [self getAvgBpmFromArray:self.sinusArray andType:self.unsinusType];
                        
                        long long timeSep1 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:[self tpFromPostion:model1]];
                    

                        if (self.beatType == 1) {
                            
                            if (avg >= 160) {
                                
                            }
                            else
                            {
                                self.beatType = 0;
                                [self checkToSaveWithTime:timeSep1 type:@"AL_STACH_L2" category:@"CAT_STACH" level:2 flag:1 duration:0];
                            }
                            
                        }
                        else if (self.beatType == 2) {
                            
                            if (avg >= 100) {
                                
                            }
                            else
                            {
                                self.beatType = 0;
                                [self checkToSaveWithTime:timeSep1 type:@"AL_STACH_L0" category:@"CAT_STACH" level:0 flag:1 duration:0];
                            }
                        }
                        else if (self.beatType == 3) {
                            
                            if (avg >= 50 && avg < 60) {
                                
                                
                            }
                            else
                            {
                                
                                self.beatType = 0;
                                [self checkToSaveWithTime:timeSep1 type:@"AL_SBRAD_L0" category:@"CAT_SBRAD" level:0 flag:1 duration:0];
                            }
                            
                            
                        }
                        else if (self.beatType == 4) {
                            
                            if (avg >= 40 && avg < 50) {
                                
                                
                            }
                            else
                            {
                                self.beatType = 0;
                                [self checkToSaveWithTime:timeSep1 type:@"AL_SBRAD_L1" category:@"CAT_SBRAD" level:1 flag:1 duration:0];
                            }
                        }
                        else if (self.beatType == 5) {
                            
                            if (avg < 40) {
                                
                            }
                            else
                            {
                                self.beatType = 0;
                                [self checkToSaveWithTime:timeSep1 type:@"AL_SBRAD_L2" category:@"CAT_SBRAD" level:2 flag:1 duration:0];
                            }
                        }
                        
                        if (self.beatType == 0) {
                            
                            [self.sinusArray removeObjectsInRange:NSMakeRange(0, self.sinusArray.count - 2)];
                        }
                        else
                        {
                            NSMutableArray *removeArray = [[NSMutableArray alloc]init];
                            for (int i = 0; i < self.sinusArray.count; i++) {
                                
                                if((position - [self.sinusArray[i] integerValue]) * 1000 / 256 >= 1000 * 60)
                                {
                                    [removeArray addObject:self.sinusArray[i]];
                                }
                            }
                            
                            
                            //循环修复
                            [self.sinusArray removeObjectsInArray:removeArray];
                        }
                    }
                    
                    
                    
                }
                else
                {
                    NSInteger model0 = [self.unsinusArray.lastObject integerValue];
                    long long timeSep1 = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:[self tpFromPostion:model0]];
                    
                    if (self.beatType == 6) {
                        
                        [self checkToSaveWithTime:timeSep1 type:@"AL_SVT_L1" category:@"CAT_SVT" level:1 flag:1 duration:0];
                    }
                    else if (self.beatType == 7) {
                        
                        [self checkToSaveWithTime:timeSep1 type:@"AL_SVT_L2" category:@"CAT_SVT" level:2 flag:1 duration:0];
                    }
                    else if (self.beatType == 8) {
                        
                        [self checkToSaveWithTime:timeSep1 type:@"AL_VT" category:@"CAT_VT" level:2 flag:1 duration:0];
                    }
                    else if (self.beatType == 9) {
                        
                        [self checkToSaveWithTime:timeSep1 type:@"AL_VT_PARO" category:@"CAT_VT" level:3 flag:1 duration:0];
                    }
                    
                    
                    [self.sinusArray removeAllObjects];
                    [self.sinusArray addObject:self.unsinusArray.lastObject];
                    [self.unsinusArray removeAllObjects];
                    [self.unsinusArray addObject:@(position)];
                    self.unsinusType = anntype;
                    self.beatType = 0;

                }
            }
            
        }
    }
    
            
//            [SynECGUtils saveStartType:self.unsinusType];
//
//            if (self.sinusArray.count > 0) {
//             
//                [SynECGUtils saveStartPosition1:self.sinusArray.firstObject];
//            }
//            else
//            {
//                [SynECGUtils saveStartPosition1:@(0)];
//            }
//
//            if (self.unsinusArray.count > 0) {
//                
//                [SynECGUtils saveStartPosition2:self.unsinusArray.firstObject];
//            }
//            else
//            {
//                [SynECGUtils saveStartPosition2:@(0)];
//            }
            
            
            
//    //更新表
//    NSInteger a_np = 0;
//    NSInteger a_up = 0;
//    if (self.sinusArray.count > 0) {
//
//        a_np = [self.sinusArray.firstObject integerValue];
//    }
//    if (self.unsinusArray.count > 0) {
//
//        a_up = [self.unsinusArray.firstObject integerValue];
//    }
//    NSString *updateSql = [NSString stringWithFormat:
//                           @"UPDATE %@ set a_np = '%@',a_up ='%@', a_r = '%@' WHERE recordId = '%@'",TOTAL_TABLE,@(a_np),@(a_up),self.unsinusType,[SynECGLibSingleton sharedInstance].record_id];
//    [db executeUpdate:updateSql];

    });
    
    
}


- (NSInteger)tpFromPostion:(NSInteger)postion
{
    CGFloat tp = (CGFloat)postion * (CGFloat)1000 / (CGFloat)256;
    NSInteger tpo = round(tp);
    
    
    return tpo;
}


- (NSInteger)getAvgBpmFromArray:(NSArray *)positionArray andType:(NSString *)type
{
    
    if (positionArray.count < 3) {
        
        return 65;
    }
    
    
    NSInteger totalPosition = 0;
    NSInteger totalNum = 0;
    
    if ([type isEqualToString:@"N"])
    {
        for (int i = 0; i < positionArray.count - 2; i++) {
            
            NSInteger model0 = [positionArray[i] integerValue];
            NSInteger model1 = [positionArray[i + 1] integerValue];
            
            if (model1 - model0 > 0.2 * 256 && model1 - model0 < 2 * 256) {
                
                totalPosition = totalPosition + model1 - model0;
                totalNum = totalNum + 1;
            }
        }
    }
    else
    {
        for (int i = 0; i < positionArray.count - 1; i++) {
            
            NSInteger model0 = [positionArray[i] integerValue];
            NSInteger model1 = [positionArray[i + 1] integerValue];
            
            if (model1 - model0 > 0.2 * 256 && model1 - model0 < 2 * 256) {
                
                totalPosition = totalPosition + model1 - model0;
                totalNum = totalNum + 1;
            }
        }
    }
    
    if (totalPosition < 256 * 40 && [type isEqualToString:@"N"]) {
        
        return 65;
    }
    else
    {
        return 60 * 256 * totalNum / totalPosition;
    }
        
}


//按照时间检索数据库RR
- (void)retrieveRRBatabaseSelectForAlertFromPosition:(NSInteger)position
{
    BlockWeakSelf(self);
    dispatch_async(alertQueue3, ^{

        [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
    
            NSString *query1 = [NSString stringWithFormat:@"select count(*) from %@ where position > '%@' and  position < %@ and  ann = '%@'",RR_TABLE,@(position - 256 * 60),@(position),@"A"];
            NSString *query2 = [NSString stringWithFormat:@"select count(*) from %@ where position > '%@' and  position < %@ and  ann = '%@'",RR_TABLE,@(position - 60 * 60 * 256),@(position),@"A"];
            NSString *query3 = [NSString stringWithFormat:@"select count(*) from %@ where position > '%@' and  position < %@ and  ann = '%@'",RR_TABLE,@(position - 60 * 60 * 256),@(position),@"V"];
            NSString *query4 = [NSString stringWithFormat:@"select count(*) from %@ where position > '%@' and  position < %@ and  ann = '%@'",RR_TABLE,@(position - 60 * 256),@(position),@"V"];
            
            long long recordTime = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:[self tpFromPostion:position]];
            
            
            NSInteger num1 =  [db intForQuery:query1];
            NSInteger num2 =  [db intForQuery:query2];
            NSInteger num3 =  [db intForQuery:query3];
            NSInteger num4 =  [db intForQuery:query4];
            
            
            
            if (num1 > 5 || num2 > 30)
            {
                
                if (weakSelf.SVEB0 == YES) {
                    weakSelf.starA = 0;
                    weakSelf.SVEB0 = NO;
                    [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_SVEB_L0" category:@"CAT_SVEB" level:0 flag:1 duration:0 in:db];
                }
                
                if (weakSelf.SVEB1 == NO) {
                    
                    [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_SVEB_L1" category:@"CAT_SVEB" level:1 flag:0 duration:0 in:db];
                    weakSelf.SVEB1 = YES;
                }
                else
                {
                    weakSelf.starA ++;
                    if (weakSelf.starA >= weakSelf.interval_time) {
                     
                        weakSelf.starA = 0;
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_SVEB_L1" category:@"CAT_SVEB" level:1 flag:0 duration:0 in:db];
                    }
                }
                
                
                
            }
            else
            {
                if (weakSelf.SVEB1 == YES) {
                    weakSelf.SVEB1 = NO;
                    weakSelf.starA = 0;
                    [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_SVEB_L1" category:@"CAT_SVEB" level:1 flag:1 duration:0 in:db];
                }
                if (num1 > 0) {
                    if (weakSelf.SVEB0 == NO) {
                        weakSelf.SVEB0 = YES;
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_SVEB_L0" category:@"CAT_SVEB" level:0 flag:0 duration:0 in:db];
                    }
                    else
                    {
                        
                        weakSelf.starA ++;
                        if (weakSelf.starA >= weakSelf.interval_time) {
                            weakSelf.starA = 0;
                            [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_SVEB_L0" category:@"CAT_SVEB" level:0 flag:0 duration:0 in:db];
                        }
                    }
                }
                else
                {
                    if (weakSelf.SVEB0 == YES) {
                        self.starA = 0;
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_SVEB_L0" category:@"CAT_SVEB" level:0 flag:1 duration:0 in:db];
                        weakSelf.SVEB0 = NO;
                    }
                }
            }
            
            
            if(num3 > 30 || num4 >= 5)
            {
                if (weakSelf.VEB3 == YES) {
                    weakSelf.VEB3 = NO;
                    weakSelf.starV = 0;
                    [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L0" category:@"CAT_VEB" level:0 flag:1 duration:0 in:db];
                }
                if (weakSelf.VEB1 == YES) {
                    weakSelf.starV = 0;
                    weakSelf.VEB1 = NO;
                    [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L1" category:@"CAT_VEB" level:1 flag:1 duration:0 in:db];
                }
                
                if ([SynECGLibSingleton sharedInstance].averageHR >= 40 || [SynECGLibSingleton sharedInstance].averageHR == 0) {
                    
                    if (weakSelf.VEB0 == YES) {
                        
                        weakSelf.starV = 0;
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_BRAD" category:@"CAT_VEB" level:3 flag:1 duration:0 in:db];
                        weakSelf.VEB0 = NO;
                    }
                    
                    if (weakSelf.VEB2 == NO) {
                        weakSelf.VEB2 = YES;
                        
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L2" category:@"CAT_VEB" level:2 flag:0 duration:0 in:db];
                    }
                    else
                    {
                        weakSelf.starV++;
                        if (weakSelf.starV >= weakSelf.interval_time)
                        {
                            weakSelf.starV = 0;
                            weakSelf.interval_time = 90;
                            [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L2" category:@"CAT_VEB" level:2 flag:0 duration:0 in:db];
                        }
                    }
                }
                else
                {
                    if (weakSelf.VEB2 == YES) {
                        weakSelf.starV = 0;
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L2" category:@"CAT_VEB" level:2 flag:1 duration:0 in:db];
                        weakSelf.VEB2 = NO;
                    }
                    
                    if (weakSelf.VEB0 == NO) {
                        weakSelf.VEB0 = YES;
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_BRAD" category:@"CAT_VEB" level:3 flag:0 duration:0 in:db];
                    }
                    else
                    {
                        weakSelf.starV ++;
                        if (weakSelf.starV >= self.interval_time) {
                            weakSelf.starV = 0;
                            weakSelf.interval_time = 90;
                            [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_BRAD" category:@"CAT_VEB" level:3 flag:0 duration:0 in:db];
                        }
                    }
                }
            }
            else
            {
                if (weakSelf.VEB2 == YES) {
                    weakSelf.starV = 0;
                    weakSelf.VEB2 = NO;
                    [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L2" category:@"CAT_VEB" level:2 flag:1 duration:0 in:db];
                }
                if (weakSelf.VEB0 == YES) {
                    weakSelf.starV = 0;
                    [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_BRAD" category:@"CAT_VEB" level:3 flag:1 duration:0 in:db];
                    weakSelf.VEB0 = NO;
                }
                if (num3 > 5)
                {
                    if (weakSelf.VEB1 == NO) {
                        weakSelf.VEB1 = YES;
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L1" category:@"CAT_VEB" level:1 flag:0 duration:0 in:db];
                    }
                    else
                    {
                        weakSelf.starV++;
                        if (weakSelf.starV >= weakSelf.interval_time) {
                            weakSelf.interval_time = 90;
                            weakSelf.starV = 0;
                            [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L1" category:@"CAT_VEB" level:1 flag:0 duration:0 in:db];
                        }
                    }
                }
                else
                {
                    if (weakSelf.VEB1 == YES) {
                        
                        weakSelf.starV = 0;
                        weakSelf.VEB1 = NO;
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L1" category:@"CAT_VEB" level:1 flag:1 duration:0 in:db];
                    }
                    
                    
                    if (num4 > 0 ) {
                        if (weakSelf.VEB3 == NO) {
                            weakSelf.VEB3 = YES;
                            [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L0" category:@"CAT_VEB" level:0 flag:0 duration:0 in:db];
                        }
                        else
                        {
                            weakSelf.starV ++;
                            if (weakSelf.starV >= weakSelf.interval_time) {
                                weakSelf.interval_time = 90;
                                weakSelf.starV = 0;
                                [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L0" category:@"CAT_VEB" level:0 flag:0 duration:0 in:db];
                            }
                        }
                    }
                    else
                    {
                        weakSelf.VEB3 = NO;
                        weakSelf.starV = 0;
                        [weakSelf savePrematureBeatAlarmWithTime:recordTime type:@"AL_VEB_L0" category:@"CAT_VEB" level:0 flag:1 duration:0 in:db];
                    }
                }
                
            }
        }];

    });
}


- (void)retrieveRRFromPosition:(NSInteger)position ann:(NSString *)ann
{
    BlockWeakSelf(self);
    dispatch_async(alertQueue3, ^{
        
            if(weakSelf.hourAArray.count > 0)
            {
                if (position - [weakSelf.hourAArray[0] integerValue] >= 60 * 60 * 256) {
                    [weakSelf.hourAArray removeObjectAtIndex:0];
                }
            }
            
            if(self.minuteAArray.count > 0)
            {
                if (position - [weakSelf.minuteAArray[0] integerValue] >= 60 * 256) {
                    [weakSelf.minuteAArray removeObjectAtIndex:0];
                }
            }
            
            if(self.hourVArray.count > 0)
            {
                if (position - [weakSelf.hourVArray[0] integerValue] >= 60 * 60 * 256) {
                    [weakSelf.hourVArray removeObjectAtIndex:0];
                }
            }
            
            if(self.minuteVArray.count > 0)
            {
                if (position - [weakSelf.minuteVArray[0] integerValue] >= 60 * 256) {
                    [weakSelf.minuteVArray removeObjectAtIndex:0];
                }
            }
            
        if ([ann isEqualToString:@"A"]) {
            

            [weakSelf.hourAArray addObject:@(position)];
            
            
            [weakSelf.minuteAArray addObject:@(position)];
            
            
        }
        else if ([ann isEqualToString:@"V"]) {
            

            [weakSelf.hourVArray addObject:@(position)];
            [weakSelf.minuteVArray addObject:@(position)];
        }
    
    
            NSInteger num1 =  weakSelf.minuteAArray.count;
            NSInteger num2 =  weakSelf.hourAArray.count;
            NSInteger num3 =  weakSelf.hourVArray.count;
            NSInteger num4 =  weakSelf.minuteVArray.count;
            
            long long recordTime = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:[weakSelf tpFromPostion:position]];
            if (num1 > 5 || num2 > 30)
            {
                
                if (weakSelf.SVEB0 == YES) {
                    weakSelf.starA = 0;
                    weakSelf.SVEB0 = NO;
                    [weakSelf checkToSaveWithTime:recordTime type:@"AL_SVEB_L0" category:@"CAT_SVEB" level:0 flag:1 duration:0];
                
                }
                
                if (weakSelf.SVEB1 == NO) {
                    
                    [weakSelf checkToSaveWithTime:recordTime type:@"AL_SVEB_L1" category:@"CAT_SVEB" level:1 flag:0 duration:0];
                    weakSelf.SVEB1 = YES;
                }
                else
                {
                    weakSelf.starA ++;
                    if (weakSelf.starA >= weakSelf.interval_time) {
                        
                        weakSelf.starA = 0;
                        [weakSelf checkToSaveWithTime:recordTime type:@"AL_SVEB_L1" category:@"CAT_SVEB" level:1 flag:0 duration:0];
                    }
                }
            }
            else
            {
                if (weakSelf.SVEB1 == YES) {
                    weakSelf.SVEB1 = NO;
                    weakSelf.starA = 0;
                    [weakSelf checkToSaveWithTime:recordTime type:@"AL_SVEB_L1" category:@"CAT_SVEB" level:1 flag:1 duration:0];
                }
                if (num1 > 0) {
                    if (weakSelf.SVEB0 == NO) {
                        weakSelf.SVEB0 = YES;
                        [weakSelf checkToSaveWithTime:recordTime type:@"AL_SVEB_L0" category:@"CAT_SVEB" level:0 flag:0 duration:0];
                    }
                    else
                    {
                        
                        weakSelf.starA ++;
                        if (weakSelf.starA >= self.interval_time) {
                            weakSelf.starA = 0;
                            [weakSelf checkToSaveWithTime:recordTime type:@"AL_SVEB_L0" category:@"CAT_SVEB" level:0 flag:0 duration:0];
                        }
                    }
                }
                else
                {
                    if (weakSelf.SVEB0 == YES) {
                        weakSelf.starA = 0;
                        [weakSelf checkToSaveWithTime:recordTime type:@"AL_SVEB_L0" category:@"CAT_SVEB" level:0 flag:1 duration:0];
                        weakSelf.SVEB0 = NO;
                    }
                }
            }
            
            
            if(num3 > 30 || num4 >= 5)
            {
                if (weakSelf.VEB3 == YES) {
                    weakSelf.VEB3 = NO;
                    weakSelf.starV = 0;
                    [weakSelf checkToSaveWithTime:recordTime type:@"AL_VEB_L0" category:@"CAT_VEB" level:0 flag:1 duration:0];
                }
                if (weakSelf.VEB1 == YES) {
                    weakSelf.starV = 0;
                    weakSelf.VEB1 = NO;
                    [weakSelf checkToSaveWithTime:recordTime type:@"AL_VEB_L1" category:@"CAT_VEB" level:1 flag:1 duration:0];
                }
                
                if ([SynECGLibSingleton sharedInstance].averageHR >= 40 || [SynECGLibSingleton sharedInstance].averageHR == 0) {
                    
                    if (weakSelf.VEB0 == YES) {
                        
                        weakSelf.starV = 0;
                        [weakSelf checkToSaveWithTime:recordTime type:@"AL_VEB_BRAD" category:@"CAT_VEB" level:3 flag:1 duration:0];
                        weakSelf.VEB0 = NO;
                    }
                    
                    if (weakSelf.VEB2 == NO) {
                        weakSelf.VEB2 = YES;
                        
                        [weakSelf checkToSaveWithTime:recordTime type:@"AL_VEB_L2" category:@"CAT_VEB" level:2 flag:0 duration:0];
                    }
                    else
                    {
                        weakSelf.starV++;
                        if (weakSelf.starV >= weakSelf.interval_time)
                        {
                            weakSelf.starV = 0;
                            weakSelf.interval_time = 90;
                            [weakSelf checkToSaveWithTime:recordTime type:@"AL_VEB_L2" category:@"CAT_VEB" level:2 flag:0 duration:0];
                        }
                    }
                }
                else
                {
                    if (weakSelf.VEB2 == YES) {
                        weakSelf.starV = 0;
                        [weakSelf checkToSaveWithTime:recordTime type:@"AL_VEB_L2" category:@"CAT_VEB" level:2 flag:1 duration:0];
                        weakSelf.VEB2 = NO;
                    }
                    
                    if (weakSelf.VEB0 == NO) {
                        weakSelf.VEB0 = YES;
                        [weakSelf checkToSaveWithTime:recordTime type:@"AL_VEB_BRAD" category:@"CAT_VEB" level:3 flag:0 duration:0];
                    }
                    else
                    {
                        weakSelf.starV ++;
                        if (weakSelf.starV >= self.interval_time) {
                            weakSelf.starV = 0;
                            weakSelf.interval_time = 90;
                            [weakSelf checkToSaveWithTime:recordTime type:@"AL_VEB_BRAD" category:@"CAT_VEB" level:3 flag:0 duration:0];
                        }
                    }
                }
            }
            else
            {
                if (weakSelf.VEB2 == YES) {
                    weakSelf.starV = 0;
                    weakSelf.VEB2 = NO;
                    [weakSelf checkToSaveWithTime:recordTime type:@"AL_VEB_L2" category:@"CAT_VEB" level:2 flag:1 duration:0];
                }
                if (weakSelf.VEB0 == YES) {
                    weakSelf.starV = 0;
                    [weakSelf checkToSaveWithTime:recordTime type:@"AL_VEB_BRAD" category:@"CAT_VEB" level:3 flag:1 duration:0];
                    weakSelf.VEB0 = NO;
                }
                if (num3 > 5)
                {
                    if (weakSelf.VEB1 == NO) {
                        weakSelf.VEB1 = YES;
                        [weakSelf checkToSaveWithTime:recordTime type:@"AL_VEB_L1" category:@"CAT_VEB" level:1 flag:0 duration:0];
                    }
                    else
                    {
                        weakSelf.starV++;
                        if (weakSelf.starV >= self.interval_time) {
                            weakSelf.interval_time = 90;
                            weakSelf.starV = 0;
                            [weakSelf checkToSaveWithTime:recordTime type:@"AL_VEB_L1" category:@"CAT_VEB" level:1 flag:0 duration:0];
                        }
                    }
                }
                else
                {
                    if (weakSelf.VEB1 == YES) {
                        
                        weakSelf.starV = 0;
                        weakSelf.VEB1 = NO;
                        [weakSelf checkToSaveWithTime:recordTime type:@"AL_VEB_L1" category:@"CAT_VEB" level:1 flag:1 duration:0];
                    }
                    
                    
                    if (num4 > 0 ) {
                        if (weakSelf.VEB3 == NO) {
                            weakSelf.VEB3 = YES;
                            [weakSelf checkToSaveWithTime:recordTime type:@"AL_VEB_L0" category:@"CAT_VEB" level:0 flag:0 duration:0];
                        }
                        else
                        {
                            weakSelf.starV ++;
                            if (weakSelf.starV >= self.interval_time) {
                                weakSelf.interval_time = 90;
                                weakSelf.starV = 0;
                                [weakSelf checkToSaveWithTime:recordTime type:@"AL_VEB_L0" category:@"CAT_VEB" level:0 flag:0 duration:0];
                            }
                        }
                    }
                    else
                    {
                        weakSelf.VEB3 = NO;
                        weakSelf.starV = 0;
                        [weakSelf checkToSaveWithTime:recordTime type:@"AL_VEB_L0" category:@"CAT_VEB" level:0 flag:1 duration:0];
                    }
                }
                
            }
    });
}



- (void)checkToSaveWithTime:(long long)time type:(NSString *)type category:(NSString *)category level:(NSInteger)level flag:(NSInteger)flag duration:(NSInteger)duration
{
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {

        [self savePrematureBeatAlarmWithTime:time type:type category:category level:level flag:false duration:duration in:db];
    }];
}



#pragma mark------------保存告警及水位线
//。。。。。。。。。。事件触发的。。。。。。。。。。。。。。
- (void)saveAlarmWithTime:(long long)time type:(NSString *)type category:(NSString *)category level:(NSInteger)level flag:(NSInteger)flag duration:(NSInteger)duration in:(FMDatabase *)db
{
    
    
    if (flag == 1) {
        NSString *start_alarm_id = [[NSString alloc]init];
        long long startTime = 0;
        NSString *query = [NSString stringWithFormat:@"select * from %@ where alert_type = '%@' and alarm_flag = '%@'",ALARM_TABLE,type,@(0)];
        FMResultSet *rs = [db executeQuery:query];
        int num = 0;
        while ([rs next])
        {
            start_alarm_id = [rs stringForColumn:@"start_alarm_id"];
            startTime = [rs longLongIntForColumn:@"occur_unixtime"];
            num ++;
        }
        if (num > 0) {
            
            //保存到上传库
            [[SynAlarmUploadManager sharedInstance] saveAlertWithAlarmId:[SynECGUtils uuidString] start_alarm_id:start_alarm_id occur_unixtime:time alert_type:type alert_category:category alarm_level:level alarm_flag:flag in:db];
            
            //修改水位线
            [self saveWaterWithAlertId:start_alarm_id occur_unixtime:time update_unixtime:time  category:category level:level duration:duration type:type flag:flag in:db];
        }
        else
        {
            NSString *uuid =  [SynECGUtils uuidString];
            [self saveAlertWithAlarmId:uuid start_alarm_id:uuid occur_unixtime:time -  duration alert_type:type alert_category:category alarm_level:level alarm_flag:0 in:db];
            [self saveWaterWithAlertId:uuid occur_unixtime:time -  duration update_unixtime:time category:category level:level duration:0 type:type flag:0 in:db];
            
            
            //传结束
            
            [self saveAlarmWithTime:time type:type category:category level:level flag:flag duration:duration in:db];

        }
        
    }
    else
    {
        NSString *uuid =  [SynECGUtils uuidString];
        [self saveAlertWithAlarmId:uuid start_alarm_id:uuid occur_unixtime:time alert_type:type alert_category:category alarm_level:level alarm_flag:flag in:db];
        [self saveWaterWithAlertId:uuid occur_unixtime:time update_unixtime:time category:category level:level duration:duration type:type flag:flag in:db];
    
    }
    
}

//。。。。。。。。。。。。。。早搏类的,心跳过速或过缓。。。。。。。。。。。。。。。。。
- (void)savePrematureBeatAlarmWithTime:(long long)time type:(NSString *)type category:(NSString *)category level:(NSInteger)level flag:(NSInteger)flag duration:(NSInteger)duration in:(FMDatabase *)db
{

    if (flag == 1) {
        
        //查找该类然后修改
        NSString *start_alarm_id = [[NSString alloc]init];
        long long startTime = 0;
        NSString *query = [NSString stringWithFormat:@"select * from %@ where alert_type = '%@' and alarm_flag = '%@'",ALARM_TABLE,type,@(0)];
        FMResultSet *rs = [db executeQuery:query];
        int num = 0;
        while ([rs next]) {
            
            start_alarm_id = [rs stringForColumn:@"start_alarm_id"];
            startTime = [rs longLongIntForColumn:@"update_unixtime"];
            
            num ++;
        }
        if (num > 0)
        {

            //保存到上传库
            [[SynAlarmUploadManager sharedInstance] saveAlertWithAlarmId:[SynECGUtils uuidString] start_alarm_id:start_alarm_id occur_unixtime:time alert_type:type alert_category:category alarm_level:level alarm_flag:flag in:db];
            
            //修改水位线
            [self saveWaterWithAlertId:start_alarm_id occur_unixtime:time update_unixtime:time category:category level:level duration:time - startTime type:type flag:flag in:db];
            
        }
        else
        {
        }
    }
    else
    {
        
        
        //查找该类然后修改
        NSString *start_alarm_id = [[NSString alloc]init];
        long long startTime = 0;
        long long updateTime = 0;
        NSString *query = [NSString stringWithFormat:@"select * from %@ where alert_type = '%@' and alarm_flag = '%@'",ALARM_TABLE,type,@(0)];
        FMResultSet *rs = [db executeQuery:query];
        int num = 0;
        while ([rs next]) {
            
            start_alarm_id = [rs stringForColumn:@"start_alarm_id"];
            startTime = [rs longLongIntForColumn:@"occur_unixtime"];
            updateTime = [rs longLongIntForColumn:@"update_unixtime"];
            
            num ++;
        }
        if (num > 0)
        {
        
            [self changeAlertWithAlarmId:start_alarm_id update_unixtime:time alert_category:category alert_type:type alarm_flag:0 in:db];
            //修改水位线
            [self saveWaterWithAlertId:start_alarm_id occur_unixtime:startTime update_unixtime:time category:category level:level duration:time - updateTime type:type flag:flag in:db];
            
        }
        else
        {
            //保存到本地库
            NSString *uuid = [SynECGUtils uuidString];
            [self saveAlertWithAlarmId:uuid start_alarm_id:uuid occur_unixtime:time alert_type:type alert_category:category alarm_level:level alarm_flag:flag in:db];
            //修改水位线
            [self saveWaterWithAlertId:uuid occur_unixtime:time update_unixtime:time category:category level:level duration:duration type:type flag:flag in:db];
        }
    }
}


- (void)saveWaterWithAlertId:(NSString *)alertId occur_unixtime:(long long)occur_unixtime update_unixtime:(long long)update_unixtime category:(NSString *)category level:(NSInteger)level duration:(float)duration type:(NSString *)type flag:(NSInteger)flag in:(FMDatabase *)db
{
    
    NSString *query = [NSString stringWithFormat:@"select * from %@ where alert_mark_category = '%@'",WATER_TABLE,category];
    FMResultSet *rs = [db executeQuery:query];
    NSInteger oldLevel = -1;
    NSString *oldType =[[NSString alloc]init];
    NSInteger old_seq = 0;
    NSInteger oldDuratain = 0;
    long long oldTime = 0;
    NSInteger oldFlag = -1;
    NSInteger oldEnd = 0;
    NSString *oldAlert_id = [[NSString alloc]init];
    while ([rs next]) {
        oldLevel = [rs intForColumn:@"alert_mark_level"];
        old_seq = [rs intForColumn:@"seq_no"];
        oldType = [rs stringForColumn:@"alert_type"];
        oldDuratain = (NSInteger)[rs longLongIntForColumn:@"duration_msec"];
        oldTime = [rs longLongIntForColumn:@"occur_unixtime"];
        oldFlag = (NSInteger)[rs intForColumn:@"alert_flag"];
        oldAlert_id = [rs stringForColumn:@"alert_id"];
        oldEnd = (NSInteger)[rs longLongIntForColumn:@"end_unixtime"];
    }
    if (oldLevel >= 0)
    {
        if (oldLevel < level)
        {
            NSString *updateSql1= [NSString stringWithFormat:
                                   @"UPDATE %@ SET alert_id = '%@',alert_mark_level = '%@', seq_no = '%@',duration_msec = '%@',  occur_unixtime = '%@', alert_type = '%@', alert_flag = '%@' WHERE alert_mark_category = '%@'",WATER_TABLE,alertId,@(level),@(old_seq + 1),@(duration),@(occur_unixtime),[@"" alertType:type],@(flag),category];
            BOOL succeed = [db executeUpdate:updateSql1];
            if (succeed)
            {
                [[SynWaterUploadManager sharedInstance]uploadWaterWithCategory:category in:db];
            }
            
        }
        else if(oldLevel == level)
        {
            if (flag == 0)
            {

                if (oldFlag == 0) {
                    
                    if ([oldAlert_id isEqualToString:alertId]) {
                        //更新告警时间
                        if ([oldType containsString:[@"" alertType:type]]) {
                            
                            NSString *updateSql1= [NSString stringWithFormat:
                                                   @"UPDATE %@ SET alert_id = '%@', seq_no = '%@',duration_msec = '%@', alert_flag = '%@'WHERE alert_mark_category = '%@'",WATER_TABLE,alertId,@(old_seq + 1),@(duration + oldDuratain),@(flag),category];
                            BOOL succeed = [db executeUpdate:updateSql1];
                            if (succeed)
                            {
                                
                                [[SynWaterUploadManager sharedInstance]uploadWaterWithCategory:category in:db];
                            }
                        }
                        else
                        {
                            NSString *allString = [[NSString alloc]initWithFormat:@"%@,%@",oldType,[@"" alertType:type]];
                            NSString *updateSql1= [NSString stringWithFormat:
                                                   @"UPDATE %@ SET alert_id = '%@', seq_no = '%@',duration_msec = '%@', alert_type = '%@', alert_flag = '%@' WHERE alert_mark_category = '%@'",WATER_TABLE,alertId,@(old_seq + 1),@(duration + oldDuratain),allString,@(flag),category];
                            BOOL succeed = [db executeUpdate:updateSql1];
                            if (succeed)
                            {
                                
                                
                                [[SynWaterUploadManager sharedInstance]uploadWaterWithCategory:category in:db];
                                
                            }
                        }
                    }
                    else
                    {
                        //新告警
                        
                        if(oldTime < occur_unixtime)
                        {
                            //新的告警比老的告警时间晚 更新type
                            if ([oldType containsString:[@"" alertType:type]]) {
                                
                            }
                            else
                            {
                                NSString *allString = [[NSString alloc]initWithFormat:@"%@,%@",oldType,[@"" alertType:type]];
                                NSString *updateSql1= [NSString stringWithFormat:
                                                       @"UPDATE %@ SET seq_no = '%@', alert_type = '%@' WHERE alert_mark_category = '%@'",WATER_TABLE,@(old_seq + 1),allString,category];
                                BOOL succeed = [db executeUpdate:updateSql1];
                                if (succeed)
                                {
                                    [[SynWaterUploadManager sharedInstance]uploadWaterWithCategory:category in:db];
                                    
                                }
                            }
                            
                            
                            
                        }
                        else
                        {
                            //新的告警比老的告警时间早 更新时间
                            if ([oldType containsString:[@"" alertType:type]])
                            {
                                
                                NSString *updateSql1= [NSString stringWithFormat:
                                                       @"UPDATE %@ SET alert_id = '%@', seq_no = '%@', occur_unixtime = '%@', alert_flag = '%@' WHERE alert_mark_category = '%@'",WATER_TABLE,alertId,@(old_seq + 1),@(occur_unixtime),@(flag),category];
                                BOOL succeed = [db executeUpdate:updateSql1];
                                if (succeed)
                                {
                                    [[SynWaterUploadManager sharedInstance]uploadWaterWithCategory:category in:db];
                                }
                            }
                            else
                            {
                                NSString *allString = [[NSString alloc]initWithFormat:@"%@,%@",oldType,[@"" alertType:type]];
                                NSString *updateSql1= [NSString stringWithFormat:
                                                       @"UPDATE %@ SET alert_id = '%@', seq_no = '%@', occur_unixtime = '%@', alert_type = '%@', alert_flag = '%@' WHERE alert_mark_category = '%@'",WATER_TABLE,alertId,@(old_seq + 1),@(occur_unixtime),allString,@(flag),category];
                                BOOL succeed = [db executeUpdate:updateSql1];
                                if (succeed)
                                {
                                    [[SynWaterUploadManager sharedInstance]uploadWaterWithCategory:category in:db];
                                }
                            }
                            
                            
                            
                        }
                        
                    }
                    
                }
                else
                {
                    long long durationCZ = 0;
                    if (update_unixtime > oldEnd && occur_unixtime < oldEnd) {
                        
                        durationCZ = update_unixtime - oldEnd;
                    }
        
                    if ([oldType containsString:[@"" alertType:type]])
                    {
                        
                        NSString *updateSql1= [NSString stringWithFormat:
                                               @"UPDATE %@ SET alert_id = '%@', seq_no = '%@', occur_unixtime = '%@', alert_flag = '%@',duration_msec = '%@' WHERE alert_mark_category = '%@'",WATER_TABLE,alertId,@(old_seq + 1),@(occur_unixtime),@(flag),@(oldDuratain + durationCZ),category];
                        BOOL succeed = [db executeUpdate:updateSql1];
                        if (succeed)
                        {
                            [[SynWaterUploadManager sharedInstance]uploadWaterWithCategory:category in:db];
                        }
                    }
                    else
                    {
                        NSString *allString = [[NSString alloc]initWithFormat:@"%@,%@",oldType,[@"" alertType:type]];
                        NSString *updateSql1= [NSString stringWithFormat:
                                               @"UPDATE %@ SET alert_id = '%@', seq_no = '%@', occur_unixtime = '%@', alert_type = '%@', alert_flag = '%@',duration_msec = '%@' WHERE alert_mark_category = '%@'",WATER_TABLE,alertId,@(old_seq + 1),@(occur_unixtime),allString,@(flag),@(oldDuratain + durationCZ),category];
                        BOOL succeed = [db executeUpdate:updateSql1];
                        if (succeed)
                        {
                            [[SynWaterUploadManager sharedInstance]uploadWaterWithCategory:category in:db];
                        }
                    }
                    
                }
                
                
            }
            else
            {
                
                if ([oldAlert_id isEqualToString:alertId]) {
                    
                    if ([oldType containsString:[@"" alertType:type]]) {
                        
                        NSString *updateSql1= [NSString stringWithFormat:
                                               @"UPDATE %@ SET alert_id = '%@', seq_no = '%@',duration_msec = '%@', alert_flag = '%@',end_unixtime = '%@' WHERE alert_mark_category = '%@'",WATER_TABLE,alertId,@(old_seq + 1),@(duration + oldDuratain),@(flag),@(occur_unixtime),category];
                        BOOL succeed = [db executeUpdate:updateSql1];
                        if (succeed)
                        {
                            
                            [[SynWaterUploadManager sharedInstance]uploadWaterWithCategory:category in:db];
                        }
                    }
                    else
                    {
                        NSString *allString = [[NSString alloc]initWithFormat:@"%@,%@",oldType,[@"" alertType:type]];
                        NSString *updateSql1= [NSString stringWithFormat:
                                               @"UPDATE %@ SET alert_id = '%@', seq_no = '%@',duration_msec = '%@', alert_type = '%@', alert_flag = '%@', end_unixtime = '%@' WHERE alert_mark_category = '%@'",WATER_TABLE,alertId,@(old_seq + 1),@(duration + oldDuratain),allString,@(flag),@(occur_unixtime),category];
                        BOOL succeed = [db executeUpdate:updateSql1];
                        if (succeed)
                        {
                            
                            
                            [[SynWaterUploadManager sharedInstance]uploadWaterWithCategory:category in:db];
                            
                        }
                    }
                    
                }
                else
                {
                    
                    if (oldFlag != 0 ) {
                        
                        if (occur_unixtime < oldTime ) {
                            
                            
                            long long du = occur_unixtime - oldTime;
                            NSInteger result= du<duration?du:duration;
                            
                            //排重
                            if ([oldType containsString:[@"" alertType:type]]) {
                                
                                
                                NSString *updateSql1= [NSString stringWithFormat:
                                                       @"UPDATE %@ SET alert_id = '%@', seq_no = '%@',duration_msec = '%@', alert_flag = '%@'WHERE alert_mark_category = '%@'",WATER_TABLE,alertId,@(old_seq + 1),@(result + oldDuratain),@(flag),category];
                                BOOL succeed = [db executeUpdate:updateSql1];
                                if (succeed)
                                {
                                    
                                    [[SynWaterUploadManager sharedInstance]uploadWaterWithCategory:category in:db];
                                }
                            }
                            else
                            {
                                NSString *allString = [[NSString alloc]initWithFormat:@"%@,%@",oldType,[@"" alertType:type]];
                                NSString *updateSql1= [NSString stringWithFormat:
                                                       @"UPDATE %@ SET alert_id = '%@', seq_no = '%@',duration_msec = '%@', alert_type = '%@', alert_flag = '%@'WHERE alert_mark_category = '%@'",WATER_TABLE,alertId,@(old_seq + 1),@(result + oldDuratain),allString,@(flag),category];
                                BOOL succeed = [db executeUpdate:updateSql1];
                                if (succeed)
                                {
                                    
                                    
                                    [[SynWaterUploadManager sharedInstance]uploadWaterWithCategory:category in:db];
                                    
                                }
                            }
                            
                        }
                        else
                        {
                            
                        }
                        
                    }
                    else
                    {
                        
                        
                    }
                }
            }
        }
        else
        {
            
        }

    }
    else
    {

        BOOL save = [db executeUpdate:@"INSERT INTO water_two (user_id, target_id, record_id, alert_mark_id, alert_id, alert_mark_level, seq_no, duration_msec, alert_mark_category, occur_unixtime, alert_flag, alert_type) VALUES (?,?,?,?,?,?,?,?,?,?,?,?);",[SynECGLibSingleton sharedInstance].user_id,[SynECGLibSingleton sharedInstance].target_id,[SynECGLibSingleton sharedInstance].record_id,[SynECGUtils uuidString],alertId,@(level),@(0),@(duration),category,@(occur_unixtime),@(flag),[@"" alertType:type]];
        if (save) {
            //上传
            [[SynWaterUploadManager sharedInstance]uploadWaterWithCategory:category in:db];
        }

    }
}

//保存告警并上传
- (void)saveAlertWithAlarmId:(NSString *)alarm_id start_alarm_id:(NSString *)start_alarm_id occur_unixtime:(long long)occur_unixtime alert_type:(NSString *)alert_type alert_category:(NSString *)alert_category alarm_level:(NSInteger)alarm_level alarm_flag:(NSInteger)alarm_flag in:(FMDatabase *)db
{
    
    //保存
    [db executeUpdate:@"INSERT INTO alarm_two (user_id, target_id, record_id, alarm_id, start_alarm_id, occur_unixtime,alert_type,alert_category,alarm_level,alarm_flag,update_unixtime) VALUES (?,?,?,?,?,?,?,?,?,?,?);",[SynECGLibSingleton sharedInstance].user_id,[SynECGLibSingleton sharedInstance].target_id,[SynECGLibSingleton sharedInstance].target_id,alarm_id,start_alarm_id,@(occur_unixtime),alert_type,alert_category,@(alarm_level),@(alarm_flag),@(occur_unixtime)];
    
    //上传
    [[SynAlarmUploadManager sharedInstance] saveAlertWithAlarmId:alarm_id start_alarm_id:start_alarm_id occur_unixtime:occur_unixtime alert_type:alert_type alert_category:alert_category alarm_level:alarm_level alarm_flag:alarm_flag in:db];
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (alarm_level >= 2) {
        
                
                NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
                [dic setObject:@(alarm_level) forKey:@"alert_mark_level"];
                [dic setObject:alert_category forKey:@"alert_mark_category"];
                [dic setObject:alert_type forKey:@"alert_mark_type"];
                
                
                NSNotification *notification =[NSNotification notificationWithName:@"Syn_Alert_Notification" object:nil userInfo:dic];
                [[NSNotificationCenter defaultCenter] postNotification:notification];
        
        }
    });
    
    
    
}

//保存告警不上传
- (void)changeAlertWithAlarmId:(NSString *)alarm_id update_unixtime:(long long)update_unixtime alert_category:(NSString *)alert_category alert_type:(NSString *)alert_type alarm_flag:(NSInteger)alarm_flag in:(FMDatabase *)db
{

    
    NSString *updateSql1= [NSString stringWithFormat:
                           @"UPDATE %@ SET update_unixtime = '%@' where alert_category = '%@' and alarm_flag = '%@' and alert_type = '%@'",ALARM_TABLE,@(update_unixtime),alert_category,@(alarm_flag),alert_type];
    BOOL succeed = [db executeUpdate:updateSql1];
    
    if (!succeed) {
        
        [self changeAlertWithAlarmId:alarm_id update_unixtime:update_unixtime alert_category:alert_category alert_type:alert_type alarm_flag:alarm_flag in:db];
    }
    
    
    
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


#pragma mark------------数据保存
- (void)comeHome:(UIApplication *)application {
    NSLog(@"进入后台");
    [self saveMessage];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"程序被杀死");
    [self saveMessage];
}

- (void)closeBlooth
{
    [self saveMessage];
}

- (void)saveMessage
{
    [SynECGUtils saveStartType:self.unsinusType];
    
    if (self.sinusArray.count > 0) {
        
        [SynECGUtils saveStartPosition1:self.sinusArray.firstObject];
    }
    else
    {
        [SynECGUtils saveStartPosition1:@(0)];
    }
    
    if (self.unsinusArray.count > 0) {
        
        [SynECGUtils saveStartPosition2:self.unsinusArray.firstObject];
    }
    else
    {
        [SynECGUtils saveStartPosition2:@(0)];
    }

    NSLog(@"杀死前保存成功");
}



@end
