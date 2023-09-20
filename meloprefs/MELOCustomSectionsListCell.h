
#import <Preferences/PSTableCell.h>
#import <UIKit/UIKit.h>

@interface UIView ()
+ (CGFloat)pu_layoutMarginWidthForCurrentScreenSize;
@end

@interface PSTableCell ()
- (UITableView *)_tableView;
- (void)setShouldHideTitle:(BOOL)arg1;
@end

@interface MELOCustomSectionsListCell : PSTableCell <UITextFieldDelegate>
@property(strong, nonatomic) NSString *sectionTitle;
@property(strong, nonatomic) NSString *sectionSubtitle;
@property(strong, nonatomic) UITextField *titleTextField;
@property(strong, nonatomic) UITextField *subtitleTextField;
@property(strong, nonatomic) UIView *verticalSeparatorView;
- (id)initWithTitle:(NSString *)arg1 subtitle:(NSString *)arg2;
- (void)updateSpecifier;
- (void)saveData;
- (void)clearText;
@end
