//
//  SportDataManager.m
//  SynECG
//
//  Created by LiangXiaobin on 21/1/2019.
//  Copyright © 2019 LiangXiaobin. All rights reserved.
//

#import "SportDataManager.h"
#import "SynConstant.h"
#import "SynECGUtils.h"
#import "SynECGLibSingleton.h"
#import "RequestManager.h"
#import "ZipArchive.h"
#import "ECGDecodeManager.h"
#import "ECGErrorCodeUpload.h"

@interface SportDataManager ()
{
    
    FMDatabaseQueue *queue;
    dispatch_queue_t upQueue;
}
@property(nonatomic,strong) NSFileHandle *outFile;

@end

@implementation SportDataManager

+ (instancetype)sharedInstance
{
    static SportDataManager * sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SportDataManager alloc] init];
    });
    return sharedInstance;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        _updating = NO;
        queue = [SDBManager defaultDBManager].queue;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        _docDir = [paths objectAtIndex:0];
        _upNum = 0;
        upQueue = dispatch_queue_create("upSport", DISPATCH_QUEUE_CONCURRENT);
        _nowIndex = -1;
        [self checkFile];
        
    }
    return self;
}


- (void)checkFile
{
    _filePathName = [_docDir stringByAppendingPathComponent:[[NSString alloc]initWithFormat:@"synSport/%@.dat",[[NSString alloc]initWithFormat:@"sportTemp"]]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.filePathName]) {
        
    }
    else {
        
        [self creatFileWithPath:_filePathName];
    }
    
    self.outFile = [NSFileHandle fileHandleForUpdatingAtPath:_filePathName];
}


- (void)saveDateInIndex:(NSInteger)index withData:(NSData *)data
{
    if(index == 0)
    {
        [self.outFile closeFile];
        _filePathName = [_docDir stringByAppendingPathComponent:[[NSString alloc]initWithFormat:@"synSport/%@.dat",[[NSString alloc]initWithFormat:@"sportTemp"]]];
        
        [self removeFileWith:_filePathName];
        [self creatFileWithPath:_filePathName];
        self.outFile = [NSFileHandle fileHandleForUpdatingAtPath:_filePathName];
    }
    else
    {
        
    }
    
    
    [self.outFile seekToEndOfFile];
    [self.outFile writeData:data];
}


- (void)creatFileWithPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    BOOL haveFile = [fileManager fileExistsAtPath:path];
    if (!haveFile)
    {
        BOOL succeed = [fileManager createFileAtPath:path contents:nil attributes:nil];

        if (succeed == NO) {

            [self creatFileWithPath:path];
        }

    }
    else
    {

    }
}


- (void)uploadWithIndex:(NSInteger)index In:(FMDatabase *)db
{
    
    
    NSInteger lenth = 16 * 5 * 60;
    [self.outFile seekToFileOffset:index *lenth];
    NSData *upData = [self.outFile readDataOfLength:lenth];
    
    NSString  *uPath = [_docDir stringByAppendingPathComponent:[[NSString alloc]initWithFormat:@"synSport/%@_%ld.dat",[SynECGLibSingleton sharedInstance].record_id,(long)index]];
    
    NSFileManager *df = [NSFileManager defaultManager];
    BOOL succeed = [df createFileAtPath:uPath contents:upData attributes:nil];
    if (!succeed) {
        
        [df createFileAtPath:uPath contents:upData attributes:nil];
    }
    
    
    NSString  *zipPath = [_docDir stringByAppendingPathComponent:[[NSString alloc]initWithFormat:@"synSport/%@_%ld.zip",[SynECGLibSingleton sharedInstance].record_id,(long)index]];
    
    [self doZipAtPath:uPath to:zipPath];
    
    NSString *sql1 = [NSString stringWithFormat:@"INSERT INTO %@ (userId, params, fileName) VALUES (?, ?, ?);",SPORT_UP_TABLE];
    
    long long occur_datetime = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:index * 5 * 60 * 1000];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    [dic setObject:[SynECGLibSingleton sharedInstance].record_id forKey:@"recordId"];
    [dic setObject:[SynECGLibSingleton sharedInstance].user_id forKey:@"userId"];
    [dic setObject:@(occur_datetime) forKey:@"occurTime"];
    [dic setObject:@(lenth * index) forKey:@"idx"];
    [dic setObject:[NSString stringWithFormat:@"%ld",(long)[SynECGLibSingleton sharedInstance].typeIndex] forKey:@"dataVer"];
    
    
    NSString *params = [SynECGUtils convertToJSONData:dic];
    
    
    
    [db executeUpdate:sql1,[SynECGLibSingleton sharedInstance].user_id,params,[[NSString alloc]initWithFormat:@"synSport/%@_%ld.zip",[SynECGLibSingleton sharedInstance].record_id,(long)index]];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self uploadSportMessageToSever];
        
    });
    
    self.nowIndex = index;
    
    
}

