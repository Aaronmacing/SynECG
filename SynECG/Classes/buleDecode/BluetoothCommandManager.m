//
//  BluetoothCommandManager.m
//  XHJY_app
//
//  Created by LiangXiaobin on 16/5/25.
//  Copyright © 2016年 成都信汇聚源科技有限公司. All rights reserved.
//

#import "BluetoothCommandManager.h"
#import "SynConstant.h"
#import "SynECGUtils.h"
#import "SynECGLibSingleton.h"
#import "ZYFMDB.h"
#import "SDBManager.h"
#import "ECGDecodeManager.h"
#import "ECGHRManager.h"
#import "SynAlarmOperationModel.h"

@implementation BluetoothCommandManager

+ (instancetype)sharedInstance
{
    static BluetoothCommandManager * sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BluetoothCommandManager alloc] init];
    });
    return sharedInstance;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)writePersonInfoMessageWith:(Comback)complection
{
    //个人信息 年龄性别  ageStr 为年龄 w为体重 h为身高 str为targetID
    
    [[SDBManager defaultDBManager].queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
       
        
        NSString *query = [NSString stringWithFormat:@"select * from %@",SYN_USERINFO_TABLE];
        FMResultSet *rs = [db executeQuery:query];
        NSString *birthday = [[NSString alloc]init];
        NSString *h = [[NSString alloc]init];
        NSString *se= [[NSString alloc]init];
        NSString *w = [[NSString alloc]init];
        NSString *str = [[NSString alloc]init];
        
        while ([rs next]) {
            birthday = [rs stringForColumn:@"birthday"];
            h = [rs stringForColumn:@"height"];
            se = [rs stringForColumn:@"sex"];
            w = [rs stringForColumn:@"weight"];
            str = [rs stringForColumn:@"targetId"];
        }
        
        NSString *sex = [self setSexWithString:se];
        
        NSDate *destDate= [SynECGUtils getDateWithDateString:birthday WithFormat:@"yyyy-MM-dd"];
        NSInteger age = [SynECGUtils ageWithDateOfBirth:destDate];
 
        Byte byte[1] = {};
        byte[0] =  (Byte) (age & 0xFF);
        int c ;
        if ([sex isEqualToString:@"1"]){
            c =  byte[0] <<1 & 0xff + 1;
            
        }else{
            c =  byte[0] <<1 & 0xff ;
        }
        
        Byte ageB = (Byte) c & 0xff;
        NSData *data1 =[NSData dataWithBytes:&ageB length:sizeof(ageB)];
        
        
        //身高体重
        NSInteger weight =[w integerValue];
        Byte wB = (Byte) weight & 0xff;
        NSData *data2 =[NSData dataWithBytes:&wB length:sizeof(wB)];
        
        NSInteger height =[h integerValue];
        Byte hB = (Byte) height & 0xff;
        NSData *data3 =[NSData dataWithBytes:&hB length:sizeof(hB)];
        //用户id
        NSMutableString *s = [NSMutableString new];
        for (int i=0; i<str.length; i++) {
            if ([[str substringWithRange:NSMakeRange(i, 1)] isEqualToString:@"-"]) {
            }else{
                [s appendString:[str substringWithRange:NSMakeRange(i, 1)]];
            }
        }
        
        NSMutableData* dataUU = [NSMutableData data];
        int idx;
        for (idx = 0; idx+2 <= s.length; idx+=2)
        {
            NSRange range = NSMakeRange(s.length - idx - 2, 2);
            NSString* hexStr = [s substringWithRange:range];
            NSScanner* scanner = [NSScanner scannerWithString:hexStr];
            unsigned int intValue;
            [scanner scanHexInt:&intValue];
            [dataUU appendBytes:&intValue length:1];
        }
 
        Byte B[]={ 0x01};
        NSData *dataB =[NSData dataWithBytes:&B length:sizeof(B)];
        NSMutableData *dataAll = [NSMutableData dataWithData:dataB];
        [dataAll appendData:dataUU];
        [dataAll appendData:data1];
        [dataAll appendData:data2];
        [dataAll appendData:data3];

        
        complection(dataAll);

    }];
}

