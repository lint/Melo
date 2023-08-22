
#import "MELOSliderCell.h"
#import <Preferences/PSSpecifier.h>

@implementation MELOSliderCell

- (id)initWithStyle:(UITableViewCellStyle)arg1 reuseIdentifier:(NSString *)arg2 specifier:(PSSpecifier *)arg3 {

	self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];

    if (self) {

        // you COULD implement showValue if you want, but it's really not necessary at this time

        _slider = [[UISlider alloc] init];
        _slider.minimumValue = [arg3.properties[@"min"] floatValue];
        _slider.maximumValue = [arg3.properties[@"max"] floatValue];
        _slider.value = [arg3.properties[@"default"] floatValue];
        _slider.continuous = YES;
        _slider.minimumTrackTintColor = [UIColor systemPinkColor]; //[UIColor colorWithRed:1.0 green:0.216 blue:0.373 alpha:1.0];
        [self.contentView addSubview:_slider];

        [_slider addTarget:self action:@selector(controlChanged:) forControlEvents:UIControlEventValueChanged];
        self.control = _slider;

        _valueLabel = [[UILabel alloc] init];
        _valueLabel.font = [UIFont boldSystemFontOfSize:12];
        _valueLabel.textColor = [UIColor grayColor];
        _valueLabel.text = @"00.00";
        [self.contentView addSubview:_valueLabel];

        _isIntegersOnly = arg3.properties[@"integersOnly"] ? [arg3.properties[@"integersOnly"] boolValue] : YES;
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect titleLabelFrame = [self textLabel].frame;

    CGFloat contentViewWidth = self.contentView.frame.size.width;
    CGFloat cellHeight = self.frame.size.height;
    CGFloat spacing = 20;

    CGFloat valueLabelWidth = 30; // not actually being used for the width..
    CGFloat valueLabelHeight = 15;
    CGFloat valueLabelXOrigin = contentViewWidth - spacing - valueLabelWidth;

    //CGSize textSize = [_valueLabel.text boundingRectWithSize:CGSizeMake(spacing + 30, cellHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : _valueLabel.font} context:nil].size;
    //CGFloat valueLabelWidth = textSize.width;
    //CGFloat valueLabelHeight = textSize.height;

    CGRect valueLabelFrame = CGRectMake(valueLabelXOrigin, (cellHeight - valueLabelHeight) / 2, contentViewWidth - valueLabelXOrigin, valueLabelHeight);

    CGFloat sliderWidth = valueLabelFrame.origin.x - (titleLabelFrame.origin.x + titleLabelFrame.size.width) - (spacing * 2);
    CGFloat sliderHeight = floor(cellHeight * .70);
    CGRect sliderFrame = CGRectMake(titleLabelFrame.origin.x + titleLabelFrame.size.width + spacing, (cellHeight - sliderHeight) / 2, sliderWidth, sliderHeight);

    _slider.frame = sliderFrame;
    _valueLabel.frame = valueLabelFrame;
}

- (void)updateValueLabel {

    NSNumber *value = [self controlValue];
    _valueLabel.text = _isIntegersOnly ? [value stringValue] : [NSString stringWithFormat:@"%.2f", [value floatValue]];
}

- (void)setValue:(NSNumber *)arg1 {
    _slider.value = [arg1 floatValue];
    [self updateValueLabel];
}

- (void)controlChanged:(UIControl *)arg1 {
    [super controlChanged:arg1];

    [self updateValueLabel];
}

- (NSNumber *)controlValue {
    return _isIntegersOnly ? [NSNumber numberWithInteger:lround(_slider.value)] : [NSNumber numberWithFloat:_slider.value];
}

@end
