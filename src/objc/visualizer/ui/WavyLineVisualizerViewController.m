
#import "WavyLineVisualizerViewController.h"
#import "../processing/processing.h"
#import "../../managers/managers.h"
#import "../../utilities/utilities.h"

@implementation WavyLineVisualizerViewController 

// default initializer
// - (instancetype)initWithFrame:(CGRect)arg1 {
- (instancetype)init {

    if ((self = [super init])) {

        MeloManager *meloManager = [MeloManager sharedInstance];

        _dataUpdateInterval = .25;
        _animationInterval = .25;
        _displayUpdateCount = 0;
        _numDataItems = [meloManager prefsIntForKey:@"visualizerNumBars"];
        
        _pointSpacing = 0;
        _shouldAnimateAlpha = [meloManager prefsBoolForKey:@"visualizerAnimateAlphaEnabled"];

        _linePath = [UIBezierPath new];
        _shapeLayer = [CAShapeLayer layer];
        _shapeLayer.path = _linePath.CGPath;
        _shapeLayer.strokeColor = [UIColor blueColor].CGColor;
        _shapeLayer.fillColor = [UIColor clearColor].CGColor;
        _shapeLayer.lineWidth = 1.0;
        [self.view.layer addSublayer:_shapeLayer];

        _srcControlHeights = calloc(_numDataItems, sizeof(float));
        _dstControlHeights = calloc(_numDataItems, sizeof(float));
        _curControlHeights = calloc(_numDataItems, sizeof(float));

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
        // [self createBarViews];
    }

    _shouldAnimateAlpha = [meloManager prefsBoolForKey:@"visualizerAnimateAlphaEnabled"];

    [self.view setNeedsLayout];
}

