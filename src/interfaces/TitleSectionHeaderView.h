#import <UIKit/UIKit.h>

// forward declarations
@class LibraryRecentlyAddedViewController, RecentlyAddedManager;

@interface TitleSectionHeaderView : UICollectionReusableView
@property(strong, nonatomic) NSString *title;
@property(strong, nonatomic) NSString *subtitle;
@property(strong, nonatomic) UIView *accessibilityAdditionalContentView;
@property(strong, nonatomic) UIButton *accessibilityImageButton;
- (id)_collectionView;
- (UIEdgeInsets)music_layoutInsets;
- (void)music_setLayoutInsets:(UIEdgeInsets)arg1;

// custom elements
@property(strong, nonatomic) UIImageView *chevronIndicatorView;
@property(strong, nonatomic) NSString *identifier;
@property(strong, nonatomic) UITapGestureRecognizer *tapGesture;
@property(strong, nonatomic) LibraryRecentlyAddedViewController *recentlyAddedViewController;

// - (LibraryRecentlyAddedViewController *)recentlyAddedViewController;
- (RecentlyAddedManager *)recentlyAddedManager;
- (BOOL)isCollapsed;
- (void)createCollapseItems;
- (void)handleTapGesture:(UIGestureRecognizer *)arg1;
@end