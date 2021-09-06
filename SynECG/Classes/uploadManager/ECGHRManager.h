//
//  ECGHRManager.h
//  SynECG
//
//  Created by LiangXiaobin on 16/7/1.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDBManager.h"

@interface ECGHRManager : NSObject
@property(nonatomic,assign)BOOL updating;
@property(nonatomic,assign)BOOL reUpdate;
@property(nonatomic,copy)NSString *docDir;
@property(nonatomic,copy)NSString *filePathName;
@property(nonatomic,strong)NSMutableData *tempSaveData;
@property(nonatomic,strong) NSFileHandle *ecgOutFile;
@property(nonatomic,assign)NSInteger upNum;
@property(nonatomic,assign)BOOL inSave;
+ (instancetype)sharedInstance;
- (void)saveDateInRecordId:(NSString *)recordId withData:(NSData *)data;
- (void)uploadECGHRMessageToSever;
- (void)uploadLastMessageIn:(FMDatabase *)db;

//移除多余的、之前移除失败的文件；
- (void)deleteOthorMessage;
@end
