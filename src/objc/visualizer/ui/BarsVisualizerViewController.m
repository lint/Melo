
#import "BarsVisualizerViewController.h"
#import "../../managers/managers.h"
#import "../processing/processing.h"

@implementation BarsVisualizerViewController 

// default initializer
// - (instancetype)initWithFrame:(CGRect)arg1 {
- (instancetype)init {

    if ((self = [super init])) {

        MeloManager *meloManager = [MeloManager sharedInstance];

        _dataUpdateInterval = .25;
        _animationInterval = .25;
        _displayUpdateCount = 0;
        _numDataItems = [meloManager prefsIntForKey:@"visualizerNumBars"];
        _barSpacing = [meloManager prefsFloatForKey:@"visualizerBarSpacing"];
        _barWidth = 0;
        _shouldAnimateAlpha = [meloManager prefsBoolForKey:@"visualizerAnimateAlphaEnabled"];
        _shouldCenterBars = [meloManager prefsBoolForKey:@"visualizerCenterBarsEnabled"];

        _barViews = [NSMutableArray array];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLibraryPrefsUpdate:) name:@"MELO_NOTIFICATION_PREFS_UPDATED_LIBRARY" object:meloManager];
    }

    return self;
}

// update the visualizer related settings if change detected
- (void)handleLibraryPrefsUpdate:(NSNotification *)arg1 {

    MeloManager *meloManager = [MeloManager sharedInstance];
    NSInteger newNumDataItems = [meloManager prefsIntForKey:@"visualizerNumBars"];

    if (newNumDataItems != _numDataItems) {
        _numDataItems = newNumDataItems;
        [self createBarViews];
    }

    _barSpacing = [meloManager prefsFloatForKey:@"visualizerBarSpacing"];
    _shouldAnimateAlpha = [meloManager prefsBoolForKey:@"visualizerAnimateAlphaEnabled"];
    _shouldCenterBars = [meloManager prefsBoolForKey:@"visualizerCenterBarsEnabled"];

    [self.view setNeedsLayout];
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

    [self removeBarViews];

    for (NSInteger i = 0; i < _numDataItems; i++) {

        UIView *barView = [[UIView alloc] initWithFrame:CGRectZero];
        barView.backgroundColor = [UIColor labelColor];

        [_barViews addObject:barView];
        [self.view addSubview:barView];
    }

    [self setupBarViewFrames]; // TODO: do i need this here?
}

// sets the frames of all the bar views
- (void)setupBarViewFrames {

    CGFloat boundsWidth = self.view.bounds.size.width;
    CGFloat boundsHeight = self.view.bounds.size.height;

    _barWidth = (boundsWidth - _barSpacing * (_numDataItems - 1)) / _numDataItems;
    CGFloat barHeight = 2;

    for (NSInteger i = 0; i < _numDataItems; i++) {
        CGFloat barYOrigin = _shouldCenterBars ? (boundsHeight - barHeight) / 2 : boundsHeight - barHeight;
        CGRect frame = CGRectMake((_barWidth + _barSpacing) * i, barYOrigin, _barWidth, barHeight);

        UIView *barView = _barViews[i];
        barView.frame = frame;
    }
}

// start a new timer to update the visualizer
- (void)startDataUpdateTimer {
    [self invalidateDataUpdateTimer];
    self.dataUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:_dataUpdateInterval target:self selector:@selector(dataUpdateTimerFired:) userInfo:nil repeats:YES];
}

// stop the timer that updates the visualizer
- (void)invalidateDataUpdateTimer {
    if (self.dataUpdateTimer) {
        [self.dataUpdateTimer invalidate];
    }
}

// handler method for the update timer
- (void)dataUpdateTimerFired:(NSTimer *)timer {
    // [self layoutBars];
    [self updateVisualizer:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self createBarViews];
}

- (void)viewWillAppear:(BOOL)arg1 {
    [super viewWillAppear:arg1];

    [self setupBarViewFrames];
}

- (void)viewWillDisappear:(BOOL)arg1 {
    [super viewWillDisappear:arg1];
}

- (void)viewDidAppear:(BOOL)arg1 {
    [super viewDidAppear:arg1];

    [self startDataUpdateTimer];
    VisualizerManager *visualizerManager = [VisualizerManager sharedInstance];
    visualizerManager.numVisualizersActive++;
}

- (void)viewDidDisappear:(BOOL)arg1 {
    [super viewDidDisappear:arg1];

    [self invalidateDataUpdateTimer];
    VisualizerManager *visualizerManager = [VisualizerManager sharedInstance];
    visualizerManager.numVisualizersActive--;
}

- (void)updateVisualizer:(BOOL)animated {

    if (animated) {

        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:_animationInterval];
        [UIView setAnimationBeginsFromCurrentState:YES];

        [self updateVisualizerData];

        [UIView commitAnimations];
    } else {
        [self updateVisualizerData];
    }
}

- (void)updateVisualizerData {

    _displayUpdateCount++;

    MeloManager *meloManager = [MeloManager sharedInstance];
    VisualizerManager *visualizerManager = [VisualizerManager sharedInstance];

    CGFloat boundsWidth = self.view.bounds.size.width;
    CGFloat boundsHeight = self.view.bounds.size.height;

    float maxBinValue = [visualizerManager rollingMaxBinValue];

    // set the frame for every view according to it's relative bin value
    for (NSInteger i = 0; i < _numDataItems; i++) {

        UIView *barView = _barViews[i];
        float binVal = [visualizerManager valueForBin:i];
        float perc = maxBinValue > 0 ? binVal / maxBinValue : 0;

        CGFloat barHeight = MIN(MAX(boundsHeight * perc, 1), boundsHeight);
        CGFloat barYOrigin = _shouldCenterBars ? (boundsHeight - barHeight) / 2 : boundsHeight - barHeight;
        
        CGRect frame = CGRectMake((_barWidth + _barSpacing) * i, barYOrigin, _barWidth, barHeight);
        barView.frame = frame;

        if (_shouldAnimateAlpha) {
            barView.alpha = MAX(MIN(perc * 3, 1), .15);
        } else {
            barView.alpha = 1;
        }
    }
}

@end