//
//  SynECGBlueManager.m
//  libSynECG
//
//  Created by LiangXiaobin on 16/6/29.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import "SynECGBlueManager.h"
#import "SynECGUtils.h"
#import "BluetoothCommandManager.h"
#import "ECGDecodeManager.h"
#import "SynECGLibSingleton.h"
#import "SynConstant.h"
#import "HADeviceStatusManager.h"
#import "RequestManager.h"
#import "ECGRRManager.h"
#import "ECGBreathUpload.h"
#import "ECGEnergryManager.h"
#import "SynAlarmOperationModel.h"
#import "ECGHRManager.h"
#import "NSString+EnumSynEcg.h"
#import "SDBManager.h"
#import "ZYFMDB.h"
#import "HeartBeatModel.h"
#import "RequestManager.h"
#import "ECGHRManager.h"
#import "SynWaterUploadManager.h"
#import "SynAlarmUploadManager.h"
#import "HAEventManager.h"
#import "SynAlarmOperationModel.h"
#import "SportDataManager.h"


@interface SynECGBlueManager ()<CBCentralManagerDelegate,CBPeripheralDelegate,LoggerDelegate, DFUServiceDelegate, DFUProgressDelegate,ECGDecodeManagerDelegate>
{
    FMDatabaseQueue *queue;
    
    int ecgLength;
    int annLength;
    int evtLength;
}
@property (strong, nonatomic) DFUServiceController *controller;
//系统蓝牙设备管理对象，可以把他理解为主设备，通过他，可以去扫描和链接外设
@property (nonatomic,copy) NSMutableArray *discoverPeripherals;
@property (nonatomic,strong)CBCentralManager *manager;

@property (assign,nonatomic)BOOL upateSucceed;

@property(strong,nonatomic) CBPeripheral *currPeripheral;
@property(strong,nonatomic) CBCharacteristic *characteristic;

@property (nonatomic,strong) NSMutableArray *eventDataArray;

@property(nonatomic ,assign) BOOL writeMessage;
//曾经工资
@property (nonatomic, assign)BOOL isConnect;
//新工作开始
@property (nonatomic,assign) BOOL iSNewWoking;

@property (nonatomic,copy) NSString *filePath;

@property (nonatomic,assign)BOOL needConection;

@property (nonatomic,assign)BOOL needUpdateFirm;

@property (nonatomic,assign)BOOL needRetry;

@property (nonatomic,assign)NSInteger retryNum;

@property (nonatomic,assign)BOOL getDeviceStatus;

@property (nonatomic,strong) NSTimer *timer;


@property (nonatomic,strong) NSTimer *dfuTimer;
@property (nonatomic,assign) NSInteger dfuOutTime;
@property (nonatomic, assign) NSInteger indexType; //数据类型
@property (nonatomic,strong) NSTimer *speedTimer;

@property (nonatomic, strong) NSTimer *scatterTimer;

@property (nonatomic,assign) NSInteger lastLength;

@property (nonatomic,strong) ECGDecodeManager  *decodeManager;



@property (nonatomic,assign)BOOL upFirewareing;

@property (nonatomic,copy) NSTimer *rssiTimer;

//补传历史数据
@property (nonatomic,copy) NSMutableData *data00;
@property (nonatomic,copy) NSMutableData *data01;
@property (nonatomic,copy) NSMutableData *data02;
@property (nonatomic,copy) NSMutableData *data03;

@property (nonatomic, assign) NSInteger evtIndex;
@property (nonatomic, assign) NSInteger alreadyByte;
@property (nonatomic, assign) NSInteger allByte;


@property (nonatomic, assign) BOOL getHistory;
@property (nonatomic, assign)NSInteger getLocation;
@property (nonatomic, copy) NSMutableArray *stagingArray;

@property (nonatomic, assign) NSInteger stepLength;


@end

@implementation SynECGBlueManager

@synthesize controller;

+(instancetype)sharedInstance
{
    static SynECGBlueManager * sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SynECGBlueManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _filePath = [[NSString alloc]init];
        //初始化并设置委托和线程队列，最好一个线程的参数可以为nil，默认会就main线程
        _manager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
        //持有发现的设备,如果不持有设备会导致CBPeripheralDelegate方法不能正确回调
        _discoverPeripherals = [[NSMutableArray alloc]init];
        _eventDataArray = [[NSMutableArray alloc]init];
        _isConnect = NO;
        _typeNum = 0;
        _needConection = NO;
        _getDeviceStatus = NO;
        _upateSucceed = NO;
        _needUpdateFirm = NO;
        _btStatus = NO;
        _upFirewareing = NO;
        _needRetry = NO;
        _dfuOutTime = 0;
        _cellType = 0;
        _batteryNum = 0;
        _lastLength = 0;
        _recordId = 0;
        _stepLength = 0;
        _getHistory = NO;
        _getLocation = 0;
        _stagingArray = [[NSMutableArray alloc]init];
        _nowfirmwareNumber = [[NSString alloc]init];
        _firmwareNumber = [[NSString alloc]init];
        _canUpdateFirmWare = NO;
        _needMandatoryUpdateFirmWare = NO;
        _deviceName = [[NSString alloc]init];
        _descMessage = [[NSString alloc]init];
        _data00 = [NSMutableData new];
        _data01 = [NSMutableData new];
        _data02 = [NSMutableData new];
        _data03 = [NSMutableData new];
        _evtIndex = 0;
        _allByte = 0;
        _alreadyByte = 0;
        //计时器
         _timer = [NSTimer  timerWithTimeInterval:300 target:self selector:@selector(heartReatMethod) userInfo:nil repeats:YES];
          [ _timer setFireDate:[NSDate distantFuture]];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
        
        _indexType = 0;
        _dfuTimer = [NSTimer  timerWithTimeInterval:1.0f target:self selector:@selector(updateFirmWareError) userInfo:nil repeats:YES];
        [_dfuTimer setFireDate:[NSDate distantFuture]];
        [[NSRunLoop currentRunLoop] addTimer:_dfuTimer forMode:NSRunLoopCommonModes];
        

        _speedTimer = [NSTimer  timerWithTimeInterval:1.0f target:self selector:@selector(getSpeed) userInfo:nil repeats:YES];
        [_speedTimer setFireDate:[NSDate distantFuture]];
        [[NSRunLoop currentRunLoop] addTimer:_speedTimer forMode:NSRunLoopCommonModes];
        
        
        _recordTimer = [NSTimer  timerWithTimeInterval:300 target:self selector:@selector(checkRecordlist) userInfo:nil repeats:YES];
        [_recordTimer setFireDate:[NSDate distantFuture]];
        [[NSRunLoop currentRunLoop] addTimer:_recordTimer forMode:NSRunLoopCommonModes];
        
        _scatterTimer = [NSTimer  timerWithTimeInterval:1.0f target:self selector:@selector(getRRiWithLength:) userInfo:nil repeats:YES];
        [_scatterTimer setFireDate:[NSDate distantFuture]];
        [[NSRunLoop currentRunLoop] addTimer:_scatterTimer forMode:NSRunLoopCommonModes];
        
        
        _rssiTimer = [NSTimer  timerWithTimeInterval:5.f target:self selector:@selector(bleReadRSSI) userInfo:nil repeats:YES];
        [_rssiTimer setFireDate:[NSDate distantFuture]];
        [[NSRunLoop currentRunLoop] addTimer:_rssiTimer forMode:NSRunLoopCommonModes];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reConnectDevice) name:@"SynAddDeve" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeDevice) name:@"SynChange" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deletedeviceAndChangeStatus) name:@"SynDelete" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tongzhi:) name:@"Syn_Alert_Notification" object:nil];
        [self registerObservers];
        _decodeManager = [ECGDecodeManager sharedInstance];
        _decodeManager.delegate = self;
        
        _startTime = [SynECGLibSingleton sharedInstance].startMonitorTime;        
        queue = [SDBManager defaultDBManager].queue;
    
        NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
        
        NSString *sr = [user objectForKey:@"syn_recordId"];
        NSInteger ss = [[user objectForKey:@"syn_startTime"] integerValue];
        self.iSNewWoking = [[user objectForKey:@"iSNewWoking"] boolValue];
        
        if (sr != nil) {
            
            [SynECGLibSingleton sharedInstance].record_id = sr;
            [SynECGLibSingleton sharedInstance].startMonitorTime = ss;
        
        }
        
        self.recordId = [SynECGLibSingleton sharedInstance].record_id;
        self.startTime = [SynECGLibSingleton sharedInstance].startMonitorTime;
        

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setNetworkStatusMonitortor];
        });
    }
    return self;
}

-(void)setNetworkStatusMonitortor{
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status > 0)
        {
            [self uploadLastMessage];
            
            
            if (self.needUpdateFirm == YES) {
            
                [self getDeviceUpdateMessage];
            }
        }
    }];
}


- (void)uploadLastMessage
{
    [[SynWaterUploadManager sharedInstance] uploadEnergyMessageToSever];;
    [[SynAlarmUploadManager sharedInstance] uploadAlertMessageToSever];;
    [[ECGBreathUpload sharedInstance] uploadBreathMessageToSever];;
    [[ECGEnergryManager sharedInstance] uploadEnergyMessageToSever];;
    [[ECGHRManager sharedInstance] uploadECGHRMessageToSever];
    [[ECGRRManager sharedInstance] uploadRRMessageToSever];
    [[HADeviceStatusManager sharedInstance] uploadStatusMessage];
    [[HAEventManager sharedInstance] uploadEventMessageToSever];
    [[SportDataManager sharedInstance] uploadSportMessageToSever];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"SynDelete" object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"SynAddDeve" object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"SynChange" object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"Syn_Alert_Notification" object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillTerminateNotification object:nil];


    [self stopOldTask];
}

- (void)syn_ecgScanSearchDevice
{
    [_manager stopScan];
    _needSearch = YES;
    [self.manager scanForPeripheralsWithServices:nil options:nil];
}

- (void)syn_ecgScanAndConnectionDevice
{
    [_manager stopScan];
    _needConection = YES;
    _needSearch = YES;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {

        [SynECGLibSingleton sharedInstance].mac = [self queryTable:SYN_USERINFO_TABLE Column:@"mac" inDb:db];
        [SynECGLibSingleton sharedInstance].deviceId = [self queryTable:SYN_USERINFO_TABLE Column:@"deviceId" inDb:db];
        [SynECGLibSingleton sharedInstance].deviceTypeId = [self queryTable:SYN_USERINFO_TABLE Column:@"deviceTypeId" inDb:db];
        [SynECGLibSingleton sharedInstance].deviceName = [self queryTable:SYN_USERINFO_TABLE Column:@"deviceName" inDb:db];
        self.deviceName = [SynECGLibSingleton sharedInstance].deviceName;

        if ([SynECGLibSingleton sharedInstance].mac.length > 0) {
         
            [self.manager scanForPeripheralsWithServices:nil options:nil];
        }
    }];
    
}

- (void)syn_ecgReScanAndConnectionDevice
{
    [_manager stopScan];
    _needConection = YES;
    _needSearch = YES;
    if ([SynECGLibSingleton sharedInstance].mac.length > 0) {
        
        [self.manager scanForPeripheralsWithServices:nil options:nil];
    }
}



- (void)syn_ecgCancelSearchDevice
{
    self.needSearch = NO;
    [_manager stopScan];
}

/**
 *  开始检测
 */
- (void)syn_ecgStartMeasurementWithCompletion:(CommonBlockCompletion)completionCallback
{
    
    if (_typeNum == 0) {
        
        completionCallback(@"设备未连接");
    }
    else if(_typeNum != 1)
    {
        completionCallback(@"设备测量中");
    }
    
    else if(_needMandatoryUpdateFirmWare == YES)
    {
        completionCallback(@"设备需要强制更新");
    }
    else
    {
        if (_currPeripheral &&_characteristic)
        {
            [self startMonitoringECG];
        }
    }
    
}

//停止上传
- (void)endUploadMessageTosever
{
    
       
        [[SDBManager defaultDBManager].queue inTransaction:^(FMDatabase *db, BOOL *rollback) {

            //移除事件不再解析
            if([ECGDecodeManager sharedInstance].eventTempData.length > 0)
            {
                [[ECGDecodeManager sharedInstance].eventTempData resetBytesInRange:NSMakeRange(0, [ECGDecodeManager sharedInstance].eventTempData.length)];
                [[ECGDecodeManager sharedInstance].eventTempData setLength:0];

            }
            
            [ECGDecodeManager sharedInstance].parseing = NO;
            
            [[ECGEnergryManager sharedInstance]uploadEnergryMessageIn:db];
            [[ECGBreathUpload sharedInstance]uploadLatBreathIn:db];
            [[ECGRRManager sharedInstance]uploadRRMessageIn:db];
            [[ECGHRManager sharedInstance] uploadLastMessageIn:db];
            
            if ([SynECGLibSingleton sharedInstance].deviceVerType >= 2) {
             
                [[SportDataManager sharedInstance] uploadLastIn:db];
            }
            
        }];

    
    
    [[SynAlarmOperationModel sharedInstance] closeAllAlert];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [SynECGLibSingleton sharedInstance].record_id = @"";
        [SynECGLibSingleton sharedInstance].startMonitorTime = 0;
        
        NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
        [user setObject:@"" forKey:@"syn_recordId"];
        [user setObject:@(0) forKey:@"syn_startTime"];
        [user setObject:@(0) forKey:@"iSNewWoking"];
        
    });
    
    

}


/**
 *  停止检测
 */
- (void)syn_ecgStopMeasurement
{
    [self endMonitoringECG];
}

