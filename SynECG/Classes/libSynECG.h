//
//  libSynECG.h
//  libSynECG
//
//  Created by LiangXiaobin on 16/6/29.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void(^CommonBlockCompletion)(id obj);

@interface libSynECG : NSObject

/**
 *  初始化
 */

+ (instancetype)sharedInstance;

/*
 *更新库
 */
- (void)updateRealmConfig;

- (void)getRecordId:(CommonBlockCompletion)completionCallback;

/**
 *  本地登录
 *
 *  @param params             登录参数
 *  @param completionCallback 回调
 */
- (void)syn_ecgWriteinWith:(NSDictionary *)params completion:(CommonBlockCompletion)completionCallback;
/**
 *  登录接口
 *
 *  @param params             登录参数，包括userId和token;
 *  @param completionCallback 回调
 */

- (void)syn_ecgLoginWith:(NSDictionary *)params completion:(CommonBlockCompletion)completionCallback;

/**
 *  设置用户信息接口
 *
 *  @param params             用户信息
 *  @param completionCallback 回调
 */
- (void)syn_ecgGetInfoWith:(NSDictionary *)params completion:(CommonBlockCompletion)completionCallback;
/**
 *  退出登录
 */
- (void)syn_ecgLogout;

/**
 *  绑定设备
 *
 *  @param params             设备信息
 *  @param completionCallback 回调
 */
 - (void)syn_ecgAddDeviceWith:(NSDictionary *)params completion:(CommonBlockCompletion)completionCallback;

/**
 *  解绑设备
 *
 *  @param params             设备信息
 *  @param completionCallback 回调
 */
- (void)syn_ecgDeleteDeviceWith:(NSDictionary *)params completion:(CommonBlockCompletion)completionCallback;

/**
 *  更换设备
 *
 *  @param params             设备信息
 *  @param completionCallback 回调
 */
- (void)syn_ecgChangeDeviceWith:(NSDictionary *)params completion:(CommonBlockCompletion)completionCallback;

/**
 *  上传症状
 *
 *  @param params             症状信息
 *  @param completionCallback 回调
 */
- (void)syn_ecgUpSymptomWith:(NSDictionary *)params completion:(CommonBlockCompletion)completionCallback;
@end
