//
//  LineView.m
//  SynECG
//
//  Created by zzh_iPhone on 2017/6/6.
//  Copyright © 2017年 LiangXiaobin. All rights reserved.
//

#import "LineView.h"
#import "XLBallLoading.h"
#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGH ([UIScreen mainScreen].bounds.size.height)

@interface LineView()
{
    NSMutableArray *_ECGYArray;//心电图y坐标
    BOOL _isLabelSet;
    BOOL _show;
    CGFloat _start;
    CGFloat _h;
    NSInteger index;
    NSInteger dataIndex;
    NSInteger statusIndex;

}
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UILabel *label1;
@property (nonatomic, strong) UIImageView *label2;
@property (nonatomic, strong) UILabel *label3;
@end

@implementation LineView
-(instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _ECGYArray = [NSMutableArray array];
        dataIndex = 0;
        statusIndex = 1;
        if (SCREEN_HEIGH > 667) {
            _h = 278;
        }else{
            _h = 224;
        }
        _label = [[UILabel alloc]initWithFrame:CGRectMake(28+75, _h-30, 75, 30)];
        _label.tag = 33;
        _label.textColor = [UIColor blackColor];
        _label.font= [UIFont systemFontOfSize:16];
        _label.text = @"10.0mm/mV";
        _label.textAlignment = NSTextAlignmentCenter;
        
        _label3 = [[UILabel alloc]initWithFrame:CGRectMake(28, _h-30, 150, 30)];
        _label3.tag = 88;
        _label3.hidden = YES;
        _label3.adjustsFontSizeToFitWidth = YES;
        _label3.textColor = [UIColor blackColor];
        _label3.font= [UIFont systemFontOfSize:16];
        _label3.text = @"补偿数据进度:--%";
        _label3.textAlignment = NSTextAlignmentCenter;
        
        
        _label2 = [[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH/2-20,_h/2-20 , 40, 40)];
        _label2.image = [UIImage imageNamed:@"playImg"];
        
        
        _label1 = [[UILabel alloc]initWithFrame:CGRectMake(28, _h-30, 75, 30)];
        _label1.tag = 34;
        _label1.textColor = [UIColor blackColor];
        _label1.font= [UIFont systemFontOfSize:16];
        _label1.text = @"25.0mm/s";
        _label1.textAlignment = NSTextAlignmentCenter;
        UIPinchGestureRecognizer *pan=[[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(panAction:)];
        [self addGestureRecognizer:pan];
        UITapGestureRecognizer* singleRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction:)];
        _show = YES;
        _label2.hidden = YES;
        [self addGestureRecognizer:singleRecognizer];
        [self addSubview:_label2];
        [self addSubview:_label];
        [self addSubview:_label1];
        [self addSubview:_label3];
        
        //        NSArray *arr = @[@"1.5",@"1.0",@"0.5",@"0",@"-0.5",@"-1.0",@"-1.5"];
        //        for (int i = 0; i < 7; i++) {
        //            UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0,0, 24, 10)];
        //            label.tag = i;
        //            label.text = arr[i];
        //            label.textAlignment = NSTextAlignmentRight;
        //            label.font = [UIFont systemFontOfSize:10];
        //            label.center = CGPointMake(label.center.x, 28*i);
        //            [self addSubview:label];
        //        }
    }
    return self;
}



-(void)syn_ecgShowECGWithData:(NSData *)array{
    
    if (_show == NO) {
        return;
    }
    NSInteger Xheight = self.bounds.size.height / 3;
    NSInteger Ynum1 = (self.bounds.size.width - 12) / 28;
    NSInteger Ynum = 0;
    switch (statusIndex) {
        case 0:
            Ynum = (Ynum1*28)/0.27;
            
            break;
        case 1:
            Ynum = (Ynum1*28)/0.54;
            
            break;
        case 2:
            Ynum = (Ynum1*28)/1.08;
            break;
        default:
            break;
    }
    NSMutableArray *ECGData =[NSMutableArray new];
    Byte *c = (Byte*)[array bytes];
    for (int i = 2; i<array.length-2; i+=3) {
        @autoreleasepool {
            short  a = (((short)(char)c[i])<<4)|((c[i+1]>>4)&0x0f);
            short  b = (((short)((char)(c[i+1]<<4))<<4)&0xff00)|(c[i+2]&0x00ff);
            float f = a/273.f;
            float g = b/273.f;
            [ECGData addObject:[NSString stringWithFormat:@"%f",f]];
            [ECGData addObject:[NSString stringWithFormat:@"%f",g]];
        }
    }
    
    for (int i = 0; i<ECGData.count; i++) {
        double _yECG = 7.5 - [ECGData[i]doubleValue];
        double _y = _yECG * Xheight;
        //            [_ECGYArray insertObject:[NSNumber numberWithDouble:_y] atIndex:0];
        if ([_ECGYArray count] <Ynum) {
            [_ECGYArray addObject:[NSNumber numberWithDouble:_y]];
        }else{
            
            [_ECGYArray replaceObjectAtIndex:dataIndex withObject:[NSNumber numberWithDouble:_y]];//最多111个点
            if (dataIndex == Ynum-1) {
                dataIndex = 0;
            }else{
                dataIndex = dataIndex+1;
            }
        }
        
        //            if ([_ECGYArray count] > Ynum) {
        //                [_ECGYArray removeLastObject];//最多111个点
        //            }
    }
    CGFloat maxValue = [[_ECGYArray valueForKeyPath:@"@max.floatValue"] floatValue];
    CGFloat minValue = [[_ECGYArray valueForKeyPath:@"@min.floatValue"] floatValue];
    if (maxValue - minValue <= 224) {
        _start = (maxValue + minValue)*0.5-112;
        index = 1;
        _label.text = @"10.0mm/mV";
    }else if(maxValue -minValue <= 448){
        _start = (maxValue + minValue)*0.25-112;
        index = 2;
        _label.text = @" 5.0mm/mV";
        
    }else if (maxValue - minValue <= 896){
        _start = (maxValue + minValue)*0.175-112;
        index = 3;
        _label.text = @"2.5mm/mV";
    }else{
        _label.text = @"1.25mm/mV";
        _start = (maxValue + minValue)*0.5-112;
        index = 4;
    }
    [self setNeedsDisplay];


}

