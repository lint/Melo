
#import <UIKit/UIKit.h>

@class BarsVisualizerViewController, LineStackVisualizerViewController, WavyLineVisualizerViewController, GridVisualizerViewController;

@interface VisualizerPageViewController : UIViewController {
// @property(assign, nonatomic) NSTimeInterval updateInterval;
    NSTimeInterval _updateInterval; // TODO: change back to property (causing crash cause of allemand...)
}


@property(strong, nonatomic) NSTimer *updateTimer;
@property(strong, nonatomic) UILabel *bpmLabel;
// @property(strong, nonatomic) VisualizerView *vizView;
@property(strong, nonatomic) BarsVisualizerViewController *barsVizViewController;
@property(strong, nonatomic) LineStackVisualizerViewController *lineStackVizViewController;
@property(strong, nonatomic) WavyLineVisualizerViewController *wavyLineVizViewController;
@property(strong, nonatomic) GridVisualizerViewController *gridVizViewController;
@property(strong, nonatomic) UIButton *circleDebugToggleButton;
@property(assign, nonatomic) BOOL barsVizEnabled;
@property(assign, nonatomic) BOOL lineStackVizEnabled;
@property(assign, nonatomic) BOOL wavyLineVizEnabled;
@property(assign, nonatomic) BOOL gridVizEnabled;

- (void)updateVisualizerDisplay;

- (void)startUpdateTimer;
- (void)invalidateUpdateTimer;
- (void)updateTimerFired:(NSTimer *)timer;

@end