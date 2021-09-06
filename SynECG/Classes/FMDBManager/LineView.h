//
//  LineView.h
//  SynECG
//
//  Created by zzh_iPhone on 2017/6/6.
//  Copyright © 2017年 LiangXiaobin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LineView : UIView
-(void)syn_ecgShowECGWithData:(NSData *)array;
- (void)syn_ecgHubECG;
- (void)syn_ecgDissECG;
- (void)syn_remove;
- (void)syn_getPersentValue:(NSInteger)value;
@end
