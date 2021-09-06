//
//  NSString+EnumSynEcg.m
//  SynECG
//
//  Created by LiangXiaobin on 2016/12/16.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import "NSString+EnumSynEcg.h"

@implementation NSString (EnumSynEcg)
#pragma mark -----------------ECG：根据index获得对应的Enum字符串或对应的文字------


///ECG告警级别枚举
- (NSString *)ECGAlertEventTypeToStringWith:(ECGAlertEventType)alertEventType
{
    
    
    NSDictionary *dic = @{@(Event_None):@"EVENT_NONE",                    
                          @(Event_HR_Slow_on):@"EVENT_HR_Slow_on",
                          @(Event_HR_Slow_off):@"EVENT_HR_Slow_off",
                          @(Event_HR_Fast_on):@"EVENT_HR_Fast_on",
                          @(Event_HR_Fast_off):@"EVENT_HR_Fast_off",
                          @(Event_AHR_Fast_on):@"EVENT_AHR_Fast_on",
                          @(Event_AHR_Fast_off):@"EVENT_AHR_Fast_off",
                          @(Event_VHR_Fast_on):@"EVENT_VHR_Fast_on",
                          @(Event_VHR_Fast_off):@"EVENT_VHR_Fast_off",
                          @(Event_PB_PAC_RC):@"EVENT_PB_PAC_RC",
                          @(Event_PB_PAC_Couple):@"EVENT_PB_PAC_Couple",
                          @(Event_PB_PAC_Fast):@"EVENT_PB_PAC_Fast",
                          @(Event_PB_PAC_Tick2_on):@"EVENT_PB_PAC_Tick2_on",
                          @(Event_PB_PAC_Tick2_off):@"EVENT_PB_PAC_Tick2_off",
                          @(Event_PB_PAC_Tick3_on):@"EVENT_PB_PAC_Tick3_on",
                          @(Event_PB_PAC_Tick3_off):@"EVENT_PB_PAC_Tick3_off",
                          @(Event_PB_PVC_RC):@"EVENT_PB_PVC_RC",
                          @(Event_PB_PVC_Couple):@"EVENT_PB_PVC_Couple",
                          @(Event_PB_PVC_Fast):@"EVENT_PB_PVC_Fast",
                          @(Event_PB_PVC_Tick2_on):@"EVENT_PB_PVC_Tick2_on",
                          @(Event_PB_PVC_Tick2_off):@"EVENT_PB_PVC_Tick2_off",
                          @(Event_PB_PVC_Tick3_on):@"EVENT_PB_PVC_Tick3_on",
                          @(Event_PB_PVC_Tick3_off):@"EVENT_PB_PVC_Tick3_off",
                          @(Event_PB_PNC_RC):@"EVENT_PB_PNC_RC",
                          @(Event_PB_PNC_Couple):@"EVENT_PB_PNC_Couple",
                          @(Event_PB_PNC_Fast):@"EVENT_PB_PNC_Fast",
                          @(Event_PB_PNC_Tick2_on):@"EVENT_PB_PNC_Tick2_on",
                          @(Event_PB_PNC_Tick2_off):@"EVENT_PB_PNC_Tick2_off",
                          @(Event_PB_PNC_Tick3_on):@"EVENT_PB_PNC_Tick3_on",
                          @(Event_PB_PNC_Tick3_off):@"EVENT_PB_PNC_Tick3_off",
                          @(Event_PB_NEB):@"EVENT_PB_NEB",
                          @(Event_FC_AFIB):@"EVENT_FC_AFIB",
                          @(Event_FC_AFL):@"EVENT_FC_AFL",
                          @(Event_FC_VFIB):@"EVENT_FC_VFIB",
                          @(Event_FC_VFL):@"EVENT_FC_VFL",
                          @(Event_ST_High_on):@"EVENT_ST_High_on",
                          @(Event_ST_Low_on):@"EVENT_ST_Low_on",
                          @(Event_TWA):@"EVENT_TWA",
                          @(Event_SCD_RISK):@"EVENT_SCD_RISK",
                          @(Event_ST_High_off):@"EVENT_ST_High_off",
                          @(Event_ST_Low_off):@"EVENT_ST_Low_off",
                          @(Event_BEAT_STOP):@"EVENT_BEAT_STOP",
                          @(Event_PAUSE_on): @"EVENT_PAUSE_on",
                          @(Event_PAUSE_off):@"EVENT_PAUSE_off",
                          @(Event_AFIB_on):@"EVENT_AFIB_on",
                          @(Event_AFIB_off):@"EVENT_AFIB_off" ,
                          @(EVENT_PAUSE_SHORT):@"EVENT_PAUSE_SHORT"};
    
    NSString *stringValue = dic[@(alertEventType)];
    
    return stringValue?stringValue:@"EVENT_NONE";
}

