//
//  SubLineView.m
//  TimeLineView
//
//  Created by zzh_iPhone on 16/8/3.
//  Copyright © 2016年 zengjia. All rights reserved.
//

#import "lineChartShow.h"
#import "LineView.h"
#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGH ([UIScreen mainScreen].bounds.size.height)


@interface lineChartShow ()
@property (nonatomic, strong) LineView *lineView;

@end
@implementation lineChartShow

-(instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self layerBack];
        if (SCREEN_HEIGH > 667) {
            self.lineView = [[LineView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 278)];
        }else{
            self.lineView = [[LineView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 224)];

        }
        [self addSubview:self.lineView];
    }
    return self;
}
- (void)layerBack{

    
    NSInteger Ynum = (SCREEN_WIDTH - 12) / 28;
    double c = (SCREEN_WIDTH - Ynum*28)/2 ;
    NSInteger Xnum ;
    if (SCREEN_HEIGH > 667) {
        Xnum = 11;
    }else{
        Xnum = 9;
    }
    
    NSInteger  Xheight = 28;
    
    //先画出背景格子 248 * 342
    //先画粗线 粗线间隔：31 粗线直径：2  横竖12根粗线   左侧线距左边26
    
    NSMutableArray *verticalArray = [NSMutableArray array];//竖线粗线的点
    //竖线12
    for (int i = 0; i < Ynum+1; i++) {
        
        NSInteger x = c + 28 * i;
        [verticalArray addObject:[NSNumber numberWithInteger:x]];
        
        CAShapeLayer *layer2 = [CAShapeLayer layer];
        layer2.fillColor = nil;
        layer2.lineWidth = 2;
        layer2.strokeColor = [UIColor colorWithRed:251/255.0 green:173/255.0 blue:195/255.0 alpha:1].CGColor;
        layer2.path = [self getLineXLayerBezierPath:(CGFloat)x andY:Xheight * (Xnum - 1)].CGPath;
        [self.layer addSublayer:layer2];
    }
    
    NSMutableArray *horizontalArray = [NSMutableArray array];
    //横线9
    for (int i = 0; i < Xnum; i++) {
        
        NSInteger y =  Xheight * i;
        [horizontalArray addObject:[NSNumber numberWithInteger:y]];
        
        CAShapeLayer *layer2 = [CAShapeLayer layer];
        layer2.fillColor = nil;
        layer2.lineWidth = 2;
        layer2.strokeColor = [UIColor colorWithRed:251/255.0 green:173/255.0 blue:195/255.0 alpha:1].CGColor;
        layer2.path = [self getLineYLayerBezierPath:(CGFloat)c andX:(CGFloat)y].CGPath;
        [self.layer addSublayer:layer2];
    }

    for (int i = 0; i < [verticalArray count] - 1; i++) {
        //每一根竖线粗线的x值
        NSInteger x = [[verticalArray objectAtIndex:i] integerValue];
        
        //计算细线的x值
        x += 2 + 4.4;//每一个格子第一根细线的x值
        
        for (int i = 0; i < 4; i++) {
            CAShapeLayer *layer2 = [CAShapeLayer layer];
            layer2.fillColor = nil;
            layer2.lineWidth = 1;
            layer2.strokeColor = [UIColor colorWithRed:251/255.0 green:173/255.0 blue:195/255.0 alpha:1].CGColor;
            layer2.path = [self getLineXLayerBezierPath:(CGFloat)(x+5.4*i) andY:Xheight * (Xnum - 1)].CGPath;
            [self.layer addSublayer:layer2];
        }
    }
    
    for (int i = 0 ; i < [horizontalArray count] - 1; i++) {
        //每一根横线粗线的y值
        NSInteger y = [[horizontalArray objectAtIndex:i] integerValue];
        y +=6.4;
        for (int i = 0; i < 4; i++) {
            CAShapeLayer *layer2 = [CAShapeLayer layer];
            layer2.fillColor = nil;
            layer2.lineWidth = 1;
            layer2.strokeColor = [UIColor colorWithRed:251/255.0 green:173/255.0 blue:195/255.0 alpha:1].CGColor;
            layer2.path = [self getLineYLayerBezierPath:(CGFloat)c andX: y +  5.4 * i].CGPath;
            [self.layer addSublayer:layer2];
        }
    }

}

- (UIBezierPath *)getLineXLayerBezierPath:(CGFloat)num andY:(CGFloat)yValue{
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(num, 0)];
    [bezierPath addLineToPoint:CGPointMake(num, yValue)];
    [bezierPath closePath];
    return bezierPath;
}
- (UIBezierPath *)getLineYLayerBezierPath:(CGFloat)num andX:(CGFloat)xValue{
    NSInteger Ynum = (SCREEN_WIDTH - 12) / 28;
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(num,xValue)];
    
    [bezierPath addLineToPoint:CGPointMake(Ynum*28+num, xValue)];
    [bezierPath closePath];
    return bezierPath;
}
-(void)syn_ecgShowECGWithData:(NSData *)array
{
    [self.lineView syn_ecgShowECGWithData:array];
}
- (void)syn_ecgHubECG{
    [self.lineView syn_ecgHubECG];
}
- (void)syn_ecgDissECG{
    [self.lineView syn_ecgDissECG];
}

- (void)syn_getPersentValue:(NSInteger)value{
    [self.lineView syn_getPersentValue:value];
}
- (void)syn_remove{
    [self.lineView syn_remove];
}
@end
