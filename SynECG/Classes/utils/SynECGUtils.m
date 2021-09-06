//
//  SynECGUtils.m
//  SynECG
//
//  Created by LiangXiaobin on 16/6/30.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import "SynECGUtils.h"
#import "zlib.h"
#import "SynConstant.h"
#import "SynECGLibSingleton.h"
#import <UIKit/UIKit.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import "SDBManager.h"

static NSString * const KSTPT1 = @"KSTARTPOSITION1";
static NSString * const KSTPT2 = @"KSTARTPOSITION2";
static NSString * const KSTTP = @"KSTARTTYPE";

static const char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static NSString * const KSECGDATA = @"ECGDATAType";

@implementation SynECGUtils


+ (NSNumber *)setTypeFromEventType:(NSString *)str
{
    if ([str hasSuffix:@"on"]) {
        
        return [NSNumber numberWithInt:1];
    }
    else if([str hasSuffix:@"off"])
    {
        return [NSNumber numberWithInt:2];
    }
    else
    {
        return [NSNumber numberWithInt:0];
    }
    
    
}

- (void)setRecordId
{
    NSString *str = [SynECGLibSingleton sharedInstance].target_id;
    NSLog(@"%@",str);
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
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [s substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [dataUU appendBytes:&intValue length:1];
    }
    NSLog(@"%@",dataUU);
    
    //开始  点击开始的时候 写入该data
    int value = (int)[SynECGUtils getCount];
    Byte b = (Byte) ((value) & 0xFF);
    Byte c = (Byte) ((value>>8)& 0xFF);
    Byte d = (Byte) ((value>>16)& 0xFF);
    Byte f = (Byte) (value>>24 & 0xFF);
    NSLog(@"%hhu,%hhu,%hhu,%hhu",b,c,d,f);
    Byte g[]= {b,c,d,f};
    NSData *data =[NSData dataWithBytes:&g length:sizeof(g)];
    NSLog(@"%@",data);
    
    NSMutableData *dataAll = [NSMutableData dataWithData:dataUU];
    [dataAll appendData:data];
    
    [SynECGLibSingleton sharedInstance].record_id = [SynECGUtils hexadecimalString:dataAll];
    
}


+ (BOOL)isApplicationStateInactiveORBackground {
    UIApplicationState applicationState = [[UIApplication sharedApplication] applicationState];
    return applicationState == UIApplicationStateInactive || applicationState == UIApplicationStateBackground;
}

+(void)showAlert:(NSString *)message withController:(UIViewController *)controller
{
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"DFU" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    // Create the actions.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        NSLog(@"The \"Okay/Cancel\" alert's cancel action occured.");
    }];
    
    // Add the actions.
    [alertController addAction:cancelAction];
    
    
    [controller presentViewController:alertController animated:YES completion:nil];
    
}

+(void)showBackgroundNotification:(NSString *)message
{
    
//    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
//        
//        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
//        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound)
//                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
//                                  if(granted)
//                                  {
//                                      NSLog(@"授权成功");
//                                  }
//                              }];
//        //regitser
//        UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
//        content.title = [NSString localizedUserNotificationStringForKey:@"" arguments:nil];
//        content.body = [NSString localizedUserNotificationStringForKey:message arguments:nil];
//        content.subtitle = [NSString localizedUserNotificationStringForKey:@"" arguments:nil];
//        content.sound = [UNNotificationSound defaultSound];
//        
//        // Deliver the notification in ten seconds.
//        UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:10 repeats:NO];
//        UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:@"FiveSecond"
//                                                                              content:content
//                                                                              trigger:trigger];
//        
//        // Schedule the notification.
//        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
//            if(error)
//            {
//                NSLog(@"%@",error);
//            }
//        }];
//     
//        
//    }
//    else {
//        //categories 必须为nil
//#if __IPHONE_OS_VERSION_MAX_ALLOWED < 100000
//    
//        UILocalNotification *notification = [[UILocalNotification alloc]init];
//        notification.alertAction = @"Show";
//        notification.alertBody = message;
//        notification.hasAction = NO;
//        notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
//        notification.timeZone = [NSTimeZone  defaultTimeZone];
//        notification.soundName = UILocalNotificationDefaultSoundName;
//        [[UIApplication sharedApplication] setScheduledLocalNotifications:[NSArray arrayWithObject:notification]];
//#endif
//    }

}


