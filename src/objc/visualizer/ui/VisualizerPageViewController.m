
#import "VisualizerPageViewController.h"
#import "../../managers/managers.h"
#import "../processing/processing.h"
#import "BarsVisualizerViewController.h"
#import "LineStackVisualizerViewController.h"
#import "WavyLineVisualizerViewController.h"
#import "GridVisualizerViewController.h"

@implementation VisualizerPageViewController

// default initializer
- (instancetype)init {

    if ((self = [super init])) {

        _updateInterval = 0.01;
        _barsVizEnabled = NO;
        _lineStackVizEnabled = NO;
        _wavyLineVizEnabled = NO;
        _gridVizEnabled = YES;
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
    CGFloat containerHeight = 200;
    CGRect containerFrame = CGRectMake(margins, (screenBounds.size.height - containerHeight) / 2, screenBounds.size.width - (margins * 2), containerHeight);

    if (_barsVizEnabled) {
        BarsVisualizerViewController *barsVizVC = [BarsVisualizerViewController new];
        [self setBarsVizViewController:barsVizVC];
        [self addChildViewController:barsVizVC];   
        barsVizVC.view.frame = containerFrame;
        [self.view addSubview:barsVizVC.view];
        [barsVizVC didMoveToParentViewController:self];
    }

    if (_lineStackVizEnabled) {
        LineStackVisualizerViewController *lineStackVizVC = [LineStackVisualizerViewController new];
        [self setLineStackVizViewController:lineStackVizVC];
        [self addChildViewController:lineStackVizVC];   
        lineStackVizVC.view.frame = containerFrame;
        [self.view addSubview:lineStackVizVC.view];
        [lineStackVizVC didMoveToParentViewController:self];
    }

    if (_wavyLineVizEnabled) {
        WavyLineVisualizerViewController *wavyLineVizVC = [WavyLineVisualizerViewController new];
        [self setWavyLineVizViewController:wavyLineVizVC];
        [self addChildViewController:wavyLineVizVC];   
        wavyLineVizVC.view.frame = containerFrame;
        [self.view addSubview:wavyLineVizVC.view];
        [wavyLineVizVC didMoveToParentViewController:self];
    }

    if (_gridVizEnabled) {
        GridVisualizerViewController *gridVizVC = [GridVisualizerViewController new];
        [self setGridVizViewController:gridVizVC];
        [self addChildViewController:gridVizVC];   
        gridVizVC.view.frame = containerFrame;
        [self.view addSubview:gridVizVC.view];
        [gridVizVC didMoveToParentViewController:self];

        UIButton *debugToggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [debugToggleButton addTarget:self action:@selector(handleTestButton:) forControlEvents:UIControlEventTouchUpInside];
        debugToggleButton.backgroundColor = [UIColor secondaryLabelColor];
        [debugToggleButton setTitle:@"Toggle Circles" forState:UIControlStateNormal];
        debugToggleButton.frame = CGRectMake(containerFrame.origin.x, containerFrame.origin.y + containerFrame.size.height + 40, 100, 20);
        debugToggleButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.view addSubview:debugToggleButton];
        [self setCircleDebugToggleButton:debugToggleButton];
    }


    // _vizView = [[VisualizerView alloc] initWithFrame:containerFrame];
    // [self.view addSubview:_vizView];

    // CGRect bpmLabelFrame = CGRectMake(containerFrame.origin.x, containerFrame.origin.y + containerFrame.size.height + margins, screenBounds.size.width - (margins * 2), 40);
    // _bpmLabel = [[UILabel alloc] initWithFrame:bpmLabelFrame];
    // _bpmLabel.text = @"BPM: ";

    // [self.view addSubview:_bpmLabel];
}

- (void)handleTestButton:(UIButton *)sender {
    if (_gridVizEnabled) {

        GridVisualizerViewController *gridVizVC = [self gridVizViewController];
        [gridVizVC toggleCircleDebugLayer];

    }
}

// called when the view appeared on screen
- (void)viewDidAppear:(BOOL)arg1 {
    [super viewDidAppear:arg1];

    // [_vizView startUpdateTimer];
    // [self startUpdateTimer];
    // [_vizView startDisplayLink];

    // VisualizerManager *visualizerManager = [VisualizerManager sharedInstance];
    // visualizerManager.numVisualizersActive++;
}

// called when the view disappeared from the screen
- (void)viewDidDisappear:(BOOL)arg1 {
    [super viewDidDisappear:arg1];

    // [_vizView invalidateUpdateTimer];
    // [self invalidateUpdateTimer];
    // [_vizView stopDisplayLink];

    // VisualizerManager *visualizerManager = [VisualizerManager sharedInstance];
    // visualizerManager.numVisualizersActive--;
}

// update the visualizer display with processed audio data
- (void)updateVisualizerDisplay {

    MeloManager *meloManager = [MeloManager sharedInstance];
    VisualizerManager *visualizerManager = [VisualizerManager sharedInstance];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:_updateInterval * 40];
    [UIView setAnimationBeginsFromCurrentState:YES];

    if (visualizerManager.hasRecentlyDetectedBeat) {
        CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
        CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
        CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
        UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];

        self.view.backgroundColor = color;
        // _bpmLabel.textColor = color;
        visualizerManager.hasRecentlyDetectedBeat = NO;
    }

    [UIView commitAnimations];


    float bpm = [visualizerManager calculateBPM];
    _bpmLabel.text = [NSString stringWithFormat:@"BPM: %.3f", bpm];
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
    [self updateVisualizerDisplay];
}
@end