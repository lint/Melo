
#import <UIKit/UIKit.h>

@interface AlbumCell : UICollectionViewCell
@property(strong, nonatomic) NSString *title;
@property(strong, nonatomic) NSString *artistName;

// custom elements
- (void)addShakeAnimation;
- (void)removeShakeAnimation;
- (void)setTextAndBadgeHidden:(BOOL)arg1;
@end