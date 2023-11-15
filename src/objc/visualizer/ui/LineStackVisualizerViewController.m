
#import "LineStackVisualizerViewController.h"
#import "../../managers/managers.h"
#import "../processing/processing.h"

@implementation LineStackVisualizerViewController 

// default initializer
// - (instancetype)initWithFrame:(CGRect)arg1 {
- (instancetype)init {

    if ((self = [super init])) {

        MeloManager *meloManager = [MeloManager sharedInstance];

        _dataUpdateInterval = .05;
        _animationInterval = .5;
        _displayUpdateCount = 0;
        _numDataItems = [meloManager prefsIntForKey:@"visualizerNumBars"];
        
        _pointSpacing = 0;
        _shouldAnimateAlpha = [meloManager prefsBoolForKey:@"visualizerAnimateAlphaEnabled"];
        _shouldMirrorLines = [meloManager prefsBoolForKey:@"visualizerCenterBarsEnabled"];

        [self createLineStackInfo];

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
    _shouldMirrorLines = [meloManager prefsBoolForKey:@"visualizerCenterBarsEnabled"];

    [self.view setNeedsLayout];
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

// create new line stack info
- (void)createLineStackInfo {

    _lineStackInfo = [NSMutableArray array];

    // [self addLineToStackWithColor:[UIColor redColor] heightPercent:0.5];
    // [self addLineToStackWithColor:[UIColor greenColor] heightPercent:0.75];
    // [self addLineToStackWithColor:[UIColor blueColor] heightPercent:1.0];

    [self addLineToStackWithColor:[UIColor systemRedColor] heightPercent:0.1];
    [self addLineToStackWithColor:[UIColor systemOrangeColor] heightPercent:0.2];
    [self addLineToStackWithColor:[UIColor systemYellowColor] heightPercent:0.3];
    [self addLineToStackWithColor:[UIColor systemGreenColor] heightPercent:0.4];
    [self addLineToStackWithColor:[UIColor systemTealColor] heightPercent:0.5];
    [self addLineToStackWithColor:[UIColor systemBlueColor] heightPercent:0.6];
    [self addLineToStackWithColor:[UIColor systemIndigoColor] heightPercent:0.7];
    [self addLineToStackWithColor:[UIColor systemPurpleColor] heightPercent:0.8];
    [self addLineToStackWithColor:[UIColor systemPinkColor] heightPercent:0.9];
    [self addLineToStackWithColor:[UIColor whiteColor] heightPercent:1.0];   
}

- (void)addLineToStackWithColor:(UIColor *)color heightPercent:(CGFloat)perc {

    UIBezierPath *path = [UIBezierPath new];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path = path.CGPath;
    layer.strokeColor = color.CGColor;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.lineWidth = 1.0;

    NSDictionary *lineData = @{
        @"heightPercent": [NSNumber numberWithFloat:perc],
        @"layer": layer,
        @"path": path
    };

    [_lineStackInfo addObject:lineData];
    [self.view.layer addSublayer:layer];
}

- (void)resetLineStackPaths {

    CGPoint point = CGPointMake(0, self.view.bounds.size.height / 2);

    for (NSInteger i = 0; i < [_lineStackInfo count]; i++) {
        UIBezierPath *path = _lineStackInfo[i][@"path"];

        if (path) {
            [path removeAllPoints];
            [path moveToPoint:point];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // [self createBarViews];
}

- (void)viewWillAppear:(BOOL)arg1 {
    [super viewWillAppear:arg1];

    // [self setupBarViewFrames];
    _pointSpacing = self.view.bounds.size.width / _numDataItems;
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

    [self resetLineStackPaths];

    // set the frame for every view according to it's relative bin value
    for (NSInteger i = 0; i < _numDataItems; i++) {

        float binVal = [visualizerManager valueForBin:i];
        float perc = maxBinValue > 0 ? binVal / maxBinValue : 0;

        CGFloat barHeight = MIN(MAX(boundsHeight * perc, 1), boundsHeight);
        
        CGFloat pointX = _pointSpacing * i;

        for (NSInteger j = 0; j < [_lineStackInfo count]; j++) {

            NSDictionary *lineInfo = _lineStackInfo[j];
            UIBezierPath *path = lineInfo[@"path"] ?: [UIBezierPath new];

            CGPoint lastPoint = [path currentPoint];

            CGFloat perc = lineInfo[@"heightPercent"] ? [lineInfo[@"heightPercent"] floatValue] : 0;
            CGFloat weightedHeight = barHeight * perc;
            CGFloat pointY = _shouldMirrorLines ? (boundsHeight - weightedHeight) / 2 : boundsHeight - weightedHeight;

            CGPoint topPoint = CGPointMake(pointX, pointY);
            [path addLineToPoint:topPoint];

            if (_shouldMirrorLines) {

                CGPoint lastBottomPoint = CGPointMake(lastPoint.x, (boundsHeight/2 - lastPoint.y) + boundsHeight/2);
                CGPoint bottomPoint = CGPointMake(topPoint.x, topPoint.y + weightedHeight);

                [path moveToPoint:lastBottomPoint];
                [path addLineToPoint:bottomPoint];
                [path moveToPoint:topPoint];
            }
        }
    }

    for (NSInteger i = 0; i < [_lineStackInfo count]; i++) {

        NSDictionary *lineInfo = _lineStackInfo[i];
        UIBezierPath *path = lineInfo[@"path"];
        CAShapeLayer *layer = lineInfo[@"layer"];

        if (!path || !layer) {
            continue;
        }

        CABasicAnimation *morph = [CABasicAnimation animationWithKeyPath:@"path"];
        morph.duration = _animationInterval;
        morph.fillMode = kCAFillModeForwards;
        morph.removedOnCompletion = NO; 
        morph.toValue = (id)path.CGPath;
        [layer addAnimation:morph forKey:nil];
    }  
}

@end