
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "hooks.h"
#import "../objc/objc_classes.h"
#import "../interfaces/interfaces.h"

%group WiggleModeGroup

%hook VerticalStackScrollView
%property(assign, nonatomic) BOOL hasDelayedContentSizeChange;
%property(assign, nonatomic) CGSize delayedContentSize;

// prevents instaneous (and glitchy) shrinking of the main scroll view while in wiggle mode
- (void)setContentSize:(CGSize)arg1 {

    LibraryRecentlyAddedViewController *currentLRAVC = [[MeloManager sharedInstance] currentLRAVC];

    // check if there is a current library recently added view controller 
    if (!currentLRAVC) {
        [self setHasDelayedContentSizeChange:NO];
        %orig;
        return;
    }

    WiggleModeManager *wiggleManager = [currentLRAVC wiggleModeManager];
    BOOL inWiggleMode = [wiggleManager inWiggleMode];

    // allow the content size change to go through if not in wiggle mode, or if the new height is larger than the current height
    if ((inWiggleMode && arg1.height > [self contentSize].height) || !inWiggleMode) {
        [self setHasDelayedContentSizeChange:NO];
        // [UIView animateWithDuration:0.1 animations:^{
        // TODO: should i always animate this? there is a setContentSize:animated: method, which i could potentially use instead of manually animating here?
        // moved animation to apply delayed content size if needed
            %orig;
        // }];
    
    // delay the content size change 
    } else {
        [self setHasDelayedContentSizeChange:YES];
        [self setDelayedContentSize:arg1];
    }
}

// attempts to apply the content size change if one has been delayed while in wiggle mode
%new
- (void)applyDelayedContentSizeIfNeeded {
    if ([self hasDelayedContentSizeChange]) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1];
            [self setContentSize:[self delayedContentSize]];
        [UIView commitAnimations];
    }
}

%end


%hook AlbumCell
%property(strong, nonatomic) NSString *identifier;
%property(strong, nonatomic) UIView *wiggleModeFakeAlbumView;
%property(strong, nonatomic) UIImageView *wiggleModeFakeAlbumIconView;

- (void)layoutSubviews {
    %orig;

    MeloManager *meloManager = [MeloManager sharedInstance];
    id dataSource = [[self _collectionView] dataSource];

    if ([dataSource isKindOfClass:objc_getClass("MusicApplication.LibraryRecentlyAddedViewController")]) {
        
        WiggleModeManager *wiggleManager = [dataSource wiggleModeManager];
        RecentlyAddedManager *recentlyAddedManager = [dataSource recentlyAddedManager];
        Album *album = [recentlyAddedManager albumWithIdentifier:[self identifier]];
        
        if ([meloManager prefsBoolForKey:@"wiggleModeShakeAnimationsEnabled"]) {
            if (wiggleManager && ![album isFakeAlbum]) {
                [wiggleManager inWiggleMode] ? [self addShakeAnimation] : [self removeShakeAnimation];
            } else if ([album isFakeAlbum]) {
                [self removeShakeAnimation];
            }
        }

        [self layoutWiggleModeFakeAlbumViews];   
    }
}

// layout views for wiggle mode's fake insertion album
%new
- (void)layoutWiggleModeFakeAlbumViews {

    MeloManager *meloManager = [MeloManager sharedInstance];
    id dataSource = [[self _collectionView] dataSource];

    WiggleModeManager *wiggleManager = [dataSource wiggleModeManager];
    RecentlyAddedManager *recentlyAddedManager = [dataSource recentlyAddedManager];
    Album *album = [recentlyAddedManager albumWithIdentifier:[self identifier]];
    
    UIView *wiggleModeFakeAlbumView = [self wiggleModeFakeAlbumView];
    UIImageView *wiggleModeFakeAlbumIconView = [self wiggleModeFakeAlbumIconView];
    UIView *artworkView = MSHookIvar<UIView *>(MSHookIvar<id>(self, "artworkComponent"), "imageView");
    // UIView *customTextView = [self respondsToSelector:@selector(customTextView)] ? [self customTextView] : nil;
    
    if ([album isFakeAlbum] && wiggleModeFakeAlbumView) {
        
        // doesn't need to be artworkView necessarily
        wiggleModeFakeAlbumView.frame = CGRectMake(0, 0, artworkView.frame.size.width, artworkView.frame.size.width);

        CGFloat radius;            
        if ([meloManager prefsBoolForKey:@"customAlbumCellCornerRadiusEnabled"]) {
            radius = [[meloManager prefsObjectForKey:@"customAlbumCellCornerRadius"] floatValue] / 100 * [self frame].size.width;
        } else {
            radius = 4; // default radius
        }

        artworkView.hidden = YES;
        wiggleModeFakeAlbumView.hidden = NO;
        wiggleModeFakeAlbumView.clipsToBounds = YES;
        [[wiggleModeFakeAlbumView layer] setCornerRadius:radius];

        if (wiggleModeFakeAlbumIconView) {
            wiggleModeFakeAlbumIconView.hidden = NO;
            wiggleModeFakeAlbumIconView.frame = CGRectMake(0, 0, wiggleModeFakeAlbumView.frame.size.width / 2, wiggleModeFakeAlbumView.frame.size.height / 2);
            wiggleModeFakeAlbumIconView.center = wiggleModeFakeAlbumView.center;
        }

        if ([self respondsToSelector:@selector(setTextAndBadgeHidden:)]) {
            [self setTextAndBadgeHidden:YES];
        }

        if ([self respondsToSelector:@selector(setCustomTextViewHidden:)]) {
            [self setCustomTextViewHidden:YES];
        }

    } else if (wiggleModeFakeAlbumView) {
        wiggleModeFakeAlbumView.hidden = YES;
        artworkView.hidden = NO;

        if ([self respondsToSelector:@selector(setTextAndBadgeHidden:)]) {
            [self setTextAndBadgeHidden:NO];
        }

        if ([self respondsToSelector:@selector(setCustomTextViewHidden:)]) {
            [self setCustomTextViewHidden:NO];
        }

        if (wiggleModeFakeAlbumIconView) {
            wiggleModeFakeAlbumIconView.hidden = YES;
        }
    }
}

