//
//  ECGEnergryManager.h
//  SynECG
//
//  Created by LiangXiaobin on 16/7/4.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDBManager.h"

@interface ECGEnergryManager : NSObject
@property(nonatomic,assign)BOOL updatimg;
@property(nonatomic,assign)BOOL reUpdate;
@property(nonatomic,assign)NSInteger upNum;
+ (instancetype)sharedInstance;
- (void)uploadEnergryMessageIn:(FMDatabase *)db;;
- (void)uploadEnergyMessageToSever;
@end
