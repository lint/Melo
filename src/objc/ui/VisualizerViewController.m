
#import "VisualizerViewController.h"
#import "../managers/managers.h"
#import "VisualizerView.h"

@implementation VisualizerViewController

// default initializer
- (instancetype)init {

    if ((self = [super init])) {

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

    _vizView = [[VisualizerView alloc] initWithFrame:containerFrame];
    [self.view addSubview:_vizView];

    // CGRect bpmLabelFrame = CGRectMake(containerFrame.origin.x, containerFrame.origin.y + containerFrame.size.height + margins, screenBounds.size.width - (margins * 2), 40);
    // _bpmLabel = [[UILabel alloc] initWithFrame:bpmLabelFrame];
    // _bpmLabel.text = @"BPM: ";

    // [self.view addSubview:_bpmLabel];
}

// called when the view appeared on screen
- (void)viewDidAppear:(BOOL)arg1 {
    [super viewDidAppear:arg1];

    [_vizView startUpdateTimer];

    LibraryMenuManager *libraryMenuManager = [LibraryMenuManager sharedInstance];
    VisualizerManager *visualizerManager = libraryMenuManager.visualizerManager;
    visualizerManager.numVisualizersActive++;
}

// called when the view disappeared from the screen
- (void)viewDidDisappear:(BOOL)arg1 {
    [super viewDidDisappear:arg1];

    [_vizView invalidateUpdateTimer];

    LibraryMenuManager *libraryMenuManager = [LibraryMenuManager sharedInstance];
    VisualizerManager *visualizerManager = libraryMenuManager.visualizerManager;
    visualizerManager.numVisualizersActive--;
}

// update the visualizer display with processed audio data
- (void)updateVisualizerDisplay {

    // MeloManager *meloManager = [MeloManager sharedInstance];
    // LibraryMenuManager *libraryMenuManager = [LibraryMenuManager sharedInstance];
    // VisualizerManager *visualizerManager = libraryMenuManager.visualizerManager;

    // if (visualizerManager.hasRecentlyDetectedBeat) {
    //      CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    //     CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    //     CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    //     UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];

    //     self.view.backgroundColor = color;
    //     // _bpmLabel.textColor = color;
    //     visualizerManager.hasRecentlyDetectedBeat = NO;
    // }

    // float bpm = [visualizerManager calculateBPM];
    // _bpmLabel.text = [NSString stringWithFormat:@"BPM: %.3f", bpm];
}

@end