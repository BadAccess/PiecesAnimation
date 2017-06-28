//
//  ViewController.m
//  test
//
//  Created by ZhengWei on 2017/3/14.
//  Copyright © 2017年 ZhengWei. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UIScrollViewDelegate>
@property (nonatomic, strong) NSMutableArray *booms;
@property (nonatomic, strong) UIImageView *imageView;
@end

NSInteger cellCount = 30;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //     Do any additional setup after loading the view, typically from a nib.
    self.booms = [[NSMutableArray alloc] init];
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    self.imageView.image = [UIImage imageNamed:@"ios.jpg"];
    [self.view addSubview:self.imageView];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self boom];
}

-(void)boom{
    [self.booms removeAllObjects];
    for(int i = 0 ; i < cellCount ; i++){
        for(int j = 0 ; j < cellCount ; j++){
            CGFloat pWidth = MIN(self.imageView.frame.size.width, self.imageView.frame.size.height)/cellCount;
            CALayer *boomCell = [CALayer layer];
            boomCell.backgroundColor = [self getPixelColorAtLocation:CGPointMake(i*2, j*2)].CGColor;
            //            boomCell.cornerRadius = pWidth/2;
            boomCell.frame = CGRectMake(i*pWidth, j*pWidth, pWidth, pWidth);
            [self.imageView.layer.superlayer addSublayer:boomCell];
            [self.booms addObject:boomCell];
        }
    }
    //粉碎动画
    [self cellAnimation];
    //缩放消失
    [self scaleOpacityAnimations];
}

- (void)cellAnimation {
    for(CALayer *cell in self.booms){
        CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
        CAKeyframeAnimation *keyframeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        keyframeAnimation.path = [self makeRandomPath:cell].CGPath;
        keyframeAnimation.fillMode = kCAFillModeForwards;
        keyframeAnimation.timingFunction =  [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut];
        keyframeAnimation.duration = (random()%10) * 0.05 + 0.3;
        CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scale.toValue = @([self makeScaleValue]);
        scale.duration = keyframeAnimation.duration;
        scale.removedOnCompletion = NO;
        scale.fillMode = kCAFillModeForwards;
        CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacity.fromValue = @1;
        opacity.toValue = @0;
        opacity.duration = keyframeAnimation.duration;
        opacity.removedOnCompletion = NO;
        opacity.fillMode = kCAFillModeForwards;
        opacity.timingFunction =  [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut];
        animationGroup.duration = keyframeAnimation.duration;
        animationGroup.removedOnCompletion = NO;
        animationGroup.fillMode = kCAFillModeForwards;
        animationGroup.animations = @[keyframeAnimation,scale,opacity];
        animationGroup.delegate = self;
        [cell addAnimation:animationGroup forKey: @"moveAnimation"];
    }
}

- (void)scaleOpacityAnimations {
    // 缩放
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath: @"transform.scale"];
    scaleAnimation.toValue = @0.01;
    scaleAnimation.duration = 0.15;
    scaleAnimation.fillMode = kCAFillModeForwards;
    // 透明度
    CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath: @"opacity"];
    opacityAnimation.fromValue = @1;
    opacityAnimation.toValue = @0;
    opacityAnimation.duration = 0.15;
    opacityAnimation.fillMode = kCAFillModeForwards;
    [self.imageView.layer addAnimation: scaleAnimation forKey: @"lscale"];
    [self.imageView.layer addAnimation: opacityAnimation forKey: @"lopacity"];
    self.imageView.layer.opacity = 0;
}

/**
 *  绘制粉碎路径
 */
- (UIBezierPath *) makeRandomPath: (CALayer *) alayer {
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint startPoint = CGPointMake(alayer.frame.origin.x + alayer.frame.size.width/2, alayer.frame.origin.y);
    CGPoint endPoint = CGPointMake(alayer.frame.origin.x + alayer.frame.size.width/2, alayer.frame.origin.y + 200);
    [path moveToPoint:startPoint];
    [path addLineToPoint:endPoint];
    return path;
}

- (CGFloat)makeScaleValue {
    return 1 - 0.7 * (random()%101 - 50)/50;
}

/**
 *  根据点，取得对应颜色
 *  point 坐标点
 *  @return 颜色
 */
- (UIColor *)getPixelColorAtLocation:(CGPoint)point {
    //拿到放大后的图片
    CGImageRef inImage = [self scaleImageToSize:CGSizeMake(cellCount*2, cellCount*2)].CGImage;
    //使用上面的方法(createARGBBitmapContextFromImage:)创建上下文
    CGContextRef cgctx = [self createARGBBitmapContextFromImage:inImage];
    //图片的宽高
    size_t w = CGImageGetWidth(inImage);
    size_t h = CGImageGetHeight(inImage);
    //rect
    CGRect rect = CGRectMake(0, 0, w, h);
    //将目标图像绘制到指定的上下文，实际为上下文内的bitmapData。
    CGContextDrawImage(cgctx, rect, inImage);
    //取色
    unsigned char *bitmapData = CGBitmapContextGetData(cgctx);
    int pixelInfo = 4*((w*round(point.y))+round(point.x));
    CGFloat a = bitmapData[pixelInfo]/255.0;
    CGFloat r = bitmapData[pixelInfo+1]/255.0;
    CGFloat g = bitmapData[pixelInfo+2]/255.0;
    CGFloat b = bitmapData[pixelInfo+3]/255.0;
    //释放上面的函数创建的上下文
    CGContextRelease(cgctx);
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

/**
 *  缩放图片
 *
 *  @param size 缩放大小
 *
 *  @return 图片
 */
- (UIImage *)scaleImageToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [[self snapShot] drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *res = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return res;
}

- (UIImage *)snapShot {
    //根据视图size开始图片上下文
    UIGraphicsBeginImageContext(self.imageView.frame.size);
    //提供视图当前图文
    [self.imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    //获取视图当前图片
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    //关闭图片上下文
    UIGraphicsEndImageContext();
    return image;
}

- (CGContextRef) createARGBBitmapContextFromImage:(CGImageRef) inImage {
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    //内存空间的指针，该内存空间的大小等于图像使用RGB通道所占用的字节数
    void *bitmapData;
    unsigned long bitmapByteCount;
    unsigned long bitmapBytePerRow;
    size_t pixelsWide = CGImageGetWidth(inImage);//获取横向的像素点的个数
    size_t pixelsHeight = CGImageGetHeight(inImage);
    //每一行的像素点占用的字节数，每个像素点的ARGB四个通道各占8个bit(0-255)的空间
    bitmapBytePerRow = pixelsWide * 4;
    //计算整张图占用的字节数
    bitmapByteCount = bitmapBytePerRow * pixelsHeight;
    //创建依赖于设备的RGB通道
    colorSpace = CGColorSpaceCreateDeviceRGB();
    //分配足够容纳图片字节数的内存空间
    bitmapData = malloc(bitmapByteCount);
    //创建CoreGraphic的图形上下文，该上下文描述了bitmaData指向的内存空间需要绘制的图像的一些绘制参数
    context = CGBitmapContextCreate(bitmapData, pixelsWide, pixelsHeight, 8, bitmapBytePerRow, colorSpace, kCGImageAlphaPremultipliedFirst);
    //Core Foundation中通过含有Create、Alloc的方法名字创建的指针，需要使用CFRelease()函数释放
    CGColorSpaceRelease(colorSpace);
    return context;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
