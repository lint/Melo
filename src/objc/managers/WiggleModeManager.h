
#import <UIKit/UIKit.h>

@interface WiggleModeManager : NSObject
@property(assign, nonatomic) BOOL inWiggleMode;
@property(strong, nonatomic) UILongPressGestureRecognizer *longPressRecognizer;
@property(strong, nonatomic) UIView *draggingView;
@property(assign, nonatomic) CGPoint draggingOffset;
@property(strong, nonatomic) NSIndexPath *draggingIndexPath;
@property(strong, nonatomic) NSString *draggingAlbumIdentifier;
@property(strong, nonatomic) NSTimer *autoScrollTimer;
@property(strong, nonatomic) NSTimer *emptyInsertTimer;
@property(strong, nonatomic) UIView *endWiggleModeView;

- (void)invalidateTimers;
@end