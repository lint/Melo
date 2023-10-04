
#import <UIKit/UIKit.h>
#import "hooks.h"
#import "../objc/objc_classes.h"
#import "../interfaces/interfaces.h"

// hooks focused on backporting features from ios 16 and 17
%group BackportGroup

%hook MusicNowPlayingControlsViewController
%property(strong, nonatomic) UIView *test;

// called when the music player view is loaded into memory
- (void)viewDidLoad {

    [Logger logStringWithFormat:@"ViewController: %p viewDidLoad", self];
    %orig;

    MeloManager *meloManager = [MeloManager sharedInstance];

    BOOL shouldApplyCustomValues = [meloManager prefsBoolForKey:@"newMusicPlayerEnabled"];

    PlayerTimeControl *timeControl = (PlayerTimeControl *)MSHookIvar<UIControl *>(self, "timeControl");
    VolumeSlider *volumeSlider = MSHookIvar<VolumeSlider *>(self, "volumeSlider");
    
    [timeControl setShouldApplyCustomValues:shouldApplyCustomValues];
    [volumeSlider setShouldApplyCustomValues:shouldApplyCustomValues];

    [timeControl createCustomTimeLabels];
    [volumeSlider createCustomTrackViews];
    [volumeSlider applyCustomTrackCornerRadius];
    [volumeSlider backupStockThumbImage];
    
    // setup ios 16 music player if applicable
    if (shouldApplyCustomValues) {

        [timeControl setKnobHidden:YES];
        [volumeSlider setStockImageViewsHidden:YES];
    }

    // add an observer for whenever a backport preferences change was detected
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBackportPrefsUpdate:) name:@"MELO_NOTIFICATION_PREFS_UPDATED_BACKPORT" object:nil];

    // // UIView *view = [self view];
    // // MeloModernSlider *test = [[MeloModernSlider alloc] initWithFrame:CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height)];

    // [self setTest:test];
    // [timeControl addSubview:test];


}

// called whenever the music player is about to appear
- (void)viewWillAppear:(BOOL)arg1 {
    %orig;

    MeloManager *meloManager = [MeloManager sharedInstance];

    // the knob of the volume slider must be hidden again
    if ([meloManager prefsBoolForKey:@"newMusicPlayerEnabled"]) {

        VolumeSlider *volumeSlider = MSHookIvar<VolumeSlider *>(self, "volumeSlider");
        [volumeSlider setStockImageViewsHidden:YES];
    }
}

- (void)viewDidAppear:(BOOL)arg1 {
    %orig;


}

- (void)viewDidLayoutSubviews {

    %orig;
    // PlayerTimeControl *timeControl = (PlayerTimeControl *)MSHookIvar<UIControl *>(self, "timeControl");
    // UIView *test = [self test];
    // test.frame = CGRectMake(0, -40, timeControl.bounds.size.width, timeControl.bounds.size.height);
    // [test setNeedsLayout];


}

// update the view when backport preferences were changed
%new
- (void)handleBackportPrefsUpdate:(NSNotification *)arg1 {

    MeloManager *meloManager = [MeloManager sharedInstance];
    PlayerTimeControl *timeControl = (PlayerTimeControl *)MSHookIvar<UIControl *>(self, "timeControl");
    VolumeSlider *volumeSlider = MSHookIvar<VolumeSlider *>(self, "volumeSlider");

    BOOL shouldApplyCustomValues = [meloManager prefsBoolForKey:@"newMusicPlayerEnabled"];
    [timeControl setShouldApplyCustomValues:shouldApplyCustomValues];
    [volumeSlider setShouldApplyCustomValues:shouldApplyCustomValues];

    [timeControl setKnobHidden:shouldApplyCustomValues];
    [timeControl applyRoundedCorners];
    [volumeSlider applyCustomTrackCornerRadius];
    [volumeSlider setStockImageViewsHidden:shouldApplyCustomValues];

    [timeControl setNeedsLayout];
    [volumeSlider setNeedsLayout];
}

%end