- (NSString *)water:(NSString *)water
{
    NSDictionary *dic = @{@"CAT_STACH":@"窦性心动过速",
                          @"CAT_SBRAD":@"窦性心动过缓",
                          @"CAT_PAUSE":@"停博",
                          @"CAT_SVEB":@"室上性早搏",
                          @"CAT_VEB":@"室性早搏",
                          @"CAT_SVT":@"室上性心动过速",
                          @"CAT_VT":@"室性心动过速",
                          @"CAT_AF":@"房颤",
                          @"CAT_ST_DEP":@"ST 压低",
                          @"CAT_ST_ELEV":@"ST 段抬高"};
    NSString *stringValue = dic[water];
    return stringValue?stringValue:@"未知告警";
}



- (NSString *)alertType:(NSString *)alertType
{
    NSDictionary *dic = @{@"AL_STACH_L0":@"窦性心动过速L0",
                          @"AL_STACH_L2":@"窦性心动过速L2",
                          @"AL_SBRAD_L0":@"窦性心动过缓L0",
                          @"AL_SBRAD_L1":@"窦性心动过缓L1",
                          @"AL_SBRAD_L2":@"窦性心动过缓L2",
                          @"AL_PAUSE_L2":@"程度较低的停博",
                          @"AL_PAUSE_L3":@"停博",
                          @"AL_SVEB_L0":@"偶发性室上性早搏",
                          @"AL_SVEB_L1":@"频发室上性早搏",
                          @"AL_VEB_L0":@"偶发室性早搏",
                          @"AL_VEB_L1":@"室性早搏",
                          @"AL_VEB_L2":@"频发室性早搏",
                          @"AL_PVEB":@"成对室早",
                          @"AL_RVEB":@"连发室早",
                          @"AL_VEB_BRAD":@"频发室性早搏, 伴窦性心动过缓",
                          @"AL_SVT_L1":@"室上性心动过速L1",
                          @"AL_SVT_L2":@"室上性心动过速L2",
                          @"AL_VT":@"室性心动过速",
                          @"AL_VT_PARO":@"阵发性室性心动过速",
                          @"AL_VT_INCE":@"持续性室速",
                          @"AL_AF":@"房颤",
                          @"AL_AF_TACH":@"房颤伴心动过速",
                          @"AL_AF_LRR":@"房颤伴长间期",
                          @"AL_AF_BRAD":@"房颤伴心动过缓",
                          @"AL_AF_INCE":@"持续性房颤",
                          @"AL_ST_DEPR":@"ST段压低",
                          @"AL_ST_ELEV":@"ST段抬高"};
    
    NSString *stringValue = dic[alertType];
    return stringValue?stringValue:@"未知告警";
}




- (NSString *)acticity:(ECGEnergyType)energyType{
    
    NSDictionary *dic = @{@(ECGEnergyUnkonwn):@"UNKNOWN",
                          @(ECGEnergyREPOSE):@"REPOSE",
                          @(ECGEnergySIT_QUIETLY):@"SIT_QUIETLY",
                          @(ECGEnergySLOW_RUN):@"WALKING",
                          @(ECGEnergyFAST_RUN):@"JOG",
                          @(ECGEnergySTRENUOUS_EXERCISE):@"RUN"};
    
    NSString *stringValue = dic[@(energyType)];
    return stringValue?stringValue:@"UNKNOWN";
}

- (NSString *)acticityByType:(NSString *)energyType{
    
    NSDictionary *dic = @{@"00":@"NONE",
                          @"01":@"STATIONARY",
                          @"11":@"LYING_SUPINE",
                          @"12":@"LYING_PRONE",
                          @"13":@"LYING_SIDEWAYS",
                          @"20":@"SIT",
                          @"30":@"STAND",
                          @"40":@"WALK",
                          @"50":@"JOG",
                          @"60":@"RUN",
                          @"F0":@"FALLDOWN"
                          };
    
    NSString *stringValue = dic[energyType];
    return stringValue?stringValue:@"";
}