- (void)uploadLastIn:(FMDatabase *)db
{
    
    NSInteger index = self.nowIndex + 1;
    NSInteger lenth = 16 * 5 * 60;
    [self.outFile seekToFileOffset:index *lenth];
    NSData *upData = [self.outFile readDataToEndOfFile];
    [self.outFile closeFile];
    
    NSString  *uPath = [_docDir stringByAppendingPathComponent:[[NSString alloc]initWithFormat:@"synSport/%@_%ld.dat",[SynECGLibSingleton sharedInstance].record_id,(long)index]];
    
    NSFileManager *df = [NSFileManager defaultManager];
    BOOL succeed = [df createFileAtPath:uPath contents:upData attributes:nil];
    if (!succeed) {
        
        [df createFileAtPath:uPath contents:upData attributes:nil];
    }
    
    
    NSString  *zipPath = [_docDir stringByAppendingPathComponent:[[NSString alloc]initWithFormat:@"synSport/%@_%ld.zip",[SynECGLibSingleton sharedInstance].record_id,(long)index]];
    
    [self doZipAtPath:uPath to:zipPath];
    
    NSString *sql1 = [NSString stringWithFormat:@"INSERT INTO %@ (userId, params, fileName) VALUES (?, ?, ?);",SPORT_UP_TABLE];
    
    long long occur_datetime = [SynECGUtils setOccerTimeUnixTimestampFromPastSeconds:index * 5 * 60 * 1000];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    [dic setObject:[SynECGLibSingleton sharedInstance].record_id forKey:@"recordId"];
    [dic setObject:[SynECGLibSingleton sharedInstance].user_id forKey:@"userId"];
    [dic setObject:@(occur_datetime) forKey:@"occurTime"];
    [dic setObject:@(lenth * index) forKey:@"idx"];
    [dic setObject:@"v5" forKey:@"dataVer"];
    
    
    NSString *params = [SynECGUtils convertToJSONData:dic];
    
    
    
    [db executeUpdate:sql1,[SynECGLibSingleton sharedInstance].user_id,params,[[NSString alloc]initWithFormat:@"synSport/%@_%ld.zip",[SynECGLibSingleton sharedInstance].record_id,(long)index]];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self uploadSportMessageToSever];
        
    });
    
    self.nowIndex = -1;
    
    
    
}


/**
 *  根据路径将文件压缩为zip到指定路径
 *
 */
- (BOOL)doZipAtPath:(NSString*)sourcePath to:(NSString*)destZipFile
{
    @autoreleasepool {
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        ZipArchive * zipArchive = [[ZipArchive alloc]init];
        BOOL isdic;
        //判断sourcePath下是文件夹还是文件
        if(![fileManager fileExistsAtPath:sourcePath isDirectory:&isdic])
            return NO;//文件已存在，直接返回
        
        [zipArchive CreateZipFile2:destZipFile];
        
        if (isdic)//文件夹
        {
            NSArray *fileList = [fileManager contentsOfDirectoryAtPath:sourcePath error:nil];//文件列表
            for(NSString *filePath in fileList){
                NSString *fileName = [filePath lastPathComponent];//取得文件名
                NSString *path = [sourcePath stringByAppendingString:[[NSString alloc]initWithFormat:@"/%@",filePath]];
                [zipArchive addFileToZip:path newname:fileName];
            }
        }
        else
        {
            [zipArchive addFileToZip:sourcePath newname:[sourcePath lastPathComponent]];
        }
        
        [zipArchive CloseZipFile2];
        
        BOOL haveFile = [fileManager fileExistsAtPath:destZipFile];
        
        if(haveFile)
        {
            [self removeFileWith:sourcePath];
            return YES;
        }
        else
        {
            return NO;
        }
    }
}