+ (NSInteger)ageWithDateOfBirth:(NSDate *)date
{
    
    if ([date isKindOfClass:[NSDate class]] && date) {
        
        // 出生日期转换 年月日
        NSDateComponents *components1 = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
        NSInteger brithDateYear  = [components1 year];
        NSInteger brithDateDay   = [components1 day];
        NSInteger brithDateMonth = [components1 month];
        
        // 获取系统当前 年月日
        NSDateComponents *components2 = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
        NSInteger currentDateYear  = [components2 year];
        NSInteger currentDateDay   = [components2 day];
        NSInteger currentDateMonth = [components2 month];
        
        // 计算年龄
        // 计算年龄
        NSInteger iAge = currentDateYear - brithDateYear - 1;
        if ((currentDateMonth > brithDateMonth) || (currentDateMonth == brithDateMonth && currentDateDay >= brithDateDay)) {
            iAge++;
        }
        
        if (iAge >= 2) {
            //St_Type9Age ---年龄
            return iAge;
        }
        else
        {
            //St_Type9Age ---年龄
            return 1;
        }
    }
    else
    {
        return 30;
    }
}



//根据格式获取当前日期
+ (NSDate *)getDateWithDateString:(NSString *)dateString WithFormat:(NSString *)format
{
    
    [[SynECGLibSingleton sharedInstance].dateFormatter setDateFormat:format];
    NSDate *date = [[SynECGLibSingleton sharedInstance].dateFormatter dateFromString:dateString];
    return date;
    
}

//根据格式获取当前日期
+ (NSString *)getDateStringWithDate:(NSDate *)date WithFormat:(NSString *)format
{
    @autoreleasepool {
     
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:format];
        return [dateFormatter stringFromDate:date==nil?[NSDate date]:date];
    }
}

//压缩
+ (NSData *)gzipDeflate:(NSData*)data
{
    @autoreleasepool {
     
        if ([data length] == 0) return data;
        
        z_stream strm;
        
        strm.zalloc = Z_NULL;
        strm.zfree = Z_NULL;
        strm.opaque = Z_NULL;
        strm.total_out = 0;
        strm.next_in=(Bytef *)[data bytes];
        strm.avail_in = (uInt)[data length];
        
        // Compresssion Levels:
        //   Z_NO_COMPRESSION
        //   Z_BEST_SPEED
        //   Z_BEST_COMPRESSION
        //   Z_DEFAULT_COMPRESSION
        
        if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
        
        NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
        
        do {
            
            if (strm.total_out >= [compressed length])
                [compressed increaseLengthBy: 16384];
            
            strm.next_out = [compressed mutableBytes] + strm.total_out;
            strm.avail_out = (uInt)([compressed length] - strm.total_out);
            
            deflate(&strm, Z_FINISH);
            
        } while (strm.avail_out == 0);
        
        deflateEnd(&strm);
        
        [compressed setLength: strm.total_out];
        return [NSData dataWithData:compressed];
    }
}

/**
 *  data转字符串
 */