// create views for wiggle mode's fake insertion album
%new
- (void)createWiggleModeFakeAlbumView {

    MeloManager *meloManager = [MeloManager sharedInstance];
    UIView *fakeAlbumView = [self wiggleModeFakeAlbumView];

    if (!fakeAlbumView) {
        fakeAlbumView = [[UIView alloc] initWithFrame:[self bounds]];
        fakeAlbumView.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.2];

        UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"arrow.left.circle.fill"]];
        iconView.tintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.25];
        iconView.contentMode = UIViewContentModeScaleAspectFit;

        [self setWiggleModeFakeAlbumIconView:iconView];
        [fakeAlbumView addSubview:iconView];

        [self setWiggleModeFakeAlbumView:fakeAlbumView];
        [self addSubview:fakeAlbumView];

    } else if (![fakeAlbumView isDescendantOfView:self]) {

        [fakeAlbumView removeFromSuperview];
        [self addSubview:fakeAlbumView];
    }
}

// from https://github.com/tmded/ccshakelayout/blob/master/CCUIModuleHook.xm
%new
-(void)addShakeAnimation {
    CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];

    float distanceToWobble = 0.03f;
    float distanceToCorner = sqrt(pow([self bounds].size.height/2,2) + pow([self bounds].size.width/2,2));

    CGFloat wobbleAngle = acos(((2*pow(distanceToCorner, 2))-(pow(distanceToWobble, 2)))/(2*distanceToCorner*distanceToCorner)) * (180 / M_PI);
    NSValue* valLeft = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(wobbleAngle, 0.0f, 0.0f, 1.0f)];
    NSValue* valRight = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(-wobbleAngle, 0.0f, 0.0f, 1.0f)];
    animation.values = [NSArray arrayWithObjects:valLeft, valRight, nil];
    //animation.beginTime = CACurrentMediaTime() + excc;
    animation.autoreverses = YES;
    animation.duration = 0.125;
    animation.repeatCount = HUGE_VALF;

    [[self layer] removeAnimationForKey:@"position"];
    [[self layer] addAnimation:animation forKey:@"position"];
}

%new
-(void)removeShakeAnimation{
    [[self layer] removeAnimationForKey:@"position"];
}

%end

%hook LibraryRecentlyAddedViewController

// TODO: (just an indicator to update these comments)
// implemented for wiggle mode
%new
- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    [Logger logStringWithFormat:@"LRAVC: %p collectionView canMoveItemAtIndexPath:<%ld,%ld>", self, indexPath.section, indexPath.item];
    
    Album *album = [[self recentlyAddedManager] albumAtAdjustedIndexPath:indexPath];
    return ![album isFakeAlbum];
}

