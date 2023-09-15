
#import <UIKit/UIKit.h>

@interface AlbumCell : UICollectionViewCell
@property(strong, nonatomic) NSString *title;
@property(strong, nonatomic) NSString *artistName;
@property(strong, nonatomic) NSString *identifier;
@property(strong, nonatomic) UIView *wiggleModeFakeAlbumView;
@property(strong, nonatomic) UIImageView *wiggleModeFakeAlbumIconView;

// custom elements
- (void)addShakeAnimation;
- (void)removeShakeAnimation;
- (void)setTextAndBadgeHidden:(BOOL)arg1;
- (void)createWiggleModeFakeAlbumView;
- (void)layoutWiggleModeFakeAlbumViews;
@end