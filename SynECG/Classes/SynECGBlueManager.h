//
//  SynECGBlueManager.h
//  libSynECG
//
//  Created by LiangXiaobin on 16/6/29.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <iOSDFULibrary/iOSDFULibrary-Swift.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef void(^CommonBlockCompletion)(id obj);

@protocol SYNScatterDelegate <NSObject>
@optional
/**
 历史rr数据
 
 @param rriArray rr数组
 */
- (void)syn_ecgHistoryAnn:(NSArray *)rriArray;


- (void)syn_ecgHistoryBpm:(NSDictionary *)hrValue;
@end


@protocol SYNDFUDelegate <NSObject>

@optional
//升级状态：
-(void)syn_ecgdidStateChangedTo:(enum DFUState)state;

//升级进度：
-(void)syn_ecgOnUploadProgress:(NSInteger)percentage;


@end

@protocol SYNBlueToothDelegate <NSObject>

@optional
- (void)syn_ecgSearchDeviceWithInfo:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)message;

@end



@protocol SYNECGDataDelegate <NSObject>

@optional



/**
 *  设备是否可以升级
 */

- (void)syn_ecgFirmWareCanUpdate:(BOOL)status;

/**
 *  设备电量
 */
- (void)syn_ecgMessageOnDeviceBattery:(NSInteger)batteryLevel;

/**
 *  设备状态
 */
- (void)syn_ecgMessageOnDeviceStatus:(NSDictionary *)status;
/**
 *  实时心率
 */
- (void)syn_ecgMessageOnHRValue:(NSDictionary *)hrValue;
/**
 *  hrv数据
 */
 - (void)syn_ecgMessageOnHRVValue:(NSDictionary*)hrvValue;
/**
 *  实时姿态数据
 */
- (void)syn_ecgMessageOnActivityValue:(NSDictionary *)activityValue;
/**
 *  呼吸数据
 */
- (void)syn_ecgMessageOnBreathValue:(NSDictionary *)breathValue;
/**
 *  异常数据
 */
- (void)syn_ecgMessageOnEventValue:(NSDictionary *)eventValue;

/**
 *  心电数据
 */
- (void)syn_ecgMessageOnECG:(NSData *)ecgArray;

/**
 *  ANN数据 数组里面是字典 
 */
- (void)syn_ecgMessageOnAnn:(NSArray *)annArray;

/**
 *  告警数据
 */
- (void)syn_ecgMessageOnAlert:(NSDictionary *)alertValue;


/**
 *  补数据进度
 */
- (void)syn_ecgMessageOnToFillTheData:(NSInteger)percentValue;


/**
 *  补数据进度
 */
- (void)syn_ecgMessageOnPercentValue:(NSInteger)percentValue andSpendTime:(NSInteger)st andV:(float)v andUnfinishTime:(NSInteger)ufTime;

/**
 *  是否在充电
 */
- (void)syn_ecgMessageOnToCharging:(BOOL)charging;


/**
补传结束
 */
- (void)syn_ecgMessageOnToSFTF:(BOOL)sftf;

/**
 信号级别
 */
- (void)syn_ecgSignalLevel:(NSInteger)level;


@end


@interface SynECGBlueManager : NSObject
@property(nonatomic,weak)id<SYNBlueToothDelegate> searchDelegate;
@property(nonatomic,weak)id<SYNECGDataDelegate> dataSource;
@property(nonatomic,weak)id<SYNDFUDelegate> dfuDelegate;
@property(nonatomic,weak)id<SYNScatterDelegate> sctDelegate;
//当前的状态
@property (nonatomic,assign)NSInteger typeNum;

//开始测量的时间
@property (nonatomic,assign)NSInteger startTime;

@property (nonatomic,assign)NSInteger cellType;
@property (nonatomic,assign)NSInteger batteryNum;
@property (nonatomic,retain)NSString *recordId;
@property(nonatomic,copy) NSString *nowfirmwareNumber;
@property(nonatomic,copy) NSString *firmwareNumber;
@property(nonatomic,assign)BOOL canUpdateFirmWare;
@property(nonatomic,assign)BOOL needMandatoryUpdateFirmWare;
@property(nonatomic,retain)NSString *descMessage;
//当前蓝牙状态;
@property(nonatomic,assign)BOOL btStatus;
@property(nonatomic,copy) NSString *deviceName;
//是否需要重连
@property(nonatomic ,assign) BOOL needReLink;
//需要扫描
@property (nonatomic,assign)BOOL needSearch;
//不要动
@property (nonatomic,strong)NSTimer *recordTimer;

/**
 型号强度0 - 3
 */
@property (nonatomic,assign)NSInteger signalLevel;

/**
 *  初始化
 */

+ (instancetype)sharedInstance;

/**
 *  开始扫描蓝牙设备并且连接设备
 */
- (void)syn_ecgScanAndConnectionDevice;

/**
 固件更新后
 */
- (void)syn_ecgReScanAndConnectionDevice;
/**
 *  开始扫描蓝牙设备不连接设备
 */
- (void)syn_ecgScanSearchDevice;


/**
 *  停止扫描蓝牙设备
 */
- (void)syn_ecgCancelSearchDevice;

/**
 *  升级失败，重设蓝牙
 */
- (void)reSetManager;


/**
 *  断开设备
 */
- (void)syn_ecgDisconnectDevice;


/**
 *  开始检测
 */
- (void)syn_ecgStartMeasurementWithCompletion:(CommonBlockCompletion)completionCallback;

/**
 *  停止检测
 */
 - (void)syn_ecgStopMeasurement;

/**
 *  获取全部告警水位线
 */

- (void)syn_ecgGetAllAlertWaterMarkByTimeWithCompletion:(CommonBlockCompletion)completionCallback;

- (void)syn_ecgGetAllAlertWaterMarkByLevelWithCompletion:(CommonBlockCompletion)completionCallback;

/**
 *  设备固件更新
 *
 *  @param completionCallback 回调
 */
- (void)syn_ecgFirmWareUpdateWithCompletion:(CommonBlockCompletion)completionCallback;

/**
 *  切换设备状态(换设备,删除设备)时候使用它。
 */
- (void)changeBluetoothWorkStatus;

//返回当前数据库中请求数数据;
- (void)getNowInternetNumWithCompletion:(CommonBlockCompletion)completionCallback;

//rri
- (void)getRRIDataFromTime:(NSInteger)startTime WithCompletion:(CommonBlockCompletion)completionCallback;

/**
 连接设备 测试专用
 
 @param message 设备信息
 */
- (void)syn_ecgScanSearchDeviceWithMessage:(NSDictionary *)message;
/**
 开始测量 测试专用
 */
- (void)syn_ecgStartMonitoringECGWithCompletion:(CommonBlockCompletion)completionCallback;
/**
 停止测量 测试专用
 */
- (void)syn_ecgEndMonitoringECG;

/**
 停止测量 退出登录
 */
- (void)syn_ecgLoginOut;

/**
 获取历史rri
 @param length 每次的长度
 */
- (void)syn_getRRiWithLength:(NSInteger)length withStart:(NSInteger)startNum;


/**
 终止获取
 */
- (void)syn_closeRRi;
@end
