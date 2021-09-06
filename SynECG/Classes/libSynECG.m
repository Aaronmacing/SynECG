///
//  libSynECG.m
//  libSynECG
//
//  Created by LiangXiaobin on 16/6/29.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import "libSynECG.h"
#import "RequestManager.h"
#import "SynECGLibSingleton.h"
#import "SynConstant.h"
#import <UIKit/UIKit.h>
#import "SynECGUtils.h"
#import "SDBManager.h"
#import "ZYFMDB.h"
#import "SynECGBlueManager.h"
#import "SynWaterUploadManager.h"
#import "SynAlarmUploadManager.h"
#import "ECGBreathUpload.h"
#import "ECGEnergryManager.h"
#import "ECGHRManager.h"
#import "ECGRRManager.h"
#import "HADeviceStatusManager.h"
#import "HAEventManager.h"
#import "SportDataManager.h"


#define APPTYPE @"HEALTH"

@interface libSynECG ()
{
    FMDatabaseQueue *queue;
}
@property(nonatomic,strong)NSString *oldSId;
@property (nonatomic,strong) NSTimer *timer;
@end

@implementation libSynECG


+(instancetype)sharedInstance
{
    static libSynECG * sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[libSynECG alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        queue = [SDBManager defaultDBManager].queue;
        _oldSId = [[NSString alloc]init];
        [self updateRealmConfig];
        [self selectFromOldId];
        
    }
    return self;
}


- (void)selectFromOldId
{
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        self.oldSId = [self queryTable:SYN_USERINFO_TABLE Column:@"targetId" inDb:db];
  
    }];
    
}



