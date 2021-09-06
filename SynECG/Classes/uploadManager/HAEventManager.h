//
//  HAEventManager.h
//  SynECG
//
//  Created by LiangXiaobin on 16/7/5.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDBManager.h"
@interface HAEventManager : NSObject
@property(nonatomic,assign)BOOL updating;
@property(nonatomic,assign)BOOL reupdate;
@property(nonatomic,assign)NSInteger upNum;;

+ (instancetype)sharedInstance;
- (void)uploadEventMessageIn:(FMDatabase *)db;
- (void)uploadEventMessageToSever;
@end
