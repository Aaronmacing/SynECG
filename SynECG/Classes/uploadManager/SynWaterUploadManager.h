//
//  SynWaterUploadManager.h
//  SynECG
//
//  Created by LiangXiaobin on 2016/10/5.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDBManager.h"

@interface SynWaterUploadManager : NSObject
@property(nonatomic,assign)BOOL updating;
@property(nonatomic,assign)BOOL reUpdate;
@property(nonatomic,assign)NSInteger upNum;
+ (instancetype)sharedInstance;
- (void)uploadWaterWithCategory:(NSString *)category in:(FMDatabase *)db;
- (void)uploadEnergyMessageToSever;

@end