- (void)syn_ecgDisconnectDevice
{
    if( _manager && _currPeripheral) {
        //停止之前的连接
        _needReLink = NO;
        [_manager cancelPeripheralConnection:_currPeripheral];
    }
}

- (void)stopOldTask
{
    if( _manager && _currPeripheral && _iSNewWoking) {
        [self endMonitoringECG];
    }
}

- (void)deletedeviceAndChangeStatus
{
    //停止之前的连接
    _needReLink = NO;
    _writeMessage = NO;
    _canUpdateFirmWare = NO;
    _needMandatoryUpdateFirmWare = NO;
    if( _manager && _currPeripheral)
    {
        if (_iSNewWoking) {
            [self stopOldTask];
            BlockWeakSelf(self);
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                
                [weakSelf.manager cancelPeripheralConnection:weakSelf.currPeripheral];
            });
        }
        else
        {
            [_manager cancelPeripheralConnection:_currPeripheral];
        }
    }
}



- (void)changeBluetoothWorkStatus
{
    //停止之前的连接
    _needReLink = NO;
    _writeMessage = NO;
    _canUpdateFirmWare = NO;
    _needMandatoryUpdateFirmWare = NO;
    if( _manager && _currPeripheral)
    {
        if (_iSNewWoking) {
            [self stopOldTask];
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC));
            BlockWeakSelf(self);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
               
                [weakSelf.manager cancelPeripheralConnection:weakSelf.currPeripheral];
            });
        }
        else
        {
                [_manager cancelPeripheralConnection:_currPeripheral];
        }
    }
}

- (void)reConnectDevice
{
    _writeMessage = NO;
    [self.manager scanForPeripheralsWithServices:nil options:nil];
   
}

- (void)changeDevice
{
    
    _writeMessage = NO;
    _needReLink = NO;

    if( _manager && _currPeripheral)
    {
        
        [_manager cancelPeripheralConnection:_currPeripheral];
        [_manager scanForPeripheralsWithServices:nil options:nil];
        
    }
    else
    {
        [_manager scanForPeripheralsWithServices:nil options:nil];
    }
    
}




- (void)reSetManager
{
    self.manager = nil;
    self.filePath = nil;
    self.discoverPeripherals = nil;
    self.eventDataArray = nil;
    
    _filePath = [[NSString alloc]init];
    //初始化并设置委托和线程队列，最好一个线程的参数可以为nil，默认会就main线程
    _manager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    //持有发现的设备,如果不持有设备会导致CBPeripheralDelegate方法不能正确回调
    _discoverPeripherals = [[NSMutableArray alloc]init];
    _eventDataArray = [[NSMutableArray alloc]init];

}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 11.0)
    {
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
        switch (central.state) {
            case CBManagerStateUnknown:
                NSLog(@">>>CBCentralManagerStateUnknown");
                break;
            case CBManagerStateResetting:
                NSLog(@">>>CBCentralManagerStateResetting");
                break;
            case CBManagerStateUnsupported:
                NSLog(@">>>CBCentralManagerStateUnsupported");
                break;
            case CBManagerStateUnauthorized:
                NSLog(@">>>CBCentralManagerStateUnauthorized");
                break;
            case CBManagerStatePoweredOff:
                self.btStatus = NO;
                NSLog(@">>>CBCentralManagerStatePoweredOff");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CBCentralManagerStatePoweredOff" object:nil];
                [self blueToothClosedByILow];
                break;
            case CBManagerStatePoweredOn:
                NSLog(@">>>CBCentralManagerStatePoweredOn");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CBCentralManagerStatePoweredOn" object:nil];
                self.btStatus = YES;
                if (_needSearch) {
                    
                    [central scanForPeripheralsWithServices:nil options:nil];
                }
                
                break;
            default:
                break;
        }
#endif
    }
    else if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        
        #ifdef NSFoundationVersionNumber_iOS_9_x_Max
        switch (central.state) {
            case CBManagerStateUnknown:
                NSLog(@">>>CBCentralManagerStateUnknown");
                break;
            case CBManagerStateResetting:
                NSLog(@">>>CBCentralManagerStateResetting");
                break;
            case CBManagerStateUnsupported:
                NSLog(@">>>CBCentralManagerStateUnsupported");
                break;
            case CBManagerStateUnauthorized:
                NSLog(@">>>CBCentralManagerStateUnauthorized");
                break;
            case CBManagerStatePoweredOff:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CBCentralManagerStatePoweredOff" object:nil];
                
                self.btStatus = NO;
                NSLog(@">>>CBCentralManagerStatePoweredOff");
                [self blueToothClosed];
                break;
            case CBManagerStatePoweredOn:
                NSLog(@">>>CBCentralManagerStatePoweredOn");
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"CBCentralManagerStatePoweredOn" object:nil];
                self.btStatus = YES;
                if (_needSearch) {
                 
                     [central scanForPeripheralsWithServices:nil options:nil];
                }
                
                break;
            default:
                break;
        }
        #endif
       
    } else {
        //categories 必须为nil
        switch (central.state) {
            case CBCentralManagerStateUnknown:
                NSLog(@">>>CBCentralManagerStateUnknown");
                break;
            case CBCentralManagerStateResetting:
                NSLog(@">>>CBCentralManagerStateResetting");
                break;
            case CBCentralManagerStateUnsupported:
                NSLog(@">>>CBCentralManagerStateUnsupported");
                break;
            case CBCentralManagerStateUnauthorized:
                NSLog(@">>>CBCentralManagerStateUnauthorized");
                break;
            case CBCentralManagerStatePoweredOff:
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CBCentralManagerStatePoweredOff" object:nil];
                
                self.btStatus = NO;
                NSLog(@">>>CBCentralManagerStatePoweredOff");
                [self blueToothClosedByILow];
                break;
            case CBCentralManagerStatePoweredOn:
                NSLog(@">>>CBCentralManagerStatePoweredOn");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CBCentralManagerStatePoweredOn" object:nil];
                
                self.btStatus = YES;
                if (_needSearch) {
                    [central scanForPeripheralsWithServices:nil options:nil];
                }
                break;
            default:
                break;
        }
    }
}

- (void)blueToothClosed
{
    //手动关蓝牙
    _getDeviceStatus = NO;

}

