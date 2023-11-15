
#import <UIKit/UIKit.h>

@interface BarsVisualizerViewController : UIViewController {
    NSTimeInterval _dataUpdateInterval;
    NSTimeInterval _animationInterval;
}

@property(strong, nonatomic) NSTimer *dataUpdateTimer;
@property(assign, nonatomic) NSInteger displayUpdateCount;
@property(assign, nonatomic) NSInteger numDataItems;

@property(strong, nonatomic) NSMutableArray *barViews;
@property(assign, nonatomic) CGFloat barSpacing;
@property(assign, nonatomic) CGFloat barWidth;
@property(assign, nonatomic) BOOL shouldAnimateAlpha;
@property(assign, nonatomic) BOOL shouldCenterBars;

- (void)handleLibraryPrefsUpdate:(NSNotification *)arg1;
- (void)removeBarViews;
- (void)createBarViews;
- (void)setupBarViewFrames;
- (void)startDataUpdateTimer;
- (void)invalidateDataUpdateTimer;
- (void)dataUpdateTimerFired:(NSTimer *)timer;

- (void)updateVisualizer:(BOOL)animated;
- (void)updateVisualizerData;

@end