- (void)updateRealmConfig
{
     NSString * docp = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    NSString *totalPath1 = [docp stringByAppendingString:[NSString stringWithFormat:@"/synCache"]];
    NSString *totalPath2 = [docp stringByAppendingString:[NSString stringWithFormat:@"/syn"]];
    NSString *totalPath3 = [docp stringByAppendingString:[NSString stringWithFormat:@"/synSport"]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager isExecutableFileAtPath:totalPath3])
    {
        [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey: NSFileProtectionNone} ofItemAtPath:totalPath1 error:nil];
        [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey: NSFileProtectionNone} ofItemAtPath:totalPath2 error:nil];
        [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey: NSFileProtectionNone} ofItemAtPath:totalPath3 error:nil];
    }
    else
    {
        NSError *error = nil;
        if (![fileManager isExecutableFileAtPath:totalPath1])
        {
            [fileManager createDirectoryAtPath:totalPath1 withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        if (![fileManager isExecutableFileAtPath:totalPath3])
        {
            [fileManager createDirectoryAtPath:totalPath3 withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        
        //解除这个目录的保护
        
        [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey: NSFileProtectionNone} ofItemAtPath:totalPath1 error:nil];
        
        [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey: NSFileProtectionNone} ofItemAtPath:totalPath2 error:nil];
        [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey: NSFileProtectionNone} ofItemAtPath:totalPath3 error:nil];
        
        ZYFMDB *key =  [[ZYFMDB alloc]init];
        
        //    if (!a) {
        
        [key creatTableWithName:HR_TABLE withArguments:@"id integer PRIMARY KEY AUTOINCREMENT, path text, userId text,targetId text, recordId text, keyNo integer, start integer, end integer"];
        //    }
        //    if (!b) {
        [key creatTableWithName:HR_UPLOAD_TABLE withArguments:@"id integer PRIMARY KEY AUTOINCREMENT, path text, userId text,targetId text, recordId text, keyNo integer, start integer, end integer"];
        //    }
        
        //    if (!c) {
        [key creatTableWithName:TOTAL_TABLE withArguments:@"id integer PRIMARY KEY AUTOINCREMENT, hr integer, hrv integer,ecg integer, event integer, ann integer, act integer, rsp integer,ecgUpload integer,rrUpload integer,recordId text, a_np integer, a_up integer, a_r text"];
        //    }
        
        //    if (!d) {
        
        [key creatTableWithName:RR_TABLE withArguments:@"id integer PRIMARY KEY AUTOINCREMENT, user_id text,target_id text, record_id text, keyNo integer, data integer, ann text, avergeHR integer,singleHR integer, position integer, amp integer, extra text"];
        //    }
        
        //    if (!e) {
        
        [key creatTableWithName:RR_UPLOAD_TABLE withArguments:@"id integer PRIMARY KEY AUTOINCREMENT, user_id text,target_id text, record_id text, keyNo integer, occur_datetime text, rrpeak_values blob, bpmVo blob"];
        //    }
        
        //    if (!f) {
        
        [key creatTableWithName:BREATH_TABLE withArguments:@"id integer PRIMARY KEY AUTOINCREMENT, user_id text,target_id text, record_id text, keyNo integer, occur_datetime text, value text"];
        //    }
        //    if(!g)
        //    {
        [key creatTableWithName:BREATH_UPLOAD_TABLE withArguments:@"id integer PRIMARY KEY AUTOINCREMENT,rsp_value text, user_id text,target_id text, record_id text, keyNo integer, occur_datetime text, end_datetime text"];
        //    }
        //    if (!h) {
        [key creatTableWithName:ENERGY_TABLE withArguments:@"id integer PRIMARY KEY AUTOINCREMENT, user_id text, record_id text, keyNo integer,activity_type text, kcal integer, step integer"];
        //    }
        
        //    if(!i)
        //    {
        [key creatTableWithName:ENERGY_UPLOAD_TABLE withArguments:@"id integer PRIMARY KEY AUTOINCREMENT, user_id text, paras string, urlstr string"];
        //    }
        
        //    if(!m)
        //    {
        
        [key creatTableWithName:EVENT_TABLE withArguments:@"id integer PRIMARY KEY AUTOINCREMENT, user_id text,target_id text, record_id text,duration integer,occur_unixtime integer,event_type text,eventData text,position integer,outType integer"];
        //    }
        //    if (!n) {
        
        [key creatTableWithName:EVENT_UPLOAD_TABLE withArguments:@"id integer PRIMARY KEY AUTOINCREMENT, user_id text,target_id text, record_id text,duration integer,occur_unixtime integer,event_type text,eventData text,position integer"];
        //    }
        //    if (!o) {
        
        [key creatTableWithName:STATUS_TABLE withArguments:@"id integer PRIMARY KEY AUTOINCREMENT, deviceStatus text,startTime text, recordId text,deviceId text,oldDeviceStatus text,occurUnixTime integer, targetId text,dataIndexVo text"];
        //    }
        
        //    if (!p) {
        
        [key creatTableWithName:ALARM_TABLE withArguments:@"id integer PRIMARY KEY AUTOINCREMENT, target_id text,user_id text, record_id text,alarm_id text,start_alarm_id text,occur_unixtime integer, update_unixtime integer, alert_type text,alert_category text,alarm_level integer,alarm_flag integer"];
        //    }
        //    if (!q) {
        
        
        [key creatTableWithName:ALARM_UPLOAD_TABLE withArguments:@"id integer PRIMARY KEY AUTOINCREMENT, target_id text,user_id text, record_id text,alarm_id text,start_alarm_id text,occur_unixtime integer, alert_type text,alert_category text,alarm_level integer,alarm_flag integer"];
        //    }
        //    if (!r) {
        
        [key creatTableWithName:WATER_TABLE withArguments:@"id integer PRIMARY KEY AUTOINCREMENT, target_id text,user_id text, record_id text,alert_mark_id text,alert_id text,alert_mark_level integer,seq_no integer,duration_msec integer,alert_mark_category text,occur_unixtime integer,end_unixtime integer,alert_flag integer,alert_type text"];
        
        //    }
        
        //    if (!s) {
        
        [key creatTableWithName:WATER_UPLOAD_TABLE withArguments:@"id integer PRIMARY KEY AUTOINCREMENT, target_id text,user_id text, record_id text,alert_mark_id text,alert_id text,alert_mark_level integer,seq_no integer,duration_msec integer,alert_mark_category text,alert_occur_unixtime integer"];
        //    }
        
        //    if (!t) {
        
        [key creatTableWithName:SYN_USERINFO_TABLE withArguments:@"id integer PRIMARY KEY AUTOINCREMENT, userId text,targetId text, weight text,birthday text,bloodType text,height text,sex text,mac text,deviceId text, deviceTypeId text, deviceName text"];
        //    }
        
        //    if (!u) {
        [key creatTableWithName:SYN_NUM withArguments:@"id integer PRIMARY KEY AUTOINCREMENT, a integer,b integer, c integer,d integer,e integer,f integer,g integer,h integer,time text, status integer"];
        //    }
        
        
        [key creatTableWithName:SYN_RECORD withArguments:@"id integer PRIMARY KEY AUTOINCREMENT,recordId text"];
        
        
        [key creatTableWithName:SPORT_UP_TABLE withArguments:@"id integer PRIMARY KEY AUTOINCREMENT,userId text, fileName string,params string"];
        
        
        
        
        
        
        
        
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            //occur_unixtime
            
            [db executeUpdate:[NSString stringWithFormat:@"create index idx0 on %@(occur_unixtime)",EVENT_TABLE]];
            [db executeUpdate:[NSString stringWithFormat:@"create index idx1 on %@(target_id)",EVENT_UPLOAD_TABLE]];
            [db executeUpdate:[NSString stringWithFormat:@"create index idx2 on %@(occur_unixtime)",EVENT_TABLE]];
            
            [db executeUpdate:[NSString stringWithFormat:@"create index idx3 on %@(targetId)",STATUS_TABLE]];
            
            [db executeUpdate:[NSString stringWithFormat:@"create index idx4 on %@(keyNo)",RR_TABLE]];
            [db executeUpdate:[NSString stringWithFormat:@"create index idx5 on %@(target_id)",RR_UPLOAD_TABLE]];
            
            [db executeUpdate:[NSString stringWithFormat:@"create index idx7 on %@(targetId)",HR_UPLOAD_TABLE]];
            [db executeUpdate:[NSString stringWithFormat:@"create index idx8 on %@(user_id)",ENERGY_UPLOAD_TABLE]];
            [db executeUpdate:[NSString stringWithFormat:@"create index idx9 on %@(target_id)",BREATH_UPLOAD_TABLE]];
            [db executeUpdate:[NSString stringWithFormat:@"create index idx10 on %@(target_id)",ALARM_UPLOAD_TABLE]];
            [db executeUpdate:[NSString stringWithFormat:@"create index idx11 on %@(target_id)",WATER_UPLOAD_TABLE]];
            
            [db executeUpdate:[NSString stringWithFormat:@"create index idx12 on %@(alert_mark_category)",WATER_TABLE]];
            
            [db executeUpdate:[NSString stringWithFormat:@"create index idx13 on %@(data)",RR_TABLE]];
            
            //alert_type = '%@' and alarm_flag
            [db executeUpdate:[NSString stringWithFormat:@"create index idx14 on %@(alert_type)",ALARM_TABLE]];
            [db executeUpdate:[NSString stringWithFormat:@"create index idx15 on %@(alarm_flag)",ALARM_TABLE]];
            [db executeUpdate:[NSString stringWithFormat:@"create index idx16 on %@(alert_type,alarm_flag)",ALARM_TABLE]];
            [db executeUpdate:[NSString stringWithFormat:@"create index idx17 on %@(recordId)",TOTAL_TABLE]];
            [db executeUpdate:[NSString stringWithFormat:@"create index idx18 on %@(recordId)",SYN_RECORD]];
            
        }];
    }
}