// implemented for wiggle mode TODO: update this line
%new
- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destIndexPath {
    [Logger logStringWithFormat:@"LRAVC: %p collectionView:moveItemAtIndexPath:<%ld,%ld> toIndexPath:<%ld,%ld>", 
        self, sourceIndexPath.section, sourceIndexPath.item, destIndexPath.section, destIndexPath.item];

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];

    if (sourceIndexPath && destIndexPath) {
        // Album *sourceAlbum = [recentlyAddedManager albumAtAdjustedIndexPath:sourceIndexPath];
        // NSString *sourceAlbumIdentifier = [apManager identifierForAlbumAtAdjustedIndexPath:sourceIndexPath];

        // [self updateDataByMovingItemAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
        // NSIndexPath *finalDestinationIndexPath = [apManager adjustedIndexPathForAlbumWithIdentifier:sourceAlbumIdentifier];
        // [collectionView moveItemAtIndexPath:sourceIndexPath toIndexPath:finalDestinationIndexPath];

        [recentlyAddedManager moveAlbumAtAdjustedIndexPath:sourceIndexPath toAdjustedIndexPath:destIndexPath];
        [self moveAlbumCellFromAdjustedIndexPath:sourceIndexPath toAdjustedIndexPath:destIndexPath dataUpdateBlock:nil]; 
    }
}

%new // technically this is used for interactive movement of cells in a uicollectionview, but since I do my own, this isn't called automatically
- (NSIndexPath *)collectionView:(UICollectionView *)collectionView targetIndexPathForMoveOfItemFromOriginalIndexPath:(NSIndexPath *)originalIndexPath 
    atCurrentIndexPath:(NSIndexPath *)currentIndexPath toProposedIndexPath:(NSIndexPath *)proposedIndexPath {

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    Album *proposedAlbumTarget = [recentlyAddedManager albumAtAdjustedIndexPath:proposedIndexPath];
    NSInteger recentlyAddedSectionIndex = [recentlyAddedManager numberOfSections] - 1;

    // TODO: actually do this? one of the fun things about wiggle mode is being able to whip an album thru recently added and watch them go everywhere
    // do not allow moves within the recent section
    // if (proposedIndexPath.section == recentlyAddedSectionIndex) {
    //     return [NSIndexPath indexPathForItem:0 inSection:recentlyAddedSectionIndex];
    // } 

    // offset the proposed path by -1 if attempting to move ontop of fake album from within the same section (ensures the fake album doesn't move)
    if ([proposedAlbumTarget isFakeAlbum]) {
        if (currentIndexPath.section == proposedIndexPath.section) {
            return [NSIndexPath indexPathForItem:proposedIndexPath.item - 1 inSection:proposedIndexPath.section];
        }
    }

    return proposedIndexPath;
}

%new
- (void)endWiggleMode {
    [Logger logStringWithFormat:@"LRAVC: %p - endWiggleMode", self];
    
    if ([self wiggleModeManager].inWiggleMode) {
        [self toggleWiggleMode];
    }
}

