//
//  ZYFMDB.h
//  AirQualityDemo
//
//  Created by 邱虎龙 on 15-1-20.
//  Copyright (c) 2015年 邱虎龙. All rights reserved.
//FMDB使用

#import <Foundation/Foundation.h>
#import "SDBManager.h"


typedef void (^query)(FMResultSet *data);

@interface ZYFMDB : NSObject {

    FMDatabase *_db;
    FMDatabaseQueue *_queue;
}


/**
 *  判断是否存在表,不存在就创建新的
 */

- (void)creatTableWithName:(NSString *)tableName withArguments:(NSString *)arguments;

/*
 * 移除表
 */
- (void)deleteTableMessageByName:(NSString *)tableName;

/**
 *  判断是否存在表
 */

- (BOOL)isTableOK:(NSString *)tableName;

/**
 *  判断该数据是否已经存在，用来保证没有同名的成员
 *
 *  @param tableName 表名
 *  @param column    通过什么字段（列）来判断  例如：siteName
 *  @param name      你要插入的数据的该字段的值      成都市
 *
 *  @return bool值
 */
- (BOOL)isColumnOK:(NSString *)tableName column:(NSString *)column name:(NSString *)name;


/**
 *  创建表
 *
 */
- (BOOL) createTable:(NSString *)tableName withArguments:(NSString *)arguments;

/*
 *不存在时创建表
 */
- (BOOL)creatExistsTable:(NSString *)tableName withArguments:(NSString *)arguments;



/**
 *  删除表 --彻底删除表
 */
- (BOOL)deleteTable:(NSString *)tableName;

/**
 *  清空表 -- 清空表数据
 */
- (BOOL)eraseTable:(NSString *)tableName;

/**
 *  插入一条数据
 */
- (BOOL)executeUpdate:(NSString*)sql withArgumentsInArray:(NSArray *)arguments;

/**
 *  删除一条数据
 */
- (BOOL)deleteData:(NSString*)sql, ...;

/**
 *  查询表中的数据
 */
- (void)queryTable:(NSString *)tableName
            result:(query)result;



@end
