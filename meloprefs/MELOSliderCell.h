
#import <UIKit/UIKit.h>
#import <Preferences/PSControlTableCell.h>

@interface MELOSliderCell : PSControlTableCell
@property(strong, nonatomic) UISlider *slider;
@property(strong, nonatomic) UILabel *valueLabel;
@property(assign, nonatomic) BOOL isIntegersOnly;
@end