%new
- (void)toggleWiggleMode {
    [Logger logStringWithFormat:@"LRAVC: %p - toggleWiggleMode", self];

    MeloManager *meloManager = [MeloManager sharedInstance];
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    WiggleModeManager *wiggleManager = [self wiggleModeManager];

    UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");
    UIScrollView *scrollView = [[self parentViewController] contentScrollView];

    BOOL newWiggleModeState = !wiggleManager.inWiggleMode;
    wiggleManager.inWiggleMode = newWiggleModeState;

    // wiggle mode turned on
    if (newWiggleModeState) {

        // add an observer to end wiggle mode if the app loses focus
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endWiggleMode) name:UIApplicationWillResignActiveNotification object:nil];

        // adding a bar button to end wiggle mode
        //UIBarButtonItem *endWiggleModeBarButton = [[UIBarButtonItem alloc] initWithTitle:@"End Wiggle Mode" style:UIBarButtonItemStylePlain target:self action:@selector(endWiggleMode)];
        //[self parentViewController].navigationItem.leftBarButtonItem = endWiggleModeBarButton;

        // adding a button to end wiggle mode
        [self createEndWiggleModeButtonItems];

        UIView *endWiggleModeView = [wiggleManager endWiggleModeView];
        endWiggleModeView.hidden = NO;

        NSDictionary *context = @{
            @"view": [endWiggleModeView superview]
        };

        [UIView beginAnimations:@"MELO_ANIMATION_END_WIGGLE_VIEW_POP_UP" context:(__bridge_retained void *)context];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationDelegate:[self animationManager]];
        [UIView setAnimationDidStopSelector:@selector(handleAnimationDidStop:finished:context:)];
            endWiggleModeView.frame = [endWiggleModeView superview].bounds;
            scrollView.contentInset = UIEdgeInsetsMake(0, 0, endWiggleModeView.frame.size.height, 0); // TODO: is this actually animatable?
        [UIView commitAnimations];

        // creating a gesture recognizer for dragging
        if (![wiggleManager longPressRecognizer]) {
            UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");
            UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];

            wiggleManager.longPressRecognizer = recognizer;
            [collectionView addGestureRecognizer:recognizer];
            //collectionView.reorderingCadence = UICollectionViewReorderingCadenceFast; // commented out in old code
        }

        // getting indexes of collapsed sections to be uncollapsed
        NSMutableArray *indexesToUncollapse = [NSMutableArray array];

        // get index paths of fake albums to insert
        NSMutableArray *fakeAlbumIndexPaths = [NSMutableArray array];

        for (NSInteger i = 0; i < [recentlyAddedManager numberOfSections]; i++) {
            Section *section = [recentlyAddedManager sectionAtIndex:i];
            
            if (section.isCollapsed) {
                [indexesToUncollapse addObject:@(i)];
            }

            NSIndexPath *fakeAlbumIndexPath = [NSIndexPath indexPathForItem:[section numberOfAlbums] inSection:i];
            [fakeAlbumIndexPaths addObject:fakeAlbumIndexPath];
        }

        // uncollapse the sections (old code had this in a performBatchUpdates block, necessary?)
        for (NSNumber *index in indexesToUncollapse) {
            [self toggleSectionCollapsedAtIndex:[index integerValue]];
        }

        // insert fake albums for moving an album into an empty section (this must take place after uncollapsing sections)
        [recentlyAddedManager updateFakeInsertionAlbums:YES];

        // insert fake albums to every section
        [collectionView insertItemsAtIndexPaths:fakeAlbumIndexPaths];

        // starts shake animation on album cells and updates the collapse arrow view on section headers
        for (UIView *view in [collectionView _visibleViews]) {

            if ([view isKindOfClass:objc_getClass("MusicApplication.TitleSectionHeaderView")]) {
                TitleSectionHeaderView *headerView = (TitleSectionHeaderView *)view;
                [headerView transitionCollapseItemsForWiggleMode:newWiggleModeState];
            }

            [view setNeedsLayout];
        }

        // disabling navigation bar large title
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.25];
            [[self parentViewController] navigationItem].largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
        [UIView commitAnimations];

    // wiggle mode turned off
    } else {

        VerticalStackScrollView *scrollView = (VerticalStackScrollView *)[[self parentViewController] contentScrollView];

        // force stop scrolling so that the large title can reappear properly
        scrollView.scrollEnabled = NO;
        [scrollView setContentOffset:scrollView.contentOffset animated:NO];

        // removing end wiggle mode button
        UIView *endWiggleModeView = wiggleManager.endWiggleModeView;

        NSDictionary *context = @{
            @"endWiggleModeView": endWiggleModeView
        };

        [UIView beginAnimations:@"MELO_ANIMATION_END_WIGGLE_VIEW_DISMISS" context:(__bridge_retained void *)context];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationDelegate:[self animationManager]];
        [UIView setAnimationDidStopSelector:@selector(handleAnimationDidStop:finished:context:)];
            UIView *paletteView = MSHookIvar<UIView *>([self tabBarController], "paletteView");
            endWiggleModeView.frame =  CGRectMake(endWiggleModeView.frame.origin.x, paletteView.frame.origin.y, endWiggleModeView.frame.size.width, endWiggleModeView.frame.size.height);
            scrollView.contentInset = UIEdgeInsetsZero;
        [UIView commitAnimations];

        // re-enabling large title for navigation bar
        [[self parentViewController] navigationItem].largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;

        // removing observer for application losing focus
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];

        // removing long press recognizer from the collection view
        if (wiggleManager.longPressRecognizer) {
            [collectionView removeGestureRecognizer:wiggleManager.longPressRecognizer];
            wiggleManager.longPressRecognizer = nil;
        }

        // remove fake album index paths from the collection view
        NSMutableArray *fakeAlbumIndexPaths = [NSMutableArray array];

        for (NSInteger sectionIndex = 0; sectionIndex < [recentlyAddedManager numberOfSections]; sectionIndex++) {
            Section *section = [recentlyAddedManager sectionAtIndex:sectionIndex];

            for (NSInteger albumIndex = 0; albumIndex < [section numberOfAlbums]; albumIndex++) {
                Album *album = [section albumAtIndex:albumIndex];
                
                if ([album isFakeAlbum]) {
                    NSIndexPath *fakeAlbumIndexPath = [NSIndexPath indexPathForItem:albumIndex inSection:sectionIndex];
                    [fakeAlbumIndexPaths addObject:fakeAlbumIndexPath];
                }
            }
        }

        // remove fake albums from recentlyAddedManager's data
        [recentlyAddedManager updateFakeInsertionAlbums:NO];

        // remove fake albums from every section in the collection view
        [collectionView deleteItemsAtIndexPaths:fakeAlbumIndexPaths];

        // stops shake animation and causes collapsed item views to reappear
        for (UIView *view in [collectionView _visibleViews]) {
            [view setNeedsLayout];

            if ([view isKindOfClass:objc_getClass("MusicApplication.TitleSectionHeaderView")]) {
                TitleSectionHeaderView *headerView = (TitleSectionHeaderView *)view;
                [headerView transitionCollapseItemsForWiggleMode:NO];
            }
        }

        // fixing the scroll view
        scrollView.scrollEnabled = YES;
        [scrollView applyDelayedContentSizeIfNeeded];
    }
}

