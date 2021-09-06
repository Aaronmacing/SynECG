//
//  ECGDecodeManager.m
//  SynECG
//
//  Created by LiangXiaobin on 16/6/30.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import "ECGDecodeManager.h"
#import "SynECGUtils.h"
#import "NSString+EnumSynEcg.h"
#import "SynECGLibSingleton.h"
#import "SynConstant.h"
#import "HAEventManager.h"
#import "ECGHRManager.h"
#import "ECGRRManager.h"
#import "SynAlarmOperationModel.h"
#import "ECGBreathUpload.h"
#import "ECGEnergryManager.h"
#import "SDBManager.h"
#import "SportDataManager.h"


#define hrNum 10

@interface ECGDecodeManager ()
{
    NSInteger maxAndMinBpm;
    NSInteger tempHR;
    FMDatabaseQueue *queue;
    NSInteger timeAdd;
    NSInteger lastKB;

}

@end

@implementation ECGDecodeManager

+ (instancetype)sharedInstance
{
    static ECGDecodeManager * sharedInstance = nil;
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
        maxAndMinBpm = 0;
        timeAdd = 0;
        lastKB = 0;
        _time_flag = 0;
        queue = [SDBManager defaultDBManager].queue;
        _eventQueue = dispatch_queue_create("decodeEvent", DISPATCH_QUEUE_SERIAL);
        _annQueue = dispatch_queue_create("decodeAnn", DISPATCH_QUEUE_SERIAL);
        _p15 = 0;
        _p30 = 0;
        _p60 = 0;
        _rrp = 0;
        _eventTempData = [[NSMutableData alloc]init];
        _parseing = NO;
        _needReturn = NO;
        
        _enengyQueue = dispatch_queue_create("decodeenergy", DISPATCH_QUEUE_SERIAL);
        _eventTempQueue = dispatch_queue_create("eventTempQueue", DISPATCH_QUEUE_SERIAL);
//        _breathQueue = dispatch_queue_create("decodeBreath", DISPATCH_QUEUE_SERIAL);
        _hrQueue = dispatch_queue_create("decodeHR", DISPATCH_QUEUE_SERIAL);
        _ecgQueue = dispatch_queue_create("decodeECG", DISPATCH_QUEUE_SERIAL);
        _nowPosition = 0;
        _rrNUm = 0;
    }
    return self;
}

- (void)loadSECGMessageFromData:(NSData *)date
{
    if (date.length < 1) {
        
    }
    else
    {
        if((date.length - 5) % 3 == 0)
        {
            dispatch_async(_ecgQueue, ^{
            
                NSMutableData *updata   = [NSMutableData new];
                
                int index = [self intFromDataReverse:[date subdataWithRange:NSMakeRange(1, 4)]];

                if (index > [SynECGLibSingleton sharedInstance].ecgInt + [ECGHRManager sharedInstance].tempSaveData.length / 2) {

                    NSLog(@"走一次加0");
                    
                    NSMutableData *dataDelete = [[NSMutableData alloc] initWithLength:(index - ([SynECGLibSingleton sharedInstance].ecgInt + [ECGHRManager sharedInstance].tempSaveData.length / 2)) * 2];
                    [[ECGHRManager sharedInstance].tempSaveData appendData:dataDelete];
                }
                else if(index < [SynECGLibSingleton sharedInstance].ecgInt + [ECGHRManager sharedInstance].tempSaveData.length / 2)
                {
                    NSLog(@"走一次cut");
                    
                    if([SynECGLibSingleton sharedInstance].ecgInt + [ECGHRManager sharedInstance].tempSaveData.length / 2 - index <= [ECGHRManager sharedInstance].tempSaveData.length / 2)
                    {
                        
                        [[ECGHRManager sharedInstance].tempSaveData replaceBytesInRange:NSMakeRange(0, ([SynECGLibSingleton sharedInstance].ecgInt + [ECGHRManager sharedInstance].tempSaveData.length / 2 - index) * 2) withBytes:NULL length:0];
                    }
                    else
                    {
                    
                       [[ECGHRManager sharedInstance].tempSaveData replaceBytesInRange:NSMakeRange(0,[ECGHRManager sharedInstance].tempSaveData.length / 2) withBytes:NULL length:0];
                    }
                }
                else
                {

                }
                
                    Byte *c = (Byte*)[date bytes];
                    for (int i = 5; i<date.length-2; i+=3) {
                        @autoreleasepool {
                            short  a = (((short)(char)c[i])<<4)|((c[i+1]>>4)&0x0f);
                            short  b = (((short)((char)(c[i+1]<<4))<<4)&0xff00)|(c[i+2]&0x00ff);
                            short  c = a*2048/273;
                            short  e = b*2048/273;
                            Byte d[4];
                            d[0] = (Byte)(c>>8)&0x0ff;
                            d[1]= (Byte)c&0x0ff;
                            d[2]= (Byte)(e>>8)&0x0ff;
                            d[3]= (Byte)e&0x0ff;
                            NSData *data = [NSData dataWithBytes:d length:4];
                            [updata appendData:data];
                        }
                    }
                
                BlockWeakSelf(self);

                [[ECGHRManager sharedInstance] saveDateInRecordId:[SynECGLibSingleton sharedInstance].record_id withData:updata];
                self.time_flag = self.time_flag + updata.length / 2;
        
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(syn_ecgDecodeMessageOnECG:)])
                    {
                        NSMutableData *data11 = [[NSMutableData alloc] initWithData:date];
                        [data11 replaceBytesInRange:NSMakeRange(1,3) withBytes:NULL length:0];
                        [weakSelf.delegate syn_ecgDecodeMessageOnECG:data11];
                    }
                });
            
            });
        }
    }
}

- (int) intFromDataReverse:(NSData *)data
{
    int intSize = sizeof(int);// change it to fixe length
    unsigned char * buffer = malloc(intSize * sizeof(unsigned char));
    [data getBytes:buffer length:intSize];
    int num = 0;
    for (int i = intSize - 1; i >= 0; i--) {
        num = (num << 8) + buffer[i];
    }
    free(buffer);
    return num;
}