- (void)getRecordId:(CommonBlockCompletion)completionCallback
{
    //编写SQL查询语句
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
     
        NSString *query = [NSString stringWithFormat:@"select * from %@",TOTAL_TABLE];
        NSString *rd = [[NSString alloc]init];
        FMResultSet *rs = [db executeQuery:query];
        while ([rs next]) {
            rd = [rs stringForColumn:@"recordId"];
        }
        completionCallback(rd);
       
    }];
}

- (void)syn_ecgWriteinWith:(NSDictionary *)params completion:(CommonBlockCompletion)completionCallback
{
    
    if ([SynECGLibSingleton sharedInstance].loginIn == YES) {
        
        [SynECGLibSingleton sharedInstance].token = params[@"token"];
        [SynECGLibSingleton sharedInstance].baseurl = params[@"baseURL"];
        [SynECGLibSingleton sharedInstance].target_id = params[@"targetId"];
        [SynECGLibSingleton sharedInstance].user_id = params[@"userId"];
        [SynECGLibSingleton sharedInstance].userName = params[@"targetInfo"][@"name"];
        completionCallback(@"写入成功");
        
        [self judgeUserWithTargetId:[SynECGLibSingleton sharedInstance].target_id];
        [self savePersonInfoWithInfo:params[@"targetInfo"]];
    }
    else
    {
        [SynECGLibSingleton sharedInstance].loginIn = YES;
        
        [SynECGLibSingleton sharedInstance].token = params[@"token"];
        [SynECGLibSingleton sharedInstance].baseurl = params[@"baseURL"];
        [SynECGLibSingleton sharedInstance].target_id = params[@"targetId"];
        [SynECGLibSingleton sharedInstance].user_id = params[@"userId"];
        [SynECGLibSingleton sharedInstance].userName = params[@"targetInfo"][@"name"];
        completionCallback(@"写入成功");
        
        [self judgeUserWithTargetId:[SynECGLibSingleton sharedInstance].target_id];
        [self savePersonInfoWithInfo:params[@"targetInfo"]];
        [self uploadLastMessage];
    }

}

