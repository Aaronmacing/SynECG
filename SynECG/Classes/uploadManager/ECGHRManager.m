//
//  ECGHRManager.m
//  SynECG
//
//  Created by LiangXiaobin on 16/7/1.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import "ECGHRManager.h"
#import "SynConstant.h"
#import "SynECGUtils.h"
#import "SynECGLibSingleton.h"
#import "RequestManager.h"
#import "ZipArchive.h"
#import "ECGDecodeManager.h"
#import "ECGErrorCodeUpload.h"

@interface ECGHRManager ()
{

    FMDatabaseQueue *queue;
    dispatch_queue_t upQueue;
}
@property(nonatomic,strong) NSFileHandle *outFile;

@end

@implementation ECGHRManager

+ (instancetype)sharedInstance
{
    static ECGHRManager * sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ECGHRManager alloc] init];
    });
    return sharedInstance;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        _updating = NO;
        _tempSaveData = [[NSMutableData alloc]init];
        queue = [SDBManager defaultDBManager].queue;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        _docDir = [paths objectAtIndex:0];
        _upNum = 0;
        _inSave = NO;
        upQueue = dispatch_queue_create("upECG", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)saveDateInRecordId:(NSString *)recordId withData:(NSData *)data
{
    [self.tempSaveData appendData:data];
    dispatch_async(upQueue, ^{
        
        [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            [self saveToDatInRecordId:recordId inDB:db];
        }];
    });
    
    
    
}


