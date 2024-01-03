
#import "GridVisualizerViewController.h"
#import "../../managers/managers.h"
#import "../processing/processing.h"
#import "../grid/grid.h"

@implementation GridVisualizerViewController 

// default initializer
- (instancetype)init {

    if ((self = [super init])) {

        MeloManager *meloManager = [MeloManager sharedInstance];

        _manager = [GridVisualizerManager new];
        // GridCircleGroupCollection *circleGroups = [[GridCircleGroupCollection alloc] init];
        // _manager.circleGroups = circleGroups;
        [_manager updateNumColumns:[meloManager prefsIntForKey:@"visualizerNumBars"]];

        _dataUpdateInterval = .1;
        _animationInterval = .25;
        _displayUpdateCount = 0;
        _animationStartTimestamp = 0;
        // _numColumns = 
        
        _pointSpacing = 0;
        _shouldAnimateAlpha = [meloManager prefsBoolForKey:@"visualizerAnimateAlphaEnabled"];

        _circleDebugEnabled = YES;
        _circleIntersectionsDebugEnabled = YES;

        // _testPoint = CGPointMake(0, 0.5);
        // _testPointMult = 1;

        _shapeLayer = [CAShapeLayer layer];
        _shapeLayer.path = [UIBezierPath new].CGPath;
        _shapeLayer.strokeColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:.5].CGColor;
        _shapeLayer.fillColor = [UIColor clearColor].CGColor;
        _shapeLayer.lineWidth = 1.0;

        _circleDebugLayer = [CAShapeLayer layer];
        _circleDebugLayer.path = [UIBezierPath new].CGPath;
        _circleDebugLayer.strokeColor = [UIColor blueColor].CGColor;
        _circleDebugLayer.fillColor = [UIColor clearColor].CGColor;
        _circleDebugLayer.lineWidth = 1.0;

        _circleIntersectionsDebugLayer = [CAShapeLayer layer];
        _circleIntersectionsDebugLayer.path = [UIBezierPath new].CGPath;
        _circleIntersectionsDebugLayer.strokeColor = [UIColor redColor].CGColor;
        _circleIntersectionsDebugLayer.fillColor = [UIColor clearColor].CGColor;
        _circleIntersectionsDebugLayer.lineWidth = 1.0;

        [self.view.layer addSublayer:_shapeLayer];
        [self.view.layer addSublayer:_circleDebugLayer];
        [self.view.layer addSublayer:_circleIntersectionsDebugLayer];

        // _maxNumGridCircles = 10;
        // _numGridCircles = 0;
        // _gridCircles = malloc(_maxNumGridCircles * sizeof(GridCircle));

        _gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        // _gesture.minimumPressDuration = 0;
        // _gesture.numberOfTouchesRequired = 2;
        [self.view addGestureRecognizer:_gesture];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLibraryPrefsUpdate:) name:@"MELO_NOTIFICATION_PREFS_UPDATED_LIBRARY" object:meloManager];
    }

    return self;
}

// update the visualizer related settings if change detected
- (void)handleLibraryPrefsUpdate:(NSNotification *)arg1 {

    MeloManager *meloManager = [MeloManager sharedInstance];
    NSInteger newNumColumns = [meloManager prefsIntForKey:@"visualizerNumBars"];
    _shouldAnimateAlpha = [meloManager prefsBoolForKey:@"visualizerAnimateAlphaEnabled"];

    [_manager updateNumColumns:newNumColumns];
    [self.view setNeedsLayout];
}

// start a new timer to update the visualizer
- (void)startDataUpdateTimer {
    [self invalidateDataUpdateTimer];
    _dataUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:_dataUpdateInterval target:self selector:@selector(dataUpdateTimerFired:) userInfo:nil repeats:YES];
}

// stop the timer that updates the visualizer
- (void)invalidateDataUpdateTimer {
    if (_dataUpdateTimer) {
        [_dataUpdateTimer invalidate];
    }
}

// handler method for the update timer
- (void)dataUpdateTimerFired:(NSTimer *)timer {
    [self updateVisualizerData];
}

// starts a display link which executes a callback method to smoothly animate curves
- (void)startDisplayLink {
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink:)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

// stop the display link from executing the callback method
- (void)stopDisplayLink {
    if (_displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
    }
}

