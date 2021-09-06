//
//  ECGRRManager.h
//  SynECG
//
//  Created by LiangXiaobin on 16/7/4.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDBManager.h"
@interface ECGRRManager : NSObject
@property(nonatomic,assign)BOOL uploading;
@property(nonatomic,assign)BOOL reUpdate;
@property(nonatomic,assign)NSInteger upNum;;
+ (instancetype)sharedInstance;
- (void)uploadRRMessageIn:(FMDatabase *)db;
- (void)uploadRRMessageToSever;

- (void)deleteRRMessageFrom:(FMDatabase *)db num:(NSInteger )position;
@end
