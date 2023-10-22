
#import "VisualizerView.h"
#import "../managers/managers.h"

@implementation VisualizerView 

// default initializer
- (instancetype)initWithFrame:(CGRect)arg1 {

    if ((self = [super initWithFrame:arg1])) {

        MeloManager *meloManager = [MeloManager sharedInstance];

        _barViews = [NSMutableArray array];
        _numBars = [meloManager prefsIntForKey:@"visualizerNumBars"];
        _barSpacing = [meloManager prefsFloatForKey:@"visualizerBarSpacing"];

        [self createBarViews];

        _shouldAnimateAlpha = [meloManager prefsBoolForKey:@"visualizerAnimateAlphaEnabled"];
        _shouldCenterBars = [meloManager prefsBoolForKey:@"visualizerCenterBarsEnabled"];

        _updateInterval = 0.01;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLibraryPrefsUpdate:) name:@"MELO_NOTIFICATION_PREFS_UPDATED_LIBRARY" object:meloManager];
    }

    return self;
}

// update the visualizer related settings if change detected
- (void)handleLibraryPrefsUpdate:(NSNotification *)arg1 {

    MeloManager *meloManager = [MeloManager sharedInstance];

    NSInteger newNumBars = [meloManager prefsIntForKey:@"visualizerNumBars"];

    if (newNumBars != _numBars) {
        _numBars = newNumBars;

        [self removeBarViews];
        [self createBarViews];
    }

    _barSpacing = [meloManager prefsFloatForKey:@"visualizerBarSpacing"];
    _shouldAnimateAlpha = [meloManager prefsBoolForKey:@"visualizerAnimateAlphaEnabled"];
    _shouldCenterBars = [meloManager prefsBoolForKey:@"visualizerCenterBarsEnabled"];

    [self setNeedsLayout];
}

// remove the current bar views
- (void)removeBarViews {

    for (UIView *barView in _barViews) {
        [barView removeFromSuperview];
    }

    _barViews = [NSMutableArray array];
}

// create new bar views
- (void)createBarViews {

    CGFloat barWidth = (self.bounds.size.width - _barSpacing * (_numBars - 1)) / _numBars;
    CGFloat barHeight = 2;

    for (NSInteger i = 0; i < _numBars; i++) {
        CGFloat barYOrigin = _shouldCenterBars ? (self.bounds.size.height - barHeight) / 2 : self.bounds.size.height - barHeight;
        CGRect frame = CGRectMake((barWidth + _barSpacing) * i, barYOrigin, barWidth, barHeight);

        UIView *view = [[UIView alloc] initWithFrame:frame];
        view.backgroundColor = [UIColor labelColor];

        [_barViews addObject:view];
        [self addSubview:view];
    }
}

// layout the bar views
- (void)layoutSubviews {

    // [self layoutBars];
    [super layoutSubviews];
}

- (void)layoutBars {

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:_updateInterval * 40];
    [UIView setAnimationBeginsFromCurrentState:YES];

    MeloManager *meloManager = [MeloManager sharedInstance];
    LibraryMenuManager *libraryMenuManager = [LibraryMenuManager sharedInstance];
    VisualizerManager *visualizerManager = libraryMenuManager.visualizerManager;

    CGFloat barWidth = (self.bounds.size.width - _barSpacing * (_numBars - 1)) / _numBars;

    // float maxBinValue = [visualizerManager maxBinValue];
    // maxBinValue = 100;
    // float maxBinValue = [visualizerManager overallMaxBinValue];
    float maxBinValue = [visualizerManager rollingMaxBinValue];
    // maxBinValue = MIN(maxBinValue, 100);
    // maxBinValue = 64;

    // set the frame for every view according to it's relative bin value
    for (NSInteger i = 0; i < _numBars; i++) {

        UIView *view = _barViews[i];
        float binVal = [visualizerManager valueForBin:i];
        float perc = maxBinValue > 0 ? binVal / maxBinValue : 0;
        
        // if (perc < 0.10) {
        //     perc *= 3;
        // } else if (perc < 0.25) {
        //     perc *= 1.5;
        // } else if (perc < 0.5) {
        //     perc *= 1.25;
        // }

        CGFloat barHeight = MIN(MAX(self.bounds.size.height * perc, 1), self.bounds.size.height);
        CGFloat barYOrigin = _shouldCenterBars ? (self.bounds.size.height - barHeight) / 2 : self.bounds.size.height - barHeight;
        
        CGRect frame = CGRectMake((barWidth + _barSpacing) * i, barYOrigin, barWidth, barHeight);
        view.frame = frame;

        if (_shouldAnimateAlpha) {
            view.alpha = MAX(MIN(perc * 3, 1), .15);
        } else {
            view.alpha = 1;
        }
    }

    [UIView commitAnimations];
}

// start a new timer to update the visualizer
- (void)startUpdateTimer {
    [self invalidateUpdateTimer];
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:_updateInterval target:self selector:@selector(updateTimerFired:) userInfo:nil repeats:YES];
}

// stop the timer that updates the visualizer
- (void)invalidateUpdateTimer {
    if (self.updateTimer) {
        [self.updateTimer invalidate];
    }
}

// handler method for the update timer
- (void)updateTimerFired:(NSTimer *)timer {
    [self layoutBars];
    [self setNeedsLayout];
}

@end