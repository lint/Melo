
#import <UIKit/UIKit.h>

// forward declarations
@class GridVisualizerManager;

@interface GridVisualizerViewController : UIViewController {
    NSTimeInterval _dataUpdateInterval;
    NSTimeInterval _animationInterval;
}

@property(strong, nonatomic) NSTimer *dataUpdateTimer;
@property(assign, nonatomic) NSInteger displayUpdateCount;
@property(strong, nonatomic) CAShapeLayer *shapeLayer;

@property(strong, nonatomic) CAShapeLayer *circleDebugLayer;
@property(assign, nonatomic) BOOL circleDebugEnabled;

@property(strong, nonatomic) CAShapeLayer *circleIntersectionsDebugLayer;
@property(assign, nonatomic) BOOL circleIntersectionsDebugEnabled;

@property(assign, nonatomic) CGFloat pointSpacing;
@property(assign, nonatomic) BOOL shouldAnimateAlpha;

// @property(assign, nonatomic) CGPoint testPoint;
@property(assign, nonatomic) NSInteger testPointMult;

@property(assign, nonatomic) CFTimeInterval animationStartTimestamp;
@property(strong, nonatomic) CADisplayLink *displayLink;
@property(strong, nonatomic) UIPanGestureRecognizer *gesture;

@property(strong, nonatomic) GridVisualizerManager *manager;

- (void)handleLibraryPrefsUpdate:(NSNotification *)arg1;
- (void)startDataUpdateTimer;
- (void)invalidateDataUpdateTimer;
- (void)dataUpdateTimerFired:(NSTimer *)timer;

- (void)updateVisualizerData;

- (void)startDisplayLink;
- (void)stopDisplayLink;
- (void)handleDisplayLink:(CADisplayLink *)displayLink;

- (void)handleGesture:(UIGestureRecognizer *)arg1;
- (void)toggleCircleDebugLayer;


@end