- (void)blueToothClosedByILow
{
    _getDeviceStatus = NO;
    [_timer setFireDate:[NSDate distantFuture]];
    [_rssiTimer setFireDate:[NSDate distantFuture]];
    [_speedTimer setFireDate:[NSDate distantFuture]];
    _lastLength = 0;
    _alreadyByte = 0;
    
    NSNotification *notification =[NSNotification notificationWithName:@"CloseBlueth" object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    
    //开启线程
    if ([SynECGLibSingleton sharedInstance].isSuspend == YES) {
        
        [[ECGDecodeManager sharedInstance].eventTempData resetBytesInRange:NSMakeRange(0, [ECGDecodeManager sharedInstance].eventTempData.length)];
        [[ECGDecodeManager sharedInstance].eventTempData setLength:0];
        [ECGDecodeManager sharedInstance].needReturn = YES;
        dispatch_resume([ECGDecodeManager sharedInstance].eventQueue);
        [SynECGLibSingleton sharedInstance].isSuspend = NO;
        
    }
    
    if ([ECGHRManager sharedInstance].tempSaveData != nil) {
        
        
        [[ECGHRManager sharedInstance].tempSaveData resetBytesInRange:NSMakeRange(0, [ECGHRManager sharedInstance].tempSaveData.length)];
        [[ECGHRManager sharedInstance].tempSaveData setLength:0];
        
        [SynECGLibSingleton sharedInstance].ecgData = [ECGHRManager sharedInstance].tempSaveData;
        
    }
    
    [ECGDecodeManager sharedInstance].parseing = NO;
    if([ECGDecodeManager sharedInstance].eventTempData.length > 0)
    {
        [[ECGDecodeManager sharedInstance].eventTempData resetBytesInRange:NSMakeRange(0, [ECGDecodeManager sharedInstance].eventTempData.length)];
        [[ECGDecodeManager sharedInstance].eventTempData setLength:0];
        
    }
    
    if(self.data03.length > 0)
    {
        [self.data03 resetBytesInRange:NSMakeRange(0, self.data03.length)];
        [self.data03 setLength:0];
    }
    
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    
    [dic setObject:[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"] forKey:@"time"];
    [dic setObject:@"0" forKey:@"deviceStatus"];
    
    _typeNum = 0;
    [SynECGLibSingleton sharedInstance].typeNum = _typeNum;
    
    [self saveDeviceStatusWithMessage:dic];

}



//扫描到设备会进入方法
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    //找到的设备必须持有它，否则CBCentralManager中也不会保存peripheral，那么CBPeripheralDelegate中的方法也不会被调用！！
    
    if ([advertisementData.allKeys containsObject:@"kCBAdvDataLocalName"] && [advertisementData.allKeys containsObject:@"kCBAdvDataServiceUUIDs"] )
    {

        
//        if ([[self getUUIDFrom:advertisementData[@"kCBAdvDataServiceUUIDs"]] isEqualToString:@"8E9222B8-0FFD-4F30-83DF-79D9BD168266"])
//            {
        
        NSData *manufacture = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
        NSData *inc = [manufacture subdataWithRange:NSMakeRange(0, 2)];
        NSString *incString = [SynECGUtils hexadecimalString:inc];
            
        if ([incString isEqualToString:@"cd01"])
        {
            
            
            NSString *AddataSring = [self hexadecimalString:manufacture];
            NSString *mac = [[AddataSring substringWithRange:NSMakeRange(7, 17)] uppercaseString];
            
            if (_searchDelegate && [_searchDelegate respondsToSelector:@selector(syn_ecgSearchDeviceWithInfo:advertisementData:)])
            {
                NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
                [dic setObject:mac forKey:@"mac"];
                [dic setObject:@"Synwing" forKey:@"vendor"];
                [dic setObject:advertisementData[@"kCBAdvDataLocalName"] forKey:@"device_name"];
                [dic setObject:@"SYNWING_ECG" forKey:@"deviceTypeId"];
                [_searchDelegate syn_ecgSearchDeviceWithInfo:peripheral advertisementData:dic];
                
                NSLog(@"%@",dic);
                
            }
            if (_needConection)
            {
                
                if ([mac isEqualToString:[[SynECGLibSingleton sharedInstance].mac uppercaseString]])
                {
                    [_discoverPeripherals addObject:peripheral];
                    [central connectPeripheral:peripheral options:nil];
                    self.deviceName = advertisementData[@"kCBAdvDataLocalName"];
                    
                    [self setSignalLevelFromNum:RSSI];
                }
                else
                {
                    
                    
                    if (manufacture.length >= 15)
                    {
                        
                        NSData *dataMac = [manufacture subdataWithRange:NSMakeRange(7, 1)];
                        int8_t A;;
                        [dataMac getBytes:&A length:sizeof(A)];
                        A = A - 1;
                        NSData *dataA = [NSData dataWithBytes: &A length: sizeof(A)];
                        NSString *dataStr = [[SynECGUtils hexadecimalString:dataA] uppercaseString];
                        //此处为获取的mac地址最后一位的值+1
                        
                        mac = [mac substringToIndex:15];
                        mac =  [mac stringByAppendingString:dataStr];
                        
                        if ([mac isEqualToString:[SynECGLibSingleton sharedInstance].mac])
                        {
                            
                            
                            NSData *data = [manufacture subdataWithRange:NSMakeRange(8, 1)];
                            int8_t b;
                            [data getBytes:&b length:sizeof(b)];
                            
                            if (b == 0)
                            {
                                NSString *softStr = [SynECGUtils hexadecimalString:[manufacture subdataWithRange:NSMakeRange(10, 3)]];
                                NSString *softStr1 = [SynECGUtils hexadecimalString:[manufacture subdataWithRange:NSMakeRange(13, 2)]];
                                [SynECGLibSingleton sharedInstance].softwareVer = [NSString stringWithFormat:@"%@_%@_01",softStr,softStr1];
                                [SynECGLibSingleton sharedInstance].hardwareVer = [SynECGUtils hexadecimalString:[manufacture subdataWithRange:NSMakeRange(9, 1)]];
                                
                                _needUpdateFirm = YES;
                                self.currPeripheral = peripheral;
                                self.typeNum = 1;
                                self.getDeviceStatus = YES;
                                
                                [self getDeviceUpdateMessage];
                            }
                            
                            
                        }
                        
                        
                        
                    }
                    
                    
                }
            }

//                    }
        }

    }
    
    

 }

//查询字段
- (NSString *)queryTable:(NSString *)tableName  Column:(NSString *)columnName inDb:(FMDatabase *)dataBase
{
    NSString *query = [NSString stringWithFormat:@"select * from %@",tableName];
    FMResultSet *rs = [dataBase executeQuery:query];
    NSString *rr = [[NSString alloc]init];
    while ([rs next]) {
        rr = [rs stringForColumn:columnName];
    }
    return rr;
}



//连接到Peripherals-失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@">>>连接到名称为（%@）的设备-失败,原因:%@",[peripheral name],[error localizedDescription]);
    [self syn_ecgScanAndConnectionDevice];
}

//Peripherals断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@">>>外设连接断开连接 %@: %@\n", [peripheral name], [error localizedDescription]);


    _getDeviceStatus = NO;
    [_timer setFireDate:[NSDate distantFuture]];
    [_speedTimer setFireDate:[NSDate distantFuture]];
    _lastLength = 0;
    _alreadyByte = 0;
    
    NSNotification *notification =[NSNotification notificationWithName:@"CloseBlueth" object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    
    //开启线程
    if ([SynECGLibSingleton sharedInstance].isSuspend == YES) {
        
        [[ECGDecodeManager sharedInstance].eventTempData resetBytesInRange:NSMakeRange(0, [ECGDecodeManager sharedInstance].eventTempData.length)];
        [[ECGDecodeManager sharedInstance].eventTempData setLength:0];
        [ECGDecodeManager sharedInstance].needReturn = YES;
        dispatch_resume([ECGDecodeManager sharedInstance].eventQueue);
        [SynECGLibSingleton sharedInstance].isSuspend = NO;
        
    }
    
    
    if (_needReLink) {

        [_manager connectPeripheral:peripheral options:nil];
    }
    
    if ([ECGHRManager sharedInstance].tempSaveData != nil) {
        
        
        [[ECGHRManager sharedInstance].tempSaveData resetBytesInRange:NSMakeRange(0, [ECGHRManager sharedInstance].tempSaveData.length)];
        [[ECGHRManager sharedInstance].tempSaveData setLength:0];
        
        [SynECGLibSingleton sharedInstance].ecgData = [ECGHRManager sharedInstance].tempSaveData;
        
    }
    
    [ECGDecodeManager sharedInstance].parseing = NO;
    if([ECGDecodeManager sharedInstance].eventTempData.length > 0)
    {
        [[ECGDecodeManager sharedInstance].eventTempData resetBytesInRange:NSMakeRange(0, [ECGDecodeManager sharedInstance].eventTempData.length)];
        [[ECGDecodeManager sharedInstance].eventTempData setLength:0];
        
    }
    
    if(self.data03.length > 0)
    {
        [self.data03 resetBytesInRange:NSMakeRange(0, self.data03.length)];
        [self.data03 setLength:0];
    }
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];

    [dic setObject:[SynECGUtils getDateStringWithDate:[NSDate date] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"] forKey:@"time"];
    [dic setObject:@"0" forKey:@"deviceStatus"];

    _typeNum = 0;
    [SynECGLibSingleton sharedInstance].typeNum = _typeNum;

    [self saveDeviceStatusWithMessage:dic];

}


//连接到Peripherals-成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@">>>连接到名称为（%@）的设备-成功",peripheral.name);
    [central stopScan];
    
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    [user setObject:@"0" forKey:@"oldDeviceStatus"];
    [user synchronize];
    [_rssiTimer setFireDate:[NSDate distantPast]];
    _needUpdateFirm = YES;
    _needReLink = YES;
    self.needRetry = YES;
    self.currPeripheral = peripheral;
    
    [SynECGLibSingleton sharedInstance].typeNum = 1;
    
    //设置的peripheral委托CBPeripheralDelegate
    //@interface ViewController : UIViewController<CBCentralManagerDelegate,CBPeripheralDelegate>
    [peripheral setDelegate:self];
    //扫描外设Services，成功后会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    [peripheral discoverServices:nil];

}


//扫描到Services
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    //  NSLog(@">>>扫描到服务：%@",peripheral.services);
    if (error)
    {
        NSLog(@">>>Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    
    for (CBService *service in peripheral.services) {
        
        //扫描每个service的Characteristics，扫描到后会进入方法： -(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
        [peripheral discoverCharacteristics:nil forService:service];
    }
    
}

//扫描到Characteristics
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error)
    {
        NSLog(@"error Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics)
    {

        //电量
        if ([characteristic.UUID.UUIDString isEqualToString:@"2A19"]) {
            
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        
        if ([characteristic.UUID.UUIDString isEqualToString:@"8E9222BB-0FFD-4F30-83DF-79D9BD168266"]) {
            
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        
        if ([characteristic.UUID.UUIDString isEqualToString:@"8E9222BD-0FFD-4F30-83DF-79D9BD168266"]) {
            
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        
        if ([characteristic.UUID.UUIDString isEqualToString:@"8E9222BC-0FFD-4F30-83DF-79D9BD168266"]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
    
    //获取Characteristic的值，读到数据会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
    for (CBCharacteristic *characteristic in service.characteristics){
        {
            [peripheral readValueForCharacteristic:characteristic];
        }
    }
    
    //搜索Characteristic的Descriptors，读到数据会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
    for (CBCharacteristic *characteristic in service.characteristics){
        [peripheral discoverDescriptorsForCharacteristic:characteristic];
    }
}

//获取的charateristic的值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    //打印出characteristic的UUID和值
    //!注意，value的类型是NSData，具体开发时，会根据外设协议制定的方式去解析数据
    
    //电量
    if ([characteristic.UUID.UUIDString isEqualToString:@"2A19"])
    {
        
        [self updateBatteryMessageWith:characteristic];
    }
    //硬件版本号
    if ([characteristic.UUID.UUIDString isEqualToString:@"2A27"]) {
        
        [self updaeHardwareRevisionWith:characteristic];
    }
    //版本号1.6
    if ([characteristic.UUID.UUIDString isEqualToString:@"2A28"]) {
        
        [self updaeSoftwareRevisionWith:characteristic];
    }
    //设备固件版本
    if([characteristic.UUID.UUIDString isEqualToString:@"2A26"])
    {
        [self updaeFirmwareRevisionWith:characteristic];
    }                                    
    if ([characteristic.UUID.UUIDString isEqualToString:@"8E9222B9-0FFD-4F30-83DF-79D9BD168266"]) {
        
        self.characteristic = characteristic;

        if ([SynECGLibSingleton sharedInstance].record_id.length < 1 || [SynECGLibSingleton sharedInstance].record_id == nil)
        {
            if (_typeNum == 2 || _typeNum == 9) {

                [self endMonitoringECG];
            }

            if (!_writeMessage)
            {
                [self writePersonInfoMessageToBleforCharacteristic:characteristic];
            }
            else
            {
                [self startView];
            }
        }
        else
        {
            if (_typeNum == 2 || _typeNum == 9 || _typeNum == 3 ) {

                _isConnect = YES;
            }
            else
            {
                if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"state"] isEqualToString:@"or"]) {
                    
                }
                else
                {
                    if (!_writeMessage)
                    {
                        [self writePersonInfoMessageToBleforCharacteristic:characteristic];
                    }
                    else
                    {
                        [self startView];
                    }
                }
            }
        }
    }
    
    if ([characteristic.UUID.UUIDString isEqualToString:@"8E9222BB-0FFD-4F30-83DF-79D9BD168266"]) {
        
        [self updateECGMessageWith:characteristic];
    }
    
    if ([characteristic.UUID.UUIDString isEqualToString:@"8E9222BD-0FFD-4F30-83DF-79D9BD168266"]) {
       
        [self updateStatusMessageWith:characteristic];

    }
    
    if ([characteristic.UUID.UUIDString isEqualToString:@"8E9222BC-0FFD-4F30-83DF-79D9BD168266"]) {
        [self updateRecordMessageWith:characteristic];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error writing characteristic value: %@",
              [error localizedDescription]);
        return;
    }

    if (_writeMessage == NO) {
        _writeMessage = YES;
        [self startView];
        
    }
    
}

//设置通知
-(void)notifyCharacteristic:(CBPeripheral *)peripheral
             characteristic:(CBCharacteristic *)characteristic{
    //设置通知，数据通知会进入：didUpdateValueForCharacteristic方法
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    
}

//取消通知
-(void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
                   characteristic:(CBCharacteristic *)characteristic{
    
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}

//停止扫描并断开连接
-(void)disconnectPeripheral:(CBCentralManager *)centralManager
                 peripheral:(CBPeripheral *)peripheral{
    //停止扫描
    [centralManager stopScan];
    //断开连接
    [centralManager cancelPeripheralConnection:peripheral];
    [_rssiTimer setFireDate:[NSDate distantFuture]];
}


-(void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error
{
    NSInteger level = [self setSignalLevelFromNum:RSSI];
    
    NSLog(@"%ld",(long)level);
    
    
    if(self.dataSource && [self.dataSource respondsToSelector:@selector(syn_ecgSignalLevel:)])
    {
        [self.dataSource syn_ecgSignalLevel:level];
    }
    
}

- (NSInteger)setSignalLevelFromNum:(NSNumber *)data
{
    NSInteger value = [data integerValue];
    
    self.signalLevel = 0;
    
//    if(value < -110) {
//        self.signalLevel = 0;
//    }else if(value < -90){
//        self.signalLevel = 1;
//    }else if(value < -80) {
//        self.signalLevel = 2;
//    }else if(value < -70) {
//        self.signalLevel = 3;
//    }else if(value < -60) {
//        self.signalLevel = 4;
//    }else if(value < 0) {
//        self.signalLevel = 5;
//    }
    
    
    if(value < -110) {
        self.signalLevel = 0;
    }else if(value < -90){
        self.signalLevel = 1;
    }else if(value < -80) {
        self.signalLevel = 1;
    }else if(value < -70) {
        self.signalLevel = 2;
    }else if(value < -60) {
        self.signalLevel = 2;
    }else if(value < 0) {
        self.signalLevel = 3;
    }

    
    
    return self.signalLevel;
}


- (void)bleReadRSSI
{
    
    if (self.currPeripheral != nil) {

        [self.currPeripheral readRSSI];
    }
}



- (void)updateStatusMessageWith:(CBCharacteristic *)characteristic
{
    
    @autoreleasepool {
        
        
        _getDeviceStatus = YES;
        NSArray *array = [[BluetoothCommandManager sharedInstance] getStatus:characteristic.value];
        
        self.cellType = [[BluetoothCommandManager sharedInstance] getBatteryStatusFRom:characteristic.value];
        
        
        if (_dataSource &&[_dataSource respondsToSelector:@selector(syn_ecgMessageOnToCharging:)]) {
            [_dataSource syn_ecgMessageOnToCharging:self.cellType];
        }
        
        
        
        if (array.count > 0) {
            
            if (_typeNum == 1 && [array[1] integerValue] == 2) {
                
                [SynECGLibSingleton sharedInstance].record_id =[[BluetoothCommandManager sharedInstance]getRecordFormData:characteristic.value];
                
                self.recordId = [SynECGLibSingleton sharedInstance].record_id;
                 [[BluetoothCommandManager sharedInstance] saveStartMessage];
                
                NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
                [user setObject:[SynECGLibSingleton sharedInstance].record_id forKey:@"syn_recordId"];
            }
            
            
            _typeNum = [array[1] integerValue];
            
            if (_typeNum == 12) {
                
                _typeNum = 9;
            }
            
            if (_typeNum == 9 && _typeNum == [SynECGLibSingleton sharedInstance].typeNum && characteristic.value.length == 18 && self.isConnect == NO) {
                
                if (_dataSource &&[_dataSource respondsToSelector:@selector(syn_ecgMessageOnToFillTheData:)]) {
                    [_dataSource syn_ecgMessageOnToFillTheData:[array[2] integerValue]];
                }
                
                return;
            }
            [SynECGLibSingleton sharedInstance].typeNum = _typeNum;
            
            
            NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
            [dic setObject:array[0] forKey:@"time"];
            [dic setObject:array[1] forKey:@"deviceStatus"];
            
            
            [self saveDeviceStatusWithMessage:dic];
            
            
            if ((![array[1] isEqualToString:@"0"] || ![array[1] isEqualToString:@"1"])  && self.isConnect == YES)
            {
                self.iSNewWoking = YES;
                self.isConnect = NO;
                int value = (int)[SynECGLibSingleton sharedInstance].startMonitorTime;
                NSData *data =[NSData dataWithBytes:&value length:sizeof(value)];
                NSString *str1 = [SynECGUtils hexadecimalString:data];
                
                NSString *str = [NSString stringWithString:[SynECGUtils hexadecimalString:[characteristic.value subdataWithRange:NSMakeRange(1, 4)]]];
                
                if ([str isEqualToString:str1])
                {
                    _writeMessage = YES;
                    [self  startOffsetsView];
                }
                else
                {
                    [self endMonitoringECG];
                }
            }
            else if([array[1] isEqualToString:@"1"] && [SynECGLibSingleton sharedInstance].record_id.length > 0 && self.iSNewWoking == YES && [[[NSUserDefaults standardUserDefaults] objectForKey:@"state"] isEqualToString:@"or"])
            {
                if (self.needRetry == YES) {
                    
                    self.needRetry = NO;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        
                        //获取记录列表
                        [self getDeviceRecodList];
                        
                    });
                }
    
            }
            else
            {
                
            }
            
        }
        
    }
}

- (void)updateECGMessageWith:(CBCharacteristic *)characteristic
{
    if (self.iSNewWoking == YES)
    {

        NSString *string = [SynECGUtils hexadecimalString:characteristic.value];

        // EVT v2
        if ([string hasPrefix:@"09"]) {
            [_decodeManager  loadNewEventDataFromData:characteristic.value];
        }
        // ANN  v2 v3
        else if ([string hasPrefix:@"12"] || [string hasPrefix:@"0b"]) {

            [_decodeManager  loadNewRRDataFromData:characteristic.value];
        }
        // ACT v2 v3
        else if ([string hasPrefix:@"2a"] || [string hasPrefix:@"13"]) {

            [_decodeManager loadNewEnergyDataFromData:characteristic.value];
        }
        // ACT v4
        else if ([string hasPrefix:@"3a"]) {

            [_decodeManager  loadNewBreathDataFromData:characteristic.value];
        }

        // DATA_INFO
        else if ([string hasPrefix:@"0c"]) {

            [_decodeManager  loadNewinfoDataFromData:characteristic.value];
        }
        else if ([string hasPrefix:@"04"])
        {

            [_decodeManager loadECGMessageFromData:characteristic.value];
        }

        else if ([string hasPrefix:@"00"]) {

            [_decodeManager loadHeartRateDataWithData:characteristic.value];
            
        }else if ([string hasPrefix:@"08"]){
            [_decodeManager loadSECGMessageFromData:characteristic.value];
            
        }
        else if ([string hasPrefix:@"0e"]){
            [_decodeManager loadAct_V5DataWithData:characteristic.value];
            
        }
        else
        {
            
        }

    }
}


//电池电量
- (void)updateBatteryMessageWith:(CBCharacteristic *)characteristic
{
    if (characteristic.value != nil) {
        
        NSString *str = [self hexadecimalString:characteristic.value];
        NSInteger battery = strtoul([[str substringWithRange:NSMakeRange(1, 2)] UTF8String],0,16);
        self.batteryNum = battery;
         NSLog(@"%ld",(long)self.batteryNum);
        if (_dataSource && [_dataSource respondsToSelector:@selector(syn_ecgMessageOnDeviceBattery:)])
        {
            [_dataSource syn_ecgMessageOnDeviceBattery:battery];
        }
        
        
        if ([SynECGLibSingleton sharedInstance].loginIn == YES) {
         
            NSDictionary *dic = @{@"deviceId":[SynECGLibSingleton sharedInstance].deviceId,@"battery":[NSString stringWithFormat:@"%ld",(long)battery]};
            
            [[RequestManager sharedInstance] postParameters:dic Url:BATTERY_STATUS_URL sucessful:^(id obj) {
            } failure:^(id obj) {
            }];
        }
    }
}

- (void)updaeHardwareRevisionWith:(CBCharacteristic *)characteristic
{
    
    NSString *aString = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
     if (aString.length > 0) {
    [SynECGLibSingleton sharedInstance].hardwareVer = aString;
     }
    
}
- (void)updaeSoftwareRevisionWith:(CBCharacteristic *)characteristic
{
    
    NSString *aString = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    if (aString.length > 0) {
        [SynECGLibSingleton sharedInstance].softwareVer = aString;
    }
    
    
    if (characteristic.value.length >10) {
        NSLog(@"1.6以后的版本");
        [SynECGLibSingleton sharedInstance].max = 1;
    }else{
        [SynECGLibSingleton sharedInstance].max = 0;
        NSLog(@"1.6以前的版本");
    }
    
}

- (void)updaeFirmwareRevisionWith:(CBCharacteristic *)characteristic
{
    
    NSString *aString = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    _nowfirmwareNumber = aString;
    if (aString.length > 0) {
        
        //上传设备信息
        [SynECGLibSingleton sharedInstance].firmwareVer = aString;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self getDeviceUpdateMessage];
        });
    }
}