// the volume slider in the music player
%hook VolumeSlider
%property(strong, nonatomic) AnimationManager *animationManager;
%property(strong, nonatomic) UIView *customElapsedView;
%property(strong, nonatomic) UIView *customRemainingView;
%property(strong, nonatomic) UIView *customTrackContainerView;
%property(strong, nonatomic) UIImageView *customMinValueView;
%property(strong, nonatomic) UIImageView *customMaxValueView;
%property(assign, nonatomic) BOOL largeSliderActive;
%property(assign, nonatomic) BOOL shouldApplyCustomValues;
%property(assign, nonatomic) BOOL shouldApplyLargeSliderWidth;
%property(strong, nonatomic) UIImage *stockThumbImage;

// initializer method
- (id)initWithFrame:(CGRect)arg1 style:(NSInteger)arg2 {
    id orig = %orig;

    // set default values to not apply custom changes
    [self setShouldApplyCustomValues:NO];
    [self setLargeSliderActive:NO];
    [self setShouldApplyLargeSliderWidth:NO];
    [self setAnimationManager:[AnimationManager new]];

    return orig;
}

// detect when the volume slider starts being used
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {

    BOOL orig = %orig;

    if (orig && [self shouldApplyCustomValues]) {
        [self animateCustomSliderSize:YES];
    }

    return orig;
}

// detect when the volume slider is no longer being touched 
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {

    if ([self shouldApplyCustomValues]) {
        [self animateCustomSliderSize:NO];
    }

    %orig;
}

// detect when the volume slider is no longer being touched 
- (void)cancelTrackingWithEvent:(UIEvent *)event {
    
    if ([self shouldApplyCustomValues]) {
        [self animateCustomSliderSize:NO];
    }

    %orig;
}

// detect when the volume slider is no longer being touched 
- (void)_endTracking {
    // %orig;

    if ([self shouldApplyCustomValues]) {
        [self animateCustomSliderSize:NO];
    }

    %orig;
}

// lays out the subviews of this view
- (void)layoutSubviews {

    %orig;

    if ([self shouldApplyCustomValues]) {
        [self layoutCustomMinMaxViews];
        [self layoutCustomTrackViews];

        [self setStockTrackViewsHidden:YES];
        [self setCustomViewsHidden:NO];
    } else {
        [self setStockTrackViewsHidden:NO];
        [self setCustomViewsHidden:YES];
    }
}

// provides the frame for the slider track view
- (CGRect)trackRectForBounds:(CGRect)bounds {

    CGRect orig = %orig;

    // apply the slider offset if applicable
    if ([self shouldApplyCustomValues] && [self largeSliderActive] && [self shouldApplyLargeSliderWidth] ) {
        CGFloat largeSliderOffset = 10;
        orig = CGRectMake(
            orig.origin.x - largeSliderOffset,
            orig.origin.y,
            orig.size.width + largeSliderOffset * 2,
            orig.size.height
        );
    }

    return orig;
}

// grow or shrink the custom slider when touches start or end
%new
- (void)animateCustomSliderSize:(BOOL)largeSliderActive {

    if (largeSliderActive == [self largeSliderActive]) {
        return;
    }

    [self setLargeSliderActive:largeSliderActive];
    
    NSDictionary *context = @{
        @"volumeSlider": self,
        @"shouldApplyLargeOriginalSliderWidth": @(largeSliderActive)
    };

    [UIView beginAnimations:@"MELO_ANIMATION_VOLUME_SLIDER_TOUCH" context:(__bridge_retained void *)context];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationDelegate:[self animationManager]];
    [UIView setAnimationDidStopSelector:@selector(handleAnimationDidStop:finished:context:)];
    [UIView setAnimationBeginsFromCurrentState:YES];

        [self layoutCustomMinMaxViews];
        [self layoutCustomTrackViews];
        [self applyCustomTrackCornerRadius];
        [self applyCustomViewsBackgroundColors];

    [UIView commitAnimations];
}