- (void)syn_ecgLoginWith:(NSDictionary *)params completion:(CommonBlockCompletion)completionCallback
{
 
    [SynECGLibSingleton sharedInstance].record_id = @"";
//    NSString *ip = [SynECGUtils getIPAddress];
//    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
//    NSString *severIp = [user objectForKey:@"severIp"];
//    NSString *laserTime = [user objectForKey:@"severIpTime"];
//    if (!severIp) {
//        severIp = @"";
//        laserTime = @"";
//    }
//    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
//    CFShow((__bridge CFTypeRef)(infoDictionary));
//    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
//    NSString *appVer = [NSString stringWithFormat:@"v%@",app_Version];
//  
//    NSDictionary *params1 = @{@"phoneIp":ip,
//                             @"serverIp":severIp,
//                             @"lastTime":laserTime,
//                             @"appVer":appVer,
//                             @"appType":APPTYPE};
    
    [SynECGLibSingleton sharedInstance].token = params[@"token"];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    [dic setObject:[NSString stringWithFormat:@"%@%@",params[@"appId"],params[@"userId"]] forKey:@"userId"];
    
//#if DEBUG
//    [SynECGLibSingleton sharedInstance].baseurl = @"https://cloud.synwing.com:8443/health_app_v2/";
//#else
    [SynECGLibSingleton sharedInstance].baseurl = @"https://app-access.synwing.com/health_app_v2/";
//#endif
    
    
    
//    [[RequestManager sharedInstance]postParameters:params1 Url:GET_HTTP_BASE sucessful:^(id obj) {
    
//        [SynECGLibSingleton sharedInstance].baseurl = [NSString stringWithFormat:@"%@",  [[obj objectForKey:@"baseUrlList"] firstObject]];
        [[RequestManager sharedInstance]postParameters:dic Url:LOGIN_URL sucessful:^(id obj) {
            [SynECGLibSingleton sharedInstance].target_id = obj[@"targetInfo"][@"targetId"];
            [SynECGLibSingleton sharedInstance].userName = obj[@"targetInfo"][@"name"];
            
            [SynECGLibSingleton sharedInstance].loginIn = YES;
            [self judgeUserWithTargetId:[SynECGLibSingleton sharedInstance].target_id];
            
            [SynECGLibSingleton sharedInstance].user_id = obj[@"targetInfo"][@"userId"];
            [self savePersonInfoWithInfo:obj[@"targetInfo"]];
            [self uploadLastMessage];
            completionCallback(obj[@"result"]);
        } failure:^(id obj) {
            completionCallback(obj[@"result"]);
        }];
        
//    } failure:^(id obj) {
    
//    }];
}

- (void)uploadLastMessage
{
    
    _timer = [NSTimer  timerWithTimeInterval:300 target:self selector:@selector(upLoadLocalMessage) userInfo:nil repeats:YES];
    [ _timer setFireDate:[NSDate distantPast]];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    
}

- (void)upLoadLocalMessage
{
    if ([SynECGBlueManager sharedInstance].typeNum == 0 || [SynECGBlueManager sharedInstance].typeNum == 1)
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
}








- (void)judgeUserWithTargetId:(NSString *)targetId
{
    if (targetId.length > 0) {
  
            if ([self.oldSId isEqualToString:targetId]) {
                
            }
            else
            {
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
            }
    }

    
    
}


- (void)syn_ecgGetInfoWith:(NSDictionary *)params completion:(CommonBlockCompletion)completionCallback
{
    [self savePersonInfoWithInfo:params];
    [SynECGLibSingleton sharedInstance].userName = params[@"name"];
}