- (void)loadECGMessageFromData:(NSData *)date
{
    dispatch_async(_ecgQueue, ^{
        
        NSMutableData *updata   = [NSMutableData new];
        
        if (date.length < 1) {
            
        }
        else
        {
            Byte *c = (Byte*)[date bytes];
            for (int i = 2; i<date.length-2; i+=3) {
                @autoreleasepool {
                    short  a = (((short)(char)c[i])<<4)|((c[i+1]>>4)&0x0f);
                    short  b = (((short)((char)(c[i+1]<<4))<<4)&0xff00)|(c[i+2]&0x00ff);
                    short  c = a*2048/273;
                    short  e = b*2048/273;
                    Byte d[4];
                    d[0] = (Byte)(c>>8)&0x0ff;
                    d[1]= (Byte)c&0x0ff;
                    d[2]= (Byte)(e>>8)&0x0ff;
                    d[3]= (Byte)e&0x0ff;
                    NSData *data = [NSData dataWithBytes:d length:4];
                    [updata appendData:data];
                }
            }
        }
        
            
    BlockWeakSelf(self);

    [[ECGHRManager sharedInstance] saveDateInRecordId:[SynECGLibSingleton sharedInstance].record_id withData:updata];
    
    self.time_flag = self.time_flag + updata.length / 2;
        
    dispatch_async(dispatch_get_main_queue(), ^{
                
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(syn_ecgDecodeMessageOnECG:)])
                {
                    [weakSelf.delegate syn_ecgDecodeMessageOnECG:date];
                }
            });
    });
    
}


int16_t swap_int16( int16_t val )
{
    return (val << 8) | ((val >> 8) & 0xFF);
}

- (void)loadAct_V5DataWithData:(NSData *)message
{
    
    if ([SynECGLibSingleton sharedInstance].deviceVerType != 2) {
        
        [SynECGLibSingleton sharedInstance].deviceVerType = 2;
    }
    
    
    BlockWeakSelf(self);
    
    dispatch_async(_enengyQueue, ^{
        
        
        if ([SynECGLibSingleton sharedInstance].typeIndex == 0) {
         
            NSData *typeData = [message subdataWithRange:NSMakeRange(1, 1)];
            int type = 0;
            [typeData getBytes:&type length:sizeof(type)];
            
            [SynECGLibSingleton sharedInstance].typeIndex = type;
            
        }
        
        
        NSData *indexData = [message subdataWithRange:NSMakeRange(2, 4)];
        int index = 0;
        [indexData getBytes:&index length:sizeof(index)];

        for (int i = 0; i < (message.length - 6 ) / 24; i++) {
            //运动状态
            NSData * data1 =[message subdataWithRange:NSMakeRange(6 + 24 * i, 1)];
            NSString *string = [SynECGUtils hexadecimalString:data1];
            
            
            //步数
            NSData *data2 = [message subdataWithRange:NSMakeRange(7 + 24 * i, 3)];
            int b = 0;
            [data2 getBytes:&b length:sizeof(b)];
            //能量
            NSData *data3 = [message subdataWithRange:NSMakeRange(10 + 24 * i, 4)];
            int c = 0;
            [data3 getBytes:&c length:sizeof(c)];
            
            NSData *data4 = [message subdataWithRange:NSMakeRange(14 + 24 * i, 16)];

           
            NSInteger keyNo = index + i;
            
            
            [SynECGLibSingleton sharedInstance].activityType = [@"" acticityByType:string];
            
            NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
            [dic setObject:string forKey:@"activity_type"];
            [dic setObject:[NSNumber numberWithFloat:b] forKey:@"steps"];
            [dic setObject:[NSNumber numberWithFloat:c / 1000] forKey:@"energy"];
           
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.delegate &&[weakSelf.delegate respondsToSelector:@selector(syn_ecgDecodeMessageOnActivityValue:)]) {
                    [weakSelf.delegate syn_ecgDecodeMessageOnActivityValue:dic];
                }
                
            });
            
            [[SportDataManager sharedInstance] saveDateInIndex:keyNo withData:data4];

            [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {


                NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (user_id, record_id, keyNo, activity_type, kcal, step) VALUES (?, ?, ?, ?, ?, ?);",ENERGY_TABLE];
                [db executeUpdate:sql,[SynECGLibSingleton sharedInstance].user_id,[SynECGLibSingleton sharedInstance].record_id,@(keyNo),[SynECGLibSingleton sharedInstance].activityType,@(c),@(b)];


                [self changeTable:TOTAL_TABLE Column:@"act" value:@(1) inDB:db];


                if ((keyNo + 1) % 60 == 0) {
                    [[ECGEnergryManager sharedInstance] uploadEnergryMessageIn:db];


                    if ((keyNo + 1) % 300 == 0) {

                        [[SportDataManager sharedInstance] uploadWithIndex:index / 300 In:db];

                    }


                }
            
            }];
            
        }
        
        
    });
}


- (void)loadHeartRateDataWithData:(NSData *)message
{
    BlockWeakSelf(self);
   dispatch_async(_hrQueue, ^{
      
       NSMutableArray *array = [NSMutableArray new];
       for (int i = 0; i<message.length - 1; i+=4) {
           int a ;
           [[message subdataWithRange:NSMakeRange(1+i,4)] getBytes:&a length:sizeof(a)];
           [array addObject:[NSNumber numberWithInt:a]];
       }
       
       [self setAverageHeartRatewithArray:array];
       [self getInstantaneousHeartRateWithArray:array];
       
       [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
           [weakSelf changeTable:TOTAL_TABLE Column:@"hr" value:@(array.count) inDB:db];
       }];
   });
}

//计算最大最小心率
- (void)getMaxAndMinWithData:(NSNumber *)data
{
    
        if (!_maxAndMinArray) {
            _maxAndMinArray = [[NSMutableArray alloc]init];
        }
    
        if(_maxAndMinArray.count == 0)
        {
            [_maxAndMinArray addObject:data];
        }
        else
        {
            if(0.2 * 256 < [data floatValue] - [_maxAndMinArray.lastObject floatValue] && [data floatValue] - [_maxAndMinArray.lastObject floatValue] < 2 * 256)
            {
                if (_maxAndMinArray.count >= hrNum) {
                    
                    [_maxAndMinArray removeObjectAtIndex:0];
                }
                [_maxAndMinArray addObject:data];
            }
            else
            {
                if (_maxAndMinArray.count > 0) {
                 
                
                    [_maxAndMinArray removeAllObjects];
                }
                [_maxAndMinArray addObject:data];
            }
        }
        
        if (_maxAndMinArray.count >= hrNum) {
            
            int model0 = [_maxAndMinArray.firstObject intValue];
            int model9 = [_maxAndMinArray.lastObject intValue];
            
            NSInteger a = 60 * 256 * (self.maxAndMinArray.count - 1) / (model9 - model0);
            maxAndMinBpm = a;
            if ( [SynECGLibSingleton sharedInstance].maxBpm < a)
            {
                
                NSString *time = [SynECGUtils setOccerTimeFromPastSeconds:[data integerValue] / 256];            [SynECGLibSingleton sharedInstance].maxBpm = a;
                [[SynECGLibSingleton sharedInstance].heartRateMessage setObject:[SynECGLibSingleton sharedInstance].activityType forKey:@"maxSportType"];
                
                [[SynECGLibSingleton sharedInstance].heartRateMessage setObject:@(a) forKey:@"maxBpm"];
                
                [[SynECGLibSingleton sharedInstance].heartRateMessage setObject:time forKey:@"maxBpmTime"];
                
            }
            
            if ( [SynECGLibSingleton sharedInstance].minBpm > a)
            {
                
                NSString *time =[SynECGUtils setOccerTimeFromPastSeconds:[data integerValue] / 256];
                [SynECGLibSingleton sharedInstance].minBpm = a;
                [[SynECGLibSingleton sharedInstance].heartRateMessage setObject:[SynECGLibSingleton sharedInstance].activityType forKey:@"minSportType"];
                [[SynECGLibSingleton sharedInstance].heartRateMessage setObject:@(a) forKey:@"minBpm"];
                [[SynECGLibSingleton sharedInstance].heartRateMessage setObject:time forKey:@"minBpmTime"];
            }
            
        }


}



