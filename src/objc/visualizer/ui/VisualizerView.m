
#import "VisualizerView.h"
#import "../processing/processing.h"
#import "../../managers/managers.h"
#import "../../utilities/utilities.h"

@implementation VisualizerView

// default initializer
- (instancetype)initWithFrame:(CGRect)arg1 {

    if ((self = [super initWithFrame:arg1])) {

        MeloManager *meloManager = [MeloManager sharedInstance];
        CGRect bounds = CGRectMake(0, 0, arg1.size.width, arg1.size.height);

        _lineStackEnabled = NO;
        _barsEnabled = NO;
        _wavyLinesEnabled = YES;
        
        _updateInterval = 1;
        _numBars = [meloManager prefsIntForKey:@"visualizerNumBars"];
        _barSpacing = [meloManager prefsFloatForKey:@"visualizerBarSpacing"];
        _shouldAnimateAlpha = [meloManager prefsBoolForKey:@"visualizerAnimateAlphaEnabled"];
        _shouldCenterBars = [meloManager prefsBoolForKey:@"visualizerCenterBarsEnabled"];

        _barViews = [NSMutableArray array];
        _lineStackInfo = [NSMutableArray array];

        _barsContainer = [[UIView alloc] initWithFrame:bounds];
        _lineStackContainer = [[UIView alloc] initWithFrame:bounds];
        _wavyLinesContainer = [[UIView alloc] initWithFrame:bounds];

        _barsContainer.hidden = !_barsEnabled;
        _lineStackContainer.hidden = !_lineStackEnabled;
        _wavyLinesContainer.hidden = !_wavyLinesEnabled;
        
        [self addSubview:_barsContainer];
        [self addSubview:_lineStackContainer];
        [self addSubview:_wavyLinesContainer];

        _wavyLinesPath = [UIBezierPath new];
        _prevPath = [UIBezierPath new];
        _wavyLinesShapeLayer = [CAShapeLayer layer];
        _wavyLinesShapeLayer.path = _wavyLinesPath.CGPath;
        _wavyLinesShapeLayer.strokeColor = [UIColor blueColor].CGColor;
        _wavyLinesShapeLayer.fillColor = [UIColor clearColor].CGColor;
        _wavyLinesShapeLayer.lineWidth = 1.0;
        [_wavyLinesContainer.layer addSublayer:_wavyLinesShapeLayer];
        _wavyLinesAnimationDuration = .5;

        _sourceControlHeights = calloc(_numBars, sizeof(float));
        _destControlHeights = calloc(_numBars, sizeof(float));
        _currControlHeights = calloc(_numBars, sizeof(float));

        CGFloat pointY = arg1.size.height / 2;
        for (NSInteger i = 0; i < _numBars; i++) {
            _currControlHeights[i] = pointY;
            _destControlHeights[i] = pointY;
            _sourceControlHeights[i] = pointY;
        }

        [self createBarViews];
        [self createLineStackInfo];        

        _displayUpdateCount = 0;

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

        [self createBarViews];

        free(_sourceControlHeights);
        free(_destControlHeights);
        free(_currControlHeights);

        _sourceControlHeights = calloc(_numBars, sizeof(float));
        _destControlHeights = calloc(_numBars, sizeof(float));
        _currControlHeights = calloc(_numBars, sizeof(float));

        CGFloat pointY = self.bounds.size.height / 2;
        for (NSInteger i = 0; i < _numBars; i++) {
            _currControlHeights[i] = pointY;
            _destControlHeights[i] = pointY;
            _sourceControlHeights[i] = pointY;
        }
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

    [self removeBarViews];

    CGFloat containerWidth = _barsContainer.bounds.size.width;
    CGFloat containerHeight = _barsContainer.bounds.size.height;

    CGFloat barWidth = (containerWidth - _barSpacing * (_numBars - 1)) / _numBars;
    CGFloat barHeight = 2;

    for (NSInteger i = 0; i < _numBars; i++) {
        CGFloat barYOrigin = _shouldCenterBars ? (containerHeight - barHeight) / 2 : containerHeight - barHeight;
        CGRect frame = CGRectMake((barWidth + _barSpacing) * i, barYOrigin, barWidth, barHeight);

        UIView *view = [[UIView alloc] initWithFrame:frame];
        view.backgroundColor = [UIColor labelColor];

        [_barViews addObject:view];
        [_barsContainer addSubview:view];
    }
}

// create new line stack info
- (void)createLineStackInfo {

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
    [_lineStackContainer.layer addSublayer:layer];
}

- (void)resetLineStackPaths {

    CGPoint point = CGPointMake(0, self.bounds.size.height / 2);

    for (NSInteger i = 0; i < [_lineStackInfo count]; i++) {
        UIBezierPath *path = _lineStackInfo[i][@"path"];

        if (path) {
            [path removeAllPoints];
            [path moveToPoint:point];
        }
    }
}

// layout the bar views
- (void)layoutSubviews {

    // [self layoutBars];
    [super layoutSubviews];

    _barsContainer.frame = self.bounds;
    _lineStackContainer.frame = self.bounds;
}

- (void)layoutBars {

    _displayUpdateCount++;

    [UIView beginAnimations:nil context:nil];
    // [UIView setAnimationDuration:_updateInterval * 40];
    [UIView setAnimationDuration:_updateInterval];
    [UIView setAnimationBeginsFromCurrentState:YES];

    MeloManager *meloManager = [MeloManager sharedInstance];
    VisualizerManager *visualizerManager = [VisualizerManager sharedInstance];

    CGFloat barWidth = (self.bounds.size.width - _barSpacing * (_numBars - 1)) / _numBars;
    CGFloat containerWidth = self.bounds.size.width;
    CGFloat containerHeight = self.bounds.size.height;
    CGFloat controlPointYTopBound = -containerHeight / 2;
    CGFloat controlPointYBottomBound = containerHeight * 1.5;

    // float maxBinValue = [visualizerManager maxBinValue];
    // maxBinValue = 100;
    // float maxBinValue = [visualizerManager overallMaxBinValue];
    float maxBinValue = [visualizerManager rollingMaxBinValue];
    // maxBinValue = MIN(maxBinValue, 100);
    // maxBinValue = 64;

    [self resetLineStackPaths];
    // [_wavyLinesPath removeAllPoints];
    _prevPath = _wavyLinesPath;
    _wavyLinesPath = [UIBezierPath new];
    [_wavyLinesPath moveToPoint:CGPointMake(0, containerHeight/2)];

    // memcpy(_sourceControlHeights, _currControlHeights, _numBars * sizeof(float));
    // memset(_destControlHeights, 0, _numBars * sizeof(float)); // also not needed since every value is overwritten anyway
    // don't think i need these
    // memset(_sourceControlHeights, 0, _numBars * sizeof(float));
    // memset(_currControlHeights, 0, _numBars * sizeof(float));

    // set the frame for every view according to it's relative bin value
    for (NSInteger i = 0; i < _numBars; i++) {

        UIView *view = _barViews[i];
        float binVal = [visualizerManager valueForBin:i];
        float perc = maxBinValue > 0 ? binVal / maxBinValue : 0;

        CGFloat barHeight = MIN(MAX(containerHeight * perc, 1), containerHeight);
        CGFloat barYOrigin = _shouldCenterBars ? (containerHeight - barHeight) / 2 : containerHeight - barHeight;
        
        CGRect frame = CGRectMake((barWidth + _barSpacing) * i, barYOrigin, barWidth, barHeight);
        view.frame = frame;

        if (_barsEnabled) {
            if (_shouldAnimateAlpha) {
                view.alpha = MAX(MIN(perc * 3, 1), .15);
            } else {
                view.alpha = 1;
            }
        } else {
            view.alpha = 0;
        }

        if (_lineStackEnabled) {

            for (NSInteger j = 0; j < [_lineStackInfo count]; j++) {

                NSDictionary *lineInfo = _lineStackInfo[j];
                UIBezierPath *path = lineInfo[@"path"] ?: [UIBezierPath new];

                CGPoint lastPoint = [path currentPoint];

                CGFloat perc  =  lineInfo[@"heightPercent"] ? [lineInfo[@"heightPercent"] floatValue] : 0;
                CGFloat weightedHeight = barHeight * perc;
                CGFloat pointYOrigin = _shouldCenterBars ? (containerHeight - weightedHeight) / 2 : containerHeight - weightedHeight;

                CGPoint topPoint = CGPointMake(frame.origin.x, pointYOrigin);
                [path addLineToPoint:topPoint];

                if (_shouldCenterBars) {

                    CGPoint lastBottomPoint = CGPointMake(lastPoint.x, (containerHeight/2 - lastPoint.y) + containerHeight/2);
                    CGPoint bottomPoint = CGPointMake(topPoint.x, topPoint.y + weightedHeight);

                    [path moveToPoint:lastBottomPoint];
                    [path addLineToPoint:bottomPoint];
                    [path moveToPoint:topPoint];
                }
            }
        }

        if (_wavyLinesEnabled) {
            
            NSInteger posNegMul = i % 2 == 0 ? 1 : -1;
            CGPoint currPoint = [_wavyLinesPath currentPoint];
            CGPoint nextPoint = CGPointMake(frame.origin.x + frame.size.width, containerHeight / 2);
            CGPoint controlPoint = CGPointMake(
                (currPoint.x + nextPoint.x) / 2, 
                MAX(MIN((containerHeight/2) - (posNegMul * perc * containerHeight), controlPointYBottomBound), controlPointYTopBound)
                // _displayUpdateCount % 2 == 0 ? (i % 2 == 0 ? controlPointYTopBound : containerHeight / 2) : containerHeight / 2
            );

            _destControlHeights[i] = controlPoint.y;
            _sourceControlHeights[i] = _currControlHeights[i];

            [_wavyLinesPath addQuadCurveToPoint:nextPoint controlPoint:controlPoint];

            // if (i % 2 != 0) {
            //     continue;
            // }

            // CGPoint currPoint = [_wavyLinesPath currentPoint];
            // CGPoint nextPoint = CGPointMake(frame.origin.x + frame.size.width + barWidth + _barSpacing, containerHeight / 2);
            // CGPoint controlPoint1 = CGPointMake(
            //     (currPoint.x + nextPoint.x) / 2, 
            //     MAX(MIN((containerHeight/2) + (perc * containerHeight), controlPointYBottomBound), controlPointYTopBound)
            // );
            // CGPoint controlPoint2 = CGPointMake(
            //     (currPoint.x + nextPoint.x) / 2, 
            //     MAX(MIN((containerHeight/2) - (perc * containerHeight), controlPointYBottomBound), controlPointYTopBound)
            // );

            // [_wavyLinesPath addCurveToPoint:nextPoint controlPoint1:controlPoint1 controlPoint2:controlPoint2];
        }  
    }

    [UIView commitAnimations];

    if (_lineStackEnabled) {

        for (NSInteger i = 0; i < [_lineStackInfo count]; i++) {

            NSDictionary *lineInfo = _lineStackInfo[i];
            UIBezierPath *path = lineInfo[@"path"];
            CAShapeLayer *layer = lineInfo[@"layer"];

            if (!path || !layer) {
                continue;
            }

            CABasicAnimation *morph = [CABasicAnimation animationWithKeyPath:@"path"];
            morph.duration = 2;
            // morph.fromValu
            morph.fillMode = kCAFillModeForwards;
            morph.removedOnCompletion = NO; 
            morph.toValue = (id)path.CGPath;
            // [layer addAnimation:morph forKey:nil];
            [layer addAnimation:morph forKey:@"MELO_CAANIMATION_LINE_STACK_PATH"];
        }  
    }

    // if (_wavyLinesEnabled) {

    //     CABasicAnimation *morph = [CABasicAnimation animationWithKeyPath:@"path"];
    //     morph.duration = 0.75;
    //     // morph.fromValue = (id)_prevPath.CGPath;
    //     // _wavyLinesShapeLayer.path = _wavyLinesPath.CGPath;
    //     morph.toValue = (id)_wavyLinesPath.CGPath;
    //     morph.fillMode = kCAFillModeForwards;
    //     morph.removedOnCompletion = NO; 
    //     // morph.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    //     [_wavyLinesShapeLayer addAnimation:morph forKey:nil];
    // }

    _wavyLinesAnimationStartTimestamp = 0;
    // _wavyLinesShapeLayer.path = [self getCurrentInterpolatedBezierPath:1].CGPath;
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

- (void)startDisplayLink {
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink:)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)stopDisplayLink {

    if (_displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
    }
}

- (void)handleDisplayLink:(CADisplayLink *)displayLink {
    
    if (!_wavyLinesAnimationStartTimestamp) {
        _wavyLinesAnimationStartTimestamp = displayLink.timestamp;
    }

    NSTimeInterval elapsed = (displayLink.timestamp - _wavyLinesAnimationStartTimestamp);
    [Logger logStringWithFormat:@"timestamp: %f, start: %f, elapsed: %f", displayLink.timestamp, _wavyLinesAnimationStartTimestamp, elapsed];

    // self.shapeLayer.path = [[self pathAtInterval:elapsed] CGPath];

    // if (elapsed >= wavyLinesAnimationDuration) {
    //     // [self stopDisplayLink];
    //     // self.shapeLayer.path = [[self pathAtInterval:0] CGPath];
    //     // self.statusLabel.text = [NSString stringWithFormat:@"loopCount = %.1f frames/sec", self.loopCount / kSeconds];
    // }

    // if (elapsed < _wavyLinesAnimationDuration) {

    float animationPercent = MIN(elapsed / _wavyLinesAnimationDuration, 1);
    // float animationPercent = 0.5;
    _wavyLinesShapeLayer.path = [self getCurrentInterpolatedBezierPath:animationPercent].CGPath;
}

- (UIBezierPath *)getCurrentInterpolatedBezierPath:(float)animationPercent {

    // i think calculating the new control points should be done somewhere else
    float destWeight = MIN(MAX(animationPercent, 0), 1);
    float sourceWeight = 1 - destWeight;

    // TODO: could even combine this with the loop below
    for (NSInteger i = 0; i < _numBars; i++) {
        _currControlHeights[i] = sourceWeight * _sourceControlHeights[i] + destWeight * _destControlHeights[i];
    }

    UIBezierPath *path = [UIBezierPath new];

    CGFloat pointY = self.bounds.size.height / 2;
    CGFloat pointSpacing = self.bounds.size.width / (_numBars + 1);

    [path moveToPoint:CGPointMake(0, pointY)];

    for (NSInteger i = 0; i < _numBars; i++) { 

        CGPoint currPoint = CGPointMake(i * pointSpacing, pointY); // TODO, rather than creating a new currentPoint every time, you could just set it equal to next point at the end of the loop
        CGPoint nextPoint = CGPointMake((i + 1) * pointSpacing, pointY);
        CGPoint controlPoint = CGPointMake((currPoint.x + nextPoint.x) / 2, _currControlHeights[i]);

        [path addQuadCurveToPoint:nextPoint controlPoint:controlPoint];

    }

    return path;
}

@end