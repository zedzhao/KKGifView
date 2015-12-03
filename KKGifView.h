@interface KKGifView : UIView

- (instancetype)initWithFrame:(CGRect)frame gifPath:(NSString*)gifPath;
- (void)startGif;
- (void)stopGif;
@end