- (void)getDeviceUpdateMessage
{
    if (_getDeviceStatus == NO) {
        
        if (_typeNum != 0) {
            
        }
        else
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [self getDeviceUpdateMessage];
            });
        }
    }
    else
    {
        if (!_upFirewareing) {
            
        
            NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
            [dic setObject:[SynECGLibSingleton sharedInstance].deviceId forKey:@"deviceId"];
            [dic setObject:[SynECGLibSingleton sharedInstance].deviceTypeId forKey:@"deviceTypeId"];
            [dic setObject:[SynECGLibSingleton sharedInstance].firmwareVer forKey:@"firmwareVer"];
            [dic setObject:[SynECGLibSingleton sharedInstance].hardwareVer forKey:@"hardwareVer"];
            [dic setObject:[SynECGLibSingleton sharedInstance].deviceSN forKey:@"deviceSN"];
            [dic setObject:[SynECGLibSingleton sharedInstance].softwareVer forKey:@"softwareVer"];
            
            BlockWeakSelf(self);
            [[RequestManager sharedInstance]postParameters:dic Url:FIRMWAREVER_CHECK_URL sucessful:^(id obj) {
                
                if (weakSelf.needUpdateFirm == YES) {
                    
                    NSString *can;
                    
                    if (obj[@"firmwareVerVo"][@"desc"] == [NSNull null]) {
                        can = @"0";
                    }else{
                        can = obj[@"firmwareVerVo"][@"firmwareCanUpdate"];
                    }
                    if ([can isEqualToString:@"1"]) {
                    
                        
                        int pkg = [obj[@"firmwareVerVo"][@"pkgType"] intValue];
                        
                        if (pkg == 1) {
                            weakSelf.needMandatoryUpdateFirmWare = YES;
                        }
                        else
                        {
                            weakSelf.needMandatoryUpdateFirmWare = NO;
                        }
                        
                        weakSelf.descMessage = obj[@"firmwareVerVo"][@"desc"];
                        
                        weakSelf.canUpdateFirmWare = YES;
                        [SynECGLibSingleton sharedInstance].update_url = obj[@"firmwareVerVo"][@"url"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"d_c_u" object:nil
                         ];
                        if ([weakSelf.dataSource respondsToSelector:@selector(syn_ecgFirmWareCanUpdate:)]) {
                            [weakSelf.dataSource syn_ecgFirmWareCanUpdate:YES];
                        }
                    }
                    else
                    {
                        weakSelf.canUpdateFirmWare = NO;
                        [SynECGLibSingleton sharedInstance].update_url = obj[@"firmwareVerVo"][@"url"];
                        if ([weakSelf.dataSource respondsToSelector:@selector(syn_ecgFirmWareCanUpdate:)]) {
                            [weakSelf.dataSource syn_ecgFirmWareCanUpdate:NO];
                        }
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"gx_bb" object:nil
                         ];
                    }
                    if (obj[@"firmwareVerVo"][@"version"] != nil && ![obj[@"firmwareVerVo"][@"version"] isKindOfClass:[NSNull class]]) {
                        weakSelf.firmwareNumber = obj[@"firmwareVerVo"][@"desc"];
                    }
                    
                    
                }
                weakSelf.needUpdateFirm = NO;
                
            } failure:^(id obj) {
                //不可以升级
                self.canUpdateFirmWare = NO;
                self.upFirewareing = NO;
                self.needMandatoryUpdateFirmWare = NO;
                if ([weakSelf.dataSource respondsToSelector:@selector(syn_ecgFirmWareCanUpdate:)]) {
                    [weakSelf.dataSource syn_ecgFirmWareCanUpdate:NO];
                }
                
            }];

        }
    }
}

- (void)updateDviceSNWith:(CBCharacteristic *)characteristic
{
    
    NSString *aString = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    if (aString.length > 0) {
    }
    else
    {
        [SynECGLibSingleton sharedInstance].deviceSN = @"2016520";
    }
}


- (void)saveDeviceStatusWithMessage:(NSMutableDictionary *)dic
{
    if ([_dataSource respondsToSelector:@selector(syn_ecgMessageOnDeviceStatus:)]) {
        
        if ([SynECGLibSingleton sharedInstance].record_id.length > 0 || [dic[@"deviceStatus"] isEqualToString:@"1"] || [dic[@"deviceStatus"] isEqualToString:@"0"] || [dic[@"deviceStatus"] isEqualToString:@"3"] ) {
            
            if ([dic[@"deviceStatus"] isEqualToString:@"12"]) {
                
                [dic setObject:@"9" forKey:@"deviceStatus"];
                [_dataSource syn_ecgMessageOnDeviceStatus:dic];
            }
            else
            {
                [_dataSource syn_ecgMessageOnDeviceStatus:dic];
            }
        }
    }
    
    if ([dic[@"deviceStatus"] isEqualToString:@"0"] || [dic[@"deviceStatus"] isEqualToString:@"1"] ||[dic[@"deviceStatus"] isEqualToString:@"2"] ||[dic[@"deviceStatus"] isEqualToString:@"3"])
    {
        
        
        NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
        NSString *old =  [user objectForKey:@"oldDeviceStatus"];
        
        if (!old) {
            old = @"0";
        }
        [user setObject:dic[@"deviceStatus"] forKey:@"oldDeviceStatus"];
        
//        if ( [SynECGLibSingleton sharedInstance].record_id != nil && [SynECGLibSingleton sharedInstance].record_id.length > 0)
//        {
        
            
            if (![old isEqualToString:dic[@"deviceStatus"]]) {

                [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    
                    NSDate *date = [SynECGUtils getDateWithDateString:dic[@"time"] WithFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
                    NSTimeInterval tv = [date timeIntervalSince1970];
                    long long timeSp = (long long)(tv * 1000);
                    NSString *time = [dic[@"time"] substringWithRange:NSMakeRange(0, 19)];
                    
                    if (time > 0) {
                     
                        NSInteger rr = 0;
                        NSInteger ecg = 0;
                        NSInteger event = 0;
                        rr = [self queryTable:TOTAL_TABLE Column:@"ann" inDB:db];
                        ecg = [self queryTable:TOTAL_TABLE Column:@"ecg" inDB:db];
                        event = [self queryTable:TOTAL_TABLE Column:@"event" inDB:db];
                        
                        
                        NSMutableDictionary *new = [[NSMutableDictionary alloc]init];
                        [new setObject:@(rr) forKey:@"beatIndex"];
                        [new setObject:@(ecg) forKey:@"ecgDataIndex"];
                        [new setObject:@(event) forKey:@"eventIndex"];
                        
                        NSString *json = [SynECGUtils convertToJSONData:new];
                        
                        //STATUS_TABLE
                        BOOL succeed = [db executeUpdate:@"INSERT INTO d_s (deviceStatus, startTime, recordId, deviceId, oldDeviceStatus, occurUnixTime,targetId,dataIndexVo) VALUES (?, ?, ?, ?, ?, ?, ?, ?);",dic[@"deviceStatus"],time,[SynECGLibSingleton sharedInstance].record_id,[SynECGLibSingleton sharedInstance].deviceId,old,@(timeSp),[SynECGLibSingleton sharedInstance].target_id,json];
                        
                        
                        
                        
                        if (succeed) {
                            
                            NSLog(@"保存成功");
                            [[HADeviceStatusManager sharedInstance] uploadStatusMessage];
                        }
                        else
                        {
                            NSLog(@"保存失败");
                            [db executeUpdate:@"insert into d_s (deviceStatus, startTime, recordId, deviceId, oldDeviceStatus, occurUnixTime,targetId,dataIndexVo) VALUES (?, ?, ?, ?, ?, ?, ?, ?);",dic[@"deviceStatus"],dic[@"time"],[SynECGLibSingleton sharedInstance].record_id,[SynECGLibSingleton sharedInstance].deviceId,old,@(timeSp),[SynECGLibSingleton sharedInstance].target_id,json];
                            [[HADeviceStatusManager sharedInstance] uploadStatusMessage];
                        }

                    }
                }];
                
            }
//        }
    }
}