+ (NSString *)base64EncodedStringFrom:(NSData *)data
{
    @autoreleasepool {

    if ([data length] == 0)
        return @"";
    
    char *characters = malloc((([data length] + 2) / 3) * 4);
    if (characters == NULL)
        return nil;
    NSUInteger length = 0;
    
    NSUInteger i = 0;
    while (i < [data length])
    {
        char buffer[3] = {0,0,0};
        short bufferLength = 0;
        while (bufferLength < 3 && i < [data length])
            buffer[bufferLength++] = ((char *)[data bytes])[i++];
        
        //  Encode the bytes in the buffer to four characters, including padding "=" characters if necessary.
        characters[length++] = encodingTable[(buffer[0] & 0xFC) >> 2];
        characters[length++] = encodingTable[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];
        if (bufferLength > 1)
            characters[length++] = encodingTable[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) >> 6)];
        else characters[length++] = '=';
        if (bufferLength > 2)
            characters[length++] = encodingTable[buffer[2] & 0x3F];
        else characters[length++] = '=';
    }
    
    return [[NSString alloc] initWithBytesNoCopy:characters length:length encoding:NSASCIIStringEncoding freeWhenDone:YES];
        
    }
}


/**
 * 十六进制字符串转data
 */
+ (NSData *)fan_hexToBytes:(NSString *)hexString{
    @autoreleasepool {
    NSUInteger leng=hexString.length;
    NSMutableData *data=[[NSMutableData alloc]init];
    for (int i=0; i<leng/2; i++) {
        unsigned long red=strtoul([[hexString substringWithRange:NSMakeRange(i*2, 2)] UTF8String], 0, 16);
        Byte b=red;
        [data appendBytes:&b length:1];
    }
    return data;
        
    }
}

/**
 * data 转十六进制字符串
 */
+ (NSString*)hexadecimalString:(NSData *)data{
    @autoreleasepool {
    NSString* result;
    const unsigned char* dataBuffer = (const unsigned char*)[data bytes];
    if(!dataBuffer){
        return nil;
    }
    NSUInteger dataLength = [data length];
    NSMutableString* hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for(int i = 0; i < dataLength; i++){
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    result = [NSString stringWithString:hexString];
    return result;
        
    }
}
/**
 *  data 转16进制字符串
 */
+ (NSString *)fan_dataToHexString:(NSData *)data{
    @autoreleasepool {
     
        Byte *bytehex =(Byte *) data.bytes;
        NSMutableString *hexString=[[NSMutableString alloc]init];
        for (int i=0; i<data.length; i++) {
            Byte b=bytehex[i];
            [hexString appendFormat:@"%02X",b];
        }
        return hexString;
    }
}

+ (NSInteger)getCount
{
    @autoreleasepool {
     
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];  // 设置时间格式
        
        NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        
        [dateFormatter setTimeZone:timeZone]; //设置时区 ＋8:00
        NSString  *someDayStr= @"2000-01-01 00:00:00";   // 设置过去的某个时间点比如:2000-01-01 00:00:00
        
        NSDate *someDayDate = [dateFormatter dateFromString:someDayStr];
        
        NSDate *currentDate = [NSDate date];
        
        NSTimeInterval time=[currentDate timeIntervalSinceDate:someDayDate];  //当前时间距离2000-01-01 00：00：00的秒数
        NSString *str = [NSString stringWithFormat:@"%f",time];
        return  [str integerValue];
    }
}
+ (long long)getMSCount{
    NSDate *currentDate = [NSDate date];
    long long time = [currentDate timeIntervalSince1970];
    return time;
    
}
+ (NSString *)setOccerTimeFromPastSeconds:(NSInteger)past
{
    NSInteger time = (NSInteger)(past + [SynECGLibSingleton sharedInstance].startMonitorTime  + 946656000 + 8 * 60 * 60 );
    
    [[SynECGLibSingleton sharedInstance].dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *destDateString = [[SynECGLibSingleton sharedInstance].dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:time]];

    
    return destDateString;

    
}

//毫秒时间戳
+ (long long)setOccerTimeUnixTimestampFromPastSeconds:(NSInteger)past
{
    long long a = 946656000000 + 8 * 60 * 60 *1000;
    long long b = (long long)[SynECGLibSingleton sharedInstance].startMonitorTime * 1000;
    long long c = a + b;
    long long d = c + past;
    
    
    return d;
}


