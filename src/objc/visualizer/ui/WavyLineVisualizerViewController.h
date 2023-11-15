
#import <UIKit/UIKit.h>

@interface WavyLineVisualizerViewController : UIViewController {
    NSTimeInterval _dataUpdateInterval;
    NSTimeInterval _animationInterval;

    float *_srcControlHeights;
    float *_dstControlHeights;
    float *_curControlHeights;
}

@property(strong, nonatomic) NSTimer *dataUpdateTimer;
@property(assign, nonatomic) NSInteger displayUpdateCount;
@property(assign, nonatomic) NSInteger numDataItems;

@property(strong, nonatomic) CAShapeLayer *shapeLayer;
@property(assign, nonatomic) CGFloat pointSpacing;
@property(assign, nonatomic) CGFloat pointY;
@property(assign, nonatomic) BOOL shouldAnimateAlpha;

@property(strong, nonatomic) UIBezierPath *linePath;
@property(assign, nonatomic) CGFloat animationPercent;
@property(assign, nonatomic) CFTimeInterval animationStartTimestamp;
@property(strong, nonatomic) CADisplayLink *displayLink;

@property(assign, nonatomic) CGFloat controlPointYTopBound;
@property(assign, nonatomic) CGFloat controlPointYBottomBound;

- (void)handleLibraryPrefsUpdate:(NSNotification *)arg1;
- (void)startDataUpdateTimer;
- (void)invalidateDataUpdateTimer;
- (void)dataUpdateTimerFired:(NSTimer *)timer;

// - (void)updateVisualizer:(BOOL)animated;
- (void)updateVisualizerData;
- (void)setupSizeRelatedValues;

@end