- (void)savePersonInfoWithInfo:(NSDictionary *)dic
{
    
    [[SynECGBlueManager sharedInstance].recordTimer setFireDate:[NSDate distantPast]];
 
    [queue inDatabase:^(FMDatabase *db) {
    
        NSString *query = [NSString stringWithFormat:@"select * from %@",SYN_USERINFO_TABLE];
        FMResultSet *rs = [db executeQuery:query];
        int num = 0;
        while ([rs next]) {
            num++;
        }
        if (num > 0) {
            if ([dic.allKeys containsObject:@"birthday"]) {
                
                [self changeTable:SYN_USERINFO_TABLE Column:@"birthday" value:dic[@"birthday"] inDb:db];
            }
            if ([dic.allKeys containsObject:@"bloodType"]) {
                [self changeTable:SYN_USERINFO_TABLE Column:@"bloodType" value:dic[@"bloodType"] inDb:db];
            }
            if ([dic.allKeys containsObject:@"height"]) {
                [self changeTable:SYN_USERINFO_TABLE Column:@"height" value:dic[@"height"] inDb:db];
            }
            if ([dic.allKeys containsObject:@"sex"]) {
                [self changeTable:SYN_USERINFO_TABLE Column:@"sex" value:dic[@"sex"] inDb:db];
            }
            if ([dic.allKeys containsObject:@"userId"]) {
                [self changeTable:SYN_USERINFO_TABLE Column:@"userId" value:dic[@"userId"] inDb:db];
            }
            else
            {
                [self changeTable:SYN_USERINFO_TABLE Column:@"userId" value:[SynECGLibSingleton sharedInstance].user_id inDb:db];
            }
            
            
            if ([dic.allKeys containsObject:@"targetId"]) {
                
                [self changeTable:SYN_USERINFO_TABLE Column:@"targetId" value:dic[@"targetId"] inDb:db];
            }
            else
            {
                [self changeTable:SYN_USERINFO_TABLE Column:@"targetId" value:[SynECGLibSingleton sharedInstance].target_id inDb:db];
            }
            
            
            
            if ([dic.allKeys containsObject:@"weight"]) {
                
                [self changeTable:SYN_USERINFO_TABLE Column:@"weight" value:dic[@"weight"] inDb:db];
            }
            if ([dic.allKeys containsObject:@"indicateList" ]) {
                NSArray *array = dic[@"indicateList"];
                if (array.count > 0) {
                    NSArray *array1 = [array[0] objectForKey:@"deviceList"];
                    if (array1.count > 0) {
                        
                        [self changeTable:SYN_USERINFO_TABLE Column:@"mac" value:[array1[0] objectForKey:@"mac"] inDb:db];
                        [self changeTable:SYN_USERINFO_TABLE Column:@"deviceId" value:[array1[0] objectForKey:@"deviceId"] inDb:db];
                        [self changeTable:SYN_USERINFO_TABLE Column:@"deviceTypeId" value:[array1[0] objectForKey:@"deviceTypeId"] inDb:db];
                    }
                }
                else
                {
                    [self changeTable:SYN_USERINFO_TABLE Column:@"mac" value:@"" inDb:db];
                    [self changeTable:SYN_USERINFO_TABLE Column:@"deviceId" value:@"" inDb:db];
                    [self changeTable:SYN_USERINFO_TABLE Column:@"deviceTypeId" value:@"" inDb:db];
                    [self changeTable:SYN_USERINFO_TABLE Column:@"deviceName" value:@"" inDb:db];
                }
            }
            
        }
        else
        {
            NSString *birthday = [[NSString alloc]init];
            NSString *bloodType = [[NSString alloc]init];
            NSString *height = [[NSString alloc]init];
            NSString *sex = [[NSString alloc]init];
            NSString *userId = [[NSString alloc]init];
            NSString *targetId = [[NSString alloc]init];
            NSString *weight = [[NSString alloc]init];
            NSString *mac = [[NSString alloc]init];
            NSString *deviceId = [[NSString alloc]init];
            NSString *deviceTypeId = [[NSString alloc]init];
            NSString *deviceName = [[NSString alloc]init];
            
            if ([dic.allKeys containsObject:@"birthday"]) {
                
                birthday = dic[@"birthday"];
            }
            if ([dic.allKeys containsObject:@"bloodType"]) {
                
                bloodType = dic[@"bloodType"];
            }
            if ([dic.allKeys containsObject:@"height"]) {
                
                height = dic[@"height"];
            }
            if ([dic.allKeys containsObject:@"sex"]) {
                
                sex = dic[@"sex"];
            }
            if ([dic.allKeys containsObject:@"userId"]) {
                
                userId = dic[@"userId"];
            }
            if ([dic.allKeys containsObject:@"targetId"]) {
                
                targetId = dic[@"targetId"];
            }
            if ([dic.allKeys containsObject:@"weight"]) {
                
                weight = dic[@"weight"];
            }
            if ([dic.allKeys containsObject:@"indicateList" ]) {
                NSArray *array = dic[@"indicateList"];
                if (array.count > 0) {
                    NSArray *array1 = [array[0] objectForKey:@"deviceList"];
                    if (array1.count >0) {
                        mac = [array1[0] objectForKey:@"mac"];
                        deviceId = [array1[0] objectForKey:@"deviceId"];
                        deviceTypeId = [array1[0] objectForKey:@"deviceTypeId"];
                    }
                }
            }
            
            [db executeUpdate:@"INSERT INTO userInfo_one (birthday, bloodType, height, sex, userId, targetId,weight,mac,deviceId,deviceTypeId,deviceName) VALUES (?,?,?,?,?,?,?,?,?,?,?);",birthday,bloodType,height,sex,userId,targetId,weight,mac,deviceId,deviceTypeId,deviceName];
            
        }

        
        
        
    }];
    
    
    
    
}


