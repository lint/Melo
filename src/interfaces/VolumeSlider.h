
#import "MPResources.h"

@interface VolumeSlider : MPVolumeSlider
@property(assign, nonatomic) float value;

// Backport.xm
@property(strong, nonatomic) AnimationManager *animationManager;
@property(strong, nonatomic) UIView *customElapsedView;
@property(strong, nonatomic) UIView *customRemainingView;
@property(strong, nonatomic) UIView *customTrackContainerView;
@property(strong, nonatomic) UIImageView *customMinValueView;
@property(strong, nonatomic) UIImageView *customMaxValueView;
@property(assign, nonatomic) BOOL largeSliderActive;
@property(assign, nonatomic) BOOL shouldApplyCustomValues;
@property(assign, nonatomic) BOOL shouldApplyLargeSliderWidth;
@property(strong, nonatomic) UIImage *stockThumbImage;
- (void)animateCustomSliderSize:(BOOL)largeSliderActive;
- (void)createCustomTrackViews;
- (void)layoutCustomTrackViews;
- (void)layoutCustomMinMaxViews;
- (void)applyCustomTrackCornerRadius;
- (void)applyCustomViewsBackgroundColors;
- (void)setStockTrackViewsHidden:(BOOL)arg1;
- (void)setCustomViewsHidden:(BOOL)arg1;
- (void)setStockImageViewsHidden:(BOOL)arg1;
- (void)backupStockThumbImage;
@end