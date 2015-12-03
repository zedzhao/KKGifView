#import <ImageIO/ImageIO.h>
#import <QuartzCore/CoreAnimation.h>
#import "UIView+addition.h"


void getFrameInfo(CFURLRef url, NSMutableArray *frames, NSMutableArray *delayTimes, CGFloat *totalTime, CGFloat *gifWidth, CGFloat *gifHeight);

void getFrameInfo(CFURLRef url, NSMutableArray *frames, NSMutableArray *delayTimes, CGFloat *totalTime, CGFloat *gifWidth, CGFloat *gifHeight)
{
    CGImageSourceRef gifSource = CGImageSourceCreateWithURL(url, NULL);
    
    size_t frameCount = CGImageSourceGetCount(gifSource);
    
    for (size_t i = 0; i < frameCount; i++) {
        CGImageRef frame = CGImageSourceCreateImageAtIndex(gifSource, i, NULL);
        [frames addObject:(__bridge id)frame];
        CGImageRelease(frame);
        
        NSDictionary *dict = (__bridge NSDictionary*)CGImageSourceCopyPropertiesAtIndex(gifSource, i, NULL);
        
        if (gifWidth != NULL && gifHeight != NULL) {
            *gifWidth = [[dict valueForKey:(__bridge id)kCGImagePropertyPixelWidth] floatValue];
            *gifHeight = [[dict valueForKey:(__bridge id)kCGImagePropertyPixelHeight] floatValue];
        }
        
        NSDictionary *gifDict = [dict valueForKey:(__bridge id)kCGImagePropertyGIFDictionary];
        [delayTimes addObject:[gifDict valueForKey:(__bridge id)kCGImagePropertyGIFDelayTime]];
        
        if (totalTime) {
            *totalTime = *totalTime + [[gifDict valueForKey:(__bridge id)kCGImagePropertyGIFDelayTime] floatValue];
        }
        
    }
}

@interface KKGifView()

@property (nonatomic, strong) NSMutableArray 	*frames;
@property (nonatomic, strong) NSMutableArray	*frameDelayTimes;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat totalTime; //seconds

@end

@implementation KKGifView

- (instancetype)initWithFrame:(CGRect)frame gifPath:(NSString*)gifPath
{
    self = [super initWithFrame:frame];
    if (self) {
        _frames = [[NSMutableArray alloc] init];
        _frameDelayTimes = [[NSMutableArray alloc] init];
        
        _width = 0;
        _height = 0;
        _totalTime = 0;
        
        NSURL *url = [NSURL fileURLWithPath:gifPath];
        if (url) {
            getFrameInfo((__bridge  CFURLRef)url, _frames, _frameDelayTimes, &_totalTime, &_width, &_height);
        }
        [self setSize:CGSizeMake(_width, _height)];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"loading" ofType:@"gif"];
    return [self initWithFrame:frame gifPath:path];
}

- (void)startGif
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    NSMutableArray *times = [NSMutableArray arrayWithCapacity:5];
    CGFloat currentTime = 0;
    
    for (int i = 0; i < _frameDelayTimes.count; i++) {
        [times addObject: [NSNumber numberWithFloat:(currentTime / _totalTime)]];
        currentTime +=[_frameDelayTimes[i] floatValue];
    }
    
    [animation setKeyTimes:times];
    
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:5];
    for (int i = 0; i < _frames.count; i++) {
        [images addObject: _frames[i]];
    }
    
    [animation setValues:images];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    animation.duration = _totalTime;
    animation.repeatCount = FLT_MAX;
    animation.delegate = self;
    [self.layer addAnimation:animation forKey:@"gifAnimation"];
}

- (void)stopGif
{
    [self.layer removeAllAnimations];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    self.layer.contents = nil;
}

@end