//计算瞬时心率
- (void)getInstantaneousHeartRateWithArray:(NSArray *)array
{
    if (!_tempArray)
    {
        _tempArray = [[NSMutableArray alloc]init];
    
    }
    
    if(_tempArray.count == 0)
    {
        [_tempArray addObjectsFromArray:array];
    }
    else
    {
        for (int i = 0; i < array.count; i++) {
         
            if(0.2 * 256 < [array[i] floatValue] - [_tempArray.lastObject floatValue] && [array[i] floatValue] - [_tempArray.lastObject floatValue] < 2 * 256)
            {
                if (_tempArray.count >= hrNum) {
                    
                    [_tempArray removeObjectAtIndex:0];
                }
                [_tempArray addObject:array[i]];
            }
            else
            {
                [_tempArray removeAllObjects];
                [_tempArray addObject:array[i]];
            }
        }
    }
    
    if (_tempArray.count >= hrNum) {
        
        int model1 = [_tempArray.firstObject intValue];
        int model5 = [_tempArray.lastObject intValue];
        
        NSInteger a = 60 * (_tempArray.count - 1) * 256;
        NSInteger b = (model5 - model1);
        
        tempHR = a / b;
        
        [[SynECGLibSingleton sharedInstance].heartRateMessage setObject:[SynECGLibSingleton sharedInstance].activityType forKey:@"sportType"];
        [[SynECGLibSingleton sharedInstance].heartRateMessage setObject:@(tempHR) forKey:@"nowBpm"];
        
        BlockWeakSelf(self);
        dispatch_async(dispatch_get_main_queue(), ^{
           
            if (weakSelf.delegate &&[weakSelf.delegate respondsToSelector:@selector(syn_ecgDecodeMessageOnHRValue:)]) {
                [weakSelf.delegate syn_ecgDecodeMessageOnHRValue:[SynECGLibSingleton sharedInstance].heartRateMessage];
            }
            
        });
    }

}


//计算一分钟的平均心率
- (void)setAverageHeartRatewithArray:(NSArray *)array
{
//    if (!_totalArray)
//    {
//        _totalArray = [[NSMutableArray alloc]init];
//        
//    }
//   
//    if(_totalArray.count == 0)
//    {
//        [_totalArray addObjectsFromArray:array];
//    }
//    else
//    {
//        for (int i = 0; i < array.count; i++) {
//            
//            if(0.2 * 256 < [array[i] floatValue] - [_totalArray.lastObject floatValue] && [array[i] floatValue] - [_totalArray.lastObject floatValue] < 2 * 256)
//            {
//                if (_totalArray.count >= hrNum) {
//                    
//                    [_totalArray removeObjectAtIndex:0];
//                }
//                [_totalArray addObject:array[i]];
//            }
//            else
//            {
//                [_totalArray removeAllObjects];
//                [_totalArray addObject:array[i]];
//            }
//        }
//    }
//    
//    if (_totalArray.count >= 60) {
//        
//        int model1 = [_totalArray.firstObject intValue];
//        int model5 = [_totalArray.lastObject intValue];
//        
//        NSInteger a = 60 * (_tempArray.count - 1) * 256;
//        NSInteger b = (model5 - model1);
//        
//        [SynECGLibSingleton sharedInstance].averageHR = a / b;
//        
//    }
//    else
//    {
          [SynECGLibSingleton sharedInstance].averageHR = maxAndMinBpm;
//    }
    

}

//查询字段
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



//修改字段
- (void)changeTable:(NSString *)tableName  Column:(NSString *)columnName value:(NSNumber *)value inDB:(FMDatabase *)db
{
    NSString *updateSql = [NSString stringWithFormat:
                           @"UPDATE %@ set %@ = %@ + '%@' WHERE recordId = '%@'",tableName,columnName,columnName,value,[SynECGLibSingleton sharedInstance].record_id];
    [db executeUpdate:updateSql];
}