// sets up any properties that rely on the view's size having a value
- (void)setupSizeRelatedValues {

    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;

    _pointSpacing = width / _numDataItems;
    _pointY = height / 2;

    _controlPointYTopBound = -height / 2;
    _controlPointYBottomBound = height * 1.5;

    for (NSInteger i = 0; i < _numDataItems; i++) {
        _curControlHeights[i] = _pointY;
        _dstControlHeights[i] = _pointY;
        _srcControlHeights[i] = _pointY;
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
    [self updateVisualizerData];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // [self createBarViews];
}

- (void)viewWillAppear:(BOOL)arg1 {
    [super viewWillAppear:arg1];

    // [self setupBarViewFrames];
    [self setupSizeRelatedValues];
}

- (void)viewWillDisappear:(BOOL)arg1 {
    [super viewWillDisappear:arg1];
}

- (void)viewDidAppear:(BOOL)arg1 {
    [super viewDidAppear:arg1];

    [self startDataUpdateTimer];
    [self startDisplayLink];

    VisualizerManager *visualizerManager = [VisualizerManager sharedInstance];
    visualizerManager.numVisualizersActive++;
}

- (void)viewDidDisappear:(BOOL)arg1 {
    [super viewDidDisappear:arg1];

    [self invalidateDataUpdateTimer];
    [self stopDisplayLink];

    VisualizerManager *visualizerManager = [VisualizerManager sharedInstance];
    visualizerManager.numVisualizersActive--;
}

// - (void)updateVisualizer:(BOOL)animated {

//     if (animated) {

//         // [UIView beginAnimations:nil context:nil];
//         // [UIView setAnimationDuration:_animationInterval];
//         // [UIView setAnimationBeginsFromCurrentState:YES];

//         [self updateVisualizerData];

//         // [UIView commitAnimations];
//     } else {
//         [self updateVisualizerData];
//     }
// }

- (void)updateVisualizerData {

    _displayUpdateCount++;

    MeloManager *meloManager = [MeloManager sharedInstance];
    VisualizerManager *visualizerManager = [VisualizerManager sharedInstance];

    CGFloat boundsWidth = self.view.bounds.size.width;
    CGFloat boundsHeight = self.view.bounds.size.height;

    float maxBinValue = [visualizerManager rollingMaxBinValue];

    [_linePath removeAllPoints];
    [_linePath moveToPoint:CGPointMake(0, boundsHeight/2)];

    // set the frame for every view according to it's relative bin value
    for (NSInteger i = 0; i < _numDataItems; i++) {

        float binVal = [visualizerManager valueForBin:i];
        float perc = maxBinValue > 0 ? binVal / maxBinValue : 0;

        CGFloat barHeight = MIN(MAX(boundsHeight * perc, 1), boundsHeight);
        
        CGFloat pointX = _pointSpacing * i;

        NSInteger posNegMul = i % 2 == 0 ? 1 : -1;
        CGPoint currPoint = [_linePath currentPoint];
        CGPoint nextPoint = CGPointMake(pointX + _pointSpacing, boundsHeight / 2);
        CGPoint controlPoint = CGPointMake(
            (currPoint.x + nextPoint.x) / 2, 
            MAX(MIN((boundsHeight/2) - (posNegMul * perc * boundsHeight), _controlPointYBottomBound), _controlPointYTopBound)
            // _displayUpdateCount % 2 == 0 ? (i % 2 == 0 ? controlPointYTopBound : boundsHeight / 2) : boundsHeight / 2
        );

        _dstControlHeights[i] = controlPoint.y;
        _srcControlHeights[i] = _curControlHeights[i];

        [_linePath addQuadCurveToPoint:nextPoint controlPoint:controlPoint];

        // if (i % 2 != 0) {
        //     continue;
        // }

        // CGPoint currPoint = [_linePath currentPoint];
        // CGPoint nextPoint = CGPointMake(frame.origin.x + frame.size.width + barWidth + _barSpacing, boundsHeight / 2);
        // CGPoint controlPoint1 = CGPointMake(
        //     (currPoint.x + nextPoint.x) / 2, 
        //     MAX(MIN((boundsHeight/2) + (perc * boundsHeight), _controlPointYBottomBound), _controlPointYTopBound)
        // );
        // CGPoint controlPoint2 = CGPointMake(
        //     (currPoint.x + nextPoint.x) / 2, 
        //     MAX(MIN((boundsHeight/2) - (perc * boundsHeight), _controlPointYBottomBound), _controlPointYTopBound)
        // );

        // [_linePath addCurveToPoint:nextPoint controlPoint1:controlPoint1 controlPoint2:controlPoint2];
    }

    _animationStartTimestamp = 0;
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

    NSTimeInterval elapsed = (displayLink.timestamp - _animationStartTimestamp);
    [Logger logStringWithFormat:@"timestamp: %f, start: %f, elapsed: %f", displayLink.timestamp, _animationStartTimestamp, elapsed];

    // self.shapeLayer.path = [[self pathAtInterval:elapsed] CGPath];

    // if (elapsed >= wavyLinesAnimationDuration) {
    //     // [self stopDisplayLink];
    //     // self.shapeLayer.path = [[self pathAtInterval:0] CGPath];
    //     // self.statusLabel.text = [NSString stringWithFormat:@"loopCount = %.1f frames/sec", self.loopCount / kSeconds];
    // }

    // if (elapsed < _wavyLinesAnimationDuration) {

    float animationPercent = MIN(elapsed / _animationInterval, 1);
    _shapeLayer.path = [self getCurrentInterpolatedBezierPath:animationPercent].CGPath;
}

// get a path that is some percentage between the source and the destination
- (UIBezierPath *)getCurrentInterpolatedBezierPath:(float)animationPercent {

    // i think calculating the new control points should be done somewhere else
    float destWeight = MIN(MAX(animationPercent, 0), 1);
    float sourceWeight = 1 - destWeight;

    UIBezierPath *path = [UIBezierPath new];

    [path moveToPoint:CGPointMake(0, _pointY)];

    for (NSInteger i = 0; i < _numDataItems; i++) { 

        float controlHeight = sourceWeight * _srcControlHeights[i] + destWeight * _dstControlHeights[i];
        _curControlHeights[i] = controlHeight;

        CGPoint currPoint = CGPointMake(i * _pointSpacing, _pointY); // TODO, rather than creating a new currentPoint every time, you could just set it equal to next point at the end of the loop
        CGPoint nextPoint = CGPointMake((i + 1) * _pointSpacing, _pointY);
        CGPoint controlPoint = CGPointMake((currPoint.x + nextPoint.x) / 2, controlHeight);

        [path addQuadCurveToPoint:nextPoint controlPoint:controlPoint];
    }

    return path;
}

@end