//
//  SportDataManager.h
//  SynECG
//
//  Created by LiangXiaobin on 21/1/2019.
//  Copyright © 2019 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDBManager.h"
NS_ASSUME_NONNULL_BEGIN

@interface SportDataManager : NSObject
@property(nonatomic,assign)BOOL updating;
@property(nonatomic,assign)BOOL reUpdate;
@property(nonatomic,copy)NSString *docDir;
@property(nonatomic,copy)NSString *filePathName;
@property(nonatomic,assign)NSInteger upNum;
@property(nonatomic,assign)NSInteger nowIndex;

+ (instancetype)sharedInstance;
- (void)saveDateInIndex:(NSInteger)index withData:(NSData *)data;

- (void)uploadWithIndex:(NSInteger)index In:(FMDatabase *)db;

- (void)uploadLastIn:(FMDatabase *)db;

- (void)uploadSportMessageToSever;

@end

NS_ASSUME_NONNULL_END
