
#import <UIKit/UIKit.h>

@interface LineStackVisualizerViewController : UIViewController {
    NSTimeInterval _dataUpdateInterval;
    NSTimeInterval _animationInterval;
}

@property(strong, nonatomic) NSTimer *dataUpdateTimer;
@property(assign, nonatomic) NSInteger displayUpdateCount;
@property(assign, nonatomic) NSInteger numDataItems;

@property(strong, nonatomic) NSMutableArray *lineStackInfo;
@property(assign, nonatomic) CGFloat pointSpacing;
@property(assign, nonatomic) BOOL shouldAnimateAlpha;
@property(assign, nonatomic) BOOL shouldMirrorLines;

- (void)handleLibraryPrefsUpdate:(NSNotification *)arg1;
- (void)startDataUpdateTimer;
- (void)invalidateDataUpdateTimer;
- (void)dataUpdateTimerFired:(NSTimer *)timer;

// - (void)updateVisualizer:(BOOL)animated;
- (void)updateVisualizerData;

@end