- (void)saveToDatInRecordId:(NSString *)recordId inDB:(FMDatabase *)db
{
    @autoreleasepool {
        
        if (self.inSave == YES) {
            
            return;
        }
        else
        {
            if([[SynECGLibSingleton sharedInstance].filePathName hasPrefix:recordId])
            {
                if (self.tempSaveData.length >= 5 * 30 * 1024)
                {
                    self.inSave = YES;
                    NSData *writeData = [self.tempSaveData subdataWithRange:NSMakeRange(0,5 * 30 * 1024)];
                    
                    NSInteger ecgUpload = [self queryTable:TOTAL_TABLE Column:@"ecgUpload" in:db];
                    NSInteger ecgInt = [self queryTable:TOTAL_TABLE Column:@"ecg" in:db];
                    
                    [self.ecgOutFile seekToEndOfFile];
                    [self.ecgOutFile writeData:writeData];
                    
                    //写小文件
                    [self.outFile writeData:writeData];
                    [self.outFile closeFile];
                    self.outFile = nil;
                    
                    
                    
                    [self saveToUploadWithPath:[SynECGLibSingleton sharedInstance].filePathName keyNo:ecgUpload start:ecgInt end:(ecgInt + writeData.length / 2) db:db];
                    
                    
                    NSString *updateSql = [NSString stringWithFormat:
                                           @"UPDATE %@ SET ecgUpload = '%@', ecg = '%@'  WHERE recordId = '%@'",TOTAL_TABLE,@(ecgUpload + 1),@(ecgInt + writeData.length / 2),[SynECGLibSingleton sharedInstance].record_id];
                    [db executeUpdate:updateSql];
                    
                    
                    [SynECGLibSingleton sharedInstance].ecgInt = ecgInt + writeData.length / 2;
                    
                    
                    if ([SynECGLibSingleton sharedInstance].ecgInt >= [ECGDecodeManager sharedInstance].nowPosition && [ECGDecodeManager sharedInstance].rrp >= [ECGDecodeManager sharedInstance].nowPosition && [SynECGLibSingleton sharedInstance].isSuspend == YES) {
                        
                        dispatch_resume([ECGDecodeManager sharedInstance].eventQueue);
                        [SynECGLibSingleton sharedInstance].isSuspend = NO;
                        
                    }
                    
                    
                    [self.tempSaveData replaceBytesInRange:NSMakeRange(0, 5 * 30 * 1024) withBytes:NULL length:0];
                    
                    
                    
                    [SynECGLibSingleton sharedInstance].filePathName = [[NSString alloc]initWithFormat:@"%@+%@.dat",recordId,[[NSString alloc]initWithFormat:@"%ld",(long)ecgUpload + 1]];
                    
                    _filePathName = [_docDir stringByAppendingPathComponent:[[NSString alloc]initWithFormat:@"syn/%@.dat",[[NSString alloc]initWithFormat:@"%@+%@",recordId,[[NSString alloc]initWithFormat:@"%ld",(long)ecgUpload + 1]]]];
                    
                    
                    [self creatFileWithPath:_filePathName];
                    
                    self.outFile = [NSFileHandle fileHandleForWritingAtPath:_filePathName];
                    if(self.outFile == nil)
                    {
                        NSLog(@"Open of file for writing failed");
                    }
                    else
                    {
                        //找到并定位到file的末尾位置(在此后追加文件)
                        
                        [self.outFile seekToEndOfFile];
                    }
                    self.inSave = NO;
                    
                    [self saveToDatInRecordId:recordId inDB:db];
                    
                }
                else
                {
                    
                }
                
            }
            else
            {
                
                //创建文件，跳转到最后
                NSInteger ecgUpload = [self queryTable:TOTAL_TABLE Column:@"ecgUpload" in:db];
                _filePathName = [_docDir stringByAppendingPathComponent:[[NSString alloc]initWithFormat:@"syn/%@.dat",[[NSString alloc]initWithFormat:@"%@+%@",recordId,[[NSString alloc]initWithFormat:@"%ld",(long)ecgUpload]]]];
                [SynECGLibSingleton sharedInstance].filePathName = [[NSString alloc]initWithFormat:@"%@+%@.dat",recordId,[[NSString alloc]initWithFormat:@"%ld",(long)ecgUpload]];
                
                
                [self creatFileWithPath:_filePathName];
                
                
                self.outFile = [NSFileHandle fileHandleForWritingAtPath:_filePathName];
                self.ecgOutFile = [NSFileHandle fileHandleForUpdatingAtPath:[SynECGLibSingleton sharedInstance].ecgTempFile];
                if(self.outFile == nil)
                {
                    NSLog(@"Open of file for writing failed");
                    
                }
                else
                {
                    
                    //找到并定位到outFile的末尾位置(在此后追加文件)
                    [self.outFile seekToEndOfFile];
                    
                }
                
                self.inSave = NO;
            }
        }
    }
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




- (unsigned long long) fileSizeAtPath:(NSString*) filePath{
    
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
    
}

- (void)saveToUploadWithPath:(NSString *)path keyNo:(NSInteger)keyNo start:(NSInteger)start end:(NSInteger)end db:(FMDatabase *)db
{
    [self creatFileAtPath:path];
    NSString *newPath =  [path stringByReplacingOccurrencesOfString:@".dat" withString:@".zip"];
    
    if ([SynECGLibSingleton sharedInstance].record_id.length > 0) {
        
        [db executeUpdate:@"INSERT INTO hrupload (path, userId, targetId, recordId, keyNo, start, end) VALUES (?, ?, ?, ?, ?, ?, ?);",newPath,[SynECGLibSingleton sharedInstance].user_id,[SynECGLibSingleton sharedInstance].target_id,[SynECGLibSingleton sharedInstance].record_id,@(keyNo),@(start),@(end)];
        [self uploadECGHRMessageToSever];
    }
    else
    {
        [self removeFileWith:newPath];
    }
}

- (void)creatFileAtPath:(NSString *)path
{
        NSString *newPath =  [path stringByReplacingOccurrencesOfString:@".dat" withString:@".zip"];
        BOOL creat = [self doZipAtPath:path to:newPath];
    
    if (creat == NO) {
        
        [self creatFileWithPath:path];
    }
}

/**
 *  上传至服务器端
 */
- (void)uploadECGHRMessageToSever
{
    if ([RequestManager isNetworkReachable] == YES && !_updating && [SynECGLibSingleton sharedInstance].loginIn == YES)
    {
        
        self.updating = YES;
        BlockWeakSelf(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
       
            [self->queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                NSString *numQuery  = [NSString stringWithFormat:@"select count(*) from %@",HR_UPLOAD_TABLE];
                NSUInteger num = [db intForQuery:numQuery];
                NSString *query = [NSString stringWithFormat:@"select * from %@ ORDER by id limit 0,1",HR_UPLOAD_TABLE];
                NSMutableArray *tempArray = [[NSMutableArray alloc]init];
                NSString *pathName = [[NSString alloc]init];
                FMResultSet *rs = [db executeQuery:query];
                while ([rs next]) {
                    
                    pathName = [rs stringForColumn:@"path"];
                    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
                    [dic setObject:[rs stringForColumn:@"userId"] forKey:@"userId"];
                    [dic setObject:[rs stringForColumn:@"targetId"] forKey:@"targetId"];
                    [dic setObject:[rs stringForColumn:@"recordId"] forKey:@"recordId"];
                    [dic setObject:@([rs longLongIntForColumn:@"start"])  forKey:@"startIdx"];
                    [dic setObject:@([rs longLongIntForColumn:@"end"])  forKey:@"endIdx"];
                    
                    [tempArray addObject:dic];
                    
                }
                
                if (tempArray.count > 0)
                {
                    
                    if (num >= 2) {
                        
                        weakSelf.reUpdate = YES;
                    }
                    else
                    {
                        weakSelf.reUpdate = NO;
                    }
                    
                    self->_updating = YES;
                    
                    NSString *path = [[NSString alloc]initWithFormat:@"syn/%@",pathName];
                    NSString *filePath = [self->_docDir stringByAppendingPathComponent:path];
                    [weakSelf uploadECGHRMessageToSeverWithModel:tempArray[0] fileUrl:filePath path:path];
                }
                else
                {
                    weakSelf.updating = NO;
                }
                
            }];
        });
    }
}

