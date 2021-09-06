//
//  SynECGLibSingleton.m
//  libSynECG
//
//  Created by LiangXiaobin on 16/6/29.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import "SynECGLibSingleton.h"
#import "SynConstant.h"

@implementation SynECGLibSingleton
+ (instancetype)sharedInstance
{
    static SynECGLibSingleton *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[SynECGLibSingleton alloc]init];
        _sharedInstance.user_id = [[NSString alloc]init];
        _sharedInstance.target_id = [[NSString alloc]init];
        _sharedInstance.record_id = [[NSString alloc]init];
        _sharedInstance.baseurl = [[NSString alloc]init];
        _sharedInstance.token = [[NSString alloc]init];
        _sharedInstance.hardwareVer = [[NSString alloc]init];
        _sharedInstance.firmwareVer = [[NSString alloc]init];
        _sharedInstance.deviceSN = [[NSString alloc]init];
        _sharedInstance.deviceId = [[NSString alloc]init];
        _sharedInstance.deviceTypeId = [[NSString alloc]init];
        _sharedInstance.deviceName = [[NSString alloc]init];
        _sharedInstance.update_url = [[NSString alloc]init];
        _sharedInstance.filePathName = [[NSString alloc]init];
        _sharedInstance.heartRateMessage = [[NSMutableDictionary alloc]init];
        _sharedInstance.activityType = [[NSString alloc]init];
        _sharedInstance.softwareVer = [[NSString alloc]init];
        _sharedInstance.averageHR = 0;
        _sharedInstance.typeNum = 0;
        _sharedInstance.mac = [[NSString alloc]init];
        _sharedInstance.rrUpload_Index = 0;
        _sharedInstance.breathUpload_Index = 0;
        _sharedInstance.dateFormatter = [[NSDateFormatter alloc]init];
        [_sharedInstance.dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        _sharedInstance.mac = [[NSString alloc]init];
        _sharedInstance.max = 0;
        _sharedInstance.maxBpm = 0;
        _sharedInstance.minBpm = 1000;
        _sharedInstance.ecgData = [[NSData alloc]init];
        _sharedInstance.ecgTempFile = [[NSString alloc]init];
        _sharedInstance.inBackground = NO;
        _sharedInstance.ecgInt = 0;
        _sharedInstance.isSuspend = NO;
        _sharedInstance.userName = [[NSString alloc]init];
        _sharedInstance.loginIn = NO;
        _sharedInstance.typeIndex = 0;
        _sharedInstance.deviceVerType = 1;
    });
    return _sharedInstance;
}
@end
