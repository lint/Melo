
#import <UIKit/UIKit.h>

// forward declarations
@class AlbumCellTextView;

@interface AlbumCell : UICollectionViewCell

// stock elements
@property(strong, nonatomic) NSString *title;
@property(strong, nonatomic) NSString *artistName;
- (BOOL)accessibilityIsExplicit;

// custom elements
@property(strong, nonatomic) NSString *identifier;
@property(strong, nonatomic) UIView *wiggleModeFakeAlbumView;
@property(strong, nonatomic) UIImageView *wiggleModeFakeAlbumIconView;
@property(strong, nonatomic) AlbumCellTextView *customTextView;
- (void)addShakeAnimation;
- (void)removeShakeAnimation;
- (void)setTextAndBadgeHidden:(BOOL)arg1;
- (void)setCustomTextViewHidden:(BOOL)arg1;
- (void)createWiggleModeFakeAlbumView;
- (void)layoutWiggleModeFakeAlbumViews;
- (void)createCustomTextView;
@end