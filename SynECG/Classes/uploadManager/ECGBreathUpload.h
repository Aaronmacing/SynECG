//
//  ECGBreathUpload.h
//  SynECG
//
//  Created by LiangXiaobin on 16/7/4.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDBManager.h"

@interface ECGBreathUpload : NSObject
@property(nonatomic,assign)BOOL uploading;
@property(nonatomic,assign)BOOL reUpdate;
@property(nonatomic,assign)BOOL needCreat;
@property(nonatomic,assign)BOOL inCreat;
@property(nonatomic,assign)BOOL lastMessage;

@property(nonatomic,assign)NSInteger upNum;
+ (instancetype)sharedInstance;
- (void)uploadBreathMessageIn:(FMDatabase *)db;;
- (void)uploadBreathMessageToSever;
- (void)uploadLatBreathIn:(FMDatabase *)db;
@end
