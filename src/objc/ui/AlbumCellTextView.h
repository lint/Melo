
#import <UIKit/UIKit.h>

@interface AlbumCellTextView : UIView
@property(strong, nonatomic) UILabel *titleLabel;
@property(strong, nonatomic) UILabel *artistLabel;
@property(strong, nonatomic) UILabel *explicitBadge;
@property(strong, nonatomic) UIFont *font;
@property(assign, nonatomic) CGFloat spacing;
@property(assign, nonatomic) NSInteger fontSize;
@property(assign, nonatomic) BOOL shouldShowExplicitBadge;

- (void)setLabelFontSize:(NSInteger)fontSize;
- (void)setTitleText:(NSString *)arg1;
- (void)setArtistText:(NSString *)arg1;

@end