// set colors to highlight or not based on whether the large slider is active
%new
- (void)applyCustomViewsBackgroundColors {

    UIView *customElapsedView = [self customElapsedView];
    UIImageView *customMinValueView = [self customMinValueView];
    UIImageView *customMaxValueView = [self customMaxValueView];

    if ([self largeSliderActive]) {
        customElapsedView.backgroundColor = [UIColor labelColor];
        customMinValueView.tintColor = [UIColor labelColor];
        customMaxValueView.tintColor = [UIColor labelColor];
    } else {
        customElapsedView.backgroundColor = [self minimumTrackTintColor];
        customMinValueView.tintColor = [UIColor tertiaryLabelColor];
        customMaxValueView.tintColor = [UIColor tertiaryLabelColor];
    }   
}

// set the frames for the custom min max image views
%new
- (void)layoutCustomMinMaxViews {

    UIImageView *customMinValueView = [self customMinValueView];
    UIImageView *customMaxValueView = [self customMaxValueView];

    CGFloat largeSliderOffset = [self largeSliderActive] ? 14 : 0;
    CGFloat valueItemSpacing = 14; // stock spacing value
    CGRect bounds = [self bounds];

    // size the view to the size of the images
    [customMinValueView sizeToFit];
    [customMaxValueView sizeToFit];

    // create frames that align images to edge of bounds
    CGRect minFrame = CGRectMake(
        0 - largeSliderOffset,
        (bounds.size.height - customMinValueView.frame.size.height) / 2,
        customMinValueView.frame.size.width,
        customMinValueView.frame.size.height
    );
    CGRect maxFrame = CGRectMake(
        bounds.size.width + largeSliderOffset - customMaxValueView.frame.size.width,
        (bounds.size.height - customMaxValueView.frame.size.height) / 2,
        customMaxValueView.frame.size.width,
        customMaxValueView.frame.size.height
    ); 

    customMinValueView.frame = minFrame;
    customMaxValueView.frame = maxFrame;
}

// set the frames for the custom track views
%new
- (void)layoutCustomTrackViews {

    // ensure layoutCustomMinMaxViews is called first so that the min max image views' frames are set

    UIView *customElapsedView = [self customElapsedView];
    UIView *customRemainingView = [self customRemainingView];
    UIView *customTrackContainerView = [self customTrackContainerView];
    UIImageView *customMinValueView = [self customMinValueView];
    UIImageView *customMaxValueView = [self customMaxValueView];

    CGRect bounds = [self bounds];
    CGFloat largeSliderOffset = [self largeSliderActive] ? 10 : 0;
    CGFloat trackHeight = [self largeSliderActive] ? 18 : 8;
    CGFloat valueItemSpacing = 14; // stock spacing value
    float value = [(VolumeSlider*)self value];

    // create the frames for the track views

    CGRect containerFrame = CGRectMake(
        customMinValueView.frame.size.width + valueItemSpacing - largeSliderOffset,
        (bounds.size.height - trackHeight)/2,
        bounds.size.width - (customMinValueView.frame.size.width + customMaxValueView.frame.size.width + valueItemSpacing * 2) + largeSliderOffset * 2,
        trackHeight
    );

    CGRect elapsedViewFrame = CGRectMake(
        0,
        0,
        containerFrame.size.width * value,
        containerFrame.size.height
    );

    CGRect remainingViewFrame = CGRectMake(
        elapsedViewFrame.origin.x + elapsedViewFrame.size.width,
        0,
        containerFrame.size.width - elapsedViewFrame.size.width,
        containerFrame.size.height
    );

    customElapsedView.frame = elapsedViewFrame;
    customRemainingView.frame = remainingViewFrame;
    customTrackContainerView.frame = containerFrame;
}

