
#import <UIKit/UIKit.h>

@class VisualizerView;

@interface VisualizerViewController : UIViewController 

@property(strong, nonatomic) UILabel *bpmLabel;
@property(strong, nonatomic) VisualizerView *vizView;

- (void)updateVisualizerDisplay;

@end