- (void)syn_ecgLogout;
{
    /**
     *  执行断开蓝牙的任务
     */
    [SynECGLibSingleton sharedInstance].record_id = @"";
    [SynECGLibSingleton sharedInstance].filePathName = @"";
   
}

 - (void)syn_ecgAddDeviceWith:(NSDictionary *)params completion:(CommonBlockCompletion)completionCallback
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    [dic setObject:[SynECGLibSingleton sharedInstance].target_id forKey:@"targetId"];
    [dic setObject:@"I000003" forKey:@"indicateId"];
    [dic setObject:@[params] forKey:@"deviceList"];
    
    [[RequestManager sharedInstance]postParameters:dic Url:INDICATE_BIND_URL sucessful:^(id obj) {
        completionCallback(obj);
        NSArray *array = obj[@"indicateList"];
        if (array.count > 0) {
            NSArray *array1 = [array[0] objectForKey:@"deviceList"];
            
            [SynECGLibSingleton sharedInstance].mac = [array1[0] objectForKey:@"mac"];
            [SynECGBlueManager sharedInstance].nowfirmwareNumber = @"";
            [SynECGBlueManager sharedInstance].canUpdateFirmWare = NO;
            
            [SynECGLibSingleton sharedInstance].deviceId = [array1[0] objectForKey:@"deviceId"];
            [SynECGLibSingleton sharedInstance].deviceTypeId = [array1[0] objectForKey:@"deviceTypeId"];

            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SynAddDeve" object:nil];
            
            [self->queue inDatabase:^(FMDatabase *db) {
               
                [self changeUseInfoForTable:SYN_USERINFO_TABLE mac:[array1[0] objectForKey:@"mac"] deviceId:[array1[0] objectForKey:@"deviceId"] deviceTypeId: [array1[0] objectForKey:@"deviceTypeId"] inDb:db];
            }];
        }
       
    } failure:^(id obj) {
        completionCallback(obj[@"result"]);
    }];
}


