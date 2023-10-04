
#import "AlbumCellTextView.h"
#import "../utilities/utilities.h"
#import "../../interfaces/interfaces.h"
#import <substrate.h>

@implementation AlbumCellTextView

- (instancetype)init {

    if ((self = [super init])) {

        _spacing = 5;

        _shouldShowExplicitBadge = NO;

        _titleLabel = [UILabel new];
        _artistLabel = [UILabel new];
        _explicitBadge = [UILabel new];

        _explicitBadge.text = @"🅴";

        _titleLabel.textColor = [UIColor labelColor];
        _artistLabel.textColor = [UIColor secondaryLabelColor];
        _explicitBadge.textColor = [UIColor secondaryLabelColor];

        [self addSubview:_titleLabel];
        [self addSubview:_artistLabel];
        [self addSubview:_explicitBadge];

        [self setLabelFontSize:12];
    }

    return self;
}

// lays out text labels and other views
- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect bounds = [self bounds];

    CGFloat titleXOrigin = 0;
    CGFloat titleWidth = bounds.size.width;

    if (_shouldShowExplicitBadge) {

        CGFloat explicitBadgeSpacing = 2;

        CGSize explicitBadgeSize = CGSizeMake([_font lineHeight], [_font lineHeight]);
        CGSize titleTextSize = [_titleLabel.text sizeWithAttributes:@{NSFontAttributeName:_font}];
        titleWidth = MIN(bounds.size.width - explicitBadgeSize.width - explicitBadgeSpacing, titleTextSize.width + explicitBadgeSpacing);

        CGFloat badgeXOrigin; 

        if ([objc_getClass("MeloUtils") appLanaguageIsLeftToRight]) {
            badgeXOrigin = titleWidth + explicitBadgeSpacing;
        } else {
            titleXOrigin = bounds.size.width - titleWidth;
            badgeXOrigin = titleXOrigin - explicitBadgeSpacing;
        }

        _explicitBadge.frame = CGRectMake(badgeXOrigin, _spacing, explicitBadgeSize.width, explicitBadgeSize.height);
    }

    CGRect titleFrame = CGRectMake(titleXOrigin, _spacing, titleWidth, [_font lineHeight]);
    CGRect artistFrame = CGRectMake(0, titleFrame.origin.y + titleFrame.size.height, bounds.size.width, [_font lineHeight]);

    _titleLabel.frame = titleFrame;
    _artistLabel.frame = artistFrame;

    _explicitBadge.hidden = !_shouldShowExplicitBadge;
}

- (void)setLabelFontSize:(NSInteger)fontSize {

    _fontSize = fontSize;
    _font = [UIFont systemFontOfSize:fontSize];

    _titleLabel.font = _font;
    _artistLabel.font = _font;
    _explicitBadge.font = _font;
}

- (void)setTitleText:(NSString *)arg1 {
    _titleLabel.text = arg1;
}

- (void)setArtistText:(NSString *)arg1 {
    _artistLabel.text = arg1;
}

@end