// create custom volume slider track and min/max image views to replicate ios 16
%new
- (void)createCustomTrackViews {

    // create the custom volume slider track
    UIView *customElapsedView = [UIView new];
    UIView *customRemainingView = [UIView new];
    UIView *customTrackContainerView = [UIView new];

    customElapsedView.backgroundColor = [self minimumTrackTintColor];
    customRemainingView.backgroundColor = [self maximumTrackTintColor];

    customElapsedView.userInteractionEnabled = NO;
    customRemainingView.userInteractionEnabled = NO;

    [self setCustomElapsedView:customElapsedView];
    [self setCustomRemainingView:customRemainingView];
    [self setCustomTrackContainerView:customTrackContainerView];

    [customTrackContainerView addSubview:customElapsedView];
    [customTrackContainerView addSubview:customRemainingView];
    [self addSubview:customTrackContainerView];

    // create the custom min and max slider views
    UIImageView *customMinValueView = [UIImageView new];
    UIImageView *customMaxValueView = [UIImageView new];

    UIImageSymbolConfiguration *imageConfig = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightUnspecified scale:UIImageSymbolScaleDefault];
    UIImage *minImage = [[UIImage systemImageNamed:@"speaker.fill" withConfiguration:imageConfig] imageWithTintColor:[UIColor tertiaryLabelColor]];
    UIImage *maxImage = [[UIImage systemImageNamed:@"speaker.wave.3.fill" withConfiguration:imageConfig] imageWithTintColor:[UIColor tertiaryLabelColor]];
    
    customMinValueView.image = minImage;
    customMaxValueView.image = maxImage;

    [self setCustomMinValueView:customMinValueView];
    [self setCustomMaxValueView:customMaxValueView];

    [self addSubview:customMinValueView];
    [self addSubview:customMaxValueView];
}

// set the corner radius of the custom track view
%new
- (void)applyCustomTrackCornerRadius {

    UIView *customTrackContainerView = [self customTrackContainerView];
    CGFloat cornerRadius = [self largeSliderActive] ? 9 : 4;

    customTrackContainerView.layer.cornerRadius = cornerRadius;
    customTrackContainerView.clipsToBounds = YES;
}

// hide the stock slider thumb image and min / max image views
%new
- (void)setStockImageViewsHidden:(BOOL)arg1 {

    UIImage *thumbImage;

    if (arg1) {
        // still provide thumb a decently sized rect so that it's still easily grabbable
        CGRect thumbRect = CGRectMake(0,0,40,40);     
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(40,40), false, 0);
        
        // set the thumb image to be transparent
        [[UIColor clearColor] setFill];     
        UIRectFill(thumbRect);
        thumbImage = UIGraphicsGetImageFromCurrentImageContext();     
        UIGraphicsEndImageContext(); 
    } else {
        thumbImage = [self stockThumbImage] ?: [UIImage systemImageNamed:@"circle.fill"];
    }
    
    [self setThumbImage:thumbImage forState:UIControlStateNormal];
    // [self setMinimumTrackImage:blankImg forState:UIControlStateNormal];
    // [self setMaximumTrackImage:blankImg forState:UIControlStateNormal];

    // hide the min / max image views
    UIImageView *minValueView = [self _minValueView];
    UIImageView *maxValueView = [self _maxValueView];

    minValueView.hidden = arg1;
    maxValueView.hidden = arg1;
}

// set the stock min and max track views to the given hidden value
%new
- (void)setStockTrackViewsHidden:(BOOL)arg1 {
    UIImageView *minTrackView = [self _minTrackView];
    UIImageView *maxTrackView = [self _maxTrackView];

    minTrackView.hidden = arg1;
    maxTrackView.hidden = arg1;
}

// set the custom track and min/max image views to the given hidden value
%new
- (void)setCustomViewsHidden:(BOOL)arg1 {

    UIView *customTrackContainerView = [self customTrackContainerView];
    UIImageView *customMinValueView = [self customMinValueView];
    UIImageView *customMaxValueView = [self customMaxValueView];

    customTrackContainerView.hidden = arg1;
    customMinValueView.hidden = arg1;
    customMaxValueView.hidden = arg1;
}

// backs up a reference to the original thumb image
%new
- (void)backupStockThumbImage {
    UIImage *thumbImage = [self thumbImageForState:UIControlStateNormal];
    [self setStockThumbImage:thumbImage];
}


%end


