//
//  SynECGLibSingleton.h
//  libSynECG
//
//  Created by LiangXiaobin on 16/6/29.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface SynECGLibSingleton : NSObject

@property (nonatomic,copy)NSString *userName;
@property (nonatomic, assign)NSInteger startMonitorTime;
@property (nonatomic,copy) NSString *mac;
@property (nonatomic, copy)NSString *user_id;
@property (nonatomic, copy)NSString *target_id;
@property (nonatomic, copy)NSString *record_id;

@property (nonatomic,copy)NSString *baseurl;

@property (nonatomic,copy)NSString *token;
@property (nonatomic,copy)NSString *deviceId;
@property (nonatomic,copy)NSString *deviceTypeId;
@property (nonatomic,copy)NSString *deviceName;


@property (nonatomic,copy)NSString *hardwareVer;
@property (nonatomic,copy)NSString *firmwareVer ;
@property (nonatomic,copy)NSString *deviceSN;
@property (nonatomic,copy)NSString *softwareVer;

@property (nonatomic,assign)NSInteger deviceVerType;

@property (nonatomic,copy)NSString *update_url;
//心率相关数据
@property(nonatomic,strong)NSMutableDictionary *heartRateMessage;
//最大心率
@property (nonatomic,assign)NSInteger maxBpm;
@property (nonatomic,assign)NSInteger minBpm;



//实时运动姿态
@property(nonatomic,copy)NSString *activityType;
//平均心率
@property(nonatomic,assign)NSInteger averageHR;

@property (nonatomic,assign)NSInteger typeNum;

@property (nonatomic,copy)NSString *filePathName;
//rr上传次数标记
@property(nonatomic,assign)NSInteger rrUpload_Index;
//呼吸上传次数标记
@property(nonatomic,assign)NSInteger breathUpload_Index;
//当前的ecg长度
@property(nonatomic,assign)NSInteger ecgInt;
//
@property(nonatomic,assign)BOOL isSuspend;

@property(nonatomic,copy)NSDateFormatter *dateFormatter;

@property (nonatomic, assign)NSInteger max;

@property (nonatomic, strong)NSData *ecgData;

@property (nonatomic, strong)NSString *ecgTempFile;

@property (nonatomic, assign)BOOL inBackground;
@property (nonatomic, assign)BOOL loginIn;

@property (nonatomic, assign)NSInteger typeIndex;

+ (instancetype)sharedInstance;
@end
