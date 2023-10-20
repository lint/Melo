
#import "VisualizerViewController.h"
#import "../managers/managers.h"

@implementation VisualizerViewController

// default initializer
- (instancetype)init {

    if ((self = [super init])) {

        LibraryMenuManager *libraryMenuManager = [LibraryMenuManager sharedInstance];
        VisualizerManager *visualizerManager = libraryMenuManager.visualizerManager;

        // _numVizBars = 16;
        _numVizBars = visualizerManager.numOutputBins;
        // _barSpacing = 2;
        _barSpacing = [[MeloManager sharedInstance] prefsFloatForKey:@"visualizerBarSpacing"];
        _updateInterval = 0.01;
    }

    return self;
}

// called when the view is loaded into memory
- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor systemBackgroundColor];

    // calculate view dimensions
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat margins = 20;
    CGFloat containerHeight = 300;
    CGRect containerFrame = CGRectMake(margins, (screenBounds.size.height - containerHeight) / 2, screenBounds.size.width - (margins * 2), containerHeight);
    CGFloat barWidth = (containerFrame.size.width - _barSpacing * (_numVizBars - 1)) / _numVizBars;

    // setup the container view
    _vizContainer = [[UIView alloc] initWithFrame:containerFrame];
    [self.view addSubview:_vizContainer];

    BOOL centerBars = [[MeloManager sharedInstance] prefsBoolForKey:@"visualizerCenterBarsEnabled"];

    // setup bin bar views
    _vizBarViews = [NSMutableArray array];
    for (NSInteger i = 0; i < _numVizBars; i++) {
        
        // CGFloat barHeight = containerFrame.size.height * .025;
        CGFloat barHeight = 2;
        CGFloat barYOrigin = centerBars ? (containerFrame.size.height - barHeight) / 2 : containerFrame.size.height - barHeight;
        CGRect frame = CGRectMake((barWidth + _barSpacing) * i, barYOrigin, barWidth, barHeight);

        UIView *view = [[UIView alloc] initWithFrame:frame];
        view.backgroundColor = [UIColor labelColor];

        [_vizBarViews addObject:view];
        [_vizContainer addSubview:view];
    }
}

// called when the view appeared on screen
- (void)viewDidAppear:(BOOL)arg1 {
    [super viewDidAppear:arg1];

    [self startUpdateTimer];

    LibraryMenuManager *libraryMenuManager = [LibraryMenuManager sharedInstance];
    VisualizerManager *visualizerManager = libraryMenuManager.visualizerManager;
    visualizerManager.isVisualizerActive = YES;
}

// called when the view disappeared from the screen
- (void)viewDidDisappear:(BOOL)arg1 {
    [super viewDidDisappear:arg1];

    [self invalidateUpdateTimer];

    LibraryMenuManager *libraryMenuManager = [LibraryMenuManager sharedInstance];
    VisualizerManager *visualizerManager = libraryMenuManager.visualizerManager;
    visualizerManager.isVisualizerActive = NO;
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
    
    // ensure UI updates are done on the main thread
    [self performSelectorOnMainThread:@selector(updateVisualizerDisplay) withObject:nil waitUntilDone:NO];
}

// update the visualizer display with processed audio data
- (void)updateVisualizerDisplay {

    MeloManager *meloManager = [MeloManager sharedInstance];
    LibraryMenuManager *libraryMenuManager = [LibraryMenuManager sharedInstance];
    VisualizerManager *visualizerManager = libraryMenuManager.visualizerManager;

    BOOL animateAlpha = [meloManager prefsBoolForKey:@"visualizerAnimateAlphaEnabled"];
    BOOL centerBars = [meloManager prefsBoolForKey:@"visualizerCenterBarsEnabled"];

    CGRect containerBounds = _vizContainer.bounds;
    CGFloat barWidth = (containerBounds.size.width - _barSpacing * (_numVizBars - 1)) / _numVizBars;

    // float maxBinValue = [visualizerManager maxBinValue];
    // float maxBinValue = [visualizerManager overallMaxBinValue];
    float maxBinValue = [visualizerManager rollingMaxBinValue];

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:_updateInterval * 25];
    [UIView setAnimationBeginsFromCurrentState:YES];

    // set the frame for every view according to it's relative bin value
    for (NSInteger i = 0; i < _numVizBars; i++) {

        float binVal = [visualizerManager valueForBin:i];
        UIView *view = _vizBarViews[i];

        float perc = maxBinValue > 0 ? binVal / maxBinValue : 0;
        perc *= 1.25;
        CGFloat barHeight = MAX(containerBounds.size.height * perc, 2);
        CGFloat barYOrigin = centerBars ? (containerBounds.size.height - barHeight) / 2 : containerBounds.size.height - barHeight;
        
        CGRect frame = CGRectMake((barWidth + _barSpacing) * i, barYOrigin, barWidth, barHeight);
        view.frame = frame;

        if (animateAlpha) {
            view.alpha = MAX(MIN(perc * 3, 1), .15);
        } else {
            view.alpha = 1;
        }

        [view setNeedsLayout];
    }

    [UIView commitAnimations];
}

@end