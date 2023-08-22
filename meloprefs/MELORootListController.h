
#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>

@interface MELORootListController : PSListController
@property(strong, nonatomic) UIBarButtonItem *killMusicButton;
@property(strong, nonatomic) UIColor *accentColor;
- (void)clearPins;
- (void)killMusic;
@end