#pragma mark 详细数据包
-(void)updateRecordMessageWith:(CBCharacteristic*)characteristic{
    NSString *string = [SynECGUtils hexadecimalString:characteristic.value];
    // EVT v2
    if ([string hasPrefix:@"0000"] && string.length == 38) {
        //记录列表数据块
            _indexType = 1;
        
    }else if ([string hasPrefix:@"0002"] && string.length == 38){
        //ECG数据块
        //记录列表数据块
            _indexType = 2;
        
    }else if ([string hasPrefix:@"0003"] && string.length == 38){
        //ANN数据块
        //记录列表数据块
            _indexType = 3;
    }else if ([string hasPrefix:@"0004"] && string.length == 38){
        //EVT数据块
        //记录列表数据
            _indexType = 4;
    }else if ([string hasPrefix:@"ff01"] && string.length == 38){
        if (_indexType == 1) {
            if (_data00.length > 0) {

                NSLog(@"开始补传");
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
                    
                }
                
                if ([ECGHRManager sharedInstance].ecgOutFile == nil) {
                    
                    [ECGHRManager sharedInstance].ecgOutFile = [NSFileHandle fileHandleForUpdatingAtPath:[SynECGLibSingleton sharedInstance].ecgTempFile];
                }
                
                //清空ECG
                if ([ECGHRManager sharedInstance].tempSaveData != nil) {
                    
                    
                    [[ECGHRManager sharedInstance].tempSaveData resetBytesInRange:NSMakeRange(0, [ECGHRManager sharedInstance].tempSaveData.length)];
                    [[ECGHRManager sharedInstance].tempSaveData setLength:0];
                    
                    [SynECGLibSingleton sharedInstance].ecgData = [ECGHRManager sharedInstance].tempSaveData;
                    
                }
                
                //清空EVT
                [ECGDecodeManager sharedInstance].parseing = NO;
                if([ECGDecodeManager sharedInstance].eventTempData.length > 0)
                {
                    [[ECGDecodeManager sharedInstance].eventTempData resetBytesInRange:NSMakeRange(0, [ECGDecodeManager sharedInstance].eventTempData.length)];
                    [[ECGDecodeManager sharedInstance].eventTempData setLength:0];
                    
                }
                //清空ECG暂存
                if(self.data03.length > 0)
                {
                    [self.data03 resetBytesInRange:NSMakeRange(0, self.data03.length)];
                    [self.data03 setLength:0];
                }
                
            
                [_speedTimer setFireDate:[NSDate distantPast]];
                
                
                [[_data00 subdataWithRange:NSMakeRange(29, 4)] getBytes:&ecgLength length:sizeof(ecgLength)];
                
                 [[_data00 subdataWithRange:NSMakeRange(33, 4)] getBytes:&annLength length:sizeof(annLength)];
                 [[_data00 subdataWithRange:NSMakeRange(37, 4)] getBytes:&evtLength length:sizeof(evtLength)];
                
                [[BluetoothCommandManager sharedInstance] openViewWith:^(id obj) {
                    [ECGDecodeManager sharedInstance].ecg = [[obj objectForKey:@"ecg"]integerValue];
                    [ECGDecodeManager sharedInstance].ann = [[obj objectForKey:@"ann"]integerValue];
                    [ECGDecodeManager sharedInstance].event = [[obj objectForKey:@"event"]integerValue];
                    [SynECGLibSingleton sharedInstance].ecgInt = [ECGDecodeManager sharedInstance].ecg;
                    NSInteger ecgOffect = [ECGDecodeManager sharedInstance].ecg/256;
                    NSInteger ecglong = self->ecgLength / 3 * 2 / 256 - ecgOffect;

                    self.allByte = self->ecgLength + (self -> annLength) * 8 + (self ->evtLength) * 32;
                    self.alreadyByte = [ECGDecodeManager sharedInstance].ecg * 3 / 2 + [ECGDecodeManager sharedInstance].ann * 8 + [ECGDecodeManager sharedInstance].event * 32;
                    
                    
                    Byte b = (Byte) ((ecgOffect) & 0xFF);
                    Byte c = (Byte) ((ecgOffect>>8)& 0xFF);
                    Byte d = (Byte) ((ecgOffect>>16)& 0xFF);
                    Byte f = (Byte) (ecgOffect>>24 & 0xFF);
                    Byte b1 = (Byte) ((ecglong) & 0xFF);
                    Byte c1 = (Byte) ((ecglong>>8)& 0xFF);
                    Byte d1 = (Byte) ((ecglong>>16)& 0xFF);
                    Byte f1 = (Byte) (ecglong>>24 & 0xFF);
                    Byte *testByte = (Byte *)[self->_data00  bytes];
                    Byte a = testByte[0];
                    
                    Byte g[]= {0x09,a,0x00,b,c,d,f,b1,c1,d1,f1};
                    NSData *data =[NSData dataWithBytes:&g length:sizeof(g)];
                    [self.currPeripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
                    self->_indexType = 0;
                    
                }];
            }
            else
            {
                
                if (self.retryNum <= 3) {
                    
                    self.retryNum ++;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        
                         [self getDeviceRecodList];
                        
                    });
                }
                else
                {
                    NSLog(@"实在找不到结束了");
                    self.retryNum = 0;
                    //结束接口 -- 直接
                    self.iSNewWoking = NO;
                    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
                    [user setObject:@(0) forKey:@"iSNewWoking"];
                    [user setObject:@"no" forKey:@"state"];
                    
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self endUploadMessageTosever];
                    });
                    
                    if (_dataSource && [_dataSource respondsToSelector:@selector(syn_ecgMessageOnToSFTF:)]) {
                        [_dataSource syn_ecgMessageOnToSFTF:YES];
                    }
                    
                    [queue inDatabase:^(FMDatabase *db) {
                        
                        [self changeUseInfoForTable:SYN_USERINFO_TABLE mac:@"" deviceId:@"" deviceTypeId:@"" deviceName:@"" inDb:db];
                    }];
                }
            }
            
        }else if (_indexType == 2){
            NSLog(@"ecg补传结束 写入ann补传");
            
            
            [_decodeManager loadEcgtRecordDataFromData:self.data03 andIndex:[ECGDecodeManager sharedInstance].ecg];
            [self.data03 resetBytesInRange:NSMakeRange(0, self.data03.length)];
            [self.data03 setLength:0];
            
                
                int annOffect = [ECGDecodeManager sharedInstance].ann;
                int annlong = self->annLength - annOffect;
                
                Byte b = (Byte) ((annOffect) & 0xFF);
                Byte c = (Byte) ((annOffect>>8)& 0xFF);
                Byte d = (Byte) ((annOffect>>16)& 0xFF);
                Byte f = (Byte) (annOffect>>24 & 0xFF);
                Byte b1 = (Byte) ((annlong) & 0xFF);
                Byte c1 = (Byte) ((annlong>>8)& 0xFF);
                Byte d1 = (Byte) ((annlong>>16)& 0xFF);
                Byte f1 = (Byte) (annlong>>24 & 0xFF);
                Byte *testByte = (Byte *)[_data00  bytes];
                Byte a = testByte[0];
                
                Byte g[]= {0x09,a,0x01,b,c,d,f,b1,c1,d1,f1};
                NSData *data =[NSData dataWithBytes:&g length:sizeof(g)];
                [self.currPeripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
                _indexType = 0;
            
        }else if (_indexType == 3){
            NSLog(@"ann补传结束 写入evt补传");
                
                int evtOffect = [ECGDecodeManager sharedInstance].event;
                int evtlong = self->evtLength - evtOffect;
                
                Byte b = (Byte) ((evtOffect) & 0xFF);
                Byte c = (Byte) ((evtOffect>>8)& 0xFF);
                Byte d = (Byte) ((evtOffect>>16)& 0xFF);
                Byte f = (Byte) (evtOffect>>24 & 0xFF);
                Byte b1 = (Byte) ((evtlong) & 0xFF);
                Byte c1 = (Byte) ((evtlong>>8)& 0xFF);
                Byte d1 = (Byte) ((evtlong>>16)& 0xFF);
                Byte f1 = (Byte) (evtlong>>24 & 0xFF);
                Byte *testByte = (Byte *)[_data00  bytes];
                Byte a = testByte[0];
                
                Byte g[]= {0x09,a,0x02,b,c,d,f,b1,c1,d1,f1};
                NSData *data =[NSData dataWithBytes:&g length:sizeof(g)];
                [self.currPeripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
                _indexType = 0;
            
        }
        else if(_indexType == 4)
        {
            self.allByte = 0;
            NSLog(@"传完了结束了");
            //结束接口 补传；
            self.retryNum = 0;
            self.iSNewWoking = NO;
            NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
            [user setObject:@(0) forKey:@"iSNewWoking"];
            [user setObject:@"no" forKey:@"state"];
            
            [_speedTimer setFireDate:[NSDate distantFuture]];
            self.lastLength = 0;
            self.alreadyByte = 0;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self endUploadMessageTosever];
                
                [self -> queue inDatabase:^(FMDatabase *db) {
                    
                    [self changeUseInfoForTable:SYN_USERINFO_TABLE mac:@"" deviceId:@"" deviceTypeId:@"" deviceName:@"" inDb:db];
                    
                    [db executeUpdate:@"INSERT INTO record_list (recordId) VALUES (?);",[SynECGLibSingleton sharedInstance].record_id];
                    
                }];
                
            });

            [HeartBeatModel sharedInstance].num = 0;
            if (_dataSource && [_dataSource respondsToSelector:@selector(syn_ecgMessageOnToSFTF:)]) {
                [_dataSource syn_ecgMessageOnToSFTF:YES];
            }
            
        }
        else
        {
            
        }
        
    }
    else if ([string hasPrefix:@"ff00"] && string.length == 38) {
        
        if (self.indexType == 2) {
            
            [_decodeManager loadEcgtRecordDataFromData:self.data03 andIndex:[ECGDecodeManager sharedInstance].ecg];
            [self.data03 resetBytesInRange:NSMakeRange(0, self.data03.length)];
            [self.data03 setLength:0];
        }
        
    }
    else
    {
     
        if (_indexType == 1) {
            
            //        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            //        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            
            
            if (string.length > 38) {
                for (int i = 0; i< string.length/138; i++) {
                    
                    
                    
                    NSData *data0 = [characteristic.value subdataWithRange:NSMakeRange(69 * i + 1, 16)];
                    NSData *dataChange = [[BluetoothCommandManager sharedInstance]dataTransfromBigOrSmall:data0];
                    //userId
                    NSString *userId = [SynECGUtils hexadecimalString:dataChange];
                    
                    
                    if ([[[SynECGLibSingleton sharedInstance].record_id substringWithRange:NSMakeRange(0, 32)] isEqualToString:userId]) {
                        
                        NSString *tp = [string substringWithRange:NSMakeRange(2+i*138 + 32, 8)];
                        
                        
                        NSData *data = [SynECGUtils fan_hexToBytes:tp];
                        
                        int datalength;
                        [data getBytes: &datalength length: sizeof(datalength)];
                        
                        
                        //                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(datalength + 946656000 + 28800)];
                        //
                        //                    NSString *dateString       = [formatter stringFromDate: date];
                        //                    NSLog(@"服务器返回的时间戳对应的时间是:%@",dateString);
                        
                        
                        
                        if (datalength == [SynECGLibSingleton sharedInstance].startMonitorTime) {
                            
                            _data00 = (NSMutableData *)[characteristic.value subdataWithRange:NSMakeRange(i*69, 69)];
                        }
                    }
                    
                }
            }
        }
        
        else if (_indexType == 2) {
            if (string.length != 38) {
                //百分比
                _alreadyByte = _alreadyByte + characteristic.value.length;
                [self.data03 appendData:characteristic.value];
                
            }
        }
        else if (_indexType == 3) {
            if (string.length != 38) {
                
                //百分比
                _alreadyByte = _alreadyByte + characteristic.value.length;
                
                
                int a = _data01.length/8;
                [_data01 replaceBytesInRange:NSMakeRange(0, a*8) withBytes:NULL length:0];
                [_data01 appendData:characteristic.value];
                
                
                
                [_decodeManager loadAnntRecordDataFromData:_data01 andIndex:[ECGDecodeManager sharedInstance].ann];
                [ECGDecodeManager sharedInstance].ann = [ECGDecodeManager sharedInstance].ann + _data01.length/8;
                
                
            }
            
        }
        else if (_indexType == 4) {
            if (string.length != 38) {
                
                //百分比
                _alreadyByte = _alreadyByte + characteristic.value.length;
                
                
                int a = _data02.length/32;
                [_data02 replaceBytesInRange:NSMakeRange(0, a*32) withBytes:NULL length:0];
                [_data02 appendData:characteristic.value];
                
                for (int i = 0; i< _data02.length/32; i++) {
                    [ECGDecodeManager sharedInstance].event = [ECGDecodeManager sharedInstance].event + 1;
                    [_decodeManager  loadEvtRecordDataFromData:[_data02 subdataWithRange:NSMakeRange(32*i, 32)] andIndex: [ECGDecodeManager sharedInstance].event];
                    NSLog(@"我是shi'jian%@",[_data02 subdataWithRange:NSMakeRange(32*i, 32)]);
                }
            }
            
        }
    }
}

- (void)getSpeed
{
    float percentage = ((float)_alreadyByte)/_allByte;
    NSInteger times = (_allByte - _alreadyByte) / (_alreadyByte - _lastLength);
    
    if (percentage >= 1.0) {
        
        percentage = 0.99;
    }
    if (times < 0) {
        
        times = 1;
    }
    
     CGFloat v = (_alreadyByte - _lastLength) / 1024;
    
    _lastLength = _alreadyByte;
    
    NSLog(@"%0.2f",percentage);
    NSLog(@"%ld",(long)times);
    
    if (_dataSource && [_dataSource respondsToSelector:@selector(syn_ecgMessageOnPercentValue:andSpendTime:andV:andUnfinishTime:)]) {
        [_dataSource syn_ecgMessageOnPercentValue:percentage * 100 andSpendTime:0 andV:v andUnfinishTime:times];
    }
}




#pragma mark--------------写入信息
- (void)writePersonInfoMessageToBleforCharacteristic:(CBCharacteristic *)characteristic
{
    //个人信息 年龄性别  ageStr 为年龄 w为体重 h为身高 str 为targetID
    
    [[BluetoothCommandManager sharedInstance] writePersonInfoMessageWith:^(id obj) {
       
        [self.currPeripheral writeValue:obj forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }];
}


#pragma mark--------------写入信息
- (void)writeNewPersonInfoMessageToBleforCharacteristic:(CBCharacteristic *)characteristic
{
    //个人信息 年龄性别  ageStr 为年龄 w为体重 h为身高 str 为targetID
    
    [[BluetoothCommandManager sharedInstance] writeNewPersonInfoMessageWith:^(id obj) {
        
        [self.currPeripheral writeValue:obj forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }];
}


- (void)startView
{
    //第二步写进去
    [self.currPeripheral writeValue:[[BluetoothCommandManager sharedInstance] startView] forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
}
- (void)startOffsetsView
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
        
    }
    
    if ([ECGHRManager sharedInstance].ecgOutFile == nil) {
        
        [ECGHRManager sharedInstance].ecgOutFile = [NSFileHandle fileHandleForUpdatingAtPath:[SynECGLibSingleton sharedInstance].ecgTempFile];
    }
   
    
    [_timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:300]];
    //开启线程
    if ([SynECGLibSingleton sharedInstance].isSuspend == YES) {
        
        [[ECGDecodeManager sharedInstance].eventTempData resetBytesInRange:NSMakeRange(0, [ECGDecodeManager sharedInstance].eventTempData.length)];
        [[ECGDecodeManager sharedInstance].eventTempData setLength:0];
        [ECGDecodeManager sharedInstance].needReturn = YES;
        dispatch_resume([ECGDecodeManager sharedInstance].eventQueue);
        [SynECGLibSingleton sharedInstance].isSuspend = NO;
        
    }
    
    [self startTestAlert];
//    [self getRRAlertMessage];
    
    [[BluetoothCommandManager sharedInstance] openViewWith:^(id obj) {
        [ECGDecodeManager sharedInstance].ann = [[obj objectForKey:@"ann"]integerValue];
        [ECGDecodeManager sharedInstance].ecg = [[obj objectForKey:@"ecg"]integerValue];
        [SynECGLibSingleton sharedInstance].ecgInt = [[obj objectForKey:@"ecg"]integerValue];
        [ECGDecodeManager sharedInstance].event = [[obj objectForKey:@"evt"]integerValue];
        
        [self.currPeripheral writeValue:[obj objectForKey:@"str"] forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
        
    }];
   

}

- (void)startMonitoringECG
{

    if (_currPeripheral &&_characteristic && _typeNum != 0 && _typeNum != 2 && _typeNum != 9 ) {


        self.getHistory = NO;
        self.getLocation = 0;
        [ECGBreathUpload sharedInstance].lastMessage = NO;
        [self writeNewPersonInfoMessageToBleforCharacteristic:_characteristic];
        [self startView];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[BluetoothCommandManager sharedInstance] setRecordId];
            [self.timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:300]];
            
            self.startTime = [SynECGLibSingleton sharedInstance].startMonitorTime;
            //开始  点击开始的时候 写入该data
            self.iSNewWoking = YES;
            NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
            [user setObject:@(1) forKey:@"iSNewWoking"];
            [self.currPeripheral writeValue:[[BluetoothCommandManager sharedInstance] startMonitoringECG] forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
            
            
        });
        
    }
}