- (void)uploadECGHRMessageToSeverWithModel:(NSDictionary *)dic fileUrl:(NSString *)filePath path:(NSString *)path
{
        BlockWeakSelf(self);
        [[RequestManager sharedInstance]uploadWithUrl:HR_UPLOAD_URL parameters:dic fileUrl:filePath name:@"ecgFile" sucessful:^(id obj) {
            
            weakSelf.upNum = 0;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [weakSelf deleteNewMessageWithpath:path withNum:dic[@"index"] with:dic[@"record_id"]];
                
            });

        } failure:^(id obj) {
            
            if ([obj[@"result"][@"errorMessage"] isEqualToString:@"ecg_file is null or empty!"] || [obj[@"result"][@"errorCode"] integerValue] == 1) {
                
                
                NSLog(@"delete %@ error = ecg_file is null or empty!",filePath);
                [weakSelf deleteNewMessageWithpath:path withNum:dic[@"index"] with:dic[@"record_id"]];
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
                    [weakSelf deleteNewMessageWithpath:path withNum:dic[@"index"] with:dic[@"record_id"]];
            
                }
            }

                
            NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
            
            
            NSTimeInterval tv = [[NSDate date]  timeIntervalSince1970];
            
            long long timesp = (long long)(tv * 1000 - 500);
            
            [params setObject:HR_UPLOAD_URL forKey:@"reqUrl"];
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

- (void)deleteNewMessageWithDB:(FMDatabase *)db withNum:(NSNumber *)num with:(NSString *)recordId
{
    //"DELETE FROM motionupload WHERE target_id = ? limit 0,1
    
    BOOL succeed = [db executeUpdate:@"DELETE FROM hrupload ORDER by id limit 0,1"];
    
    if (succeed) {
        self.updating = NO;
        if (self.reUpdate == YES) {
            
            [self uploadECGHRMessageToSever];
        }
    }
    else
    {
        [self deleteNewMessageWithDB:db withNum:num with:recordId];
    }
}


/**
 *  根据路径将文件压缩为zip到指定路径
 *
 */
- (BOOL) doZipAtPath:(NSString*)sourcePath to:(NSString*)destZipFile
{
    @autoreleasepool {

        sourcePath = [_docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"syn/%@",sourcePath]];
        destZipFile =  [_docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"syn/%@",destZipFile]];
        
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