%hook PlayerTimeControl
%property(strong, nonatomic) AnimationManager *animationManager;
%property(strong, nonatomic) UILabel *customElapsedTimeLabel;
%property(strong, nonatomic) UILabel *customRemainingTimeLabel;
%property(assign, nonatomic) BOOL shouldApplyCustomValues;
%property(assign, nonatomic) BOOL largeSliderActive;
%property(strong, nonatomic) id emptySetCopy;

// default initializer 
- (id)init {
    id orig = %orig;

    // set default values 
    [orig setShouldApplyCustomValues:NO];
    [orig setLargeSliderActive:NO];
    [orig setAnimationManager:[AnimationManager new]];
    [orig setEmptySetCopy:[MSHookIvar<id>(self, "knobAvoidingViews") copy]];

    return orig;
}

// layout this view's subviews
- (void)layoutSubviews {

    // MSHookIvar<id>(self, "knobAvoidingViews") = [[self emptySetCopy] copy];

    %orig;

    if ([self shouldApplyCustomValues]) {
        
        [self applyKnobConstaints:YES];
        [self applyCustomSliderHeight];
        [self applyRoundedCorners];
        [self layoutCustomTimeLabels];
        [self applyElapsedTrackColor];
        [self setStockTimeLabelsHidden:YES];
        [self setCustomTimeLabelsHidden:NO];

    } else {
        [self applyKnobConstaints:NO];
        [self setStockTimeLabelsHidden:NO];
        [self setCustomTimeLabelsHidden:YES];
    }
}


// change the size of the knob while scrubbing to allow it to go the full width of the slider
%new
- (void)applyKnobConstaints:(BOOL)shouldHideKnob {
    NSArray *constraints = MSHookIvar<NSArray *>(self, "trackingConstraints");

    NSInteger constant = shouldHideKnob ? 0 : 32;

    for (NSLayoutConstraint *con in constraints) {
        [con setConstant:constant];
    }
}

// create custom time labels to avoid the knob avoiding affect
%new
- (void)createCustomTimeLabels {

    UIFont *font = [UIFont boldSystemFontOfSize:12];

    UILabel *customElapsedTimeLabel = [UILabel new];
    UILabel *customRemainingTimeLabel = [UILabel new];

    customElapsedTimeLabel.font = font;
    customRemainingTimeLabel.font = font;

    customElapsedTimeLabel.text = @"--:--";
    customRemainingTimeLabel.text = @"--:--";

    customElapsedTimeLabel.textColor = [UIColor tertiaryLabelColor];
    customRemainingTimeLabel.textColor = [UIColor tertiaryLabelColor];

    [self setCustomElapsedTimeLabel:customElapsedTimeLabel];
    [self setCustomRemainingTimeLabel:customRemainingTimeLabel];

    [self addSubview:customElapsedTimeLabel];
    [self addSubview:customRemainingTimeLabel];
}

// set the background color of the elapsed track view
%new
- (void)applyElapsedTrackColor {

    UIView *elapsedView = [self elapsedTrack];
    
    if ([self largeSliderActive]) {
        elapsedView.backgroundColor = [UIColor labelColor];
    } else {
        elapsedView.backgroundColor = [UIColor tertiaryLabelColor];
    }
}