//蓝牙4.2的新解析
//新的事件数据
- (void)loadNewEventDataFromData:(NSData *)message{
    
    if ([SynECGLibSingleton sharedInstance].deviceVerType != 0) {
        
        [SynECGLibSingleton sharedInstance].deviceVerType = 0;
    }
    
    
    NSMutableData *allData = [NSMutableData new];
    
    if (message.length > 37) {
        int startIndex = 0;
        [[message subdataWithRange:NSMakeRange(1, 4)] getBytes:&startIndex length:sizeof(startIndex)];
        for (int i = 0; i< (message.length-5)/32; i++) {
            if (i == 0) {
                [allData appendData:[message subdataWithRange:NSMakeRange(1, 36)]];
            }else{
                startIndex = startIndex + 1;
                Byte b = (Byte) ((startIndex) & 0xFF);
                Byte c = (Byte) ((startIndex>>8)& 0xFF);
                Byte d = (Byte) ((startIndex>>16)& 0xFF);
                Byte f = (Byte) (startIndex>>24 & 0xFF);
                Byte g[]= {b,c,d,f};
                NSData *dataIndex =[NSData dataWithBytes:&g length:sizeof(g)];
                [allData appendData:dataIndex];
                [allData appendData:[message subdataWithRange:NSMakeRange(37+(i - 1)*32, 32)]];
                
                
            }
        }
        [self.eventTempData appendData:allData];
    }
    else if(message.length > 0)
    {
        [self.eventTempData appendData:[message subdataWithRange:NSMakeRange(1, 36)]];
    }
  
    if (self.parseing == NO && self.eventTempData.length >= 36) {
    
        self.parseing = YES;

    
        NSData *subData =[self.eventTempData subdataWithRange:NSMakeRange(0, 36)];
        /*解析*/
        Byte *allbyte = (Byte*)[subData bytes];
  
        int index;
        [[subData subdataWithRange:NSMakeRange(0, 4)] getBytes:&index length:sizeof(index)];
        
        
        int activity = allbyte[4];
        
        NSString *act = [@"" acticity:activity];
        
        unsigned char *bs = (unsigned char *)[[subData subdataWithRange:NSMakeRange(5, 1) ] bytes];
        int eventType = *bs;//34
        
        if (eventType < 42) {
            
            
            
            dispatch_async(_eventQueue, ^{
                
                [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    
                    
                    [self changeTable:TOTAL_TABLE Column:@"event" value:@(1) inDB:db];
                    
                }];
            });

            
            
            if (self.eventTempData.length >= 36) {
                
                [self.eventTempData replaceBytesInRange:NSMakeRange(0, 36) withBytes:NULL length:0];
                self.parseing = NO;
                [self loadNewEventDataFromData:[[NSData alloc]init]];
            }
            else
            {
                self.parseing = NO;
            }
            
            return;
            
        }
        
        NSString *str = [@"" ECGAlertEventTypeToStringWith:eventType];
        
        int RRi  = allbyte[6]+allbyte[7]*256;
        int PRi  = allbyte[8]+allbyte[9]*256;
        int QRSi = allbyte[10]+allbyte[11]*256;
        int QTi  = allbyte[12]+allbyte[13]*256;
        int STi  = allbyte[14]+allbyte[15]*256;
        
        
        int beats;
        [[subData subdataWithRange:NSMakeRange(16, 4)] getBytes:&beats length:sizeof(beats)];
        int duration;
        [[subData subdataWithRange:NSMakeRange(20, 4)] getBytes:&duration length:sizeof(duration)];
        int EVT_PAIR_INDEX;
        [[subData subdataWithRange:NSMakeRange(24, 4)] getBytes:&EVT_PAIR_INDEX length:sizeof(EVT_PAIR_INDEX)];
        
        
        
        
        int position;
        [[subData subdataWithRange:NSMakeRange(28, 4)]getBytes:&position length:sizeof(position)];
        
        int EVT_ANN_INDEX;
        [[subData subdataWithRange:NSMakeRange(32, 4)]getBytes:&EVT_ANN_INDEX length:sizeof(EVT_ANN_INDEX)];
    
        int rrposition = 0;
        if (eventType == 1||eventType == 3||eventType == 5||eventType == 7||eventType == 12||eventType == 14||eventType == 19||eventType == 21||eventType == 26||eventType == 28||eventType == 35||eventType == 36||eventType == 42||eventType == 44) {
            
            rrposition = position + 256 * 2;
            if ([SynECGLibSingleton sharedInstance].ecgInt <= (position + 5 * 256) && [SynECGLibSingleton sharedInstance].isSuspend == NO) {
                _nowPosition = position + 5 * 256;
                dispatch_suspend(_eventQueue);
                [SynECGLibSingleton sharedInstance].isSuspend = YES;
            }
            
        }
        else if(eventType == 2||eventType == 4||eventType == 6||eventType == 8||eventType == 13||eventType == 15||eventType == 20||eventType == 22||eventType == 27||eventType == 29||eventType == 39||eventType == 40||eventType == 43||eventType == 45){
            
            rrposition = position - 256 * 2;
            if ([SynECGLibSingleton sharedInstance].ecgInt <= (position + 1 * 256) && [SynECGLibSingleton sharedInstance].isSuspend == NO) {
                _nowPosition = position + 1 * 256;
                dispatch_suspend(_eventQueue);
                [SynECGLibSingleton sharedInstance].isSuspend = YES;
            }
        }
        else
        {
            rrposition = position;
            if ([SynECGLibSingleton sharedInstance].ecgInt <= (position + 3 * 256) && [SynECGLibSingleton sharedInstance].isSuspend == NO) {
                _nowPosition = position + 3 * 256;
                dispatch_suspend(_eventQueue);
                [SynECGLibSingleton sharedInstance].isSuspend = YES;
            }
        }

        if (self.nowPosition > self.rrp && [SynECGLibSingleton sharedInstance].isSuspend == NO) {
         
            dispatch_suspend(_eventQueue);
            [SynECGLibSingleton sharedInstance].isSuspend = YES;
        }


        
        dispatch_async(_eventQueue, ^{
            
            
            if (self.needReturn == YES) {
             
                self.parseing = NO;
                self.needReturn = NO;
                return;
            }
            else
            {
                int dd  = ((float)position * 1000 / 256);
                long long timesep = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:dd];
                
                NSData *ecgData;
                
                NSLog(@"position = %d",position);
                NSLog(@"rrposition = %d",rrposition);
                NSLog(@"%d",(rrposition - 3 * 256) * 2);
                if(rrposition + 3 * 256 <= [SynECGLibSingleton sharedInstance].ecgInt &&  (rrposition - 3 * 256) * 2 > 0)
                {
                    [[ECGHRManager sharedInstance].ecgOutFile seekToFileOffset:(rrposition - 3 * 256) * 2];
                    ecgData = [[ECGHRManager sharedInstance].ecgOutFile readDataOfLength:6 * 256 * 2];
                }
                else
                {
                    
                     dispatch_async(dispatch_get_main_queue(), ^{
                            if (self.eventTempData.length >= 36) {

                                [self.eventTempData replaceBytesInRange:NSMakeRange(0, 36) withBytes:NULL length:0];
                                self.parseing = NO;
                                [self loadNewEventDataFromData:[[NSData alloc]init]];
                            }
                            else
                            {
                                self.parseing = NO;
                            }
                         });
                }
                
                if (ecgData.length != 6 * 256 * 2 )
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        self.parseing = NO;
                        [self loadNewEventDataFromData:[[NSData alloc]init]];
                        
                    });
                    
                }
                else
                {
                    NSMutableData *updata = [NSMutableData dataWithData:[SynECGUtils fan_hexToBytes:@"00000600"]];
                    /**************方法二****************/
                    [updata appendData:ecgData];
                    
                    NSString *str_ecg = [SynECGUtils base64EncodedStringFrom:[SynECGUtils gzipDeflate:updata]];
                    NSMutableDictionary *dic1 = [[NSMutableDictionary alloc]init];
                    [dic1 setObject:@(index) forKey:@"index"];
                    [dic1 setObject:@(timesep) forKey:@"occur_unixtime"];
                    [dic1 setObject:[NSNumber numberWithInt:beats] forKey:@"beatCount"];
                    [dic1 setObject:[NSNumber numberWithInt:duration] forKey:@"duration"];
                    [dic1 setObject:[NSNumber numberWithFloat:RRi] forKey:@"event_rr"];
                    [dic1 setObject:[NSNumber numberWithFloat:PRi] forKey:@"event_pr"];
                    [dic1 setObject:[NSNumber numberWithFloat:QRSi] forKey:@"event_qrs"];
                    [dic1 setObject:[NSNumber numberWithFloat:QTi] forKey:@"event_qt"];
                    [dic1 setObject:[NSNumber numberWithFloat:STi] forKey:@"event_st"];
                    [dic1 setObject:act forKey:@"activity_type"];
                    [dic1 setObject:str forKey:@"event_type"];
                    [dic1 setObject:[NSNumber numberWithInt:768] forKey:@"occur_idx"];
                    [dic1 setObject:[NSNumber numberWithInt:EVT_PAIR_INDEX] forKey:@"start_index"];
                    [dic1 setObject:str_ecg forKey:@"encoded_ecg"];
                    
                    
                    [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                        
                        
                        NSMutableArray *annArray = [[NSMutableArray alloc]init];
                        NSString *query = [NSString stringWithFormat:@"select * from %@ where position >= '%@' and position <= '%@'",RR_TABLE,@(MIN_POSATION(rrposition)),@(MAX_POSATION(rrposition))];
                        FMResultSet *rs = [db executeQuery:query];
                        while ([rs next]) {

                                NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
                                [dic setObject:[rs stringForColumn:@"ann"] forKey:@"text"];
                                [dic setObject: @([rs longLongIntForColumn:@"position"] - MIN_POSATION(rrposition)) forKey:@"position"];
                                [annArray addObject:dic];
                            
                        }
                        

                        
                        [dic1 setObject:annArray forKey:@"annotations"];
                        
                        
                        NSString *event_data = [SynECGUtils convertToJSONData:dic1];
                        
                        [db executeUpdate:@"INSERT INTO event (user_id, target_id, record_id, duration, occur_unixtime, event_type,eventData,position,outType) VALUES (?, ?, ?, ?, ?, ?, ?,?,?);",[SynECGLibSingleton sharedInstance].user_id,[SynECGLibSingleton sharedInstance].target_id,[SynECGLibSingleton sharedInstance].record_id,@(duration),@(timesep),str,event_data,@(position),@([@"" setEcgEventTypeForAlambyEventType:eventType])];
                        
                        [self changeTable:TOTAL_TABLE Column:@"event" value:@(1) inDB:db];
                        [[HAEventManager sharedInstance] uploadEventMessageIn:db];
//                            [[SynAlarmOperationModel sharedInstance] eventWithType:eventType duration:duration  withPosition:position rr:RRi];
                    
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            if (self.eventTempData.length >= 36) {
                                
                                [self.eventTempData replaceBytesInRange:NSMakeRange(0, 36) withBytes:NULL length:0];
                                self.parseing = NO;
                                [self loadNewEventDataFromData:[[NSData alloc]init]];
                            }
                            else
                            {
                                self.parseing = NO;
                            }
                            
                        });
                        
                    }];
                }
                
            }
        });
    }
}
//新的ann数据
- (void)loadNewRRDataFromData:(NSData *)message{
    dispatch_async(_annQueue, ^{
        
        Byte *c = (Byte*)[message bytes];
        NSMutableArray *array = [NSMutableArray new];
        
        NSInteger leng = message.length;
        int last = 0;
        int index = 0;
        for (int i = 0 ; i<= (leng-13)/6; i++) {
            
            NSMutableDictionary *dic = [NSMutableDictionary new];
            char H;
            [[message subdataWithRange:NSMakeRange(9+6*i, 1)] getBytes:&H length:sizeof(H)];
            int amp = c[10+6*i]+c[11+6*i]*256;
            int extra = c[12+6*i];
            NSInteger amp_data = [self ampFromData:amp];
            [dic setObject:[[NSString alloc]initWithFormat:@"%c",H] forKey:@"ann"];
            [dic setObject:@(amp_data) forKey:@"amp"];
            [dic setObject:[NSString stringWithFormat:@"%d",extra] forKey:@"extra"];
            if (i == 0) {
                int first;
                [[message subdataWithRange:NSMakeRange(5, 4)] getBytes:&first length:sizeof(first)];
                int ind;
                [[message subdataWithRange:NSMakeRange(1, 4)] getBytes:&ind length:sizeof(ind)];
                [dic setObject:@(first) forKey:@"data"];
                [dic setObject:@(ind) forKey:@"index"];
                last = last +first;
                index = index +ind;
            }else{
                int second = c[13+6*(i-1)]+c[14+6*(i-1)]*256;
                last = last +second;
                index = index+1;
                [dic setObject:@(index) forKey:@"index"];
                [dic setObject:@(last) forKey:@"data"];
            }
            
            [array addObject:dic];
        }
        
        
        BlockWeakSelf(self);
        [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            
            NSMutableArray *annArray = [[NSMutableArray alloc]init];
            for (int i = 0; i < array.count; i++)
            {
                NSDictionary *dic = array[i];
                NSInteger cc = [self tpFromPostion:[dic[@"data"] integerValue]];
                [annArray addObject:@(cc)];
                
                [self getMaxAndMinWithData:dic[@"data"]];
                
                [db executeUpdate:@"INSERT INTO rr_b1 (user_id, target_id, record_id, keyNo, data, ann, avergeHR, singleHR, position, extra, amp) VALUES (?, ?, ?, ?, ?, ?, ?,?,?,?,?);",[SynECGLibSingleton sharedInstance].user_id,[SynECGLibSingleton sharedInstance].target_id,[SynECGLibSingleton sharedInstance].record_id,dic[@"index"],@(cc),dic[@"ann"],@([SynECGLibSingleton sharedInstance].averageHR),@(self->maxAndMinBpm),dic[@"data"],dic[@"extra"],dic[@"amp"]];
                
                
                if(self.p30 == 0)
                {
                    self.p30 = cc / 300000 + 1;
                    self.p60 = cc / 60000 + 1;
                }
                

                
//                [[SynAlarmOperationModel sharedInstance] retrieveAlarmFromPosition:[dic[@"data"] integerValue] type:dic[@"ann"]];
//                [[SynAlarmOperationModel sharedInstance] retrieveRRFromPosition:[dic[@"data"] integerValue] ann:dic[@"ann"]];
                


                if ((cc - 65000)/ 300000 >= self.p30)
                {
                    
                    [[ECGBreathUpload sharedInstance]uploadBreathMessageIn:db];
                    self.p30++;
                    
                    
                }
                
            }
            [self changeTable:TOTAL_TABLE Column:@"ann" value:@(array.count) inDB:db];
            
            

                
            self.rrp  = [[array.lastObject objectForKey:@"data"] integerValue];
            if ([SynECGLibSingleton sharedInstance].ecgInt >= self.nowPosition && self.rrp >= self.nowPosition && [SynECGLibSingleton sharedInstance].isSuspend == YES) {
                
                dispatch_resume(self.eventQueue);
                [SynECGLibSingleton sharedInstance].isSuspend = NO;
            }
            
            
            
            weakSelf.rrNUm = weakSelf.rrNUm + array.count;
            if (weakSelf.rrNUm >= 400) {
                weakSelf.rrNUm = 0;
                [[ECGRRManager sharedInstance]uploadRRMessageIn:db];
                
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (self.delegate &&[self.delegate respondsToSelector:@selector(syn_ecgDecodeMessageOnRRValue:)]) {
                    [self.delegate syn_ecgDecodeMessageOnRRValue:annArray];
                }
            });
            
        }];
    });
    
}