- (void)endMonitoringECG
{
    
    //点击停止的时候 写入该data
    
    if (_currPeripheral && _characteristic && _typeNum != 0 && _typeNum != 1)
    {
        
        [_timer setFireDate:[NSDate distantFuture]];
        
        [self.currPeripheral writeValue:[[BluetoothCommandManager sharedInstance] endMonitoringECG] forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];

        if (self.typeNum != 9) {
            
            NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
            [user setObject:@(0) forKey:@"iSNewWoking"];
            
            
            
            if (_iSNewWoking == YES) {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self endUploadMessageTosever];
                });
            }
            else
            {
                
            }
            
            self.iSNewWoking = NO;
        }
    }
}


- (void)getDeviceRecodList
{
    if (self.characteristic != nil) {
     
            [self.currPeripheral writeValue:[[BluetoothCommandManager sharedInstance] getListRecord] forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
    }
    else
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self getDeviceRecodList];
        });
    }
}



#pragma mark ----------特殊方法
- (NSString*)hexadecimalString:(NSData *)data{
    const unsigned char* dataBuffer = (const unsigned char*)[data bytes];
    if(!dataBuffer){
        return nil;
    }
    NSUInteger dataLength = [data length];
    NSMutableString* hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for(int i = 0; i < dataLength; i++){
        [hexString appendString:[[NSString alloc]initWithFormat:@":%02lx", (unsigned long)dataBuffer[i]]];
    }
    return hexString;
}

- (NSString *)getUUIDFrom:(id)string
{
    
    if ([string isKindOfClass:[NSString class]]) {
        
        NSMutableString *str = [[NSMutableString alloc]initWithString:string];
        
        [str stringByReplacingOccurrencesOfString:@"(" withString:@""];
        [str stringByReplacingOccurrencesOfString:@")" withString:@""];
        [str stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        [str stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        
        
        NSLog(@"%@",str);
        
        return str;
        
    }
    else if([string isKindOfClass:[NSArray class]])
    {
        
        id key = ((NSArray *)string)[0];
        
        
        
        
        if ([key isKindOfClass:[NSString class]]) {
         
            NSMutableString *str = [[NSMutableString alloc]initWithString:key];
            
            [str stringByReplacingOccurrencesOfString:@"(" withString:@""];
            [str stringByReplacingOccurrencesOfString:@")" withString:@""];
            [str stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            [str stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            
        
                  return str;
        }
        else if([key isKindOfClass:[CBUUID class]])
        {
            NSMutableString *str = [[NSMutableString alloc]initWithString:[(CBUUID *)key UUIDString]];
            
            [str stringByReplacingOccurrencesOfString:@"(" withString:@""];
            [str stringByReplacingOccurrencesOfString:@")" withString:@""];
            [str stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            [str stringByReplacingOccurrencesOfString:@"\"" withString:@""];
         
            return str;

        }
        else
        {
            return @"";
        }
    }
    else if([string isKindOfClass:[CBUUID class]])
    {
        NSMutableString *str = [[NSMutableString alloc]initWithString:[(CBUUID *)string UUIDString]];
        [str stringByReplacingOccurrencesOfString:@"(" withString:@""];
        [str stringByReplacingOccurrencesOfString:@")" withString:@""];
        [str stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        [str stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        
      
        return str;

    }
    else
    
    {
              return @"";
    
    }
    
    
}




#pragma mark---------上传状态
- (void)heartReatMethod
{
    if ([RequestManager isNetworkReachable] == YES) {
     
        [[HeartBeatModel sharedInstance] uploadStatusMessage];
    }
}

#pragma mark------------告警相关
//断开重连判断是否需要继续监控。。。。。
- (void)startTestAlert
{
    
//    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
//
//        NSString *query = [NSString stringWithFormat:@"Select * From %@ where alarm_flag = '%@'", ALARM_TABLE,@(0)];
//        FMResultSet *rs = [db executeQuery:query];
//        SynAlarmOperationModel *manager = [SynAlarmOperationModel sharedInstance];
//        while ([rs next]) {
//
//            NSString *type = [rs stringForColumn:@"alert_category"];
//            NSString *key = [rs stringForColumn:@"alert_type"];
//            if ([type isEqualToString:@"CAT_VT"]||[type isEqualToString:@"CAT_SVT"]||[type isEqualToString:@"CAT_SBRAD"]||[type isEqualToString:@"CAT_STACH"])
//            {
//
//            }
//            else if([type isEqualToString:@"CAT_SVEB"]||[type isEqualToString:@"CAT_VEB"])
//            {
//                if ([type isEqualToString:@"CAT_SVEB"]) {
//
//                    if ([key isEqualToString:@"AL_SVEB_L0"]) {
//
//                        manager.SVEB0 = YES;
//                    }
//                    else
//                    {
//                        manager.SVEB1 = YES;
//                    }
//                }
//                else
//                {
//                    if ([key isEqualToString:@"AL_VEB_L0"]) {
//
//                        manager.VEB3 = YES;
//                    }
//                    else if ([key isEqualToString:@"AL_VEB_L1"]) {
//
//                        manager.VEB1 = YES;
//                    }
//                    else if ([key isEqualToString:@"AL_VEB_BRAD"]) {
//
//                        manager.VEB0 = YES;
//                    }
//                    else if ([key isEqualToString:@"AL_VEB_L2"]) {
//                        manager.VEB2 = NO;
//                    }
//                    else
//                    {
//                    }
//                }
//            }
//            else if([type isEqualToString:@"CAT_STACH"]||[type isEqualToString:@"CAT_SBRAD"])
//            {
//                if([key isEqualToString:@"AL_STACH_L2"])
//                {
//                    manager.beatType = 1;
//                }
//                else if([key isEqualToString:@"AL_STACH_L0"])
//                {
//                    manager.beatType = 2;
//                }
//                else if([key isEqualToString:@"AL_SBRAD_L0"])
//                {
//                    manager.beatType = 3;
//                }
//                else if([key isEqualToString:@"AL_SBRAD_L1"])
//                {
//                    manager.beatType = 4;
//                }
//                else if([key isEqualToString:@"AL_SBRAD_L2"])
//                {
//                    manager.beatType = 5;
//                }
//                else if([key isEqualToString:@"AL_SVT_L1"])
//                {
//                    manager.beatType = 6;
//                }
//                else if([key isEqualToString:@"AL_SVT_L2"])
//                {
//                    manager.beatType = 7;
//                }
//                else if([key isEqualToString:@"AL_VT"])
//                {
//                    manager.beatType = 8;
//                }
//                else if([key isEqualToString:@"AL_VT_PARO"])
//                {
//                    manager.beatType = 9;
//                }
//
//            }
//
//        }
//
//
////        NSString *allindex_query = [NSString stringWithFormat:@"Select * From %@ where recordId = '%@'", TOTAL_TABLE,[SynECGLibSingleton sharedInstance].record_id];
////        FMResultSet *allindex_rs = [db executeQuery:allindex_query];
//
//        NSInteger a_np = [[SynECGUtils getStartPosition1] integerValue];
//        NSInteger a_up = [[SynECGUtils getStartPosition2] integerValue];
//        [SynAlarmOperationModel sharedInstance].unsinusType =  [SynECGUtils getStartStartType];
//
//
//        NSLog(@"%ld-----%ld------%@",(long)a_np,(long)a_up,[SynAlarmOperationModel sharedInstance].unsinusType);
//
////        while ([allindex_rs next]){
////
////            a_np = (NSInteger)[allindex_rs longLongIntForColumn:@"a_np"];
////            a_up = (NSInteger)[allindex_rs longLongIntForColumn:@"a_up"];
////            [SynAlarmOperationModel sharedInstance].unsinusType = [allindex_rs stringForColumn:@"a_r"];
////        }
//
//        [[SynAlarmOperationModel sharedInstance].unsinusArray removeAllObjects];
//        [[SynAlarmOperationModel sharedInstance].sinusArray removeAllObjects];
//        if (a_up <= a_np) {
//
//            NSString *rr_query = [NSString stringWithFormat:@"select * from %@ where position >= '%@'",RR_TABLE,@(a_np)];
//            FMResultSet *rr_rs = [db executeQuery:rr_query];
//            while ([rr_rs next]){
//
//                [[SynAlarmOperationModel sharedInstance].sinusArray addObject:@([rr_rs longLongIntForColumn:@"position"])];
//
//            }
//        }
//        else
//        {
//            NSString *rr_query = [NSString stringWithFormat:@"select * from %@ where position >= '%@'",RR_TABLE,@(a_np)];
//            FMResultSet *rr_rs = [db executeQuery:rr_query];
//            while ([rr_rs next]){
//
//                if ([rr_rs longLongIntForColumn:@"position"] >= a_up) {
//
//                    [[SynAlarmOperationModel sharedInstance].unsinusArray addObject:@([rr_rs longLongIntForColumn:@"position"])];
//                }
//                else
//                {
//                    [[SynAlarmOperationModel sharedInstance].sinusArray addObject:@([rr_rs longLongIntForColumn:@"position"])];
//                }
//
//            }
//        }
//
//
//        NSMutableArray *tot = [[NSMutableArray alloc]init];
//
//        [tot addObjectsFromArray:[SynAlarmOperationModel sharedInstance].sinusArray];
//        [tot addObjectsFromArray:[SynAlarmOperationModel sharedInstance].unsinusArray];
//
//        NSInteger position = 0;
//        position = [tot.lastObject integerValue];
//
//
//
//        [[SynAlarmOperationModel sharedInstance].hourAArray removeAllObjects];
//        [[SynAlarmOperationModel sharedInstance].hourVArray removeAllObjects];
//        [[SynAlarmOperationModel sharedInstance].minuteVArray removeAllObjects];
//        [[SynAlarmOperationModel sharedInstance].minuteAArray removeAllObjects];
//
//
//
//        NSString *HA = [NSString stringWithFormat:@"select * from %@ where position > '%@' and  position < '%@' and  ann = '%@'",RR_TABLE,@(position - 256 * 60 * 60),@(position),@"A"];
//        NSString *MA = [NSString stringWithFormat:@"select * from %@ where position > '%@' and  position < %@ and  ann = '%@'",RR_TABLE,@(position - 256 * 60),@(position),@"A"];
//
//        NSString *HV = [NSString stringWithFormat:@"select * from %@ where position > '%@' and  position < '%@' and  ann = '%@'",RR_TABLE,@(position - 256 * 60 * 60),@(position),@"V"];
//        NSString *MV = [NSString stringWithFormat:@"select * from %@ where position > '%@' and  position < '%@' and  ann = '%@'",RR_TABLE,@(position - 256 * 60),@(position),@"V"];
//
//        FMResultSet *ha_rs = [db executeQuery:HA];
//        while ([ha_rs next]){
//
//            [[SynAlarmOperationModel sharedInstance].hourAArray addObject:@([ha_rs longLongIntForColumn:@"position"])];
//
//        }
//
//        FMResultSet *ma_rs = [db executeQuery:MA];
//        while ([ma_rs next]){
//
//            [[SynAlarmOperationModel sharedInstance].minuteAArray addObject:@([ma_rs longLongIntForColumn:@"position"])];
//
//        }
//
//        FMResultSet *hv_rs = [db executeQuery:HV];
//        while ([hv_rs next]){
//
//            [[SynAlarmOperationModel sharedInstance].hourVArray addObject:@([hv_rs longLongIntForColumn:@"position"])];
//
//        }
//
//        FMResultSet *mv_rs = [db executeQuery:MV];
//        while ([mv_rs next]){
//
//            [[SynAlarmOperationModel sharedInstance].minuteVArray addObject:@([mv_rs longLongIntForColumn:@"position"])];
//
//        }
//
//
//
//
//
//        
//    }];
    
}

////获取告警检测数据
//- (void)getRRAlertMessage
//{
//    [SynAlarmOperationModel sharedInstance].unsinusType = [SynECGUtils getStartStartType];
//
//    NSInteger a1 = [[SynECGUtils getStartPosition1] integerValue];
//    NSInteger a2 = [[SynECGUtils getStartPosition2] integerValue];
//
//    [[SynAlarmOperationModel sharedInstance].unsinusArray removeAllObjects];
//    [[SynAlarmOperationModel sharedInstance].sinusArray removeAllObjects];
//
//
//    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
//
//        NSString *query1 = [NSString stringWithFormat:@"select * from %@ where position > %ld", RR_TABLE,(long)a1];
//        FMResultSet *rs1 = [db executeQuery:query1];
//        while ([rs1 next])
//        {
//            [[SynAlarmOperationModel sharedInstance].sinusArray addObject:@([rs1 longLongIntForColumn:@"position"])];
//
//        }
//
//        NSString *query2 = [NSString stringWithFormat:@"select * from %@ where position > %ld", RR_TABLE,(long)a2];
//        FMResultSet *rs2 = [db executeQuery:query2];
//        while ([rs2 next])
//        {
//            [[SynAlarmOperationModel sharedInstance].sinusArray addObject:@([rs2 longLongIntForColumn:@"position"])];
//        }
//
//
//
//    }];
//
//}







- (void)syn_ecgGetAllAlertWaterMarkByTimeWithCompletion:(CommonBlockCompletion)completionCallback
{
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSString *query = [NSString stringWithFormat:@"select * from %@ where record_id = '%@' order by occur_unixtime desc",WATER_TABLE,[SynECGLibSingleton sharedInstance].record_id];
        FMResultSet *rs = [db executeQuery:query];
        NSMutableArray *array = [[NSMutableArray alloc]init];
        while ([rs next]) {
            
            
            NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
            [dic setObject:[@""water:[rs stringForColumn:@"alert_mark_category"]] forKey:@"name"];
            [dic setObject:[rs stringForColumn:@"alert_mark_category"] forKey:@"category"];
            [dic setObject:[rs stringForColumn:@"alert_type"] forKey:@"alerts"];
            [dic setObject:@([rs intForColumn:@"alert_mark_level"]) forKey:@"level"];
            if ([rs intForColumn:@"alert_flag"] != 0) {
                
                [dic setObject:@([rs intForColumn:@"duration_msec"]) forKey:@"durationMsec"];
            }
            else
            {
                if ([rs intForColumn:@"duration_msec"] > 0)
                {
                    
                    [dic setObject:@([rs intForColumn:@"duration_msec"]) forKey:@"durationMsec"];
                }
                else
                {
                    NSInteger model = [[SynAlarmOperationModel sharedInstance].sinusArray.lastObject integerValue];
                    if ([SynAlarmOperationModel sharedInstance].unsinusArray.count > 0) {
                        model = [[SynAlarmOperationModel sharedInstance].unsinusArray.lastObject integerValue];
                    }
                    
                    
                    NSInteger past = [self tpFromPostion:model];
                    long long nowTime = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:past];
                    NSInteger recordTime = (NSInteger)(nowTime - [rs longLongIntForColumn:@"occur_unixtime"]);
                    if (recordTime < 0) {
                        
                        recordTime = 0;
                    }
                    
                    
                    [dic setObject:@([rs intForColumn:@"duration_msec"] + recordTime) forKey:@"durationMsec"];
                
                }

            }
            
            [dic setObject:@([rs longLongIntForColumn:@"occur_unixtime"]) forKey:@"occurUnixtime"];
            
            [array addObject:dic];
            
        }
        
        completionCallback(array);

    }];
}

- (void)syn_ecgGetAllAlertWaterMarkByLevelWithCompletion:(CommonBlockCompletion)completionCallback
{
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        
        NSString *query = [NSString stringWithFormat:@"select * from %@ where record_id = '%@' order by alert_mark_level desc, occur_unixtime desc",WATER_TABLE,[SynECGLibSingleton sharedInstance].record_id];
        FMResultSet *rs = [db executeQuery:query];
        NSMutableArray *array = [[NSMutableArray alloc]init];
        while ([rs next]) {
            
            
            NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
            [dic setObject:[@""water:[rs stringForColumn:@"alert_mark_category"]] forKey:@"name"];
            [dic setObject:[rs stringForColumn:@"alert_mark_category"] forKey:@"category"];
            [dic setObject:[rs stringForColumn:@"alert_type"] forKey:@"alerts"];
            [dic setObject:@([rs intForColumn:@"alert_mark_level"]) forKey:@"level"];
            if ([rs intForColumn:@"alert_flag"] != 0) {
                
                [dic setObject:@([rs intForColumn:@"duration_msec"]) forKey:@"durationMsec"];
            }
            else
            {

                if ([rs intForColumn:@"duration_msec"] > 0)
                {
                    
                    [dic setObject:@([rs intForColumn:@"duration_msec"]) forKey:@"durationMsec"];
                }
                else
                {
                    NSInteger model = [[SynAlarmOperationModel sharedInstance].sinusArray.lastObject integerValue];
                    if ([SynAlarmOperationModel sharedInstance].unsinusArray.count > 0) {
                        model = [[SynAlarmOperationModel sharedInstance].unsinusArray.lastObject integerValue];
                    }
                    
                    
                    NSInteger past = [self tpFromPostion:model];
                    long long nowTime = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:past];
                    long long recordTime = (long long)(nowTime - [rs longLongIntForColumn:@"occur_unixtime"]);
                    if (recordTime < 0) {
                        
                        recordTime = 0;
                    }
                    
                    
                    [dic setObject:@([rs intForColumn:@"duration_msec"] + recordTime) forKey:@"durationMsec"];
                    
                }

                    
                

            }
            
            [dic setObject:@([rs longLongIntForColumn:@"occur_unixtime"]) forKey:@"occurUnixtime"];
            
            [array addObject:dic];
            
        }
        
        completionCallback(array);
        
    }];
}

- (NSInteger)tpFromPostion:(NSInteger)postion
{
    CGFloat tp = (CGFloat)postion * (CGFloat)1000 / (CGFloat)256;
    NSInteger tpo = round(tp);
    
    
    return tpo;
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


#pragma mark ----------DFU
- (void)syn_ecgFirmWareUpdateWithCompletion:(CommonBlockCompletion)completionCallback
{
    self.upFirewareing = YES;
    
    [self startDownLoadFirmwareWithUrl:[SynECGLibSingleton sharedInstance].update_url completion:^(id obj) {
        if ([obj isEqualToString:@"成功"]) {
            
            NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
            [dic setObject:@"1" forKey:@"status"];
            [dic setObject:@"0" forKey:@"errorCode"];
            [dic setObject:@"固件下载成功" forKey:@"errorMessage"];
            [dic setObject:@"固件下载成功" forKey:@"message"];
            completionCallback(dic);
        }
        else if([obj isEqualToString:@"失败"])
        {
            self.upFirewareing = NO;
            NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
            [dic setObject:@"0" forKey:@"status"];
            [dic setObject:@"0" forKey:@"errorCode"];
            [dic setObject:@"固件下载失败" forKey:@"errorMessage"];
            [dic setObject:@"固件下载失败" forKey:@"message"];
            completionCallback(dic);
            
            [[NSNotificationCenter defaultCenter]  postNotificationName:@"d_c_u" object:nil];
            
            
        }
        else
        {
            self.upFirewareing = NO;
            NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
            [dic setObject:@"0" forKey:@"status"];
            [dic setObject:@"0" forKey:@"errorCode"];
            [dic setObject:@"蓝牙状态异常，无法升级" forKey:@"errorMessage"];
            [dic setObject:@"蓝牙状态异常，无法升级" forKey:@"message"];
            completionCallback(dic);
            
            [[NSNotificationCenter defaultCenter]  postNotificationName:@"d_c_u" object:nil];

        }
    }];
    
}

- (void)startDownLoadFirmwareWithUrl:(NSString *)url completion:(CommonBlockCompletion)completionCallback
{
    //开始升级
    
    BlockWeakSelf(self);
    
    [[RequestManager sharedInstance] downloadWithUrl:url sucessful:^(id obj) {
        
        if(weakSelf.typeNum == 0)
        {
            completionCallback(@"蓝牙状态异常，无法升级");
            
        }
        else
        {
            completionCallback(@"成功");
            [self startToUpdateDFUwithUrl:obj];
        }
        
    } failure:^(id obj) {
        
        completionCallback(@"失败");
        
    } downloadProgress:^(NSProgress *downloadProgress) {
        
        
        CGFloat pp = (CGFloat)downloadProgress.completedUnitCount / (CGFloat)downloadProgress.totalUnitCount;
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            if ([weakSelf.dfuDelegate respondsToSelector:@selector(syn_ecgOnUploadProgress:)]) {
                [weakSelf.dfuDelegate  syn_ecgOnUploadProgress:pp * 10];
            }
            
            
        });

    }];
    

}