- (void)drawRect:(CGRect)rect{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 2);
    UIColor *color = [UIColor colorWithRed:251/255.0 green:173/255.0 blue:195/255.0 alpha:1];
    [color set];
    
    
    NSInteger Ynum = (self.bounds.size.width - 12) / 28;
    double c = (self.bounds.size.width - Ynum*28)/2 ;
    NSInteger Xnum =  31;
    NSInteger  Xheight = 28;
    
    //心电图画图
    CGContextSetLineWidth(context, 1);
    color = [UIColor blackColor];
    [color set];
    
    if ([_ECGYArray count] == 0) {
        return;
    }
    double _y = [[_ECGYArray objectAtIndex:0]doubleValue];
    //    double _y = [[_ECGYArray lastObject]doubleValue];
    //    NSInteger _x = self.bounds.size.width-10;
    NSInteger _x = c;
    NSMutableArray *xE = [NSMutableArray new];
    NSInteger Ynum1 = (self.bounds.size.width - 12) / 28;
    NSInteger Ynum2 = 0;
    switch (statusIndex) {
        case 0:
            Ynum2 = (Ynum1*28)/0.27;
            break;
        case 1:
            Ynum2 = (Ynum1*28)/0.54;
            break;
        case 2:
            Ynum2 = (Ynum1*28)/1.08;
            break;
        default:
            break;
    }
    //    NSInteger Ynum2 = (Ynum1*28)/0.54;
    for (int i=0 ; i<Ynum2; i++) {
        //        double a = self.bounds.size.width-10-i*0.54;
        //        double a = 26+i*0.54;
        double a = 0;
        switch (statusIndex) {
            case 0:
                a = c+i*0.27;
                break;
            case 1:
                a = c+i*0.54;
                break;
            case 2:
                a = c+i*1.08;
                break;
            default:
                break;
        }
        [xE addObject:@(a)];
    }
    CGContextMoveToPoint(context, _x, _y/index-_start);
    for (int i =0; i < [_ECGYArray count]; i++) {
        double _y = [[_ECGYArray objectAtIndex:i]doubleValue];
        double _x = [xE[i] doubleValue];
        if (dataIndex == i || (dataIndex ==0 && [_ECGYArray count] == i+1)){
            CGContextMoveToPoint(context, _x, 0);
            CGContextAddLineToPoint(context, _x,  Xheight * (Xnum - 1));
        }else{
            CGContextAddLineToPoint(context, _x, _y/index-_start);
        }
    }
    CGContextStrokePath(context);

    
//    if (dataIndex >= 100) {
//        NSArray *arr = [_ECGYArray subarrayWithRange:NSMakeRange(dataIndex-100, 100)];
//        for (int i = 0; i<99; i++) {
//            CGContextSetLineWidth(context, 4);
//            NSArray * a = [self transColorBeginColor:[UIColor colorWithRed:251/256.f green:218/256.f blue:111/256.f alpha:0] andEndColor:[UIColor colorWithRed:230/256.f green:131/256.f blue:250/256.f alpha:1]];
//            double c = (double)i/100;
//            color = [self getColorWithColor:[UIColor colorWithRed:251/256.f green:218/256.f blue:111/256.f alpha:0] andCoe:c andMarginArray:a];
//            [color set];
//            double _y = [[arr objectAtIndex:i]doubleValue];
//            double _x = [xE[i+dataIndex-100] doubleValue];
//            double _y1 = [[arr objectAtIndex:i+1]doubleValue];
//            double _x1 = [xE[i+1+dataIndex-100] doubleValue];
//            CGContextMoveToPoint(context, _x, _y/index-_start);
//            CGContextAddLineToPoint(context, _x1, _y1/index-_start);
//            CGContextStrokePath(context);
//        }
//    }
    
