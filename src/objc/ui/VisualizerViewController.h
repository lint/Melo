
#import <UIKit/UIKit.h>

@interface VisualizerViewController : UIViewController {
// @property(assign, nonatomic) NSTimeInterval updateInterval;
    NSTimeInterval _updateInterval; // TODO: change back to property (causing crash cause of allemand...)
}


@property(strong, nonatomic) NSTimer *updateTimer;
@property(strong, nonatomic) UILabel *testLabel;
@property(strong, nonatomic) NSMutableArray *vizBarViews;
@property(strong, nonatomic) UIView *vizContainer;
@property(assign, nonatomic) NSInteger numVizBars;
@property(assign, nonatomic) CGFloat barSpacing;

- (void)startUpdateTimer;
- (void)invalidateUpdateTimer;
- (void)updateTimerFired:(NSTimer *)timer;
- (void)updateVisualizerDisplay;

@end