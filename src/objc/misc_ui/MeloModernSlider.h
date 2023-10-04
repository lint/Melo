
#import <UIKit/UIKit.h>

@interface MeloModernSlider : UIView
@property(strong, nonatomic) UIView *trackContainerView;
@property(strong, nonatomic) UIView *minTrackView;
@property(strong, nonatomic) UIView *maxTrackView;
@property(strong, nonatomic) UIImageView *minImageView;
@property(strong, nonatomic) UIImageView *maxImageView;
@property(assign, nonatomic) CGFloat value;
@property(assign, nonatomic) CGFloat viewSpacing;
@property(strong, nonatomic) UILongPressGestureRecognizer *longPressGesture;
@property(assign, nonatomic) BOOL isTouchActive;
@property(assign, nonatomic) CGPoint lastTouchPoint;

- (void)handleLongPressGestureUpdate:(UILongPressGestureRecognizer *)gesture;
- (void)setImagesForMinImage:(NSString *)minImageName maxImage:(NSString *)maxImageName;
- (void)animateTrack:(BOOL)isTouchActive;
- (void)executeTrackAnimation;
- (void)applyTrackCornerRadius;
- (void)calculateSubviewFrames;
- (void)calculateValueWithPoint:(CGPoint)point;
- (void)applyViewColors;

@end