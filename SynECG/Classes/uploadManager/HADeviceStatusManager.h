//
//  HADeviceStatusManager.h
//  SynECG
//
//  Created by LiangXiaobin on 16/7/7.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HADeviceStatusManager : NSObject
@property(nonatomic,assign)BOOL updating;
@property(nonatomic,assign)BOOL reUpdate;
@property(nonatomic,assign)NSInteger upNum;
+ (instancetype)sharedInstance;
- (void)uploadStatusMessage;
@end