%new
- (void)createEndWiggleModeButtonItems {
    [Logger logStringWithFormat:@"LRAVC: %p - createEndWiggleModeButtonItems", self];

    MeloManager *meloManager = [MeloManager sharedInstance];
    WiggleModeManager *wiggleManager = [self wiggleModeManager];

    if (![wiggleManager endWiggleModeView]) {

        UITabBarController *tabBarController = [self tabBarController];
        UIView *tabView = [tabBarController view];
        UIView *paletteView = MSHookIvar<UIView *>(tabBarController, "paletteView");
        UIView *paletteSeparatorView;

        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"14.0")) {
            paletteSeparatorView = MSHookIvar<UIView *>(paletteView, "$__lazy_storage_$_separator");
        } else {
            paletteSeparatorView = MSHookIvar<UIView *>(paletteView, "separator");
        }

        CGSize screenSize = [[UIScreen mainScreen] bounds].size;

        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial];
        UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect style:UIVibrancyEffectStyleSeparator];

        //CGRect endWiggleFrame = CGRectMake(0, screenSize.height, screenSize.width, 50);
        CGRect endWiggleFrame = CGRectMake(0, paletteView.frame.origin.y - 50, screenSize.width, 50);

        UIView *endWiggleWrapperView = [[UIView alloc] initWithFrame:endWiggleFrame];
        endWiggleWrapperView.clipsToBounds = YES;
        endWiggleWrapperView.userInteractionEnabled = NO;

        UIVisualEffectView *endWiggleBackgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        //CGRect wiggleBackgroundFrame = CGRectMake(0, paletteView.frame.origin.y - 50, screenSize.width, 50);

        endWiggleBackgroundView.frame = CGRectMake(0, paletteView.frame.origin.y, screenSize.width, 50);

        UIVisualEffectView *endWiggleSeparatorView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
        endWiggleSeparatorView.frame = CGRectMake(0, endWiggleFrame.size.height - .5, screenSize.width, .5);
        endWiggleSeparatorView.backgroundColor = paletteSeparatorView.backgroundColor;//[UIColor colorWithRed:1 green:1 blue:1 alpha:0.3];

        UIButton *endWiggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [endWiggleButton addTarget:self action:@selector(endWiggleMode) forControlEvents:UIControlEventTouchUpInside];
        [endWiggleButton addTarget:self action:@selector(triggerHapticFeedback) forControlEvents:UIControlEventTouchUpInside];
        endWiggleButton.frame = CGRectMake(screenSize.width / 8, 10, screenSize.width * .75, 30);
        NSString *endWiggleModeTitle = [meloManager prefsBoolForKey:@"wiggleModeShakeAnimationsEnabled"] ? @"End Wiggle Mode" : @"End \"Wiggle\" Mode";
        [endWiggleButton setTitle:endWiggleModeTitle forState:UIControlStateNormal];
        [endWiggleButton setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
        endWiggleButton.backgroundColor = [MeloUtils dictToColor:[meloManager prefsObjectForKey:@"customTintColor"]];
        endWiggleButton.layer.cornerRadius = 8;
        //endWiggleButton.clipsToBounds = YES;

        [[endWiggleBackgroundView contentView] addSubview:endWiggleButton];
        [[endWiggleBackgroundView contentView] addSubview:endWiggleSeparatorView];
        [endWiggleWrapperView addSubview:endWiggleBackgroundView];
        [tabView addSubview:endWiggleWrapperView];

        [tabView insertSubview:endWiggleWrapperView belowSubview:paletteView];

        // [self setEndWiggleModeView:endWiggleBackgroundView]; // TODO: this seems like a mistake
        wiggleManager.endWiggleModeView = endWiggleBackgroundView;
    }
}

