//
//  RequestManager.h
//  libSynECG
//
//  Created by LiangXiaobin on 16/6/29.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "AFNetworking.h"
#import <AFNetworking/AFNetworking.h>

typedef void(^CommonBlockCompletion)(id obj);

@interface RequestManager : NSObject<NSURLSessionDelegate,NSURLSessionDataDelegate>
//AFNetworking
@property (nonatomic, readonly, getter = manager) AFHTTPSessionManager *manager;
//创建单例
+ (instancetype)sharedInstance;

//post请求；
- (void)postParameters:(NSDictionary *)params Url:(NSString *)url sucessful:(CommonBlockCompletion)success failure:(CommonBlockCompletion)failure;

//下载任务
- (void)downloadWithUrl:(NSString *)urlStr sucessful:(CommonBlockCompletion)success failure:(CommonBlockCompletion)failure downloadProgress:(void (^)(NSProgress *downloadProgress))progress;

//上传任务
- (void)uploadWithUrl:(NSString *)url parameters:(NSDictionary *)params fileUrl:(NSString *)fileUrl name:(NSString *)name  sucessful:(CommonBlockCompletion)success failure:(CommonBlockCompletion)failure;

//网络状态
+ (BOOL)isNetworkReachable;

@end
