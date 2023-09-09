
#import "WiggleModeManager.h"

@implementation WiggleModeManager

// default initializer
- (id)init {
    self = [super init];

    if (self) {

        _inWiggleMode = NO;

    }

    return self;
}

- (void)invalidateTimers {

    if (_autoScrollTimer) {
        [_autoScrollTimer invalidate];
        _autoScrollTimer = nil;
    }

    if (_emptyInsertTimer) {
        [_emptyInsertTimer invalidate];
        _emptyInsertTimer = nil;
    }
}

@end