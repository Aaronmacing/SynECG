//
//  HeartBeatModel.h
//  SynECG
//
//  Created by LiangXiaobin on 2017/4/1.
//  Copyright © 2017年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDBManager.h"


@interface HeartBeatModel : NSObject
@property(nonatomic,assign)NSInteger num;
+ (instancetype)sharedInstance;
- (void)uploadStatusMessage;
- (void)searchFromRecord:(NSString *)recordId In:(FMDatabase *)db;
- (void)reCreatReportWithRecordId:(NSString *)recordid;
- (void)deleteMessageByRecord:(NSString *)recordId;
@end
