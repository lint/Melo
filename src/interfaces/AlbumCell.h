
#import <UIKit/UIKit.h>

// forward declarations
@class AlbumCellTextView;

@interface AlbumCell : UICollectionViewCell

// stock
@property(strong, nonatomic) NSString *title;
@property(strong, nonatomic) NSString *artistName;
- (BOOL)accessibilityIsExplicit;

// WiggleMode.xm
@property(strong, nonatomic) NSString *identifier;
@property(strong, nonatomic) UIView *wiggleModeFakeAlbumView;
@property(strong, nonatomic) UIImageView *wiggleModeFakeAlbumIconView;
- (void)addShakeAnimation;
- (void)removeShakeAnimation;
- (void)createWiggleModeFakeAlbumView;
- (void)layoutWiggleModeFakeAlbumViews;

// Layout.xm
@property(assign, nonatomic) BOOL shouldApplyCornerRadius;
@property(assign, nonatomic) BOOL shouldHideText;
@property(assign, nonatomic) BOOL shouldChangeFontSize;
@property(strong, nonatomic) AlbumCellTextView *customTextView;
- (void)setTextAndBadgeHidden:(BOOL)arg1;
- (void)setCustomTextViewHidden:(BOOL)arg1;
- (void)createCustomTextView;
- (void)applyDisplayDict:(NSDictionary *)arg1;

@end