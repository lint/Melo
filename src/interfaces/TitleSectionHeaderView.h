#import <UIKit/UIKit.h>

@interface TitleSectionHeaderView : UICollectionReusableView
@property(strong, nonatomic) NSString *title;
@property(strong, nonatomic) NSString *subtitle;
@property(strong, nonatomic) UIView *accessibilityAdditionalContentView;
@property(strong, nonatomic) UIButton *accessibilityImageButton;
- (id)_collectionView;
- (UIEdgeInsets)music_layoutInsets;
- (void)music_setLayoutInsets:(UIEdgeInsets)arg1;
@end