// set the text and frame of the custom time labels
%new
- (void)layoutCustomTimeLabels {

    UILabel *elapsedTimeLabel = MSHookIvar<UILabel *>(self, "elapsedTimeLabel");
    UILabel *remainingTimeLabel = MSHookIvar<UILabel *>(self, "remainingTimeLabel");
    UILabel *customElapsedTimeLabel = [self customElapsedTimeLabel];
    UILabel *customRemainingTimeLabel = [self customRemainingTimeLabel];

    // update text to match stock elements
    customElapsedTimeLabel.text = elapsedTimeLabel.text;
    customRemainingTimeLabel.text = remainingTimeLabel.text;

    if ([self accessibilityIsLiveContent]) {
        customElapsedTimeLabel.hidden = YES;
        customRemainingTimeLabel.hidden = YES;
        return;
    } else {
        customElapsedTimeLabel.hidden = NO;
        customRemainingTimeLabel.hidden = NO;
    }

    CGFloat textYSpacing = 12;
    CGRect elapsedViewFrame = [self elapsedTrack].frame;
    CGRect remainingViewFrame = [self remainingTrack].frame;

    [customElapsedTimeLabel sizeToFit];
    [customRemainingTimeLabel sizeToFit];

    // align time labels to edges of time slider
    CGRect elapsedTimeFrame = CGRectMake(
        elapsedViewFrame.origin.x,
        elapsedViewFrame.origin.y + elapsedViewFrame.size.height + textYSpacing, 
        customElapsedTimeLabel.frame.size.width,
        customElapsedTimeLabel.frame.size.height
    );
    CGRect remainingTimeFrame = CGRectMake(
        remainingViewFrame.origin.x + remainingViewFrame.size.width - customRemainingTimeLabel.frame.size.width,
        remainingViewFrame.origin.y + remainingViewFrame.size.height + textYSpacing,
        customRemainingTimeLabel.frame.size.width,
        customRemainingTimeLabel.frame.size.height
    );
    
    customElapsedTimeLabel.frame = elapsedTimeFrame;
    customRemainingTimeLabel.frame = remainingTimeFrame;
}

// set the elapsed and remaining time labels to the given hidden value
%new
- (void)setStockTimeLabelsHidden:(BOOL)arg1 {
    
    UILabel *elapsedTimeLabel = MSHookIvar<UILabel *>(self, "elapsedTimeLabel");
    UILabel *remainingTimeLabel = MSHookIvar<UILabel *>(self, "remainingTimeLabel");

    // override arg1 if currently playing live content
    if ([self accessibilityIsLiveContent]) {
        arg1 = YES;
    }

    elapsedTimeLabel.hidden = arg1;
    remainingTimeLabel.hidden = arg1;

    // move the frames out of view so they don't get put into knobAvoidingViews and cause messy animations
    if (arg1) {
        elapsedTimeLabel.frame = CGRectMake(-1,-1,0,0);
        remainingTimeLabel.frame = CGRectMake(-1,-1,0,0);
    }
}

// set the custom elapsed and remaining time labels to the given hidden value
%new
- (void)setCustomTimeLabelsHidden:(BOOL)arg1 {
    
    UILabel *customElapsedTimeLabel = [self customElapsedTimeLabel];
    UILabel *customRemainingTimeLabel = [self customRemainingTimeLabel];

    customElapsedTimeLabel.hidden = arg1;
    customRemainingTimeLabel.hidden = arg1;
}

// set the knob's hidden status to the given value
%new
- (void)setKnobHidden:(BOOL)arg1 {
    UIView *knobView = [self knobView];
    knobView.hidden = arg1;
}

// apply rounded corners to time slider
%new
- (void)applyRoundedCorners {

    CGFloat cornerRadius = [self largeSliderActive] ? 9 : 4;
    UIView *elapsedView = [self elapsedTrack];
    UIView *remainingView = [self remainingTrack];
    UIView *liveTrackView = MSHookIvar<UIView *>(self, "liveTrack");

    elapsedView.layer.cornerRadius = cornerRadius;
    remainingView.layer.cornerRadius = cornerRadius;
    liveTrackView.layer.cornerRadius = cornerRadius;
}

