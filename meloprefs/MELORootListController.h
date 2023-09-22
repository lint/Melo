
#import <UIKit/UIKit.h>
#import "MELOListController.h"

@interface MELORootListController : MELOListController
@property(strong, nonatomic) UIBarButtonItem *killMusicButton;
- (void)clearPins;
- (void)killMusic;
@end