%new
- (void)handleLongPress:(UILongPressGestureRecognizer *)arg1 {
    [Logger logStringWithFormat:@"LRAVC: %p - handleLongPress:(%@)", self, arg1];

    [Logger logStringWithFormat:@"parentViewController: %@", [self parentViewController]];
    [Logger logStringWithFormat:@"view: %@", [[self parentViewController] view]];

    CGPoint location = [arg1 locationInView:[[self parentViewController] view]];

    switch (arg1.state) {
        case UIGestureRecognizerStateBegan:
            [self startDragAtPoint:location];
            break;
        case UIGestureRecognizerStateChanged:
            [self updateDragAtPoint:location];
            break;
        case UIGestureRecognizerStateEnded:
            [self endDragAtPoint:location];
            break;
        default:
            break;
    }
}

%new
- (void)startDragAtPoint:(CGPoint)arg1 {
    [Logger logStringWithFormat:@"LRAVC: %p - startDragAtPoint:()", self];

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    WiggleModeManager *wiggleManager = [self wiggleModeManager];

    UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");
    UIView *parentView = [[self parentViewController] view];
    //NSIndexPath *sourceIndexPath = [collectionView indexPathForItemAtPoint:arg1];

    NSIndexPath *sourceIndexPath = [collectionView indexPathForItemAtPoint:[collectionView convertPoint:arg1 fromView:parentView]];

    [Logger logStringWithFormat:@"sourceIndexPath: %@", sourceIndexPath];

    [self collectionView:collectionView canMoveItemAtIndexPath:sourceIndexPath];

    if (sourceIndexPath && [self collectionView:collectionView canMoveItemAtIndexPath:sourceIndexPath]) {

        Album *album = [recentlyAddedManager albumAtAdjustedIndexPath:sourceIndexPath];
        AlbumCell *cell = (AlbumCell *)[collectionView cellForItemAtIndexPath:sourceIndexPath];
        UIView *artworkView = MSHookIvar<UIView *>(MSHookIvar<id>(cell, "artworkComponent"), "imageView");

        //[self setOriginalIndexPath:sourceIndexPath];
        wiggleManager.draggingIndexPath = sourceIndexPath;
        wiggleManager.draggingAlbumIdentifier = album.identifier;

        CGRect draggingViewFrame = [parentView convertRect:cell.frame fromView:collectionView];
        //draggingView.frame = [parentView convertRect:artworkView.frame fromView:cell];

        UIView *draggingWrapperView = [[UIView alloc] initWithFrame:CGRectMake(draggingViewFrame.origin.x, draggingViewFrame.origin.y, draggingViewFrame.size.width, draggingViewFrame.size.width)];
        draggingWrapperView.clipsToBounds = YES;

        UIView *draggingView = [cell snapshotViewAfterScreenUpdates:YES];

        //UIView *draggingView = [artworkView snapshotViewAfterScreenUpdates:YES];
        draggingView.backgroundColor = [UIColor clearColor];

        draggingView.frame = [draggingWrapperView convertRect:draggingViewFrame fromView:parentView];
        //draggingView.frame = draggingWrapperView.bounds;

        [draggingWrapperView addSubview:draggingView];
        [parentView addSubview:draggingWrapperView];

        wiggleManager.draggingView = draggingWrapperView;
        
        //[self setDraggingOffset:CGPointMake(draggingView.center.x - arg1.x, draggingView.center.y - arg1.y)]; // commented out in old code
        // [self setDraggingOffset:CGPointMake(draggingWrapperView.center.x - arg1.x, draggingWrapperView.center.y - arg1.y)];
        wiggleManager.draggingOffset = CGPointMake(draggingWrapperView.center.x - arg1.x, draggingWrapperView.center.y - arg1.y);
        // hiding the cell and making the text disappear with an animation
        artworkView.alpha = 0;

        UIView *textStackView = MSHookIvar<UIView *>(cell, "textStackView");
        UIView *customTextView = [cell respondsToSelector:@selector(customTextView)] ? [cell customTextView] : nil;

        NSDictionary *context = @{
            @"cell": cell
        };

        [UIView beginAnimations:@"MELO_ANIMATION_HIDE_ALBUM_TEXT_ON_DRAG" context:(__bridge_retained void *)context];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationDelegate:[self animationManager]];
        [UIView setAnimationDidStopSelector:@selector(handleAnimationDidStop:finished:context:)];
            textStackView.alpha = 0;

            if (customTextView) {
                customTextView.alpha = 0;
            }
        [UIView commitAnimations];


        // what was i doing here? 
        // id detailTextComponent = MSHookIvar<id>(cell, "detailTextComponents");
        // HBLogDebug(@"detailTextComponent: %@", detailTextComponent);
        // UIView *detailTextDrawView = MSHookIvar<UIView *>(detailTextComponent, "textDrawingView");
        // HBLogDebug(@"detailTextDrawView: %@", detailTextDrawView);

        // this name changed in ios 15?
        // id twoLineTitleTextComponent = MSHookIvar<id>(cell, "$__lazy_storage_$_twoLineTitleTextComponents");
        // HBLogDebug(@"twoLineTitleTextComponent: %@", twoLineTitleTextComponent);
        // UIView *twoLineTitleTextDrawView = MSHookIvar<UIView *>(twoLineTitleTextComponent, "textDrawingView");
        // HBLogDebug(@"twoLineTitleTextDrawView: %@", twoLineTitleTextDrawView);

        // TODO: old code had this animation separated from the previous one, should i keep it that way or combine them?
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
            draggingWrapperView.transform = CGAffineTransformMakeScale(1.15, 1.15);
        [UIView commitAnimations];

        wiggleManager.endWiggleModeView.userInteractionEnabled = NO; // TODO: why do i do this all the way down here?


        [self triggerHapticFeedback];

        //[collectionView.collectionViewLayout invalidateLayout]; // do I need this?
    }
}