// change the size of the slider and set various items' frames
%new
- (void)applyCustomSliderHeight {

    UIView *elapsedView = [self elapsedTrack];
    UIView *remainingView = [self remainingTrack];
    UIView *liveTrackView = MSHookIvar<UIView *>(self, "liveTrack");
    UILabel *liveLabel = [self liveLabel];

    CGRect bounds = [self bounds];
    CGFloat sliderHeight = [self largeSliderActive] ? 18 : 8;
    CGFloat sliderYOrigin = (bounds.size.height - sliderHeight) / 2;
    CGFloat largeSliderOffset = [self largeSliderActive] ? 10 : 0;

    CGRect elapsedViewFrame = CGRectMake(
        elapsedView.frame.origin.x - largeSliderOffset, 
        sliderYOrigin, 
        elapsedView.frame.size.width + largeSliderOffset, 
        sliderHeight
    );
    CGRect remainingViewFrame = CGRectMake(
        remainingView.frame.origin.x, 
        sliderYOrigin, 
        remainingView.frame.size.width + largeSliderOffset, 
        sliderHeight
    );
    CGRect liveTrackViewFrame = CGRectMake(
        liveTrackView.frame.origin.x,
        sliderYOrigin,
        liveTrackView.frame.size.width,
        sliderHeight
    );
    CGRect liveLabelFrame = CGRectMake(
        liveLabel.frame.origin.x,
        (bounds.size.height - liveLabel.frame.size.height) / 2,
        liveLabel.frame.size.width,
        liveLabel.frame.size.height
    );

    elapsedView.frame = elapsedViewFrame;
    remainingView.frame = remainingViewFrame;    
    liveTrackView.frame = liveTrackViewFrame;
    liveLabel.frame = liveLabelFrame;
}

// use this to detect when the music bar starts and ends scrubbing
- (void)panGestureRecognized:(UIGestureRecognizer *)arg1 {

    if (![self shouldApplyCustomValues]) {
        %orig;
        return;
    }

    if (arg1.state == UIGestureRecognizerStateBegan) {
        [Logger logString:@"pan gesture state began"];

        // calling %orig before animating allows the background color to stay
        %orig;
        [self animateLargeSlider:YES];

    } else if (arg1.state == UIGestureRecognizerStateEnded) {
        [Logger logString:@"pan gesture state ended"];

        // calling %orig after the animating allows it to play normally
        [self animateLargeSlider:NO];
        %orig;

    } else if (arg1.state == UIGestureRecognizerStateChanged) {
        // [Logger logString:@"pan gesture state changed"];
        %orig;

    } else {
        // [Logger logStringWithFormat:@"other state: %li", (long)arg1.state];
        %orig;
    }
}

// animate slider size and view color changes
%new 
- (void)animateLargeSlider:(BOOL)largeSliderActive {

    UILabel *customElapsedTimeLabel = [self customElapsedTimeLabel];
    UILabel *customRemainingTimeLabel = [self customRemainingTimeLabel];
    UIColor *textColor = largeSliderActive ? [UIColor labelColor] : [UIColor tertiaryLabelColor];

    customElapsedTimeLabel.textColor = textColor;
    customRemainingTimeLabel.textColor = textColor;

    [self setLargeSliderActive:largeSliderActive];

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];

        [self applyCustomSliderHeight];
        [self applyRoundedCorners];
        [self layoutCustomTimeLabels];
        [self applyElapsedTrackColor];

    [UIView commitAnimations];
}

%end

// playlist controller in Library > Playlists
%hook PlaylistsViewController
%property(assign, nonatomic) BOOL shouldApplyCustomValues;

// default initializer
- (id)init {
    id orig = %orig;

    [orig setShouldApplyCustomValues:NO];

    return orig;
}

// called when the view was loaded into memory
- (void)viewDidLoad {

    %orig;

    // check if setting is enabled and custom values should be applied
    MeloManager *meloManager = [MeloManager sharedInstance];
    [self setShouldApplyCustomValues:[meloManager prefsBoolForKey:@"smallerPlaylistsViewCellsEnabled"]];

    // add an observer for whenever a backport preferences change was detected
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBackportPrefsUpdate:) name:@"MELO_NOTIFICATION_PREFS_UPDATED_BACKPORT" object:nil];
}

// get the height of rows in the collection view
- (CGFloat)collectionView:(UICollectionView *)arg1 tableLayout:(id)arg2 heightForRowAtIndexPath:(NSIndexPath *)arg3 {

    MeloManager *meloManager = [MeloManager sharedInstance];
    
    if ([self shouldApplyCustomValues]) {

        // check if custom height is enabled
        if ([meloManager prefsBoolForKey:@"customPlaylistCellHeightEnabled"]) {
            return [meloManager prefsFloatForKey:@"customPlaylistCellHeight"];
        } else {
            return 80; // ios 16 cell height
        }
    } else {
        return %orig;
    }
}