+ (NSString *)timeWithTimeIntervalString:(NSString *)timeString
{
    // 格式化时间
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone localTimeZone];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    // 毫秒值转化为秒
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:[timeString doubleValue]/ 1000.0];
    NSString* dateString = [formatter stringFromDate:date];
    return dateString;
}


/**
 *  获取IP地址
 */
+ (NSString *)getIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

/**
 *  十进制转2进制
 */
+ (NSString *)toBinarySystemWithDecimalSystem:(int)num length:(int)length
{
    @autoreleasepool {
    int remainder = 0;      //余数
    int divisor = 0;        //除数
    
    NSString * prepare = @"";
    
    while (true)
    {
        remainder = num%2;
        divisor = num/2;
        num = divisor;
        prepare = [prepare stringByAppendingFormat:@"%d",remainder];
        
        if (divisor == 0)
        {
            break;
        }
    }
    //倒序输出
    NSString * result = @"";
    for (int i = length -1; i >= 0; i --)
    {
        if (i <= prepare.length - 1) {
            result = [result stringByAppendingFormat:@"%@",
                      [prepare substringWithRange:NSMakeRange(i , 1)]];
            
        }else{
            result = [result stringByAppendingString:@"0"];
            
        }
    }
    return result;
        
    }
}
/**
 *  二进制转十六进制
 */
+ (NSString *)getBinaryBybinary:(NSString *)binary
{
    @autoreleasepool {
    NSMutableDictionary  *hexDic = [[NSMutableDictionary alloc] initWithCapacity:16];
    [hexDic setObject:@"0000" forKey:@"0"];
    [hexDic setObject:@"0001" forKey:@"1"];
    [hexDic setObject:@"0010" forKey:@"2"];
    [hexDic setObject:@"0011" forKey:@"3"];
    [hexDic setObject:@"0100" forKey:@"4"];
    [hexDic setObject:@"0101" forKey:@"5"];
    [hexDic setObject:@"0110" forKey:@"6"];
    [hexDic setObject:@"0111" forKey:@"7"];
    [hexDic setObject:@"1000" forKey:@"8"];
    [hexDic setObject:@"1001" forKey:@"9"];
    [hexDic setObject:@"1010" forKey:@"a"];
    [hexDic setObject:@"1011" forKey:@"b"];
    [hexDic setObject:@"1100" forKey:@"c"];
    [hexDic setObject:@"1101" forKey:@"d"];
    [hexDic setObject:@"1110" forKey:@"e"];
    [hexDic setObject:@"1111" forKey:@"f"];
    
    NSMutableString *binaryString=[[NSMutableString alloc] init];
    for (int i=0; i<binary.length; i+=4) {
        NSString *subStr = [binary substringWithRange:NSMakeRange(i, 4)];
        int index = 0;
        for (NSString *str in hexDic.allValues) {
            index ++;
            if ([subStr isEqualToString:str]) {
                [binaryString appendString:hexDic.allKeys[index-1]];
                break;
            }
        }
    }
    NSMutableString *binaryString1=[[NSMutableString alloc] init];
    for (NSInteger  i = binaryString.length-2; i>= 0; i -=2) {
        NSString *substr = [binaryString substringWithRange:NSMakeRange(i, 2)];
        [binaryString1 appendString:substr];
    }
    return binaryString1;
        
    }
}

/**
 * 十进制转16进制
 */
