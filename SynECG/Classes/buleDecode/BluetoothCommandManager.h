//
//  BluetoothCommandManager.h
//  XHJY_app
//
//  Created by LiangXiaobin on 16/5/25.
//  Copyright © 2016年 成都信汇聚源科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BluetoothCommandManager : NSObject

typedef void (^StatusBlock)(NSString *time,NSString *status);
typedef void (^Comback)(id obj);

+ (instancetype)sharedInstance;
/**
 *  个人信息
 *
 */
- (void)writePersonInfoMessageWith:(Comback)complection;

/**
 *  新版本个人信息
 *
 */
- (void)writeNewPersonInfoMessageWith:(Comback)complection;

/**
 *  开启全部视图
 *
 */

- (NSData *)startView;

/**
 *  开始
 *
 */

- (NSData *)startMonitoringECG;

/**
 *  结束
 *
 */

- (NSData *)endMonitoringECG;

/**
 *  监控状态
 */

- (NSArray *)getStatus:(NSData *)data;


/**
 *  充电状态
 */

- (BOOL)getBatteryStatusFRom:(NSData *)data;

/**
 *  获取详细数据
 */

- (NSData *)detailedDataFromData:(NSData *)data;

/**
 *  打开offset视图
 */
- (void)openViewWith:(Comback)complection;

- (void)setRecordId;

- (NSData *)dataTransfromBigOrSmall:(NSData *)data;

//记录列表
- (NSData *)getListRecord;

- (NSString *)getRecordFormData:(NSData *)data;

- (void)saveStartMessage;
@end
