//
//  SubLineView.h
//  TimeLineView
//
//  Created by zzh_iPhone on 16/8/3.
//  Copyright © 2016年 zengjia. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface lineChartShow : UIView
-(void)syn_ecgShowECGWithData:(NSData *)array;
- (void)syn_ecgHubECG;
- (void)syn_ecgDissECG;
- (void)syn_remove;
- (void)syn_getPersentValue:(NSInteger)value;
@end
