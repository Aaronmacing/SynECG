//
//  SDBManager.m
//  SDatabase
//
//  Created by SunJiangting on 12-10-20.
//  Copyright (c) 2012年 sun. All rights reserved.
//

#import "SDBManager.h"


@interface SDBManager () {

    NSString *filePath;
}

@end

@implementation SDBManager

static SDBManager * _sharedDBManager;

+ (SDBManager *) defaultDBManager {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedDBManager = [[SDBManager alloc] init];
    });
    
	return _sharedDBManager;
    /**
     *  以线程安全的方式执行单例
     */
}

- (void) dealloc {
    
    [self close];
}

- (id) init {
    self = [super init];
    if (self) {
        int state = [self initializeDBWithName:kDefaultDBName];
        if (state == -1) {
            NSLog(@"数据库初始化失败");
        } else {
            if (state == 0) {
                NSLog(@"数据库创建失败");
            }else {
                NSLog(@"数据库初始化成功");
            }
        }
    }
    return self;
}

/**
 * @brief 初始化数据库操作
 * @param name 数据库名称
 * @return 返回数据库初始化状态， 0 为 已经存在，1 为创建成功，-1 为创建失败
 */
- (int) initializeDBWithName : (NSString *) name {
    if (!name) {
		return -1;  // 返回数据库创建失败
	}
    // 沙盒Docu目录
    NSString * docp = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    NSString *totalPath = [docp stringByAppendingString:[NSString stringWithFormat:@"/syn"]];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSError *error = nil;
    if (![fileManager isExecutableFileAtPath:totalPath])
    {
        [fileManager createDirectoryAtPath:totalPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            return 0;
        }
        else
        {
            filePath = [totalPath stringByAppendingString:[NSString stringWithFormat:@"/%@",name]];
            NSLog(@"%@",filePath);
            
            
       
                [fileManager createFileAtPath:filePath contents:nil attributes:nil];
                
                if (![fileManager fileExistsAtPath:filePath]) {
                    return 0;
                }else {
                    [self connect];
                    return 1;
                }
     
        }
    }
    else
    {
        filePath = [totalPath stringByAppendingString:[NSString stringWithFormat:@"/%@",name]];
        NSLog(@"%@",filePath);
        
        
        BOOL exist = [fileManager fileExistsAtPath:filePath];
        
        if (!exist)
        {
            
            //在沙盒中创建文件ECIP.db,并将NSBundle里面的ECIP文件内容存入沙盒
            /**
             *  创建文件
             */
            [fileManager createFileAtPath:filePath contents:nil attributes:nil];
            
            if (![fileManager fileExistsAtPath:filePath]) {
                return 0;
            }else {
                [self connect];
                return 1;
            }
        }
        else
        {
            [self connect];
            return 1;          // 返回 数据库已经存在
            
        }

    }
}

- (void)creatFolderBy:(NSFileManager *)manager withFileName:(NSString *)name
{
    BOOL creat = [manager createDirectoryAtPath:name withIntermediateDirectories:YES attributes:@{NSFileProtectionKey: NSFileProtectionNone} error:nil];
    
    NSLog(@"文件创建%d",creat);
    if (!creat) {
        [self creatFolderBy:manager withFileName:name];
    }
}



- (NSString *)dataPath {

    return filePath;
}

/// 连接数据库
- (void) connect {
//	if (!_dataBase) {
//		_dataBase = [[FMDatabase alloc] initWithPath:filePath];
//	}
//	if (![_dataBase open]) {
//		NSLog(@"不能打开数据库");
//	}
//    
    if (!_queue) {
        _queue = [FMDatabaseQueue databaseQueueWithPath:filePath];
    }
    
}
/// 关闭连接
- (void) close {
	[_dataBase close];
    _sharedDBManager = nil;
}

//删除数据库
-(void)deleteDatabse {

    BOOL success;
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //delete the old db
    if ([fileManager fileExistsAtPath:filePath]) {
        [_dataBase close];
        success = [fileManager removeItemAtPath:filePath error:&error];
        if (!success) {
            NSLog(@"Failed to delete old database file with message '%@'.", [error localizedDescription]);
        }
    }
}

@end