- (NSString *)ecgEventTypeStringFromEventType:(NSString *)type
{
    NSDictionary *dic = @{@"Event_None":@"未知",
                          @"EVENT_HR_Slow_on":@"心动过缓",
                          @"EVENT_HR_Slow_off":@"心动过缓",
                          @"EVENT_HR_Fast_on":@"窦性心动过速",
                          @"EVENT_HR_Fast_off":@"窦性心动过速",
                          @"EVENT_AHR_Fast_on":@"房性心动过速",
                          @"EVENT_AHR_Fast_off":@"房性心动过速",
                          @"EVENT_VHR_Fast_on":@"室性心动过速",
                          @"EVENT_VHR_Fast_off":@"室性心动过速",
                          @"EVENT_PB_PAC_RC":@"房性早搏(单发)",
                          @"EVENT_PB_PAC_Couple":@"房性早搏(成对)",
                          @"EVENT_PB_PAC_Fast":@"房性速搏",
                          @"EVENT_PB_PAC_Tick2_on":@"房性早搏(二联律)",
                          @"EVENT_PB_PAC_Tick2_off":@"房性早搏(二联律)",
                          @"EVENT_PB_PAC_Tick3_on":@"房性早搏(三联律)",
                          @"EVENT_PB_PAC_Tick3_off":@"房性早搏(三联律)",
                          @"EVENT_PB_PVC_RC":@"室性早搏(单发)",
                          @"EVENT_PB_PVC_Couple":@"室性早搏(成对)",
                          @"EVENT_PB_PVC_Fast":@"室性速搏",
                          @"EVENT_PB_PVC_Tick2_on":@"室性早搏(二联律)",
                          @"EVENT_PB_PVC_Tick2_off":@"室性早搏(二联律)",
                          @"EVENT_PB_PVC_Tick3_on":@"室性早搏(三联律)",
                          @"EVENT_PB_PVC_Tick3_off":@"室性早搏(三联律)",
                          @"EVENTPB_PNC_RC":@"交界性早搏(单发)",
                          @"EVENT_PB_PNC_Couple":@"交界性早搏(成对)",
                          @"EVENTt_PB_PNC_Fast":@"交界性速搏",
                          @"EVENT_PB_PNC_Tick2_on":@"交界性早搏(二联律)",
                          @"EVENT_PB_PNC_Tick2_off":@"交界性早搏(二联律)",
                          @"EVENT_PB_PNC_Tick3_on":@"交界性早搏(三联律)",
                          @"EVENT_PB_PNC_Tick3_off":@"交界性早搏(三联律)",
                          @"EVENT_PB_NEB":@"交界性逸搏(单发)",
                          @"EVENT_FC_AFIB":@"房颤",
                          @"EVENT_FC_AFL":@"房扑",
                          @"EVENT_FC_VFIB":@"室颤",
                          @"EVENT_FC_VFL":@"室扑",
                          @"EVENT_ST_High_on":@"ST段抬高",
                          @"EVENT_ST_Low_on":@":ST段压低",
                          @"EVENT_TWA":@"TWA事件",
                          @"EVENT_SCD_RISK":@"猝死风险预测",
                          @"EVENT_ST_High_off":@"ST段抬高",
                          @"EVENT_ST_Low_off":@":ST段压低",
                          @"EVENT_BEAT_STOP":@"停搏",
                          @"EVENT_PAUSE_on":@"停搏开始",
                          @"EVENT_PAUSE_off":@"停搏结束",
                          @"EVENT_AFIB_on":@"房颤开始",
                          @"EVENT_AFIB_off":@"房颤结束",
                          @"EVENT_PAUSE_SHORT":@"短时停搏(2~3秒)"};
    
    NSString *stringValue = dic[type];
    return stringValue?stringValue:@"";
}

- (NSString *)deviceStatusTypeStringFromEventType:(NSString *)type
{
    if ([type isEqualToString:@"9"]) {
        
        type = @"2";
    }
    NSDictionary *dic = @{@"0":@"DISCONNECTED",
                          @"1":@"READY",
                          @"2":@"MEASURING",
                          @"3":@"ETLOST",
                          @"12":@"ETLOST"};
    
    NSString *stringValue = dic[type];
    return stringValue?stringValue:@"";
}