//    CGContextSetLineWidth(context, 2);
//    color = [UIColor yellowColor];
//    [color set];
//    for (int i =0; i < [_ECGYArray count]; i++) {
//        double _y = [[_ECGYArray objectAtIndex:i]doubleValue];
//        double _x = [xE[i] doubleValue];
//        if (dataIndex-100 == i) {
//            CGContextMoveToPoint(context, _x, _y/index-_start);
//
//        }
//        if (i > dataIndex-100 && i < dataIndex) {
//            CGContextAddLineToPoint(context, _x, _y/index-_start);
//        }
//    }
//    CGContextStrokePath(context);
    

}
- (void)syn_ecgHubECG{
    if (_isLabelSet) {
        
    }else{
        _isLabelSet = YES;
        _label3.hidden = NO;
        _label.hidden = YES;
        _label1.hidden = YES;
        [XLBallLoading showInView:self];
    }

}
- (void)syn_ecgDissECG{
    if (_isLabelSet) {
        _isLabelSet = NO;
        _label3.hidden = YES;
        _label.hidden = NO;
        _label1.hidden = NO;
        [XLBallLoading hideInView:self];
    }

}
- (void)syn_remove{
    [_ECGYArray removeAllObjects];
    dataIndex = 0;
    statusIndex = 1;
    [self setNeedsDisplay];
    _show = YES;
    _label2.hidden = YES;
    _label3.hidden = YES;
    _label1.hidden = NO;
    _label.hidden = NO;

}
- (void)syn_getPersentValue:(NSInteger)value{
    _label3.text = [NSString stringWithFormat:@"补偿数据进度：%ld%%",(long)value];
}

- (void)panAction:(UIPinchGestureRecognizer *)sender{
    if(sender.state == UIGestureRecognizerStateEnded){
        if (sender.scale >0 && sender.velocity >0) {
            NSLog(@"$$$");
            if (statusIndex == 1) {
                [_ECGYArray removeAllObjects];
                dataIndex = 0;
                _label1.text = @"50.0mm/s";
                statusIndex = 2;
            }else if (statusIndex == 0){
                [_ECGYArray removeAllObjects];
                dataIndex = 0;
                statusIndex = 1;
                _label1.text = @"25.0mm/s";
            }else{
                return;
            }
        }else if (sender.scale >0 && sender.scale<1 && sender.velocity < -1){
            NSLog(@"!!!");
            if (statusIndex == 1) {
                [_ECGYArray removeAllObjects];
                dataIndex = 0;
                _label1.text = @"12.5mm/s";
                statusIndex = 0;
            }else if (statusIndex == 2){
                [_ECGYArray removeAllObjects];
                dataIndex = 0;
                statusIndex = 1;
                _label1.text = @"25.0mm/s";
            }else{
                return;
            }
        }
    }
}

- (void)tapAction:(UIGestureRecognizer*)sender{
    if (_show == NO) {
        _label2.hidden = YES;
        _label1.hidden = NO;
        _label.hidden = NO;
    }else{
        _label2.hidden = NO;
        _label1.hidden = YES;
        _label.hidden = YES;
    }
    _show = !_show;
}

- (NSArray *)getRGBDictionaryByColor:(UIColor *)originColor
{
    CGFloat r=0,g=0,b=0,a=0;
    if ([self respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
        [originColor getRed:&r green:&g blue:&b alpha:&a];
    }
    else {
        const CGFloat *components = CGColorGetComponents(originColor.CGColor);
        r = components[0];
        g = components[1];
        b = components[2];
        a = components[3];
    }
    return @[@(r),@(g),@(b)];
}
- (NSArray *)transColorBeginColor:(UIColor *)beginColor andEndColor:(UIColor *)endColor {
    NSArray<NSNumber *> *beginColorArr = [self getRGBDictionaryByColor:beginColor];
    NSArray<NSNumber *> *endColorArr = [self getRGBDictionaryByColor:endColor];
//    NSArray<NSNumber *> *endColorArr = @[@(1.0),@(1.0),@(1.0)];
    return @[@([endColorArr[0] doubleValue] - [beginColorArr[0] doubleValue]),@([endColorArr[1] doubleValue] - [beginColorArr[1] doubleValue]),@([endColorArr[2] doubleValue] - [beginColorArr[2] doubleValue])];
}

- (UIColor *)getColorWithColor:(UIColor *)beginColor andCoe:(double)coe andMarginArray:(NSArray<NSNumber *> *)marginArray {
    NSArray *beginColorArr = [self getRGBDictionaryByColor:beginColor];
    double red = [beginColorArr[0] doubleValue] + coe * [marginArray[0] doubleValue];
    double green = [beginColorArr[1] doubleValue]+ coe * [marginArray[1] doubleValue];
    double blue = [beginColorArr[2] doubleValue] + coe * [marginArray[2] doubleValue];
    return [UIColor colorWithRed:red green:green blue:blue alpha:1];
    
}
@end
