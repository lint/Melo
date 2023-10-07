
#import "MeloModernSlider.h"
#import "../utilities/utilities.h"

@implementation MeloModernSlider

// default initializer
- (instancetype)initWithFrame:(CGRect)arg1 {

    if ((self = [super initWithFrame:arg1])) {

        _value = 0;
        _viewSpacing = 10;
        _lastTouchPoint = CGPointZero;

        _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGestureUpdate:)];
        _longPressGesture.minimumPressDuration = 0;
        [self addGestureRecognizer:_longPressGesture];

        [self createSubviews];
    }

    return self;
}

// handle press detected on the slider
- (void)handleLongPressGestureUpdate:(UILongPressGestureRecognizer *)gesture {
    [Logger logStringWithFormat:@"MeloModernSlider handleLongPressGestureUpdate: %@", gesture];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {

        CGPoint point = [gesture locationInView:self];
        _lastTouchPoint = point;
        [self animateTrack:YES];

    } else if (gesture.state == UIGestureRecognizerStateChanged) {

        CGPoint point = [gesture locationInView:self];
        [self calculateValueWithPoint:point];
        [self setNeedsLayout];

    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        _lastTouchPoint = CGPointZero;
        [self animateTrack:NO];
    }
}

// update the value with a new touch point
- (void)calculateValueWithPoint:(CGPoint)point {

    CGFloat pointDiff = point.x - _lastTouchPoint.x;
    CGFloat valueDiff = pointDiff / self.bounds.size.width;
    CGFloat newValue = _value + valueDiff;

    if (newValue < 0) {
        newValue = 0;
    } else if (newValue > 1) {
        newValue = 1;
    }

    _value = newValue;
    _lastTouchPoint = point;
}
// create and set up all subviews
- (void)createSubviews {

    // create new view instances
    _minImageView = [UIImageView new];
    _maxImageView = [UIImageView new];
    _minTrackView = [UIView new];
    _maxTrackView = [UIView new];
    _trackContainerView = [UIView new];

    // set view colors
    _minTrackView.backgroundColor = [UIColor tertiaryLabelColor];
    _maxTrackView.backgroundColor = [UIColor quaternaryLabelColor];
    _minImageView.tintColor = [UIColor secondaryLabelColor];
    _maxImageView.tintColor = [UIColor secondaryLabelColor];

    // mask track 
    _trackContainerView.clipsToBounds = YES;
    _trackContainerView.layer.cornerRadius = 4;

    // disable interaction with subviews to allow gesture recognizer to see touch events
    _minImageView.userInteractionEnabled = NO;
    _maxImageView.userInteractionEnabled = NO;
    _minTrackView.userInteractionEnabled = NO;
    _maxTrackView.userInteractionEnabled = NO;
    _trackContainerView.userInteractionEnabled = NO;

    // arrange view hierarchy
    [_trackContainerView addSubview:_minTrackView];
    [_trackContainerView addSubview:_maxTrackView];
    [self addSubview:_minImageView];
    [self addSubview:_maxImageView];
    [self addSubview:_trackContainerView];
}

// set the images for the min and max views
- (void)setImagesForMinImage:(NSString *)minImageName maxImage:(NSString *)maxImageName {
    
    UIImageSymbolConfiguration *imageConfig = [UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightBold scale:UIImageSymbolScaleDefault];
    UIImage *minImage = [[UIImage systemImageNamed:minImageName withConfiguration:imageConfig] imageWithTintColor:[UIColor secondaryLabelColor]];
    UIImage *maxImage = [[UIImage systemImageNamed:maxImageName withConfiguration:imageConfig] imageWithTintColor:[UIColor secondaryLabelColor]];
    
    _minImageView.image = minImage;
    _maxImageView.image = maxImage;
}

// set frames of this view's subviews
- (void)layoutSubviews {
    [super layoutSubviews];
    [self calculateSubviewFrames];
}

// animate the track's touch start / stop animation
- (void)animateTrack:(BOOL)isTouchActive {

    // only animate if changing status
    if (isTouchActive == self.isTouchActive) {
        return;
    }

    self.isTouchActive = isTouchActive;

    // ensure that the animation is called on the main thread
    [self performSelectorOnMainThread:@selector(executeTrackAnimation) withObject:nil waitUntilDone:NO];
}

// actually execute the animation to change view colors and frames
- (void)executeTrackAnimation {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];

        [self calculateSubviewFrames];
        [self applyTrackCornerRadius];
        [self applyViewColors];

    [UIView commitAnimations];
}

// set the track's corner radius depending on if a touch is currently active
- (void)applyTrackCornerRadius {
    CGFloat cornerRadius = self.isTouchActive ? 8 : 3.5;
    _trackContainerView.layer.cornerRadius = cornerRadius;
}

// set the track and images views' colors depending on if a touch is currently active
- (void)applyViewColors {
    UIColor *color = self.isTouchActive ? [UIColor labelColor] : [UIColor tertiaryLabelColor];
    _minTrackView.backgroundColor = color;
    _minImageView.tintColor = color;
    _maxImageView.tintColor = color;
}

// calculates the positions and sizes of all subviews
- (void)calculateSubviewFrames {

    CGFloat minImageSpacing = _minImageView.image ? _viewSpacing : 0;
    CGFloat maxImageSpacing = _maxImageView.image ? _viewSpacing : 0;

    // size the view to the size of the images
    [_minImageView sizeToFit];
    [_maxImageView sizeToFit];

    // large track is 10% bigger than normal size
    CGRect bounds = self.bounds;
    CGFloat defaultTrackWidth = bounds.size.width - _minImageView.frame.size.width - minImageSpacing - _maxImageView.frame.size.width - maxImageSpacing;
    CGFloat largeTrackOffset = self.isTouchActive ? (defaultTrackWidth) * 0.1 / 2 : 0;
    CGFloat trackWidth = defaultTrackWidth + largeTrackOffset * 2;
    CGFloat trackHeight = self.isTouchActive ? 18 : 7;

    // align min image frame to the leading edge
    CGRect minImageFrame = CGRectMake(
        0 - largeTrackOffset,
        (bounds.size.height - _minImageView.frame.size.height) / 2,
        _minImageView.frame.size.width,
        _minImageView.frame.size.height
    );
    
    // align track container frame to min image plus spacing or leading edge of bounds if no image
    CGRect trackContainerFrame = CGRectMake(
        minImageFrame.origin.x + minImageFrame.size.width + minImageSpacing,
        (bounds.size.height - trackHeight)/2,
        trackWidth,
        trackHeight
    );

    // align max image frame to track container plus spacing
    CGRect maxImageFrame = CGRectMake(
        trackContainerFrame.origin.x + trackContainerFrame.size.width + maxImageSpacing,
        (bounds.size.height - _maxImageView.frame.size.height) / 2,
        _maxImageView.frame.size.width,
        _maxImageView.frame.size.height
    ); 

    // min track sized proportionally to value
    CGRect minTrackFrame = CGRectMake(
        0,
        0,
        trackContainerFrame.size.width * self.value,
        trackContainerFrame.size.height
    );

    // min track sized proportionally to remaining value
    CGRect maxTrackFrame = CGRectMake(
        minTrackFrame.origin.x + minTrackFrame.size.width,
        0,
        trackContainerFrame.size.width - minTrackFrame.size.width,
        trackContainerFrame.size.height
    );

    // set view frames
    _trackContainerView.frame = trackContainerFrame;
    _minTrackView.frame = minTrackFrame;
    _maxTrackView.frame = maxTrackFrame;
    _minImageView.frame = minImageFrame;
    _maxImageView.frame = maxImageFrame;
}

@end