- (void)startToUpdateDFUwithUrl:(NSURL *)url
{
    [self syn_ecgDisconnectDevice];
        
    BlockWeakSelf(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        self.filePath = [url path];
        DFUFirmware *selectedFirmware = [[DFUFirmware alloc] initWithUrlToZipFile:url];
        DFUServiceInitiator *initiator = [[DFUServiceInitiator alloc] initWithCentralManager: self.manager target:self.currPeripheral];
        initiator.enableUnsafeExperimentalButtonlessServiceInSecureDfu = YES;
        initiator.forceDfu = YES;
        initiator.packetReceiptNotificationParameter = 12;
        initiator.logger = self;
        initiator.delegate = self;
        initiator.progressDelegate = self;
        self->controller = [[initiator withFirmware:selectedFirmware] start];
        
        [weakSelf.dfuTimer setFireDate:[NSDate distantPast]];
        weakSelf.upateSucceed = YES;

        
        
    });

    
}

- (void)updateFirmWareError
{
    if (_upateSucceed == NO) {
        
        _dfuOutTime ++;
        
        if (_dfuOutTime >= 120) {
         
            if ([_dfuDelegate respondsToSelector:@selector(syn_ecgdidStateChangedTo:)])
            {
                [_dfuDelegate syn_ecgdidStateChangedTo:DFUStateAborted];
            }
            
            _upateSucceed = YES;
            _dfuOutTime = 0;
            [_dfuTimer setFireDate:[NSDate distantFuture]];
            [self clearUI];
        }
    }
    else
    {
        _dfuOutTime = 0;
        _upateSucceed = NO;
    }
}

#pragma mark - DFU Service delegate methods

- (void)logWith:(enum LogLevel)level message:(NSString * _Nonnull)message
{
    NSLog(@"%@",message);
}

- (void)dfuError:(enum DFUError)error didOccurWithMessage:(NSString * _Nonnull)message;
{
    
}

- (void)dfuStateDidChangeTo:(enum DFUState)state
{
    
    if ([_dfuDelegate respondsToSelector:@selector(syn_ecgdidStateChangedTo:)])
    {
        [_dfuDelegate syn_ecgdidStateChangedTo:state];
    }    
    switch (state) {
            
        case DFUStateConnecting:
            break;
        case DFUStateStarting:
            break;
        case DFUStateEnablingDfuMode:
            break;
        case DFUStateUploading:
            break;
        case DFUStateValidating:
            break;
        case DFUStateDisconnecting:
            break;
        case DFUStateCompleted:
            _upateSucceed = YES;
            _canUpdateFirmWare = NO;
            _needMandatoryUpdateFirmWare = NO;
             [_dfuTimer setFireDate:[NSDate distantFuture]];
            [self clearUI];
            break;
        case DFUStateAborted:
            _upateSucceed = YES;
            _nowfirmwareNumber = _firmwareNumber;
            [_dfuTimer setFireDate:[NSDate distantFuture]];
            [self clearUI];
            break;
    }
}

- (void)clearUI
{
    [controller abort];
    self.upFirewareing = NO;
    NSFileManager * fileManager = [[NSFileManager alloc]init];
    if ([fileManager fileExistsAtPath:self.filePath]) {
        [fileManager removeItemAtPath:self.filePath error:nil];
    }
    [self reSetManager];
    
}

- (void)dfuProgressDidChangeFor:(NSInteger)part outOf:(NSInteger)totalParts to:(NSInteger)progress currentSpeedBytesPerSecond:(double)currentSpeedBytesPerSecond avgSpeedBytesPerSecond:(double)avgSpeedBytesPerSecond;
{
    _upateSucceed = YES;
    if ([_dfuDelegate respondsToSelector:@selector(syn_ecgOnUploadProgress:)]) {
        [_dfuDelegate  syn_ecgOnUploadProgress:(10 + progress * 0.9)];
    }
}

-(void)registerObservers
{

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
}

- (void)appDidEnterBackground:(NSNotification *)_notification
{
    [SynECGLibSingleton sharedInstance].inBackground = YES;
}

- (void)appDidBecomeActive:(NSNotification *)_notification
{
    [SynECGLibSingleton sharedInstance].inBackground = NO;
}

- (void)appWillTerminate:(NSNotification *)_notification
{
}


-(void)unregisterObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}



#pragma mark------------ECGDecodeManagerDelegate

/**
 *  实时心率
 */
- (void)syn_ecgDecodeMessageOnHRValue:(NSDictionary *)hrValue
{    

    if (_dataSource && [_dataSource respondsToSelector:@selector(syn_ecgMessageOnHRValue:)])
    {
        [_dataSource syn_ecgMessageOnHRValue:hrValue];
    }
    
    if (self.sctDelegate && [self.sctDelegate respondsToSelector:@selector(syn_ecgHistoryBpm:)])
    {
        [self.sctDelegate syn_ecgHistoryBpm:hrValue];
    }
    
}

- (void)syn_ecgDecodeMessageOnRRValue:(NSArray *)rr
{
    if ( self.getHistory == YES) {
        
        
        if (self.sctDelegate && [self.sctDelegate respondsToSelector:@selector(syn_ecgHistoryAnn:)]) {
            
            [self.stagingArray addObjectsFromArray:rr];
            
            if (self.stagingArray.count > 10) {
                [self.sctDelegate syn_ecgHistoryAnn:self.stagingArray];
                
                [self.stagingArray removeObjectsInRange:NSMakeRange(0, self.stagingArray.count - 2)];
                
            }
            
        }
    }
}

