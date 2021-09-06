//
//  ZYFMDB.m
//  AirQualityDemo
//
//  Created by 邱虎龙 on 15-1-20.
//  Copyright (c) 2015年 邱虎龙. All rights reserved.
//

#import "ZYFMDB.h"

#define kUserTableName @"SUseresssss"

@implementation ZYFMDB

-(id)init {

    self = [super init];
    if (self) {
        /**
         *  首先查看有没有建立message的数据库，如果未建立，则建立数据库
         */
        _db = [SDBManager defaultDBManager].dataBase;
        _queue = [SDBManager defaultDBManager].queue;
        
    }
    return self;
}

/**
 *  判断是否存在表
 */


- (void)creatTableWithName:(NSString *)tableName withArguments:(NSString *)arguments
{
    [_queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs = [db executeQuery:[NSString stringWithFormat:@"select count(*) from sqlite_master where type = 'table' and name = '%@'",tableName]];
        [rs next];
        NSInteger count = [rs intForColumnIndex:0];
        BOOL existTable = !!count;
       
        if (existTable == NO) {
            
            NSString *sqlstr = [NSString stringWithFormat:@"create table if not exists %@ (%@)",tableName,arguments];
            if (![db executeUpdate:sqlstr]) {
                NSLog(@"Create db error!");//建表失败
            
            }
        }
        
        
        
    }];
}

- (void)deleteTableMessageByName:(NSString *)tableName
{
    [_queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
       
        NSString *sqlstr = [NSString stringWithFormat:@"DELETE FROM %@",tableName];
        [db executeUpdate:sqlstr];

    }];
}





- (BOOL)isTableOK:(NSString *)tableName {

    FMResultSet *rs = [_db executeQuery:[NSString stringWithFormat:@"select count(*) from sqlite_master where type = 'table' and name = '%@'",tableName]];
    [rs next];
    NSInteger count = [rs intForColumnIndex:0];
    BOOL existTable = !!count;
    return existTable;
}


/**
 *  判断该数据是否已经存在，用来保证没有同名的成员
 *
 *  @param tableName 表名
 *  @param column    通过什么字段（列）来判断  例如：siteName
 *  @param name      你要插入的数据的该字段的值      成都市
 *
 *  @return bool值
 */
- (BOOL)isColumnOK:(NSString *)tableName column:(NSString *)column name:(NSString *)name {

    FMResultSet *rs = [_db executeQuery:[NSString stringWithFormat:@"select count(%@) as countNum from %@ where %@ = '%@'",column,tableName,column,name]];
    while ([rs next]) {
        NSInteger count = [rs intForColumn:@"countNum"];
        if (count > 0) {
            //同名成员已经存在
            return YES;
        }
        
        return NO;
    }
    
    return YES;
}


/**
 *  创建表
   比如：NSString * sql = @"CREATE TABLE SUsered (uid INTEGER PRIMARY KEY AUTOINCREMENT  NOT NULL, name VARCHAR(50), description VARCHAR(100))";
 *
 *  @param tableName: SUsered
 *  @param arguments: uid INTEGER PRIMARY KEY AUTOINCREMENT  NOT NULL, name VARCHAR(50), description VARCHAR(100)
 *
 *  @return BOOL值
 */
- (BOOL) createTable:(NSString *)tableName withArguments:(NSString *)arguments {

    NSString *sqlstr = [NSString stringWithFormat:@"CREATE TABLE %@ (%@)",tableName,arguments];
    if (![_db executeUpdate:sqlstr]) {
        NSLog(@"Create db error!");//建表失败
        return NO;
    }
    return YES;
}


- (BOOL)creatExistsTable:(NSString *)tableName withArguments:(NSString *)arguments
{
    NSString *sqlstr = [NSString stringWithFormat:@"create table if not exists %@ (%@)",tableName,arguments];
    if (![_db executeUpdate:sqlstr]) {
        NSLog(@"Create db error!");//建表失败
        return NO;
    }
    return YES;

}




/**
 *  删除表 --彻底删除表
 */
- (BOOL)deleteTable:(NSString *)tableName {

    NSString *sqlstr = [NSString stringWithFormat:@"DROP TABLE %@",tableName];
    if (![_db executeUpdate:sqlstr]) {
        NSLog(@"Delete table error!");//表删除失败
        return NO;
    }
    return YES;
}

/**
 *  清空表 -- 清空表数据
 */
- (BOOL)eraseTable:(NSString *)tableName {

    NSString *sqlstr = [NSString stringWithFormat:@"DELETE FROM %@",tableName];
    if (![_db executeUpdate:sqlstr]) {
        NSLog(@"Erase table error!");//清空失败
        return NO;
    }
    
    return YES;
}

/**
 *  插入一条数据
 */
- (BOOL)executeUpdate:(NSString*)sql withArgumentsInArray:(NSArray *)arguments {

    return [_db executeUpdate:sql withArgumentsInArray:arguments];
}

/**
 *  删除一条数据
 */
- (BOOL)deleteData:(NSString*)sql, ... {

   return [_db executeUpdate:sql];
}

/**
 *  查询表中的数据
 */
- (void)queryTable:(NSString *)tableName
            result:(query)result {

    FMResultSet *rs = [_db executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@",tableName]];
    result(rs);
}


////将视频列表数据JSON化，存进数据库
//- (void)storageHomelistData:(NSDictionary *)dic {
//    
//    
//    ZYFMDB *_db = [[ZYFMDB alloc]init];
//    
//    //添加新信息
//    NSMutableString *query = [NSMutableString stringWithFormat:@"INSERT INTO %@",@"allindex"];
//    NSMutableString *keys = [NSMutableString stringWithFormat:@" ("];
//    NSMutableString *values = [NSMutableString stringWithFormat:@" ( "];
//    NSMutableArray *arguments = [NSMutableArray array];
//    
//    for (NSString *key in dic) {
//        [keys appendString:[NSString stringWithFormat:@"%@,",key]];
//        [values appendString:@"?,"];
//        [arguments addObject:[dic objectForKey:key]];
//    }
//    
//    [keys appendString:@")"];
//    [values appendString:@")"];
//    [query appendFormat:@" %@ VALUES%@",[keys stringByReplacingOccurrencesOfString:@",)" withString:@")"],[values stringByReplacingOccurrencesOfString:@",)" withString:@")"]];
//    
//    BOOL flag = [_db executeUpdate:query withArgumentsInArray:arguments];
//    if (flag) {
//        NSLog(@"allindex信息存储成功");
//        
//        [_db queryTable:@"allindex" result:^(FMResultSet *data) {
//            while ([data next]) {
//                NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[self getDataFromResultSet:data]];
//                NSLog(@"dic:%@",dic);
//            }
//        }];
//        
//    }else {
//        NSLog(@"allindex信息存储失败");
//    }
//}
//
//- (NSMutableDictionary *)getDataFromResultSet:(FMResultSet *)data {
//    
//    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
//    for (int i = 0; i < data.columnCount; i++) {
//        NSString *key = [data columnNameForIndex:i];
//        NSString *string = [data stringForColumn:key];
//        if (string == nil) {
//            
//            string = @"";
//        }
//        [dic setObject:string forKey:key];
//    }
//    
//    return dic;
//}

@end