%new
- (void)updateDragAtPoint:(CGPoint)arg1 {
    [Logger logStringWithFormat:@"LRAVC: %p - updateDragAtPoint:()", self];

    WiggleModeManager *wiggleManager = [self wiggleModeManager];
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    MeloManager *meloManager = [MeloManager sharedInstance];
    UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");

    NSIndexPath *draggingIndexPath = wiggleManager.draggingIndexPath;
    CGPoint draggingOffset = wiggleManager.draggingOffset;

    if (!wiggleManager.draggingView) {
        return;
    }

    wiggleManager.draggingView.center = CGPointMake(arg1.x + draggingOffset.x, arg1.y + draggingOffset.y);

    //NSIndexPath *newIndexPath = [collectionView indexPathForItemAtPoint:arg1];
    NSIndexPath *newIndexPath = [collectionView indexPathForItemAtPoint:[collectionView convertPoint:arg1 fromView:[[self parentViewController] view]]];

    // TODO: don't keep these values nil? guess it doesn't really matter
    newIndexPath = [self collectionView:nil targetIndexPathForMoveOfItemFromOriginalIndexPath:nil atCurrentIndexPath:draggingIndexPath toProposedIndexPath:newIndexPath];

    if (newIndexPath && ![newIndexPath isEqual:draggingIndexPath]) {
        [self collectionView:collectionView moveItemAtIndexPath:draggingIndexPath toIndexPath:newIndexPath];
        wiggleManager.draggingIndexPath = newIndexPath;
    }

    [self checkAutoScrollWithPoint:arg1];
}

%new
- (void)endDragAtPoint:(CGPoint)arg1 {
    [Logger logStringWithFormat:@"LRAVC: %p - endDragAtPoint:()", self];

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    WiggleModeManager *wiggleManager = [self wiggleModeManager];

    [wiggleManager invalidateTimers];

    UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");

    UIView *draggingView = wiggleManager.draggingView;
    NSIndexPath *draggingIndexPath = wiggleManager.draggingIndexPath;
    //NSIndexPath *originalIndexPath = [self originalIndexPath]; // old code

    if (!draggingView) {
        return;
    }

    AlbumCell *cell = (AlbumCell *)[collectionView cellForItemAtIndexPath:draggingIndexPath];
    UIView *artworkView = MSHookIvar<UIView *>(MSHookIvar<id>(cell, "artworkComponent"), "imageView");
    // CGPoint targetCenter = [[[self parentViewController] view] convertPoint:artworkView.center fromView:cell];
    CGPoint effectiveArtworkCenter = CGPointMake(cell.frame.origin.x + cell.frame.size.width/2, cell.frame.origin.y + cell.frame.size.width/2);
    CGPoint targetCenter = [[[self parentViewController] view] convertPoint:effectiveArtworkCenter fromView:collectionView]; // old code

    // NSMutableDictionary *context = [NSMutableDictionary dictionaryWithDictionary:@{
    //     @"cell": cell,
    //     @"artworkView": artworkView,
    //     @"wiggleManager": wiggleManager,
    //     @"draggingView": draggingView,
    //     @"textStackView": MSHookIvar<UIView *>(cell, "textStackView")
    // }];

    NSDictionary *context = @{
        @"cell": cell,
        @"artworkView": artworkView,
        @"wiggleManager": wiggleManager,
        @"draggingView": draggingView,
        @"textStackView": MSHookIvar<UIView *>(cell, "textStackView")
    };

    // if ([cell respondsToSelector:@selector(customTextView)]) {
    //     context[@"customTextView"] = [self customTextView];
    // }

    [UIView beginAnimations:@"MELO_ANIMATION_END_DRAG" context:(__bridge_retained void *)context];
    [UIView setAnimationDuration:0.4];
    [UIView setAnimationDelegate:[self animationManager]];
    [UIView setAnimationDidStopSelector:@selector(handleAnimationDidStop:finished:context:)];

        draggingView.center = targetCenter;
        draggingView.transform = CGAffineTransformIdentity;

    [UIView commitAnimations];

    [recentlyAddedManager saveData];
}