- (void)uploadLastMessageIn:(FMDatabase *)db
{

    if (self.tempSaveData.length > 0 && self.inSave == NO) {

        [self.ecgOutFile seekToEndOfFile];
        [self.ecgOutFile writeData:self.tempSaveData];
        [self.outFile writeData:self.tempSaveData];
        [self.ecgOutFile closeFile];
        [self.outFile closeFile];
        self.ecgOutFile = nil;
        self.outFile = nil;
        
        
        
        NSInteger ecgUpload = [self queryTable:TOTAL_TABLE Column:@"ecgUpload" in:db];
        NSInteger ecg = [self queryTable:TOTAL_TABLE Column:@"ecg" in:db];
        
        
        [self saveToUploadWithPath:[SynECGLibSingleton sharedInstance].filePathName keyNo:ecgUpload start:ecg end:(ecg + self.tempSaveData.length / 2) db:db];
        
        
        [SynECGLibSingleton sharedInstance].ecgInt = ecg + self.tempSaveData.length / 2;
        if ([SynECGLibSingleton sharedInstance].isSuspend == YES) {
            
            dispatch_resume([ECGDecodeManager sharedInstance].eventQueue);
            [SynECGLibSingleton sharedInstance].isSuspend = NO;
            
        }
        
        [self.tempSaveData resetBytesInRange:NSMakeRange(0, self.tempSaveData.length)];
        [self.tempSaveData setLength:0];
        
        
        [self deleteOthorMessage];
        
    }
    
}


- (void)saveECGZipAndDeleteOldMessage
{
    
        
        NSString *sourcePath = [SynECGLibSingleton sharedInstance].ecgTempFile;
        NSString *destZipFile = [sourcePath stringByReplacingOccurrencesOfString:@".dat" withString:@".zip"];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        ZipArchive * zipArchive = [[ZipArchive alloc]init];
        BOOL isdic;
        //判断sourcePath下是文件夹还是文件
        if(![fileManager fileExistsAtPath:sourcePath isDirectory:&isdic])
            return;//文件已存在，直接返回
        
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
    
}




//移除多余的dat文件

- (void)deleteOthorMessage
{
    NSString *sourcePath = [_docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"syn"]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *myDirectoryEnumerator = [fileManager enumeratorAtPath:sourcePath];  //baseSavePath 为文件夹的路径
    NSString *file;
    
    while((file = [myDirectoryEnumerator nextObject]))     //遍历当前目录
    {
        if([[file pathExtension] isEqualToString:@"dat"] && ![file isEqualToString:_filePathName] && ![file isEqualToString:@"ecgTemp"])  //取得后缀名为.xml的文件名
        {
            [self removeFileWith:[sourcePath stringByAppendingPathComponent:file]];
        }
    }
    
}


//移除多余的zip文件

- (void)deleteOthorZipMessage
{
    NSString *sourcePath = [_docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"syn"]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *myDirectoryEnumerator = [fileManager enumeratorAtPath:sourcePath];  //baseSavePath 为文件夹的路径
    NSString *file;
    
    while((file = [myDirectoryEnumerator nextObject]))     //遍历当前目录
    {
        if([[file pathExtension] isEqualToString:@"zip"] && (file.length > 5))  //取得后缀名为.xml的文件名
        {
            [self removeFileWith:[sourcePath stringByAppendingPathComponent:file]];
        }
    }
    
}


//查询字段
- (NSInteger)queryTable:(NSString *)tableName  Column:(NSString *)columnName in:(FMDatabase *)db
{
    NSString *query = [NSString stringWithFormat:@"select * from %@",tableName];
    FMResultSet *rs = [db executeQuery:query];
    NSInteger rr = 0;
    while ([rs next]) {
        rr = (NSInteger)[rs longLongIntForColumn:columnName];
        
    }
    return rr;
}



//修改字段
- (void)changeTable:(NSString *)tableName  Column:(NSString *)columnName value:(NSNumber *)value in:(FMDatabase *)db
{
    NSString *updateSql = [NSString stringWithFormat:
                           @"UPDATE %@ SET %@ = '%@' WHERE recordId = '%@'",tableName,columnName,value,[SynECGLibSingleton sharedInstance].record_id];
    [db executeUpdate:updateSql];
}



@end
