
#import <UIKit/UIKit.h>

// forward declarations
@class AnimationManager;

@interface PlayerTimeControl : UIControl

// stock
@property(strong, nonatomic) UIView *knobView;
@property(strong, nonatomic) UIView *elapsedTrack;
@property(strong, nonatomic) UIView *remainingTrack;
@property(strong, nonatomic) UILabel *liveLabel;
@property(assign, nonatomic) BOOL accessibilityIsLiveContent;

// Backport.xm
@property(strong, nonatomic) AnimationManager *animationManager;
@property(strong, nonatomic) UILabel *customElapsedTimeLabel;
@property(strong, nonatomic) UILabel *customRemainingTimeLabel;
@property(assign, nonatomic) BOOL shouldApplyCustomValues;
@property(assign, nonatomic) BOOL largeSliderActive;
@property(strong, nonatomic) id emptySetCopy;
- (void)applyCustomSliderHeight;
- (void)applyRoundedCorners;
- (void)applyKnobConstaints:(BOOL)shouldHideKnob;
- (void)createCustomTimeLabels;
- (void)setKnobHidden:(BOOL)arg1;
- (void)layoutCustomTimeLabels;
- (void)applyElapsedTrackColor;
- (void)setStockTimeLabelsHidden:(BOOL)arg1;
- (void)setCustomTimeLabelsHidden:(BOOL)arg1;
- (void)animateLargeSlider:(BOOL)largeSliderActive;
@end