- (void)writeNewPersonInfoMessageWith:(Comback)complection
{
    //个人信息 年龄性别  ageStr 为年龄 w为体重 h为身高 str为targetID
    
    [[SDBManager defaultDBManager].queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        
        NSString *query = [NSString stringWithFormat:@"select * from %@",SYN_USERINFO_TABLE];
        FMResultSet *rs = [db executeQuery:query];
        NSString *birthday = [[NSString alloc]init];
        NSString *h = [[NSString alloc]init];
        NSString *se= [[NSString alloc]init];
        NSString *w = [[NSString alloc]init];
        NSString *str = [[NSString alloc]init];
        
        while ([rs next]) {
            birthday = [rs stringForColumn:@"birthday"];
            h = [rs stringForColumn:@"height"];
            se = [rs stringForColumn:@"sex"];
            w = [rs stringForColumn:@"weight"];
            str = [rs stringForColumn:@"targetId"];
        }
        
        NSString *sex = [self setSexWithString:se];
        
        NSDate *destDate= [SynECGUtils getDateWithDateString:birthday WithFormat:@"yyyy-MM-dd"];
        NSInteger age = [SynECGUtils ageWithDateOfBirth:destDate];
        
        Byte byte[1] = {};
        byte[0] =  (Byte) (age & 0xFF);
        int c ;
        if ([sex isEqualToString:@"1"]) {
            c =  byte[0] <<1 & 0xff + 1;
            
        }else{
            c =  byte[0] <<1 & 0xff ;
        }
        
        Byte ageB = (Byte) c & 0xff;
        NSData *data1 =[NSData dataWithBytes:&ageB length:sizeof(ageB)];
        
        
        //身高体重
        NSInteger weight =[w integerValue];
        Byte wB = (Byte) weight & 0xff;
        NSData *data2 =[NSData dataWithBytes:&wB length:sizeof(wB)];
        
        NSInteger height =[h integerValue];
        Byte hB = (Byte) height & 0xff;
        NSData *data3 =[NSData dataWithBytes:&hB length:sizeof(hB)];
        //用户id
        NSMutableString *s = [NSMutableString new];
        for (int i=0; i<str.length; i++) {
            if ([[str substringWithRange:NSMakeRange(i, 1)] isEqualToString:@"-"]) {
            }else{
                [s appendString:[str substringWithRange:NSMakeRange(i, 1)]];
            }
        }
        
        NSMutableData* dataUU = [NSMutableData data];
        int idx;
        for (idx = 0; idx+2 <= s.length; idx+=2)
        {
            NSRange range = NSMakeRange(s.length - idx - 2, 2);;
            NSString* hexStr = [s substringWithRange:range];
            NSScanner* scanner = [NSScanner scannerWithString:hexStr];
            unsigned int intValue;
            [scanner scanHexInt:&intValue];
            [dataUU appendBytes:&intValue length:1];
        }
        
        NSInteger type = 0;
        Byte wType = (Byte) type & 0xff;
        NSData *dataType =[NSData dataWithBytes:&wType length:sizeof(wType)];
        
        Byte B[]={0x0B};
        NSData *dataB =[NSData dataWithBytes:&B length:sizeof(B)];
        NSMutableData *dataAll = [NSMutableData dataWithData:dataB];
        [dataAll appendData:dataUU];
        [dataAll appendData:data1];
        [dataAll appendData:data2];
        [dataAll appendData:data3];
        [dataAll appendData:dataType];
        
        
        NSMutableData *dataName = [[NSMutableData alloc]init];
        
        for (int i = 0; i < [SynECGLibSingleton sharedInstance].userName.length; i++) {
            
            NSString *p = [[SynECGLibSingleton sharedInstance].userName substringWithRange:NSMakeRange(i, 1)];
            NSData *data = [p dataUsingEncoding:NSUTF8StringEncoding];
            
            if (dataName.length + data.length > 22) {
                break;
            }
            else
            {
                [dataName appendData:data];
            }
            
            
        }
        NSInteger len = dataName.length;
        if (dataName.length < 22) {
            
            [dataName increaseLengthBy:22 - dataName.length];
        }

        Byte lenB = (Byte) len & 0xff;
        NSData *dataLen =[NSData dataWithBytes:&lenB length:sizeof(lenB)];
        [dataAll appendData:dataLen];
        [dataAll appendData:dataName];
        
        complection(dataAll);
        
    }];
}

