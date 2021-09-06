//
//  SynECGUtils.h
//  SynECG
//
//  Created by LiangXiaobin on 16/6/30.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SynECGUtils : NSObject

+ (BOOL)isApplicationStateInactiveORBackground;

+ (NSNumber *)setTypeFromEventType:(NSString *)str;

+(void)showAlert:(NSString *)message withController:(UIViewController *)controller;

+(void)showBackgroundNotification:(NSString *)message;

//生日转年龄
+ (NSInteger)ageWithDateOfBirth:(NSDate *)date;

//根据格式获取当前日期(NSDate)
+ (NSDate *)getDateWithDateString:(NSString *)dateString WithFormat:(NSString *)format;

//根据格式获取当前日期(NSString)
+ (NSString *)getDateStringWithDate:(NSDate *)date WithFormat:(NSString *)format;

//压缩
+ (NSData *)gzipDeflate:(NSData*)data;

/**
 *  data转字符串
 */
+ (NSString *)base64EncodedStringFrom:(NSData *)data;

/**
 * 十六进制字符串转data
 */
+ (NSData *)fan_hexToBytes:(NSString *)hexString;
/**
 * data 转十六进制字符串
 */
+ (NSString*)hexadecimalString:(NSData *)data;
/**
 *  data 转16进制字符串
 */
+ (NSString *)fan_dataToHexString:(NSData *)data;

+ (NSInteger)getCount;
+ (long long)getMSCount;

+ (NSString *)setOccerTimeFromPastSeconds:(NSInteger)past;

+ (long long)setOccerTimeUnixTimestampFromPastSeconds:(NSInteger)past;

+ (NSString *)timeWithTimeIntervalString:(NSString *)timeString;


+ (NSString *)getIPAddress;
/**
 *  二进制转十六进制
 */
+ (NSString *)getBinaryBybinary:(NSString *)binary;
/**
 *  十进制转2进制
 */
+ (NSString *)toBinarySystemWithDecimalSystem:(int)num length:(int)length;

/**
 * 十进制转16进制
 */
+ (NSString *)ToHex1:(int)tmpid isfront:(BOOL)front;

//生成随机uuid
+ (NSString *)uuidString;

+ (void)saveEventECGData:(NSData *)ecg;

+ (NSData *)getEventECGData;

+ (void)removeEventECGData;

//字典转jison
+ (NSString*)convertToJSONData:(id)infoDict;

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;



+ (void)saveStartPosition1:(NSNumber *)ect;
+ (NSNumber *)getStartPosition1;

+ (void)saveStartPosition2:(NSNumber *)ect;
+ (NSNumber *)getStartPosition2;

+ (void)saveStartType:(NSString *)ect;
+ (NSString *)getStartStartType;



@end