%new
- (void)checkAutoScrollWithPoint:(CGPoint)arg1 {
    [Logger logStringWithFormat:@"LRAVC: %p - checkAutoScrollWithPoint:()", self];

    WiggleModeManager *wiggleManager = [self wiggleModeManager];
    NSTimer *autoScrollTimer = [wiggleManager autoScrollTimer];
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;

    // TODO: fix this method

    // you can condense this
    if (autoScrollTimer) {
    
        // if the user is holding the album cell in the middle of the screen, delete current autoscroll timer
        if (arg1.y > 0.2 * screenHeight && arg1.y < 0.8 * screenHeight) {
            [autoScrollTimer invalidate];
            wiggleManager.autoScrollTimer = nil;
        }

    } else {

        CGFloat autoScrollInterval = 0.0025;

        // user is holding the album cell at the top of the screen, autoscroll up
        if (arg1.y <= 0.2 * screenHeight) {

            // autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:.0025 repeats:YES block:^(NSTimer *timer) {
            //     [self autoScrollAction:YES];
            // }];

            NSDictionary *userInfo = @{@"direction" : @"MELO_AUTOSCROLL_DIRECTION_UP"};
            autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:autoScrollInterval target:self selector:@selector(handleAutoScrollTimerFired:) userInfo:userInfo repeats:YES];

        // user is holding the album cell at the bottom of the screen, autoscroll down
        } else if (arg1.y >= 0.8 * screenHeight) {

            // autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:.0025 repeats:YES block:^(NSTimer *timer) {
            //     [self autoScrollAction:NO];
            // }];

            NSDictionary *userInfo = @{@"direction" : @"MELO_AUTOSCROLL_DIRECTION_DOWN"};
            autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:autoScrollInterval target:self selector:@selector(handleAutoScrollTimerFired:) userInfo:userInfo repeats:YES];
        }

        wiggleManager.autoScrollTimer = autoScrollTimer;
    }
}

%new
- (void)handleAutoScrollTimerFired:(NSTimer *)timer {
    [Logger logStringWithFormat:@"LRAVC: %p - handleAutoScrollTimerFired:(%@)", self, timer];

    NSDictionary *userInfo = (NSDictionary *)timer.userInfo;

    if ([@"MELO_AUTOSCROLL_DIRECTION_UP" isEqualToString:userInfo[@"direction"]]) {
        [self autoScrollAction:YES];
    } else if ([@"MELO_AUTOSCROLL_DIRECTION_DOWN" isEqualToString:userInfo[@"direction"]]) {
        [self autoScrollAction:NO];
    }
}

%new
- (void)autoScrollAction:(BOOL)goingUp {
    [Logger logStringWithFormat:@"LRAVC: %p - autoScrollAction: goingUp(%i)", self, goingUp];

    //UIScrollView *scrollView = MSHookIvar<UIScrollView *>([self parentViewController], "$__lazy_storage_$_scrollView");
    UIScrollView *scrollView = [[self parentViewController] contentScrollView];
    CGPoint minOffset = [scrollView _minimumContentOffset];
    CGPoint maxOffset = [scrollView _maximumContentOffset];
    CGPoint currentContentOffset = [scrollView contentOffset];

    CGFloat newContentOffsetY = goingUp ? MAX(currentContentOffset.y - 1, minOffset.y) : MIN(currentContentOffset.y + 1, maxOffset.y);
    scrollView.contentOffset = CGPointMake(0, newContentOffsetY);
}


%new
- (void)triggerHapticFeedback {
    [Logger logStringWithFormat:@"LRAVC: %p - triggerHapticFeedback", self];
    //UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    //[feedbackGenerator impactOccurred];

    AudioServicesPlaySystemSound(1520);
}

%end

%end

// wiggle mode hooks constructor
extern "C" void InitWiggleMode() {

    MeloManager *meloManager = [MeloManager sharedInstance];

    if ([meloManager prefsBoolForKey:@"pinningHooksEnabled"]) {
        %init(WiggleModeGroup,
            LibraryRecentlyAddedViewController = objc_getClass("MusicApplication.LibraryRecentlyAddedViewController"),
            VerticalStackScrollView = objc_getClass("_TtCC16MusicApplication27VerticalStackViewController10ScrollView"),
            AlbumCell = objc_getClass("MusicApplication.AlbumCell")
        );
    }
}