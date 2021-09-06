//
//  ECGErrorCodeUpload.h
//  SynECG
//
//  Created by LiangXiaobin on 2017/8/4.
//  Copyright © 2017年 LiangXiaobin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ECGErrorCodeUpload : NSObject
+ (instancetype)sharedInstance;
- (void)uploadErrorMessageWith:(NSDictionary *)params;
@end