// get the cell for a given index path
- (id)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    id orig = %orig;

    BOOL shouldApplyCustomValues = [self shouldApplyCustomValues];

    if ([self shouldApplyCustomValues]) {
        
        // check if the cell is the right class
        if ([orig isKindOfClass:objc_getClass("MusicApplication.PlaylistCell")] || [orig isKindOfClass:objc_getClass("MusicApplication.AddNewPlaylistCell")]) {
            [orig setShouldApplyCustomValues:YES];
        }
    }

    return orig;
}

// update the view when backport preferences were changed
%new
- (void)handleBackportPrefsUpdate:(NSNotification *)arg1 {

    MeloManager *meloManager = [MeloManager sharedInstance];
    UICollectionView *collectionView = [self findCollectionView];

    [self setShouldApplyCustomValues:[meloManager prefsBoolForKey:@"smallerPlaylistsViewCellsEnabled"]];

    // update the view
    if (collectionView) {
        [collectionView reloadData];
    }
}

// searches the view's subviews for a collection view 
%new
- (UICollectionView *)findCollectionView {

    UIView *view = [self view];

    if ([view isKindOfClass:[UICollectionView class]]) {
        return (UICollectionView *)view;
    }

    for (UIView *subview in [view subviews]) {
        if ([subview isKindOfClass:[UICollectionView class]]) {
            return (UICollectionView *)subview;
        }
    }

    return nil;
}

%end

// cell within the PlaylistsViewController
%hook PlaylistCell
%property(assign, nonatomic) BOOL shouldApplyCustomValues;

// default initializer
- (id)initWithFrame:(CGRect)arg1 {
    id orig = %orig;

    [self setShouldApplyCustomValues:NO];

    return orig;
}

// lays out this views subviews
- (void)layoutSubviews {

    if ([self shouldApplyCustomValues]) {
        
        // change the size of the artwork to fit within the new cell size
        id artworkComponent = MSHookIvar<id>(self, "artworkComponent");
        CGFloat imageSideLength = MAX([self bounds].size.height - 14, 0);

        MSHookIvar<CGSize>(artworkComponent, "idealImageSize") = CGSizeMake(imageSideLength, imageSideLength);
    }

    %orig;
}

%end


// cell within the PlaylistsViewController
%hook AddNewPlaylistCell
%property(assign, nonatomic) BOOL shouldApplyCustomValues;

// default initializer
- (id)initWithFrame:(CGRect)arg1 {
    id orig = %orig;

    [self setShouldApplyCustomValues:NO];

    return orig;
}

// lays out this views subviews
- (void)layoutSubviews {

    if ([self shouldApplyCustomValues]) {
        
        // change the size of the artwork to fit within the new cell size
        id artworkComponent = MSHookIvar<id>(self, "artworkComponent");
        CGFloat imageSideLength = MAX([self bounds].size.height - 14, 0);

        MSHookIvar<CGSize>(artworkComponent, "idealImageSize") = CGSizeMake(imageSideLength, imageSideLength);
    }

    %orig;
}

%end

%end

// layout hooks constructor
extern "C" void InitBackport() {

    MeloManager *meloManager = [MeloManager sharedInstance];

    if ([meloManager prefsBoolForKey:@"backportHooksEnabled"]) {
        %init(BackportGroup, 
            PlayerTimeControl = objc_getClass("MusicApplication.PlayerTimeControl"),
            VolumeSlider = objc_getClass("_TtCC16MusicApplication32NowPlayingControlsViewController12VolumeSlider"),
            PlaylistsViewController = objc_getClass("MusicApplication.PlaylistsViewController"),
            PlaylistCell = objc_getClass("MusicApplication.PlaylistCell"),
            AddNewPlaylistCell = objc_getClass("MusicApplication.AddNewPlaylistCell")
        );
    }
}