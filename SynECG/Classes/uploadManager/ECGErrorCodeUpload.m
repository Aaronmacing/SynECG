//
//  ECGErrorCodeUpload.m
//  SynECG
//
//  Created by LiangXiaobin on 2017/8/4.
//  Copyright © 2017年 LiangXiaobin. All rights reserved.
//

#import "ECGErrorCodeUpload.h"
#import "SynECGUtils.h"
#import "SynECGLibSingleton.h"
#import "RequestManager.h"
#import "SynConstant.h"

@implementation ECGErrorCodeUpload
+ (instancetype)sharedInstance
{
    static ECGErrorCodeUpload * sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)uploadErrorMessageWith:(NSDictionary *)params
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *appVer = [NSString stringWithFormat:@"v%@",app_Version];
    
    [dic setObject:@[params] forKey:@"reqVos"];
    [dic setObject:[SynECGLibSingleton sharedInstance].user_id forKey:@"userId"];
    [dic setObject:[[UIDevice currentDevice] systemVersion] forKey:@"osVer"];
    [dic setObject:appVer forKey:@"appVer"];
    [dic setObject:@"HEALTH" forKey:@"appType"];
    [dic setObject:[[UIDevice currentDevice] model] forKey:@"phoneBrand"];
    
    [[RequestManager sharedInstance]postParameters:dic Url:ERROR_UPLOAD_URL sucessful:^(id obj) {
        
    } failure:^(id obj) {
        
    }];

    
}





@end