//将十进制转化为十六进制
+ (NSString *)ToHex1:(int)tmpid isfront:(BOOL)front
{
    @autoreleasepool {
    NSString *nLetterValue;
    NSString *str =@"";
    int ttmpig;
    for (int i = 0; i<9; i++) {
        ttmpig=tmpid%16;
        tmpid=tmpid/16;
        switch (ttmpig)
        {
            case 10:
                nLetterValue =@"a";break;
            case 11:
                nLetterValue =@"b";break;
            case 12:
                nLetterValue =@"c";break;
            case 13:
                nLetterValue =@"d";break;
            case 14:
                nLetterValue =@"e";break;
            case 15:
                nLetterValue =@"f";break;
            default:
                nLetterValue = [NSString stringWithFormat:@"%u",ttmpig];
                
        }
        str = [nLetterValue stringByAppendingString:str];
        if (tmpid == 0) {
            break;
        }
    }
    //不够一个字节凑0
    NSString *tt;
    if(str.length == 1){
        tt = [NSString stringWithFormat:@"0000%@",str];
    }else if(str.length == 2){
        tt = [NSString stringWithFormat:@"000%@",str];
    }else if(str.length == 3){
        tt = [NSString stringWithFormat:@"00%@",str];
    }else if(str.length == 4){
        tt = [NSString stringWithFormat:@"0%@",str];
    }else{
        tt = str;
    }
    NSString *last = [NSString new];
    if (front == YES) {
        last = [last stringByAppendingFormat:@"%@%@%@",[tt substringWithRange:NSMakeRange(3, 2)],[tt substringWithRange:NSMakeRange(1, 2)],[tt substringWithRange:NSMakeRange(0, 1)]];
    }else{
        last = [NSString stringWithFormat:@"%@%@%@",[tt substringWithRange:NSMakeRange(4, 1)],[tt substringWithRange:NSMakeRange(2, 2)],[tt substringWithRange:NSMakeRange(0, 2)]];
    }

    return last;
        
    }
}

//生成随机uuid
+ (NSString *)uuidString
{
         CFUUIDRef uuid_ref = CFUUIDCreate(NULL);
         CFStringRef uuid_string_ref= CFUUIDCreateString(NULL, uuid_ref);
         NSString *uuid = [NSString stringWithString:(__bridge NSString *)uuid_string_ref];
         CFRelease(uuid_ref);
         CFRelease(uuid_string_ref);
         return [uuid lowercaseString];
    }

+ (void)saveEventECGData:(NSData *)ecg{
    [[NSUserDefaults standardUserDefaults] setObject:ecg forKey:KSECGDATA];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
//    [SynECGLibSingleton sharedInstance].ecgData = ecg;
    
    
}


+ (NSData *)getEventECGData{
    return [[NSUserDefaults standardUserDefaults] objectForKey:KSECGDATA];
    
//    return [SynECGLibSingleton sharedInstance].ecgData;
    
    
}

+ (void)removeEventECGData{
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:KSECGDATA];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
//    NSData *data = [[NSData alloc]init];
    
//    [SynECGLibSingleton sharedInstance].ecgData = data;
    
    
    
}


+ (NSString*)convertToJSONData:(id)infoDict
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoDict
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    NSString *jsonString = @"";
    
    if (! jsonData)
    {
        NSLog(@"Got an error: %@", error);
    }else
    {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    jsonString = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];  //去除掉首尾的空白字符和换行字符
    
    [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    return jsonString;
}

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
        return nil;
    }
    return dic;
}


+ (void)saveStartPosition1:(NSNumber *)ect{
    [[NSUserDefaults standardUserDefaults] setObject:ect forKey:KSTPT1];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}
+ (NSNumber *)getStartPosition1{
    return [[NSUserDefaults standardUserDefaults] objectForKey:KSTPT1];
}

+ (void)saveStartPosition2:(NSNumber *)ect{
    [[NSUserDefaults standardUserDefaults] setObject:ect forKey:KSTPT2];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}
+ (NSNumber *)getStartPosition2{
    return [[NSUserDefaults standardUserDefaults] objectForKey:KSTPT2];
}

+ (void)saveStartType:(NSString *)ect{
    [[NSUserDefaults standardUserDefaults] setObject:ect forKey:KSTTP];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}
+ (NSString *)getStartStartType{
    return [[NSUserDefaults standardUserDefaults] objectForKey:KSTTP];
}


@end