- (void)syn_ecgChangeDeviceWith:(NSDictionary *)params completion:(CommonBlockCompletion)completionCallback
{
     [queue inDatabase:^(FMDatabase *db) {
         NSString *deviceId = [self queryTable:SYN_USERINFO_TABLE Column:@"deviceId" inDb:db];

         if (deviceId.length == 0) {
        
             NSMutableDictionary *result = [[NSMutableDictionary alloc]init];
             NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
             [dic setObject:@"0" forKey:@"status"];
             [dic setObject:@"0" forKey:@"errorCode"];
             [dic setObject:@"没有添加设备" forKey:@"errorMessage"];
             [dic setObject:@"没有添加设备" forKey:@"message"];
             [result setObject:dic forKey:@"result"];
             completionCallback(result);
         }
         else
         {
             NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
             NSDictionary * subDic = @{@"deviceMacAdd":[params objectForKey:@"mac"],@"deviceVendor":[params objectForKey:@"vendor"]};
             [dic setObject:[SynECGLibSingleton sharedInstance].target_id forKey:@"targetId"];
             [dic setObject:@"I000003" forKey:@"indicateId"];
             [dic setObject:subDic forKey:@"deviceVo"];
             [dic setObject:deviceId forKey:@"oldDeviceId"];
        
            [[RequestManager sharedInstance]postParameters:dic Url:INDICATE_CHANGE_URL sucessful:^(id obj) {
            
                   completionCallback(obj);
                
                [SynECGBlueManager sharedInstance].nowfirmwareNumber = @"";
                [SynECGBlueManager sharedInstance].canUpdateFirmWare = NO;
                [SynECGLibSingleton sharedInstance].mac = obj[@"deviceVo"][@"mac"];
                [SynECGLibSingleton sharedInstance].deviceId = obj[@"deviceVo"][@"deviceId"];
                [SynECGLibSingleton sharedInstance].deviceTypeId = obj[@"deviceVo"][@"deviceTypeId"];
                
                
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SynChange" object:nil];
            
                   [self changeUseInfoForTable:SYN_USERINFO_TABLE mac:obj[@"deviceVo"][@"mac"] deviceId:obj[@"deviceVo"][@"deviceId"] deviceTypeId:obj[@"deviceVo"][@"deviceTypeId"] inDb:db];
                
                
            } failure:^(id obj) {
                completionCallback(obj[@"result"]);
            }];
            
         }
     }];
}


- (void)syn_ecgDeleteDeviceWith:(NSDictionary *)params completion:(CommonBlockCompletion)completionCallback;
{
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    [dic setValue:[SynECGLibSingleton sharedInstance].target_id forKey:@"targetId"];
    [dic setValue:@"I000003" forKey:@"indicateId"];
    [[RequestManager sharedInstance]postParameters:dic Url:INDICATE_DEL_URL sucessful:^(id obj) {
       completionCallback(obj[@"result"]);

        
        [SynECGLibSingleton sharedInstance].mac = @"";
        [SynECGBlueManager sharedInstance].nowfirmwareNumber = @"";
        [SynECGBlueManager sharedInstance].canUpdateFirmWare = NO;
        
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SynDelete" object:nil];
        
        [self->queue inDatabase:^(FMDatabase *db) {
           
            [self changeUseInfoForTable:SYN_USERINFO_TABLE mac:@"" deviceId:@"" deviceTypeId:@"" inDb:db];
        }];
        
    } failure:^(id obj) {
        completionCallback(obj[@"result"]);
    }];
}


//修改字段
- (void)changeTable:(NSString *)tableName  Column:(NSString *)columnName value:(NSString *)value inDb:(FMDatabase *)dataBase
{
    NSString *updateSql = [NSString stringWithFormat:
                           @"UPDATE %@ SET %@ = '%@' WHERE id = '1'",tableName,columnName,value];
    [dataBase executeUpdate:updateSql];
    
}

- (void)changeUseInfoForTable:(NSString *)tabele mac:(NSString *)mac deviceId:(NSString *)deviceId deviceTypeId:(NSString *)deviceTypeId inDb:(FMDatabase *)dataBase
{
    NSString *updateSql = [NSString stringWithFormat:
                           @"UPDATE %@ SET mac = '%@', deviceId = '%@',deviceTypeId = '%@' WHERE id = '1'",tabele,mac,deviceId,deviceTypeId];
     [dataBase executeUpdate:updateSql];
    
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

- (void)syn_ecgUpSymptomWith:(NSDictionary *)params completion:(CommonBlockCompletion)completionCallback{

    NSMutableDictionary *dic = [[NSMutableDictionary alloc]initWithDictionary:params];
    [dic setObject:[SynECGLibSingleton sharedInstance].record_id  forKey:@"recordId"];
    [dic setObject:[SynECGLibSingleton sharedInstance].target_id  forKey:@"targetId"];

    
  [[RequestManager sharedInstance]postParameters:dic Url:UPDATE_SYMPTORM sucessful:^(id obj) {
      completionCallback(obj[@"result"]);
  } failure:^(id obj) {
      NSLog(@"%@",obj[@"result"][@"message"]);
      
      completionCallback(obj[@"result"]);
  }];




}

@end