- (void)uploadSportMessageToSever
{
    if ([RequestManager isNetworkReachable] == YES && self.updating == NO && [SynECGLibSingleton sharedInstance].token.length > 0)
    {
        [[SDBManager defaultDBManager].queue inTransaction:^(FMDatabase *db, BOOL *rollback)
         {
             
             NSString *numQuery  = [NSString stringWithFormat:@"select count(*) from %@",SPORT_UP_TABLE];
             NSUInteger num = [db intForQuery:numQuery];
             if (num == 0) {
                 
                 return;
             }
             else
             {
                 
                 self.updating = YES;
                 
                 NSString *query = [NSString stringWithFormat:@"select * from %@ ORDER by id limit 0,1",SPORT_UP_TABLE];
                 FMResultSet *rs = [db executeQuery:query];
                 NSString *params = [[NSString alloc]init];
                 NSString *fileName = [[NSString alloc]init];
                 while ([rs next]) {
                     
                     params = [rs stringForColumn:@"params"];
                     fileName = [rs stringForColumn:@"fileName"];
                 }
                 [rs close];
                 
                 
                 NSString * docp = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
                 NSString *tPath = [docp stringByAppendingString:[NSString stringWithFormat:@"/%@",fileName]];
                 

                 
                 [self uploadECGHRMessageToSeverWithModel:[SynECGUtils dictionaryWithJsonString:params] fileUrl:tPath path:fileName];
                 
        

             }
         }];
    }
}

- (void)uploadECGHRMessageToSeverWithModel:(NSDictionary *)dic fileUrl:(NSString *)filePath path:(NSString *)path
{
    BlockWeakSelf(self);
    [[RequestManager sharedInstance]uploadWithUrl:SPORT_UP_URL parameters:dic fileUrl:filePath name:@"dataFile" sucessful:^(id obj) {

        weakSelf.upNum = 0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [weakSelf deleteNewMessageWithpath:path withNum:0 with:@""];
            
        });
        
    } failure:^(id obj) {

        if ([obj[@"result"][@"errorMessage"] isEqualToString:@"dataFile is null or empty!"] || [obj[@"result"][@"errorCode"] integerValue] == 1) {


            [weakSelf deleteNewMessageWithpath:path withNum:0 with:@""];

        }
        else if([obj[@"result"][@"errorCode"] integerValue] == 8888 || [obj[@"result"][@"errorCode"] integerValue] == 911)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

                [weakSelf uploadECGHRMessageToSeverWithModel:dic fileUrl:filePath path:path];
            });
        }
        else if([obj[@"result"][@"errorCode"] integerValue] == 9999 || [obj[@"result"][@"errorCode"] integerValue] == 2 || [obj[@"result"][@"errorCode"] integerValue] == 111)
        {

            weakSelf.updating = NO;

        }
        else
        {
            if (weakSelf.upNum <= 3) {

                [weakSelf uploadECGHRMessageToSeverWithModel:dic fileUrl:filePath path:path];
            }
            else
            {
                NSLog(@"delete %@ error = %@",filePath,obj[@"result"][@"message"]);
                [weakSelf deleteNewMessageWithpath:path withNum:0 with:@""];

            }
        }


        NSMutableDictionary *params = [[NSMutableDictionary alloc]init];


        NSTimeInterval tv = [[NSDate date]  timeIntervalSince1970];

        long long timesp = (long long)(tv * 1000 - 500);

        [params setObject:SPORT_UP_URL forKey:@"reqUrl"];
        [params setObject:@"ecgUpload" forKey:@"reqType"];
        [params setObject:[SynECGUtils convertToJSONData:dic] forKey:@"reqParams"];
        [params setObject:@(timesp) forKey:@"createdTime"];
        [params setObject:@(timesp) forKey:@"execTime"];
        [params setObject:obj[@"result"] forKey:@"rtnResult"];

        [[ECGErrorCodeUpload sharedInstance]uploadErrorMessageWith:params];

        weakSelf.upNum ++;



    }];
    
}


/**
 *  根据路径删除上传数据库中的数据
 */

- (void)deleteNewMessageWithpath:(NSString *)path withNum:(NSNumber *)num with:(NSString *)recordId
{
    
    NSString *filePath = [_docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",path]];
    [self removeFileWith:filePath];
    
    
    BlockWeakSelf(self);
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        [weakSelf deleteNewMessageWithDB:db withNum:num with:recordId];
        
    }];
}

- (void)removeFileWith:(NSString *)path
{
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:path]) {
        
        BOOL succeed = [fileManager removeItemAtPath:path error:nil];
        if (!succeed) {
            [self removeFileWith:path];
        }
    }
}


- (void)deleteNewMessageWithDB:(FMDatabase *)db withNum:(NSNumber *)num with:(NSString *)recordId
{
    //"DELETE FROM motionupload WHERE target_id = ? limit 0,1
    
    NSString *sqlstr = [NSString stringWithFormat:@"DELETE FROM %@  ORDER by id limit 0,1",SPORT_UP_TABLE];
    [db executeUpdate:sqlstr];
    BOOL succeed = [db executeUpdate:sqlstr];
    
    if (succeed) {
        self.updating = NO;
        if (self.reUpdate == YES) {
            
            [self uploadSportMessageToSever];
        }
    }
    else
    {
        [self deleteNewMessageWithDB:db withNum:num with:recordId];
    }
}



@end
