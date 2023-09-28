@interface UIViewController ()
- (id)contentScrollView;
@end

@interface UICollectionView ()
//@property(strong, nonatomic) NSArray *visibleViews;
- (NSArray *)_visibleViews;
@end

@interface UIScrollView ()
- (CGPoint)_minimumContentOffset;
- (CGPoint)_maximumContentOffset;
- (void)_updatePanGesture;
- (void)_notifyDidScroll;
@end

@interface UIContextMenuConfiguration ()
// @property(strong, nonatomic) UIContextMenuActionProvider actionProvider;
- (UIContextMenuActionProvider)actionProvider;
- (void)setActionProvider:(UIContextMenuActionProvider)arg1;
@end

@interface UIColor ()
+ (id)whiteColorWithAlpha:(CGFloat)arg1;
@end

@interface UISlider ()
- (id)_maxTrackView;
- (id)_minTrackView;
- (id)_thumbView;
- (id)_thumbViewNeue;
- (id)_maxValueView;
- (id)_minValueView;
@end