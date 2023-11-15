
#import <UIKit/UIKit.h>

@interface VisualizerView : UIView {
// @property(assign, nonatomic) NSTimeInterval updateInterval;
    NSTimeInterval _updateInterval; // TODO: change back to property (causing crash cause of allemand...)
    float *_sourceControlHeights;
    float *_destControlHeights;
    float *_currControlHeights;
}

@property(strong, nonatomic) NSTimer *updateTimer;
@property(strong, nonatomic) UIView *barsContainer;
@property(strong, nonatomic) NSMutableArray *barViews;
@property(assign, nonatomic) NSInteger numBars;
@property(assign, nonatomic) CGFloat barSpacing;
@property(assign, nonatomic) BOOL shouldAnimateAlpha;
@property(assign, nonatomic) BOOL shouldCenterBars;

@property(strong, nonatomic) UIView *lineStackContainer;
@property(strong, nonatomic) NSMutableArray *lineStackInfo;
@property(assign, nonatomic) BOOL barsEnabled;
@property(assign, nonatomic) BOOL lineStackEnabled;

@property(assign, nonatomic) BOOL wavyLinesEnabled;
@property(strong, nonatomic) UIView *wavyLinesContainer;
@property(strong, nonatomic) UIBezierPath *wavyLinesPath;
@property(strong, nonatomic) UIBezierPath *prevPath;
@property(strong, nonatomic) CAShapeLayer *wavyLinesShapeLayer;
@property(assign, nonatomic) NSInteger displayUpdateCount;
@property(assign, nonatomic) CGFloat wavyLinesAnimationPercent;
@property(assign, nonatomic) CGFloat wavyLinesAnimationDuration;
@property(assign, nonatomic) CFTimeInterval wavyLinesAnimationStartTimestamp;
@property(strong, nonatomic) CADisplayLink *displayLink;


- (void)removeBarViews;
- (void)createBarViews;
- (void)handleLibraryPrefsUpdate:(NSNotification *)arg1;
- (void)startUpdateTimer;
- (void)invalidateUpdateTimer;
- (void)updateTimerFired:(NSTimer *)timer;
- (void)layoutBars;
// - (UIBezierPath *)createPath;

- (void)startDisplayLink;
- (void)stopDisplayLink;
- (void)handleDisplayLink:(CADisplayLink *)displayLink;
- (UIBezierPath *)getCurrentInterpolatedBezierPath:(float)animationPercent;

@end