
#import <UIKit/UIKit.h>

@interface VisualizerView : UIView {
// @property(assign, nonatomic) NSTimeInterval updateInterval;
    NSTimeInterval _updateInterval; // TODO: change back to property (causing crash cause of allemand...)
}

@property(strong, nonatomic) NSTimer *updateTimer;
@property(strong, nonatomic) NSMutableArray *barViews;
@property(assign, nonatomic) NSInteger numBars;
@property(assign, nonatomic) CGFloat barSpacing;
@property(assign, nonatomic) BOOL shouldAnimateAlpha;
@property(assign, nonatomic) BOOL shouldCenterBars;

- (void)removeBarViews;
- (void)createBarViews;
- (void)handleLibraryPrefsUpdate:(NSNotification *)arg1;
- (void)startUpdateTimer;
- (void)invalidateUpdateTimer;
- (void)updateTimerFired:(NSTimer *)timer;
- (void)layoutBars;

@end