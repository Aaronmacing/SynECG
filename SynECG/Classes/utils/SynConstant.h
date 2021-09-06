//
//  SynConstant.h
//  SynECG
//
//  Created by LiangXiaobin on 16/6/30.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#ifndef SynConstant_h
#define SynConstant_h


#define BlockWeakSelf(object)  __weak typeof(object) weakSelf = object
//获取baseURL
#define GET_HTTP_BASE   @"https://access-directory1.synwing.com/synwing_app_config/baseUrl/listAll"
#define GET_HTTPS_BASE @"https://cloud.synwing.com:8443/synwing_app_config/baseUrl/listAll"

//登录方法
#define LOGIN_URL  @"platform/app/user/targetInfo"
//上传用户信息
#define UPDATE_USERINFO_URL     @"platform/app/target/update/info"//更新用户资料


//指标管理
#define INDICATE_DEL_URL        @"platform/app/target/removeIndicate"//指标删除
#define INDICATE_BIND_URL       @"platform/app/target/bindIndicate" //指标-绑定
#define INDICATE_CHANGE_URL     @"platform/app/target/replaceDevice"//指标-更换

//症状上传
#define UPDATE_SYMPTORM         @"platform/app/target/addSymptom"//上传症状


//获取下载地址                     
#define FIRMWAREVER_CHECK_URL  @"platform/app/device/checkFirmwareVer"

//能量数据
#define ENERGY_UPLOAD_URL @"ecg/app/upload/cumulative-energy-step"
//呼吸频率
#define BREATHING_UPLOAD_URL @"ecg/app/upload/breath-rate"
//运动姿态变化,当运动姿态变化时，上传一次数据
#define SPOTRS_TYPE_UPLOAD_URL  @"ecg/app/upload/instant-activity"
//R_R数据上传---每隔5分钟上传一次
#define RRPEAK_UPLOAD_URL       @"ecg/app/upload/5-min-anns"
//事件上传.事件发生一次，就上传一次
#define EVENT_UPLOAD_URL        @"ecg/app/upload/event/v3"
//HRV上传
#define HRV_UPLOAD_URL        @"ecg/app/upload/hrvData"
//原始数据
#define HR_UPLOAD_URL         @"ecg/app/upload/5-min-ecg-raw"

#define SPORT_UP_URL       @"ecg/app/upload/motion-data"

//水位线
#define WATER_UPLOAD_URL @"ecg/app/upload/alertMark"
//告警
#define ALARM_UPLOAD_URL @"ecg/app/upload/alert"

#define ERROR_UPLOAD_URL @"errorLog/requestLog/upload"

#define BATTERY_STATUS_URL @"platform/app/device/uploadBattery"
//Status上传
#define DEVICE_STATUS_URL @"platform/app/device/uploadStatus"

//创建单例
#ifndef SHARED_SERVICE
#define SHARED_SERVICE(ServiceName) \
+(instancetype)sharedInstance \
{ \
static ServiceName * sharedInstance; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
sharedInstance = [[ServiceName alloc] init]; \
}); \
return sharedInstance; \
}
#endif

//重写NSLog,Debug模式下打印日志和当前行数
#if DEBUG
#define NSLog(FORMAT, ...) fprintf(stderr,"\nfunction:%s line:%d content:%s\n", __FUNCTION__, __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSLog(FORMAT, ...) nil
#endif

//采样率
#define SAMPLING_REAT 256

//#define MIN_POSATION(position) (((position+128)/256 - 3) * 256)
#define MIN_POSATION(position) (position - 3 * 256)
#define MAX_POSATION(position) (position + 3 * 256)

typedef NS_ENUM (NSInteger, ECGEnergyType)
{
    ECGEnergyUnkonwn = 0,                  //未知
    ECGEnergyREPOSE = 1,                  //静卧
    ECGEnergySIT_QUIETLY = 2,             //静坐
    ECGEnergySLOW_RUN = 3,                //走
    ECGEnergyFAST_RUN = 4,                //慢跑
    ECGEnergySTRENUOUS_EXERCISE = 5       //跑
};

