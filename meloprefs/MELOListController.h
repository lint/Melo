
#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>

@interface MELOListController : PSListController
@property(strong, nonatomic) UIColor *accentColor;
- (PSSpecifier *)specifierForKey:(NSString *)arg1;
@end
