
#import <UIKit/UIKit.h>
#import <Preferences/PSControlTableCell.h>

@interface UIView ()
- (id)_viewControllerForAncestor;
@end

@interface MELOColorPickerCell : PSControlTableCell <UIColorPickerViewControllerDelegate>
@property(strong, nonatomic) UIColor *currentColor;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier;
// - (void)setCellEnabled:(BOOL)cellEnabled;
// - (BOOL)cellEnabled;
- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier;
- (UIButton *)newControl;
- (void)handleColorButtonPressed;

- (UIColor *)loadSelectedColor;
- (void)saveSelectedColor:(UIColor *)color;

- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)viewController;

- (NSDictionary *)colorToDict:(UIColor *)color;
- (UIColor *)dictToColor:(NSDictionary *)dict;
@end