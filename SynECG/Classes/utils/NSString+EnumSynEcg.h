//
//  NSString+EnumSynEcg.h
//  SynECG
//
//  Created by LiangXiaobin on 2016/12/16.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynConstant.h"

@interface NSString (EnumSynEcg)

///ECG告警级别枚举
- (NSString *)ECGAlertEventTypeToStringWith:(ECGAlertEventType)alertEventType;

- (NSString *)acticity:(ECGEnergyType)energyType;

- (NSString *)water:(NSString *)water;
- (NSString *)alertType:(NSString *)alertType;


- (NSInteger)setEcgEventTypeForAlambyEventType:(ECGAlertEventType)type;

//- (NSInteger)setEcgEventShowTypeForAlambyEventType:(ECGAlertEventType)type;

- (NSString *)deviceStatusTypeStringFromEventType:(NSString *)type;

- (NSString *)acticityByType:(NSString *)energyType;

@end