- (NSInteger)tpFromPostion:(NSInteger)postion
{
    CGFloat tp = (CGFloat)postion * (CGFloat)1000 / (CGFloat)256;
    NSInteger tpo = round(tp);
    
    
    return tpo;
}


- (NSInteger)ampFromData:(NSInteger)data
{
    CGFloat tp = (CGFloat)data * (CGFloat)2048 / (CGFloat)2730;
    NSInteger tpo = round(tp);
    
    return tpo;
}


//新的呼吸能量数据
- (void)loadNewBreathDataFromData:(NSData *)message{
    
    
    if ([SynECGLibSingleton sharedInstance].deviceVerType != 1) {
        
        [SynECGLibSingleton sharedInstance].deviceVerType = 1;
    }
    
    BlockWeakSelf(self);
    dispatch_async(_hrQueue, ^{
        
        int s;
        [[message subdataWithRange:NSMakeRange(1, 4)] getBytes:&s length:sizeof(s)];
        float min;
        [[message subdataWithRange:NSMakeRange(5, 4)] getBytes:&min length:sizeof(min)];
        
        NSString *time = [SynECGUtils setOccerTimeFromPastSeconds:s];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
        [dic setObject:time forKey:@"occur_time"];
        [dic setObject:[NSNumber numberWithFloat:min] forKey:@"value"];
        
        
        
        [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            [db executeUpdate:@"INSERT INTO breath1 (user_id,target_id,record_id,keyNo,occur_datetime,value) VALUES (?,?,?,?,?,?)",[SynECGLibSingleton sharedInstance].user_id,[SynECGLibSingleton sharedInstance].target_id,[SynECGLibSingleton sharedInstance].record_id,@(s),time,@(min)];
            
            
            [weakSelf changeTable:TOTAL_TABLE Column:@"rsp" value:@(1) inDB:db];
        }];
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (weakSelf.delegate &&[weakSelf.delegate respondsToSelector:@selector(syn_ecgDecodeMessageOnBreathValue:)]) {
                [weakSelf.delegate syn_ecgDecodeMessageOnBreathValue:dic];
            }
        });
        
    });
    
    
    
    dispatch_async(weakSelf.enengyQueue, ^{
        
        for (int i = 0; i < (message.length-9)/18; i++) {
            NSData * data1 =[message subdataWithRange:NSMakeRange(9+18*i, 1)];
            int a = 0;
            [data1 getBytes:&a length:sizeof(a)];
            NSData *data2 = [message subdataWithRange:NSMakeRange(10+18*i, 4)];
            int b = 0;
            [data2 getBytes:&b length:sizeof(b)];
            NSData *data3 = [message subdataWithRange:NSMakeRange(14+18*i, 3)];
            int c = 0;
            [data3 getBytes:&c length:sizeof(c)];
            NSData *data4 = [message subdataWithRange:NSMakeRange(17+18*i, 4)];
            float d = 0;
            [data4 getBytes:&d length:sizeof(d)];
            if (isnan(d) || isinf(d)) {
                d = 0.000000;
            }
            
            [SynECGLibSingleton sharedInstance].activityType = [@"" acticity:a];
            
            NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
            [dic setObject:[NSString stringWithFormat:@"%d",a] forKey:@"activity_type"];
            [dic setObject:[NSNumber numberWithFloat:c] forKey:@"power"];
            [dic setObject:[NSNumber numberWithFloat:d] forKey:@"energy"];

            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.delegate &&[weakSelf.delegate respondsToSelector:@selector(syn_ecgDecodeMessageOnActivityValue:)]) {
                    [weakSelf.delegate syn_ecgDecodeMessageOnActivityValue:dic];
                }
                
            });
        }
        
        
    });
    
}
//上传百分比
- (void)loadNewinfoDataFromData:(NSData *)message{
    
    if ([SynECGLibSingleton sharedInstance].typeNum == 9) {
        int ECG_SEND;
        [[message subdataWithRange:NSMakeRange(1, 4)]getBytes:&ECG_SEND length:sizeof(ECG_SEND)];
        int ECG_CURR;
        [[message subdataWithRange:NSMakeRange(5, 4)]getBytes:&ECG_CURR length:sizeof(ECG_CURR)];
        int ANN_SEND;
        [[message subdataWithRange:NSMakeRange(9, 4)]getBytes:&ANN_SEND length:sizeof(ANN_SEND)];
        int ANN_CURR;
        [[message subdataWithRange:NSMakeRange(13, 4)]getBytes:&ANN_CURR length:sizeof(ANN_CURR)];
        int EVT_SEND;
        [[message subdataWithRange:NSMakeRange(17, 4)]getBytes:&EVT_SEND length:sizeof(EVT_SEND)];
        int EVT_CURR;
        [[message subdataWithRange:NSMakeRange(21, 4)]getBytes:&EVT_CURR length:sizeof(EVT_CURR)];
        NSInteger arriveKB = ECG_SEND * 3 / 2 + ANN_SEND * 12 + EVT_SEND * 64;
        NSInteger allKB = ECG_CURR * 3 / 2 + ANN_CURR * 12 + EVT_CURR*64;
 
        if (!lastKB) {
            lastKB = arriveKB;
        }else{
            int percentage = (((float)arriveKB)/((float)(allKB)))*100;
            float v = ((float)(arriveKB-lastKB))/1024;
            NSInteger remaining = (allKB-arriveKB)/(arriveKB-lastKB);
            
            if (_delegate && [_delegate respondsToSelector:@selector(syn_ecgDecodeMessageOnPercentage:andSpendTime:andV:andUnfinishTime:)]) {
                [_delegate syn_ecgDecodeMessageOnPercentage:percentage andSpendTime:20 andV:v andUnfinishTime:remaining];
            }
            lastKB = arriveKB;
        }
        
        
    }else{
        lastKB = 0;
    }

    
}
//v2的能量数据
- (void)loadNewEnergyDataFromData:(NSData *)message{
    
    BlockWeakSelf(self);
    
    dispatch_async(_enengyQueue, ^{
        
        for (int i = 0; i < (message.length-1)/18; i++) {
            NSData * data1 =[message subdataWithRange:NSMakeRange(1+18*i, 1)];
            int a = 0;
            [data1 getBytes:&a length:sizeof(a)];
            NSData *data2 = [message subdataWithRange:NSMakeRange(2+18*i, 4)];
            int b = 0;
            [data2 getBytes:&b length:sizeof(b)];
            NSData *data3 = [message subdataWithRange:NSMakeRange(6+18*i, 3)];
            int c = 0;
            [data3 getBytes:&c length:sizeof(c)];
            NSData *data4 = [message subdataWithRange:NSMakeRange(9+18*i, 4)];
            float d = 0;
            [data4 getBytes:&d length:sizeof(d)];
            if (isnan(d) || isinf(d)) {
                d = 0.000000;
            }
            
            [SynECGLibSingleton sharedInstance].activityType = [@"" acticity:a];
            
        }
        
        
    });
}