- (NSInteger)setEcgEventTypeForAlambyEventType:(ECGAlertEventType)type
{
    NSInteger i = 0;
    switch (type) {
        case Event_None:
            i = 0;
            break;
        case Event_HR_Slow_on: //心动过缓开始
            i = 0;
            break;
        case Event_HR_Slow_off: //心动过缓结束
            i = 3;
            break;
        case Event_HR_Fast_on: //窦性心动过速
            i = 0;
            break;
        case Event_HR_Fast_off: //窦性心动过速
            i = 2;
            break;
        case Event_AHR_Fast_on: //房性心动过速开始
            i = 0;
            break;
        case Event_AHR_Fast_off://房性心动过速结束
            i = 2;
            break;
        case Event_VHR_Fast_on://室性心动过速开始
            i = 0;
            break;
        case Event_VHR_Fast_off://室性心动过速结束
            i = 2;
            break;
        case Event_PB_PAC_RC://房性早搏（单发）
            i = 2;
            break;
        case Event_PB_PAC_Couple://房性早搏（成对）
            i = 2;
            break;
        case Event_PB_PAC_Fast://房性速搏
            i = 2;
            break;
        case Event_PB_PAC_Tick2_on://房性早搏（二联律）开始
            i = 0;
            break;
        case Event_PB_PAC_Tick2_off://房性早搏（二联律）结束
            i = 2;
            break;
        case Event_PB_PAC_Tick3_on://房性早搏（三联律）开始
            i = 0;
            break;
        case Event_PB_PAC_Tick3_off://房性早搏（三联律）结束
            i = 2;
            break;
        case Event_PB_PVC_RC://室性早搏（单发）
            i = 1;
            break;
        case Event_PB_PVC_Couple://室性早搏（成对）
            i = 1;
            break;
        case Event_PB_PVC_Fast://室性速搏
            i = 1;
            break;
        case Event_PB_PVC_Tick2_on://室性早搏（二联律）开始
            i = 0;
            break;
        case Event_PB_PVC_Tick2_off://室性早搏（二联律）结束
            i = 1;
            break;
        case Event_PB_PVC_Tick3_on://室性早搏（三联律）开始
            i = 0;
            break;
        case Event_PB_PVC_Tick3_off://室性早搏（三联律）结束
            i = 1;
            break;
        case Event_PB_PNC_RC://交界性早搏（单发）
            i = 2;
            break;
        case Event_PB_PNC_Couple://交界性早搏（成对）
            i = 2;
            break;
        case Event_PB_PNC_Fast://交界性速搏
            i = 2;
            break;
        case Event_PB_PNC_Tick2_on://交界性早搏（二联律）开始
            i = 0;
            break;
        case Event_PB_PNC_Tick2_off://交界性早搏（二联律）结束
            i = 2;
            break;
        case Event_PB_PNC_Tick3_on://交界性早搏（三联律）开始
            i = 0;
            break;
        case Event_PB_PNC_Tick3_off://交界性早搏（三联律）结束
            i = 2;
            break;
        case Event_PB_NEB://交界性逸搏（单发）
            i = 2;
            break;
        case Event_FC_AFIB://房颤
            i = 4;
            break;
        case Event_FC_AFL://房扑
            i = 4;
            break;
        case Event_FC_VFIB://室颤
            i = 1;
            break;
        case Event_FC_VFL://室扑
            i = 1;
            break;
        case Event_ST_High_on://ST段抬高开始
            i = 0;
            break;
        case Event_ST_Low_on://ST段压低开始
            i = 0;
            break;
        case Event_TWA://TWA
            i = 2;
            break;
        case Event_SCD_RISK://("猝死风险预测", "猝死风险预测"),// 38
            i = 2;
            break;
        case Event_ST_High_off://ST段抬高结束39
            i = 2;
            break;
        case Event_ST_Low_off://ST段压低结束 40
            i = 2;
            break;
        case Event_BEAT_STOP://停搏 41
            i = 2;
            break;
        case Event_PAUSE_on:
            i = 0;
            break;
        case  Event_PAUSE_off:
            i = 2;
            break;
        case Event_AFIB_on:
            i = 0;
            break;
        case Event_AFIB_off:
            i = 4;
            break;
        case EVENT_PAUSE_SHORT:
            i = 2;
            break;
    }
    return i;
}
@end