/**
 *  ECG
 */
- (void)syn_ecgDecodeMessageOnECG:(NSData *)ecgArray
{
    
    if(_typeNum == 2 || _typeNum == 3)
    {
    
        if (_dataSource && [_dataSource respondsToSelector:@selector(syn_ecgMessageOnECG:)]) {
            [_dataSource syn_ecgMessageOnECG:ecgArray];
        }
    }
}

/*
 *能量
 */

- (void)syn_ecgDecodeMessageOnActivityValue:(NSDictionary *)activityValue;
{
    if(_typeNum == 2 || _typeNum == 3)
    {
        if (_dataSource && [_dataSource respondsToSelector:@selector(syn_ecgMessageOnActivityValue:)]) {
            [_dataSource syn_ecgMessageOnActivityValue:activityValue];
        }
    }
}


/**
 *  补数据进度
 */
- (void)syn_ecgDecodeMessageOnPercentage:(NSInteger)percentage andSpendTime:(NSInteger)st andV:(float)v andUnfinishTime:(NSInteger)ufTime{

    if(_typeNum == 9)
    {
        if (_dataSource && [_dataSource respondsToSelector:@selector(syn_ecgMessageOnPercentValue:andSpendTime:andV:andUnfinishTime:)]) {
            [_dataSource syn_ecgMessageOnPercentValue:percentage andSpendTime:st andV:v andUnfinishTime:ufTime];
        }
    }
}

/**
 *  hrv数据
 */
- (void)syn_ecgDecodeMessageOnHRVValue:(NSDictionary*)hrvValue
{
    if(_typeNum == 2 || _typeNum == 3)
    {
        if (_dataSource && [_dataSource respondsToSelector:@selector(syn_ecgMessageOnHRValue:)]) {
            [_dataSource syn_ecgMessageOnHRVValue:hrvValue];
        }
    }
}
/**
 *  呼吸数据
 */
- (void)syn_ecgDecodeMessageOnBreathValue:(NSDictionary *)breathValue
{
    if(_typeNum == 2 || _typeNum == 3)
    {
        if (_dataSource && [_dataSource respondsToSelector:@selector(syn_ecgMessageOnBreathValue:)])
        {
            [_dataSource syn_ecgMessageOnBreathValue:breathValue];
        }

    }
}
/**
 *  异常数据
 */
- (void)syn_ecgDecodeMessageOnEventValue:(NSDictionary *)eventValue
{
    if(_typeNum == 2 || _typeNum == 3)
    {
        if (_dataSource && [_dataSource respondsToSelector:@selector(syn_ecgMessageOnEventValue:)]) {
            [_dataSource syn_ecgMessageOnEventValue:eventValue];
        }
    }
}

- (void)tongzhi:(NSNotification *)text{

    if (_dataSource &&[_dataSource respondsToSelector:@selector(syn_ecgMessageOnAlert:)]) {
        
        [_dataSource syn_ecgMessageOnAlert:text.userInfo];
    }
    
}



- (void)getNowInternetNumWithCompletion:(CommonBlockCompletion)completionCallback
{
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        NSString *numQuery1  = [NSString stringWithFormat:@"select count(*) from %@",WATER_UPLOAD_TABLE];
        NSString *numQuery2  = [NSString stringWithFormat:@"select count(*) from %@",ALARM_UPLOAD_TABLE];
        NSString *numQuery3  = [NSString stringWithFormat:@"select count(*) from %@",BREATH_UPLOAD_TABLE];
        NSString *numQuery4  = [NSString stringWithFormat:@"select count(*) from %@",ENERGY_UPLOAD_TABLE];
        NSString *numQuery5  = [NSString stringWithFormat:@"select count(*) from %@",HR_UPLOAD_TABLE];
        NSString *numQuery7  = [NSString stringWithFormat:@"select count(*) from %@",RR_UPLOAD_TABLE];
        NSString *numQuery8  = [NSString stringWithFormat:@"select count(*) from %@",EVENT_UPLOAD_TABLE];
        NSString *numQuery9  = [NSString stringWithFormat:@"select count(*) from %@",STATUS_TABLE];
        
        int a =  [db intForQuery:numQuery1];
        int b =  [db intForQuery:numQuery2];
        int c =  [db intForQuery:numQuery3];
        int d =  [db intForQuery:numQuery4];
        int e =  [db intForQuery:numQuery5];
        int g =  [db intForQuery:numQuery7];
        int h =  [db intForQuery:numQuery8];
        int i =  [db intForQuery:numQuery9];
        
        
        completionCallback([NSString stringWithFormat:@"%d,%d,%d,%d,%d,%d,%d,%d",a,b,c,d,e,g,h,i]);
    }];

    
    
}


- (void)getRRIDataFromTime:(NSInteger)startTime WithCompletion:(CommonBlockCompletion)completionCallback
{
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        
        NSString *numQuery1  = [NSString stringWithFormat:@"select * from %@ where data > %@",RR_TABLE,@(startTime)];
        
        NSMutableArray *annArray = [NSMutableArray new];
         FMResultSet *rs1 = [db executeQuery:numQuery1];
        while ([rs1 next])
        {

        
            [annArray addObject:@([rs1 longLongIntForColumn:@"data"])];
            
        }
        
     
        NSMutableArray *pointArray = [[NSMutableArray alloc]init];
        if(annArray.count >= 3)
        {
            for (int i = 0; i < annArray.count - 1; i++) {
                
                NSInteger x1 = [annArray[i] integerValue];
                NSInteger x2 = [annArray[i + 1] integerValue];
            
                
                CGFloat x = x2 - x1;
               
               [pointArray addObject:@(x)];
                
                completionCallback(pointArray);
            }
        }
        else
        {
            completionCallback(pointArray);
        }

     
        
    }];
}


#pragma mark------use for guanxinliliao

/**
 连接设备 测试专用

 @param message 设备信息
 */
- (void)syn_ecgScanSearchDeviceWithMessage:(NSDictionary *)message
{
    [SynECGLibSingleton sharedInstance].mac = [message objectForKey:@"mac"];
    [SynECGLibSingleton sharedInstance].deviceId = [message objectForKey:@"deviceId"];
    [SynECGLibSingleton sharedInstance].deviceTypeId = [message objectForKey:@"deviceTypeId"];
    [SynECGLibSingleton sharedInstance].deviceName = [message objectForKey:@"deviceName"];
    self.deviceName = [SynECGLibSingleton sharedInstance].deviceName;
    
    
    [SynECGBlueManager sharedInstance].nowfirmwareNumber = @"";
    [SynECGBlueManager sharedInstance].canUpdateFirmWare = NO;
    
    [_manager stopScan];
    _needConection = YES;
    _needSearch = YES;
    [self.manager scanForPeripheralsWithServices:nil options:nil];
}


/**
 开始测量 测试专用
 */
- (void)syn_ecgStartMonitoringECGWithCompletion:(CommonBlockCompletion)completionCallback
{
    
    if (_typeNum == 0) {
        
        completionCallback(@"设备未连接");
    }
//    else if(_needMandatoryUpdateFirmWare == YES)
//    {
//        completionCallback(@"设备需要强制更新");
//    }
    else
    {
    
    
        [queue inDatabase:^(FMDatabase *db) {
            
            [self changeUseInfoForTable:SYN_USERINFO_TABLE mac:[SynECGLibSingleton sharedInstance].mac deviceId:[SynECGLibSingleton sharedInstance].deviceId deviceTypeId: [SynECGLibSingleton sharedInstance].deviceTypeId deviceName:[SynECGLibSingleton sharedInstance].deviceName inDb:db];
        }];
        
        [self startMonitoringECG];
        completionCallback(@"开始测量");
    }
}

/**
 停止测量 测试专用
 */
- (void)syn_ecgEndMonitoringECG
{
    
    if (self.typeNum == 9) {
        
    }
    else
    {
        [queue inDatabase:^(FMDatabase *db) {
            
            [self changeUseInfoForTable:SYN_USERINFO_TABLE mac:@"" deviceId:@"" deviceTypeId:@"" deviceName:@"" inDb:db];
        }];
    }
    [self endMonitoringECG];
}

- (void)syn_ecgLoginOut
{
    [_timer setFireDate:[NSDate distantFuture]];
    [_speedTimer setFireDate:[NSDate distantFuture]];
    [_recordTimer setFireDate:[NSDate distantFuture]];
    self.lastLength = 0;
    self.alreadyByte = 0;
    _needReLink = NO;
    _writeMessage = NO;
    _canUpdateFirmWare = NO;
    _needMandatoryUpdateFirmWare = NO;
    _startTime = 0;
    _retryNum = 0;
    [SynECGLibSingleton sharedInstance].record_id = @"";
    [SynECGLibSingleton sharedInstance].startMonitorTime = 0;
    [SynECGLibSingleton sharedInstance].mac = @"";
    [SynECGLibSingleton sharedInstance].deviceId = @"";
    [SynECGLibSingleton sharedInstance].deviceTypeId = @"";
    [SynECGLibSingleton sharedInstance].deviceName = @"";
    
    if( _manager && _currPeripheral)
    {
        if (_iSNewWoking) {
            [self stopOldTask];
            
            BlockWeakSelf(self);
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                
                [weakSelf.manager cancelPeripheralConnection:weakSelf.currPeripheral];
            });
        }
        else
        {
            [_manager cancelPeripheralConnection:_currPeripheral];
        }
    }
    else
    {
        [_manager stopScan];
    }
    
    [queue inDatabase:^(FMDatabase *db) {
        
        [self changeUseInfoForTable:SYN_USERINFO_TABLE mac:@"" deviceId:@"" deviceTypeId:@"" deviceName:@"" inDb:db];
    }];
    
    
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    [user setObject:@"" forKey:@"syn_recordId"];
    [user setObject:@(0) forKey:@"syn_startTime"];
    [user setObject:@(0) forKey:@"iSNewWoking"];
        
    [SynECGLibSingleton sharedInstance].loginIn = NO;
}



- (void)changeUseInfoForTable:(NSString *)tabele mac:(NSString *)mac deviceId:(NSString *)deviceId deviceTypeId:(NSString *)deviceTypeId deviceName:(NSString *)deviceName inDb:(FMDatabase *)dataBase
{
    NSString *updateSql = [NSString stringWithFormat:
                           @"UPDATE %@ SET mac = '%@', deviceId = '%@',deviceTypeId = '%@',deviceName = '%@' WHERE id = '1'",tabele,mac,deviceId,deviceTypeId,deviceName];
    [dataBase executeUpdate:updateSql];
    
}

#pragma maark -------------- record list

- (void)checkRecordlist
{
    
    if ([SynECGLibSingleton sharedInstance].loginIn == YES && [RequestManager isNetworkReachable] == YES) {
     
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            //取数量
            NSString *numQuery  = [NSString stringWithFormat:@"select count(*) from %@",SYN_RECORD];
            NSUInteger num = [db intForQuery:numQuery];
            
            if (num > 0) {
                
                //查询一条
                NSString *query = [NSString stringWithFormat:@"select * from %@ ORDER by id limit 0,1",SYN_RECORD];
                FMResultSet *rs = [db executeQuery:query];
                NSString *nowRecord = [[NSString alloc]init];
                
                while ([rs next]) {
                    
                    
                    nowRecord = [rs stringForColumn:@"recordId"];
                    
                }
                
                if (nowRecord.length > 0) {
                    [[HeartBeatModel sharedInstance] searchFromRecord:nowRecord In:db];
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [[HeartBeatModel sharedInstance] deleteMessageByRecord:@""];
                    });
                }
                
            }
        }];
    }
}
- (void)syn_getRRiWithLength:(NSInteger)length withStart:(NSInteger)startNum
{
    self.getHistory = NO;
    self.getLocation = startNum;
    self.stepLength = length;
    [self.stagingArray removeAllObjects];
    
    [self.scatterTimer setFireDate:[NSDate distantPast]];
    
}

- (void)syn_closeRRi
{
    self.getHistory = NO;
    [self.scatterTimer setFireDate:[NSDate distantFuture]];
}


- (void)getRRiWithLength:(NSInteger)length
{
    BlockWeakSelf(self);
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        

        NSString *query1 = [NSString stringWithFormat:@"select * from %@ where data >= %@ limit 0,%@",RR_TABLE,@(self.getLocation),@(weakSelf.stepLength)];
        FMResultSet *rs1 = [db executeQuery:query1];
        while ([rs1 next]) {
                [weakSelf.stagingArray addObject:@([rs1 intForColumn:@"data"])];
            }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (weakSelf.sctDelegate && [weakSelf.sctDelegate respondsToSelector:@selector(syn_ecgHistoryAnn:)]) {
                
                [weakSelf.sctDelegate syn_ecgHistoryAnn:weakSelf.stagingArray];
            }
            
            if (self.stagingArray.count >= weakSelf.stepLength) {
                
                [self.stagingArray removeObjectsInRange:NSMakeRange(0, self.stagingArray.count - 2)];
            }
            else
            {
                if(self.stagingArray.count >= 3)
                {
                    [self.stagingArray removeObjectsInRange:NSMakeRange(0, self.stagingArray.count - 2)];
                }
                [weakSelf.scatterTimer setFireDate:[NSDate distantFuture]];
                weakSelf.getHistory = YES;
            }
            
            weakSelf.getLocation = [self.stagingArray.lastObject intValue];
        });
    }];
    
}


@end