// the display link callback method
- (void)handleDisplayLink:(CADisplayLink *)displayLink {
    
    // set the start timestamp if it does not exist
    if (!_animationStartTimestamp) {
        _animationStartTimestamp = displayLink.timestamp;
    }

    // get the percentage of the animation that has elapsed
    NSTimeInterval elapsed = (displayLink.timestamp - _animationStartTimestamp);
    float animationPercent = MIN(elapsed / _animationInterval, 1);

    // update the date based on the animation status
    [_manager calculateCurrentGrid:animationPercent];
    _shapeLayer.path = [_manager currentGridPath].CGPath;

    if (_circleDebugEnabled) {
        _circleDebugLayer.path = [_manager currentCirclesPath].CGPath;
    } else {
        _circleDebugLayer.path = [UIBezierPath new].CGPath;
    }

    if (_circleIntersectionsDebugEnabled) {
        _circleIntersectionsDebugLayer.path = [_manager currentIntersectionLinesPath].CGPath;
    } else {
        _circleIntersectionsDebugLayer.path = [UIBezierPath new].CGPath;
    }
}

// handle a touch detected on the view
- (void)handleGesture:(UIGestureRecognizer *)arg1 {

    if (arg1.state == UIGestureRecognizerStateBegan || arg1.state == UIGestureRecognizerStateChanged) {

        CGFloat avgX = 0;
        CGFloat avgY = 0;

        NSInteger numTouches = [arg1 numberOfTouches];

        // CGPoint point = [arg1 locationInView:self.view];
        for (NSInteger i = 0; i < numTouches; i++) {
            CGPoint point = [arg1 locationOfTouch:i inView:self.view];
            avgX += point.x;
            avgY += point.y;
        }

        avgX /= numTouches;
        avgY /= numTouches;

        // CGPoint normPoint = CGPointMake(point.x / self.view.bounds.size.width, point.y / self.view.bounds.size.height);
        CGPoint normPoint = CGPointMake(avgX / self.view.bounds.size.width, avgY / self.view.bounds.size.height);

        [_manager addCircleWithIdentifier:@"touch_gesture_circle" normCenter:normPoint radius:0.2 strength:.5];

    } else {
        [_manager removeCircleWithIdentifier:@"touch_gesture_circle"];
    }
}

// the view was loaded into memory
- (void)viewDidLoad {
    [super viewDidLoad];
}

// the view is about to appear
- (void)viewWillAppear:(BOOL)arg1 {
    [super viewWillAppear:arg1];

    _manager.viewBounds = self.view.bounds;
    [_manager setupGridPoints];
    [_manager calculateCircleWidthBasedCenters];

    _shapeLayer.path = [_manager currentGridPath].CGPath;
}

// the view did appear on screen
- (void)viewDidAppear:(BOOL)arg1 {
    [super viewDidAppear:arg1];

    [self startDataUpdateTimer];
    [self startDisplayLink];

    VisualizerManager *visualizerManager = [VisualizerManager sharedInstance];
    visualizerManager.numVisualizersActive++;
}

// the view did disappear from the screen
- (void)viewDidDisappear:(BOOL)arg1 {
    [super viewDidDisappear:arg1];

    [self invalidateDataUpdateTimer];
    [self stopDisplayLink];

    VisualizerManager *visualizerManager = [VisualizerManager sharedInstance];
    visualizerManager.numVisualizersActive--;
}

// update the visualizer view based on processed audio data
- (void)updateVisualizerData {

    _displayUpdateCount++;

    MeloManager *meloManager = [MeloManager sharedInstance];
    VisualizerManager *visualizerManager = [VisualizerManager sharedInstance];

    CGFloat boundsWidth = self.view.bounds.size.width;
    CGFloat boundsHeight = self.view.bounds.size.height;

    // float maxBinValue = [visualizerManager rollingMaxBinValue];

    // set the frame for every view according to it's relative bin value
    // for (NSInteger i = 0; i < _numColumns; i++) {

    //     float binVal = [visualizerManager valueForBin:i];
    //     float perc = maxBinValue > 0 ? binVal / maxBinValue : 0;

    //     CGFloat barHeight = MIN(MAX(boundsHeight * perc, 1), boundsHeight);
        
    //     CGFloat pointX = _pointSpacing * i;

    // }

    // if (_gridCircles[0].center.x <= 0) {
    //     _testPointMult = 1;
    // } else if (_gridCircles[0].center.x >= 1) {
    //     _testPointMult = -1;
    // }

    // _gridCircles[0].center = CGPointMake(_gridCircles[0].center.x + (0.05 * _testPointMult), _gridCircles[0].center.y);

    _animationStartTimestamp = 0;
    [_manager prepareGridPointsForAnimation];
    [_manager applyCirclesToGrid];    
}

- (void)toggleCircleDebugLayer {
    _circleDebugEnabled = !_circleDebugEnabled;
    _circleIntersectionsDebugEnabled = !_circleIntersectionsDebugEnabled;
}

@end