///ECG告警级别枚举
typedef NS_ENUM (NSInteger, ECGAlertEventType)
{
    Event_None = 0,			//0、无
    
    Event_HR_Slow_on = 1,		//1、心跳过缓起始
    Event_HR_Slow_off = 2,		//2、心跳过缓结束
    
    Event_HR_Fast_on = 3,		//3、窦性心跳过快起始
    Event_HR_Fast_off = 4,		//4、窦性心跳过快结束
    
    Event_AHR_Fast_on = 5,		//5、房性心跳过快起始
    Event_AHR_Fast_off = 6,		//6、房性心跳过快结束
    
    Event_VHR_Fast_on = 7,		//7、室性心跳过快起始
    Event_VHR_Fast_off = 8,		//8、室性心跳过快结束
    
    Event_PB_PAC_RC = 9,		//9、房性早搏单发
    Event_PB_PAC_Couple = 10,		//10、房性早搏成对
    Event_PB_PAC_Fast = 11,		//11、房性速搏
    Event_PB_PAC_Tick2_on = 12,		//12、房性早搏二联律开始
    Event_PB_PAC_Tick2_off = 13 ,		//13、房性早搏二联律结束
    
    Event_PB_PAC_Tick3_on = 14,		//14、房性早搏三联律开始
    Event_PB_PAC_Tick3_off = 15,		//15、房性早搏三联律结束
    
    Event_PB_PVC_RC = 16,		//16、室性早搏单发
    Event_PB_PVC_Couple = 17,		//17、室性早搏成对
    Event_PB_PVC_Fast = 18,		//18、室性速搏
    Event_PB_PVC_Tick2_on = 19,		//19、室性早搏二联律开始
    Event_PB_PVC_Tick2_off = 20,		//20、室性早搏二联律结束
    
    Event_PB_PVC_Tick3_on = 21,		//21、室性早搏三联律开始
    Event_PB_PVC_Tick3_off = 22,		//22、室性早搏三联律结束
    
    Event_PB_PNC_RC = 23,		//23、交界性早搏单发
    Event_PB_PNC_Couple = 24,		//24、交界性早搏成对
    Event_PB_PNC_Fast = 25,		//25、交界性速搏
    Event_PB_PNC_Tick2_on = 26,		//26、交界性早搏二联律开始
    Event_PB_PNC_Tick2_off = 27,		//27、交界性早搏二联律结束
    
    Event_PB_PNC_Tick3_on = 28,		//28、交界性早搏三联律开始
    Event_PB_PNC_Tick3_off = 29,		//29、交界性早搏三联律结束
    
    Event_PB_NEB = 30,			//30、交界性逸搏
    
    Event_FC_AFIB = 31,			//31、房颤
    Event_FC_AFL = 32,			//32、房扑
    Event_FC_VFIB = 33,			//33、室颤
    Event_FC_VFL = 34,			//34、室扑
    
    Event_ST_High_on = 35,		//35、ST段抬高开始
    Event_ST_Low_on = 36,		//36、ST段压低开始
    
    Event_TWA = 37,			//37、TWA事件
    
    Event_SCD_RISK = 38,			//38、猝死风险预测
    
    Event_ST_High_off = 39,		//39、ST段抬高结束
    Event_ST_Low_off = 40,		//40、ST段压低结束
    
    Event_BEAT_STOP = 41,		//41、停搏
    Event_PAUSE_on = 42,        //42、停搏开始
    Event_PAUSE_off = 43,        //43、停搏结束
    Event_AFIB_on = 44,                //44、房颤开始
    Event_AFIB_off = 45,                //45、房颤结束
    EVENT_PAUSE_SHORT = 46,  //46、停播2-3s
};

#define TOTAL_TABLE @"measure_table"
#define HR_TABLE @"hr"
#define HR_UPLOAD_TABLE @"hrupload"
#define RR_TABLE @"rr_b1"
#define RR_UPLOAD_TABLE @"rrupload"
#define BREATH_TABLE @"breath1"
#define BREATH_UPLOAD_TABLE @"breathupload1"

#define ENERGY_TABLE @"energy"
#define ENERGY_UPLOAD_TABLE @"energyupload"
#define MOTION_UPLOAD_TABLE @"motionupload"

#define EVENT_TABLE @"event"
#define EVENT_UPLOAD_TABLE @"eventupload"

#define STATUS_TABLE @"d_s"

#define ALARM_TABLE @"alarm_two"
#define ALARM_UPLOAD_TABLE @"alarmupload"

#define WATER_TABLE @"water_two"
#define WATER_UPLOAD_TABLE @"wateruploadnew"
#define SYN_USERINFO_TABLE @"userInfo_one"


#define SYN_NUM @"internatnum"

#define SYN_RECORD @"record_list"

#define SPORT_UP_TABLE @"sport_upload"

#endif /* SynConstant_h */