//大小端数据转换（其实还有更简便的方法，不过看起来这个方法是最直观的）
- (NSData *)dataTransfromBigOrSmall:(NSData *)data{
    
    NSString *tmpStr = [self dataChangeToString:data];
    NSMutableArray *tmpArra = [NSMutableArray array];
    for (int i = 0 ;i<data.length*2 ;i+=2) {
        NSString *str = [tmpStr substringWithRange:NSMakeRange(i, 2)];
        [tmpArra addObject:str];
    }
    
    NSArray *lastArray = [[tmpArra reverseObjectEnumerator] allObjects];
    
    NSMutableString *lastStr = [NSMutableString string];
    
    for (NSString *str in lastArray) {
        
        [lastStr appendString:str];
        
    }
    
    NSData *lastData = [self HexStringToData:lastStr];
    
    return lastData;
    
}


- (NSString*)dataChangeToString:(NSData*)data{
    
    NSString * string = [NSString stringWithFormat:@"%@",data];
    string = [string stringByReplacingOccurrencesOfString:@"<" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@">" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    return string;
    
}



- (NSString *)hexStringFromString:(NSString *)string
{
    NSData *myD = [string dataUsingEncoding:NSUTF8StringEncoding];
    Byte *bytes = (Byte *)[myD bytes];    //下面是Byte 转换为16进制。
    NSString *hexStr=@"";
    for(int i=0;i<[myD length];i++)
        
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        
        if([newHexStr length]==1)
            
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];        else
                
                hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    return hexStr;
}
//编写一个NSData类型数据
- (NSMutableData*)HexStringToData:(NSString*)str
{
    NSString *command = str;
    command = [command stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [command length]/2; i++) {
        byte_chars[0] = [command characterAtIndex:i*2];
        byte_chars[1] = [command characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    return commandToSend;
}


- (NSString *)setSexWithString:(NSString *)string
{
    if ([string isEqualToString:@"MAN"]) {
        return @"0";
    }
    else
    {
        return @"1";
    }
}

- (NSData *)startView
{
    @autoreleasepool {
    //第二步写进去
    Byte C[] = {0x0a,0xff,0xff};
    NSData *dataView = [NSData dataWithBytes:&C length:sizeof(C)];
    
    return dataView;
    }
}
- (void)openViewWith:(Comback)complection
{
    [[SDBManager defaultDBManager].queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        //读取数据库的count值  停止测量的话数据库中的count值要全都置0 建议每个类型的count都加一个设备状态属性
        
        NSString *query = [NSString stringWithFormat:@"select * from %@ WHERE recordId = '%@'",TOTAL_TABLE,[SynECGLibSingleton sharedInstance].record_id];
        FMResultSet *rs = [db executeQuery:query];
        int ecg = 0;
        int ann = 0;
        int evt = 0;
        int act= 0;
        int rsp= 0;
        int hrv = 0;
        while ([rs next]) {
            
            ecg = [rs intForColumn:@"ecg"];
            ann = [rs intForColumn:@"ann"];
            evt = [rs intForColumn:@"event"];
            act = [rs intForColumn:@"act"];
            rsp = [rs intForColumn:@"rsp"];
            hrv = [rs intForColumn:@"hrv"];
        }
        
        

        
        NSString *str = [SynECGUtils toBinarySystemWithDecimalSystem:ecg length:32];
        NSString * qwert1 = [SynECGUtils getBinaryBybinary:str];
        
        NSString *str1 = [SynECGUtils toBinarySystemWithDecimalSystem:ann length:24];
        NSString * qwert2 = [SynECGUtils getBinaryBybinary:str1];
        
        
        NSString *str2 = [SynECGUtils ToHex1:evt isfront:YES];
        NSString *str3 = [SynECGUtils ToHex1:act isfront:NO];
        
        NSString *str23 = [NSString stringWithFormat:@"%@%@%@%@",[str2 substringWithRange:NSMakeRange(0, 4)],[str3 substringWithRange:NSMakeRange(0, 1)],[str2 substringWithRange:NSMakeRange(4, 1)],[str3 substringWithRange:NSMakeRange(1, 4)]];
        
        NSString *str4 = [SynECGUtils ToHex1:rsp isfront:YES];
        NSString *str5 = [SynECGUtils ToHex1:hrv isfront:NO];
        NSString *str45 = [NSString stringWithFormat:@"%@%@%@%@",[str4 substringWithRange:NSMakeRange(0, 4)],[str5 substringWithRange:NSMakeRange(0, 1)],[str4 substringWithRange:NSMakeRange(4, 1)],[str5 substringWithRange:NSMakeRange(1, 4)]];
        
        NSString *appendStr = [NSString stringWithFormat:@"%@%@%@%@",qwert1,qwert2,str23,str45];
        NSString *lastStr = [NSString stringWithFormat:@"0affff%@",appendStr];
        NSDictionary * dic = @{@"ecg":@(ecg),@"ann":@(ann),@"evt":@(evt),@"str":[SynECGUtils fan_hexToBytes:lastStr]};
//        complection([SynECGUtils fan_hexToBytes:lastStr]);
        complection(dic);

        
        
    }];
}


- (NSData *)startMonitoringECG
{
    @autoreleasepool {
    //开始  点击开始的时候 写入该data
    int value = (int)[SynECGLibSingleton sharedInstance].startMonitorTime;
    
    Byte b = (Byte) ((value) & 0xFF);
    Byte c = (Byte) ((value>>8)& 0xFF);
    Byte d = (Byte) ((value>>16)& 0xFF);
    Byte f = (Byte) (value>>24 & 0xFF);
    Byte g[]= {0x03,b,c,d,f};
    NSData *data =[NSData dataWithBytes:&g length:sizeof(g)];
    
    return data;
    }
    
}

- (NSData *)endMonitoringECG
{
    @autoreleasepool {
    //点击停止的时候 写入该data
    Byte stop[] = {0x04};
    NSData *dataStop = [NSData dataWithBytes:&stop length:sizeof(stop)];
    
    return dataStop;
    }
}

- (NSData *)getRecordList
{
    Byte stop[] = {0x07};
    NSData *dataStop = [NSData dataWithBytes:&stop length:sizeof(stop)];
    
    return dataStop;
}



- (NSArray *)getStatus:(NSData *)data
{
    if([SynECGLibSingleton sharedInstance].max == 1){
        @autoreleasepool {
            NSData *data1 = [data subdataWithRange:NSMakeRange(0, 1)];
            int8_t A;
            [data1 getBytes:&A length:sizeof(A)];
            NSData *data2 = [data subdataWithRange:NSMakeRange(1, 4)];
            int startTime;
            [data2 getBytes:&startTime length:sizeof(startTime)];
            if (data.length >= 17)
            {
                
                long long changeTime = 0;
                NSData *data3 = [data subdataWithRange:NSMakeRange(9, 8)];
                [data3 getBytes:&changeTime length:sizeof(changeTime)];
                NSDate *theDate = [SynECGUtils getDateWithDateString:@"2000-01-01 00:00:00 +000" WithFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
                int8_t P;
                if (data.length == 18) {
                    NSData *percentage = [data subdataWithRange:NSMakeRange(17, 1)];
                    [percentage getBytes:&P length:sizeof(P)];
                }else{
                    P = 0;
                }
                
                if (A == 16 || A == 20 || A == 22 || A == 2 || A == 18) {
                    if(startTime == 0)
                    {
                        return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"1",@(P)];
                    }
                    else
                    {
                        NSDate *ssDate = [NSDate dateWithTimeInterval:changeTime/1000 sinceDate:theDate];
                        NSString * time =  [SynECGUtils getDateStringWithDate:ssDate WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
                        return @[time,@"1",@(P)];
                    }
                }else if (A == 17 || A == 21){
                    NSDate *ssDate = [NSDate dateWithTimeInterval:changeTime/1000 sinceDate:theDate];
                    NSString * time =  [SynECGUtils getDateStringWithDate:ssDate WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
                    return @[time,@"2",@(P)];
                    
                }
                else if(A == 18)
                {
                    //错误状态
                    NSDate *ssDate = [NSDate dateWithTimeInterval:changeTime/1000 sinceDate:theDate];
                    NSString * time =  [SynECGUtils getDateStringWithDate:ssDate WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
                    return @[time,@"1",@(P)];
                }
                
                else if (A == 19){
                    NSDate *ssDate = [NSDate dateWithTimeInterval:changeTime/1000 sinceDate:theDate];
                    NSString * time =  [SynECGUtils getDateStringWithDate:ssDate WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
                    return @[time,@"3",@(P)];
                }else if (A == 25 || A == 15){
                    NSDate *ssDate = [NSDate dateWithTimeInterval:startTime sinceDate:theDate];
                    NSString * time =  [SynECGUtils getDateStringWithDate:ssDate WithFormat:@"yyyy-MM-dd HH:mm:ss.zzz.SSS"];
                    
                    return @[time,@"9",@(P)];
                    
                }else if(A == 27 || A == 29)
                {
                    //数据积压+电极脱落
                    NSDate *ssDate = [NSDate dateWithTimeInterval:changeTime/1000 sinceDate:theDate];
                    NSString * time =  [SynECGUtils getDateStringWithDate:ssDate WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
                    return @[time,@"12",@(P)];
                }
                else if(A == 0)
                {
                    return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"1",@(P)];
                }
                else if(A == 4)
                {
                    if(startTime == 0)
                    {
                        return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"1",@(P)];
                    }
                    else
                    {
                        NSDate *ssDate = [NSDate dateWithTimeInterval:changeTime/1000 sinceDate:theDate];
                        NSString * time =  [SynECGUtils getDateStringWithDate:ssDate WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
                        return @[time,@"1",@(P)];
                    }
                }
                else if (A == 23){
                    //测量状态下的脱落加充电状态
                    NSDate *ssDate = [NSDate dateWithTimeInterval:changeTime/1000 sinceDate:theDate];
                    NSString * time =  [SynECGUtils getDateStringWithDate:ssDate WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
                    return @[time,@"3",@(P),@"1"];
                    
                    
                }else if (A == 31){
                    //测量补偿数据时脱落加充电状态
                    NSDate *ssDate = [NSDate dateWithTimeInterval:changeTime/1000 sinceDate:theDate];
                    NSString * time =  [SynECGUtils getDateStringWithDate:ssDate WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
                    return @[time,@"9",@(P),@"1"];
                }
                else if(A % 2 == 0)
                {
                    if(startTime == 0)
                    {
                        return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"1",@(P)];
                    }
                    else
                    {
                        NSDate *ssDate = [NSDate dateWithTimeInterval:changeTime/1000 sinceDate:theDate];
                        NSString * time =  [SynECGUtils getDateStringWithDate:ssDate WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
                        return @[time,@"1",@(P)];
                    }
                }
                else{
                    
                    NSLog(@"%@",[NSDate date]);
                    NSLog(@"不明状态aaaaaaaaa");
                    NSLog(@"%d",A);
                    
                    NSArray *array = [[NSArray alloc]init];
                    return array;
                    
                    
                    //                NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
                    //                NSString *old =  [user objectForKey:@"oldDeviceStatus"];
                    //                if (!old)
                    //                {
                    //                    old = @"1";
                    //                }
                    //
                    //                return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss"],old];
                    
                    
                }
            }
            else
            {
                int8_t P;
                if (data.length == 18) {
                    NSData *percentage = [data subdataWithRange:NSMakeRange(17, 1)];
                    [percentage getBytes:&P length:sizeof(P)];
                }else{
                    P = 0;
                }
                
                if (A == 16 || A == 20 || A == 22 || A == 2 || A == 18) {
                    if(startTime == 0)
                    {
                        return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"1",@(P)];
                    }
                    else
                    {
                        
                        return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"1",@(P)];
                    }
                }else if (A == 17 || A == 21){
                    
                    return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"2",@(P)];
                    
                }
                else if(A == 18)
                {
                    //错误状态
                    return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"1",@(P)];
                }
                
                else if (A == 19){
                    return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"3",@(P)];
                }else if (A == 25 || A == 15){
                    
                    return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"9",@(P)];
                    
                }else if(A == 27 || A == 29)
                {
                    //数据积压+电极脱落
                    return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"12",@(P)];
                }
                else if(A == 0)
                {
                    return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"1",@(P)];
                }
                else if(A == 4)
                {
                    if(startTime == 0)
                    {
                        return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"1",@(P)];
                    }
                    else
                    {
                        return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"1",@(P)];
                    }
                }
                else if (A == 23){
                    return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"2",@(P),@"1"];
                    
                    
                }else if (A == 31){
                    //测量补偿数据时脱落加充电状态
                    return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"9",@(P),@"1"];
                }
                else{
                    
                    NSLog(@"不明状态aaaaaaaaa");
                    NSLog(@"%d",A);
                    
                    NSArray *array = [[NSArray alloc]init];
                    return array;
                    
                    
                    //                NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
                    //                NSString *old =  [user objectForKey:@"oldDeviceStatus"];
                    //                if (!old)
                    //                {
                    //                    old = @"1";
                    //                }
                    //
                    //                return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss"],old];
                }
            }
            
        }
        
    }
    else{
        @autoreleasepool {
            NSData *data1 = [data subdataWithRange:NSMakeRange(0, 1)];
            int8_t A;
            [data1 getBytes:&A length:sizeof(A)];
            
            if(A == 0)
            {
                //预备
                NSLog(@"预备");
                return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"1"];
                
            }
            else  if (A == 1 )
            {
                //测量
                NSString * time =  [SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
                
                return @[time,@"2"];
                
            }
            else if(A == 3){
                //电极脱落
                NSData *dataB = [data subdataWithRange:NSMakeRange(1, 4)];
                int b ;
                [dataB getBytes:&b length:sizeof(b)];
                if (b == 0) {
                    
                    return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"3"];
                }
                else
                {
                    
                    NSString * time =  [SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
                    return @[time,@"3"];
                }
            }
            else if(A==9)
            {
                //补数据
                NSData *dataB = [data subdataWithRange:NSMakeRange(1, 4)];
                int b ;
                [dataB getBytes:&b length:sizeof(b)];
                NSDate *theDate = [SynECGUtils getDateWithDateString:@"2000-01-01 00:00:00 +000" WithFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
                NSDate *ssDate = [NSDate dateWithTimeInterval:b sinceDate:theDate];
                NSString * time =  [SynECGUtils getDateStringWithDate:ssDate WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
                
                return @[time,@"9"];
            }
            else if(A==8)
            {
                return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"],@"1"];
            }
            else
            {
                NSLog(@"不明状态AAAAA");
                NSLog(@"%d",A);
                
                
                NSArray *array = [[NSArray alloc]init];
                return array;
                
                //                NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
                //                NSString *old =  [user objectForKey:@"oldDeviceStatus"];
                //                if (!old)
                //                {
                //                        old = @"1";
                //                }
                //
                //
                //
                //                //预备
                //                return @[[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss"],old];
            }
        }
    }
}

- (BOOL)getBatteryStatusFRom:(NSData *)data
{
    if([SynECGLibSingleton sharedInstance].max == 1)
    {
        NSData *data1 = [data subdataWithRange:NSMakeRange(0, 1)];
        int8_t A;
        [data1 getBytes:&A length:sizeof(A)];
        
        if (A == 20 || A == 21 || A == 22 || A == 23 || A == 28 || A == 29 || A == 30 || A == 31 || A == 4 || A == 5 || A == 6 || A == 7 || A == 12 || A == 13 || A == 14 || A == 15) {
            
            return YES;
        }
        else
        {
             return NO;
        }
        
        
    }
    else
    {
        return NO;
    }
}

- (NSData *)detailedDataFromData:(NSData *)data
{
    @autoreleasepool {
    //
    int position;
    [[data subdataWithRange:NSMakeRange(30, 4)] getBytes:&position length:sizeof(position)];
    position = (position+128)/SAMPLING_REAT-3;
    Byte b = (Byte) ((position) & 0xFF);
    Byte c = (Byte) ((position>>8)& 0xFF);
    Byte d = (Byte) ((position>>16)& 0xFF);
    Byte f = (Byte) ((position>>24) & 0xFF);
    Byte g[]= {0x09,0xff,0x00,b,c,d,f,0x06,0x00,0x00,0x00};
    NSData *dataENT =[NSData dataWithBytes:&g length:sizeof(g)];
    
    return dataENT;
    }
}

- (void)setRecordId
{
    @autoreleasepool {
    

        [SynECGLibSingleton sharedInstance].startMonitorTime =[SynECGUtils getCount];
        
        ZYFMDB *model = [[ZYFMDB alloc]init];
        [model deleteTableMessageByName:TOTAL_TABLE];
        [model deleteTableMessageByName:HR_TABLE];
        [model deleteTableMessageByName:RR_TABLE];
        [model deleteTableMessageByName:BREATH_TABLE];
        [model deleteTableMessageByName:ENERGY_TABLE];
        [model deleteTableMessageByName:EVENT_TABLE];
        [model deleteTableMessageByName:HR_TABLE];
        [model deleteTableMessageByName:WATER_TABLE];
        [model deleteTableMessageByName:ALARM_TABLE];
        [model deleteTableMessageByName:ALARM_TABLE];
        [model deleteTableMessageByName:SYN_NUM];
        
    
        //开启线程
        if ([SynECGLibSingleton sharedInstance].isSuspend == YES) {
            
            
            [[ECGDecodeManager sharedInstance].eventTempData resetBytesInRange:NSMakeRange(0, [ECGDecodeManager sharedInstance].eventTempData.length)];
            [[ECGDecodeManager sharedInstance].eventTempData setLength:0];
            [ECGDecodeManager sharedInstance].needReturn = YES;
            dispatch_resume([ECGDecodeManager sharedInstance].eventQueue);
            [SynECGLibSingleton sharedInstance].isSuspend = NO;
            
        }
        
        
        
        [SynECGUtils removeEventECGData];
        
        
        [ECGDecodeManager sharedInstance].parseing = NO;
        if([ECGDecodeManager sharedInstance].eventTempData.length > 0)
        {
            [[ECGDecodeManager sharedInstance].eventTempData resetBytesInRange:NSMakeRange(0, [ECGDecodeManager sharedInstance].eventTempData.length)];
            [[ECGDecodeManager sharedInstance].eventTempData setLength:0];
        }
        
        
        if([ECGHRManager sharedInstance].tempSaveData.length > 0)
        {
            [[ECGHRManager sharedInstance].tempSaveData resetBytesInRange:NSMakeRange(0, [ECGHRManager sharedInstance].tempSaveData.length)];
            [[ECGHRManager sharedInstance].tempSaveData setLength:0];
        }
        [ECGHRManager sharedInstance].inSave = NO;
        
        
        [[SynECGLibSingleton sharedInstance].heartRateMessage removeAllObjects];
        [SynECGLibSingleton sharedInstance].maxBpm = 0;
        [SynECGLibSingleton sharedInstance].minBpm = 1000;
        [SynECGLibSingleton sharedInstance].filePathName = @"";
        [SynECGLibSingleton sharedInstance].rrUpload_Index = 0;
        [SynECGLibSingleton sharedInstance].breathUpload_Index = 0;
        [ECGDecodeManager sharedInstance].time_flag = 0;
        [ECGDecodeManager sharedInstance].p15 = 0;
        [ECGDecodeManager sharedInstance].p30 = 0;
        [ECGDecodeManager sharedInstance].p60 = 0;
        [SynECGLibSingleton sharedInstance].ecgInt = 0;
        [[SynAlarmOperationModel sharedInstance].unsinusArray removeAllObjects];
        [[SynAlarmOperationModel sharedInstance].sinusArray removeAllObjects];
        [[SynAlarmOperationModel sharedInstance].hourAArray removeAllObjects];
        [[SynAlarmOperationModel sharedInstance].hourVArray removeAllObjects];
        [[SynAlarmOperationModel sharedInstance].minuteVArray removeAllObjects];
        [[SynAlarmOperationModel sharedInstance].minuteAArray removeAllObjects];
        [SynAlarmOperationModel sharedInstance].unsinusType = @"N";
        
        
        NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
        [user setObject:@([SynECGLibSingleton sharedInstance].startMonitorTime) forKey:@"syn_startTime"];
    }
}

- (NSString *)getRecordFormData:(NSData *)data{
    
    NSString *str = [SynECGLibSingleton sharedInstance].target_id;
    str = [str stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSMutableData* dataUU = [NSMutableData data];
    int idx;
    for (idx = 0; idx+2 <= str.length; idx+=2)
    {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [str substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [dataUU appendBytes:&intValue length:1];
    }
    
    int changeTimeS = 0;
    NSData *data3 = [data subdataWithRange:NSMakeRange(1, 4)];
    [data3 getBytes:&changeTimeS length:sizeof(changeTimeS)];
    
    int changeTimeMS = 0;
    NSData *data4 = [data subdataWithRange:NSMakeRange(7, 2)];
    [data4 getBytes:&changeTimeMS length:sizeof(changeTimeMS)];
    
    long  long time = (long long)changeTimeS*1000+ (long long)changeTimeMS + 946656000000+28800000;
    
    long long  value1 = CFSwapInt64BigToHost(time);
    
    NSData *data5 =[NSData dataWithBytes:&value1 length:sizeof(value1)];
    
    NSMutableData *dataAll = [NSMutableData dataWithData:dataUU];
    [dataAll appendData:data5];
    
    return  [SynECGUtils hexadecimalString:dataAll];
    
};



- (void)saveStartMessage
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    NSString *filePathName = [docDir stringByAppendingPathComponent:[[NSString alloc]initWithFormat:@"synCache/%@.dat",[SynECGLibSingleton sharedInstance].record_id]];
    
    [SynECGLibSingleton sharedInstance].ecgTempFile = filePathName;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL haveFile = [fileManager fileExistsAtPath:filePathName];
    if (!haveFile)
    {
        //创建
        [fileManager createFileAtPath:filePathName contents:nil attributes:nil];
    }
    else
    {
        //覆盖
        [fileManager createFileAtPath:filePathName contents:nil attributes:nil];
    }
    
    if ([ECGHRManager sharedInstance].ecgOutFile != nil) {
        
        [[ECGHRManager sharedInstance].ecgOutFile closeFile];
        [ECGHRManager sharedInstance].ecgOutFile = nil;
    }
    
        
    [ECGHRManager sharedInstance].ecgOutFile = [NSFileHandle fileHandleForUpdatingAtPath:[SynECGLibSingleton sharedInstance].ecgTempFile];
    
    
    
    [[SDBManager defaultDBManager].queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL save = [db executeUpdate:@"INSERT INTO measure_table (hr, hrv, ecg, event, ann, act, rsp, ecgUpload, rrUpload, a_np, a_up, a_r, recordId) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",@(0), @(0),@(0),@(0),@(0),@(0),@(0),@(0),@(0),@(0),@(0),@"N",[SynECGLibSingleton sharedInstance].record_id];
        
        if (!save) {
            NSLog(@"save error");
            [self saveStartMessage];
        }
        else
        {
            NSLog(@"save sc ");
        }
    }];
}

//记录列表
- (NSData *)getListRecord{
    @autoreleasepool {
        //点击停止的时候 写入该data
        Byte list[] = {0x07};
        NSData *dataList = [NSData dataWithBytes:&list length:sizeof(list)];
        
        return dataList;
    }
    
}

@end
