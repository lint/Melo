@interface VerticalStackScrollView : UIScrollView

//custom elements
@property(assign, nonatomic) BOOL hasDelayedContentSizeChange;
@property(assign, nonatomic) CGSize delayedContentSize;
- (void)applyDelayedContentSizeIfNeeded;
@end