-(void)loadEvtRecordDataFromData:(NSData *)message andIndex:(NSInteger)index{

    Byte b = (Byte) ((index) & 0xFF);
    Byte c = (Byte) ((index>>8)& 0xFF);
    Byte d = (Byte) ((index>>16)& 0xFF);
    Byte f = (Byte) (index>>24 & 0xFF);
    Byte g[]= {b,c,d,f};
    NSData *dataIndex =[NSData dataWithBytes:&g length:sizeof(g)];
    [self.eventTempData appendData:dataIndex];
    [self.eventTempData appendData:message];
    
    if (self.parseing == NO && self.eventTempData.length >= 36) {
        
        [self decodeEVTData];
    }
    else
    {
        return;
    }
}


- (void)decodeEVTData
{
    
    if (self.eventTempData.length >= 36) {
        
        self.parseing = YES;
        
        NSData *data = [self.eventTempData subdataWithRange:NSMakeRange(0, 36)];
        int index;
        [[data subdataWithRange:NSMakeRange(0, 4)] getBytes:&index length:sizeof(index)];
        
        NSData *message = [data subdataWithRange:NSMakeRange(4, 32)];
        Byte *allbyte = (Byte*)[message bytes];
        
        int activity = allbyte[0];
        
        NSString *act = [@"" acticity:activity];
        
        unsigned char *bs = (unsigned char *)[[message subdataWithRange:NSMakeRange(1, 1) ] bytes];
        int eventType = *bs;//34
        NSString *str = [@"" ECGAlertEventTypeToStringWith:eventType];
        
        if (eventType < 42) {
            
            if (self.eventTempData.length >= 36) {
                
                [self.eventTempData replaceBytesInRange:NSMakeRange(0, 36) withBytes:NULL length:0];
                self.parseing = NO;
                [self decodeEVTData];
            }
            else
            {
                self.parseing = NO;
            }
            
            return;
            
        }

        int RRi  = allbyte[2]+allbyte[3]*256;
        int PRi  = allbyte[4]+allbyte[5]*256;
        int QRSi = allbyte[6]+allbyte[7]*256;
        int QTi  = allbyte[8]+allbyte[9]*256;
        int STi  = allbyte[10]+allbyte[11]*256;
        
        int beats;
        [[message subdataWithRange:NSMakeRange(12, 4)] getBytes:&beats length:sizeof(beats)];
        int duration;
        [[message subdataWithRange:NSMakeRange(16, 4)] getBytes:&duration length:sizeof(duration)];
        int EVT_PAIR_INDEX;
        [[message subdataWithRange:NSMakeRange(20, 4)] getBytes:&EVT_PAIR_INDEX length:sizeof(EVT_PAIR_INDEX)];
        int position;
        [[message subdataWithRange:NSMakeRange(24, 4)]getBytes:&position length:sizeof(position)];
        
        int EVT_ANN_INDEX;
        [[message subdataWithRange:NSMakeRange(28, 4)]getBytes:&EVT_ANN_INDEX length:sizeof(EVT_ANN_INDEX)];
        
        int rrposition = 0;
        if (eventType == 1||eventType == 3||eventType == 5||eventType == 7||eventType == 12||eventType == 14||eventType == 19||eventType == 21||eventType == 26||eventType == 28||eventType == 35||eventType == 36||eventType == 42||eventType == 44) {
            
            rrposition = position + 256 * 2;
            _nowPosition = position + 5 * 256;
            
            
        }
        else if(eventType == 2||eventType == 4||eventType == 6||eventType == 8||eventType == 13||eventType == 15||eventType == 20||eventType == 22||eventType == 27||eventType == 29||eventType == 39||eventType == 40||eventType == 43||eventType == 45){
            
            rrposition = position - 256 * 2;
            _nowPosition = position + 1 * 256;
            
        }
        else
        {
            rrposition = position;
            
            _nowPosition = position + 3 * 256;
            
            
        }
        
        int dd  = ((float)position * 1000 / 256);
        long long timesep = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:dd];
        
        NSData *ecgData;
        
        if(rrposition + 3 * 256 <= [SynECGLibSingleton sharedInstance].ecgInt &&  (rrposition - 3 * 256) * 2 > 0)
        {
            [[ECGHRManager sharedInstance].ecgOutFile seekToFileOffset:(rrposition - 3 * 256) * 2];
            ecgData = [[ECGHRManager sharedInstance].ecgOutFile readDataOfLength:6 * 256 * 2];
            
        }
        else
        {
            if (self.eventTempData.length >= 36) {
                
                [self.eventTempData replaceBytesInRange:NSMakeRange(0, 36) withBytes:NULL length:0];
                self.parseing = NO;
                [self decodeEVTData];
            }
            else
            {
                self.parseing = NO;
            }
        }
        
        if (ecgData.length != 6 * 256 * 2 )
        {
            if (self.eventTempData.length >= 36) {
                
                [self.eventTempData replaceBytesInRange:NSMakeRange(0, 36) withBytes:NULL length:0];
                self.parseing = NO;
                [self decodeEVTData];
            }
            else
            {
                self.parseing = NO;
            }
        }
        else
        {
            NSMutableData *updata = [NSMutableData dataWithData:[SynECGUtils fan_hexToBytes:@"00000600"]];
            /**************方法二****************/
            [updata appendData:ecgData];
            
            NSString *str_ecg = [SynECGUtils base64EncodedStringFrom:[SynECGUtils gzipDeflate:updata]];
            NSMutableDictionary *dic1 = [[NSMutableDictionary alloc]init];
            [dic1 setObject:@(index) forKey:@"index"];
            [dic1 setObject:@(timesep) forKey:@"occur_unixtime"];
            [dic1 setObject:[NSNumber numberWithInt:beats] forKey:@"beatCount"];
            [dic1 setObject:[NSNumber numberWithInt:duration] forKey:@"duration"];
            [dic1 setObject:[NSNumber numberWithFloat:RRi] forKey:@"event_rr"];
            [dic1 setObject:[NSNumber numberWithFloat:PRi] forKey:@"event_pr"];
            [dic1 setObject:[NSNumber numberWithFloat:QRSi] forKey:@"event_qrs"];
            [dic1 setObject:[NSNumber numberWithFloat:QTi] forKey:@"event_qt"];
            [dic1 setObject:[NSNumber numberWithFloat:STi] forKey:@"event_st"];
            [dic1 setObject:act forKey:@"activity_type"];
            [dic1 setObject:str forKey:@"event_type"];
            [dic1 setObject:[NSNumber numberWithInt:768] forKey:@"occur_idx"];
            [dic1 setObject:[NSNumber numberWithInt:EVT_PAIR_INDEX] forKey:@"start_index"];
            [dic1 setObject:str_ecg forKey:@"encoded_ecg"];
            
            
            [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                
                NSMutableArray *annArray = [[NSMutableArray alloc]init];
                NSString *query = [NSString stringWithFormat:@"select * from %@ where position >= '%@' and position <= '%@'",RR_TABLE,@(MIN_POSATION(rrposition)),@(MAX_POSATION(rrposition))];
                FMResultSet *rs = [db executeQuery:query];
                while ([rs next]) {
                    
                    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
                    [dic setObject:[rs stringForColumn:@"ann"] forKey:@"text"];
                    [dic setObject: @([rs longLongIntForColumn:@"position"] - MIN_POSATION(rrposition)) forKey:@"position"];
                    [annArray addObject:dic];
                    
                }
                
                [dic1 setObject:annArray forKey:@"annotations"];
                
                
                NSString *event_data = [SynECGUtils convertToJSONData:dic1];
                
                [db executeUpdate:@"INSERT INTO event (user_id, target_id, record_id, duration, occur_unixtime, event_type,eventData,position,outType) VALUES (?, ?, ?, ?, ?, ?, ?,?,?);",[SynECGLibSingleton sharedInstance].user_id,[SynECGLibSingleton sharedInstance].target_id,[SynECGLibSingleton sharedInstance].record_id,@(duration),@(timesep),str,event_data,@(position),@([@"" setEcgEventTypeForAlambyEventType:eventType])];
                
                [self changeTable:TOTAL_TABLE Column:@"event" value:@(1) inDB:db];
                [[HAEventManager sharedInstance] uploadEventMessageIn:db];
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (self.eventTempData.length >= 36) {
                        
                        [self.eventTempData replaceBytesInRange:NSMakeRange(0, 36) withBytes:NULL length:0];
                        self.parseing = NO;
                        [self decodeEVTData];
                    }
                    else
                    {
                        self.parseing = NO;
                    }
                });
            }];
        }
    }
    else
    {
        return;
    }
}

    
-(void)loadAnntRecordDataFromData:(NSData *)message andIndex:(NSInteger)index{

    NSMutableArray *array = [NSMutableArray new];
    for (int i = 0; i < message.length / 8; i++) {
        
        NSData * sy = [message subdataWithRange:NSMakeRange(i * 8, 8)];
        Byte *c = (Byte*)[sy bytes];
        int first;
        [[sy subdataWithRange:NSMakeRange(0, 4)] getBytes:&first length:sizeof(first)];
        char H;
        [[sy subdataWithRange:NSMakeRange(4, 1)] getBytes:&H length:sizeof(H)];
        int amp = c[6]+c[7]*256;
        int extra = c[5];
        
        
        NSLog(@"%c",H);
        
        NSMutableDictionary *dic = [NSMutableDictionary new];
        
        [dic setObject:[[NSString alloc]initWithFormat:@"%c",H] forKey:@"ann"];
        [dic setObject:@(amp) forKey:@"amp"];
        [dic setObject:[NSString stringWithFormat:@"%d",extra] forKey:@"extra"];
        [dic setObject:@(first) forKey:@"data"];
        [dic setObject:@(index + i) forKey:@"index"];
        
        [array addObject:dic];
    }
    

    BlockWeakSelf(self);
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        for (int i = 0; i < array.count; i++)
        {
            NSDictionary *dic = array[i];
            NSInteger cc = [self tpFromPostion:[dic[@"data"] integerValue]];
    
            
            [db executeUpdate:@"INSERT INTO rr_b1 (user_id, target_id, record_id, keyNo, data, ann, avergeHR, singleHR, position, extra, amp) VALUES (?, ?, ?, ?, ?, ?, ?,?,?,?,?);",[SynECGLibSingleton sharedInstance].user_id,[SynECGLibSingleton sharedInstance].target_id,[SynECGLibSingleton sharedInstance].record_id,dic[@"index"],@(cc),dic[@"ann"],@(90),@(90),dic[@"data"],dic[@"extra"],dic[@"amp"]];
            
            
                [self changeTable:TOTAL_TABLE Column:@"ann" value:@(1) inDB:db];
            
            
            
                weakSelf.rrNUm = weakSelf.rrNUm + 1;
                if (weakSelf.rrNUm >= 66) {
                    weakSelf.rrNUm = 0;
                    [[ECGRRManager sharedInstance]uploadRRMessageIn:db];

                }
        }
    }];
    
}
- (void)loadEcgtRecordDataFromData:(NSData *)message andIndex:(NSInteger)index{
    // index 为传进来数据起始值的位置
    
    NSMutableData *updata   = [NSMutableData new];
    
    if (message.length < 1) {
        
        return;
    }
    else
    {
        Byte *c = (Byte*)[message bytes];
        for (int i = 0; i<message.length-2; i+=3) {
            @autoreleasepool {
                short  a = (((short)(char)c[i])<<4)|((c[i+1]>>4)&0x0f);
                short  b = (((short)((char)(c[i+1]<<4))<<4)&0xff00)|(c[i+2]&0x00ff);
                short  c = a*2048/273;
                short  e = b*2048/273;
                Byte d[4];
                d[0] = (Byte)(c>>8)&0x0ff;
                d[1]= (Byte)c&0x0ff;
                d[2]= (Byte)(e>>8)&0x0ff;
                d[3]= (Byte)e&0x0ff;
                NSData *data = [NSData dataWithBytes:d length:4];
                [updata appendData:data];
            }
        }
    }
    [[ECGHRManager sharedInstance] saveDateInRecordId:[SynECGLibSingleton sharedInstance].record_id withData:updata];
   
}


@end
