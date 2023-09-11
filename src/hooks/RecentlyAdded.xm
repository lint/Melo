
#import <UIKit/UIKit.h>
#import <HBLog.h>
#import <AudioToolbox/AudioToolbox.h>
#import "../objc/objc_classes.h"
#import "../interfaces/interfaces.h"

// TODO: place this in some other header file
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

%hook MPModelLibraryRequest

- (void)setContentRange:(NSRange)arg1 {
    [[Logger sharedInstance] logStringWithFormat:@"MPModelLibraryRequest: %p - setContentRange: %@", self, arg1];
    [[Logger sharedInstance] logStringWithFormat:@"length: %li", (long)arg1.length];

    if (arg1.length > 0) {
        arg1.length = 10000;
    }

    %orig;
}

%end

// doesn't work on iPad I suppose
%hook UICollectionViewFlowLayout

// changes the number of columns in UICollectionViews
- (void)setItemSize:(CGSize)arg1 {

    MeloManager *meloManager = [MeloManager sharedInstance];

    // needed to check if the album layout is for certain classes
    id dataSource = [[self collectionView] dataSource];

    // TODO: you can definitley condense this / just make it better

    if ([dataSource isKindOfClass:objc_getClass("MusicApplication.LibraryRecentlyAddedViewController")]) {

        CGSize size;

        if ([meloManager prefsBoolForKey:@"customNumColumnsEnabled"]) {

            NSInteger numColumns = [[meloManager prefsObjectForKey:@"customNumColumns"] integerValue];
            NSInteger screenWidth = [[UIScreen mainScreen] bounds].size.width;

            float albumWidth = floor((screenWidth - 20 * 2 - [meloManager minimumCellSpacing] * (numColumns - 1)) / numColumns);
            float albumHeight = (albumWidth * 1.5 - albumWidth) > 40 ? floor(albumWidth * 1.5) : albumWidth + 40;

            size = [meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] ? CGSizeMake(albumWidth, albumWidth) : CGSizeMake(albumWidth, albumHeight);
        } else {
            size = [meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] ? CGSizeMake(arg1.width, arg1.width) : arg1;
        }

        %orig(size);
    } else if ([meloManager prefsBoolForKey:@"affectAlbumPagesEnabled"] && 
        ([dataSource isKindOfClass:objc_getClass("MusicApplication.AlbumsViewController")] || 
        [dataSource isKindOfClass:objc_getClass("MusicApplication.ArtistViewController")])) {

        CGSize size;

        if ([meloManager prefsBoolForKey:@"customNumColumnsEnabled"]) {

            NSInteger numColumns = [[meloManager prefsObjectForKey:@"customNumColumns"] integerValue];
            NSInteger screenWidth = [[UIScreen mainScreen] bounds].size.width;

            float albumWidth = floor((screenWidth - 20 * 2 - [meloManager minimumCellSpacing] * (numColumns - 1)) / numColumns);
            float albumHeight = (albumWidth * 1.5 - albumWidth) > 40 ? floor(albumWidth * 1.5) : albumWidth + 40;

            size = [meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] ? CGSizeMake(albumWidth, albumWidth) : CGSizeMake(albumWidth, albumHeight); 
        } else {
            size = [meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] ? CGSizeMake(arg1.width, arg1.width) : arg1;
        }

        %orig(size);

    } else {
        %orig;
    }
}

%end

%hook TitleSectionHeaderView
%property(strong, nonatomic) UIImageView *chevronIndicatorView;
%property(strong, nonatomic) NSString *identifier;
%property(strong, nonatomic) UITapGestureRecognizer *tapGesture;
%property(strong, nonatomic) LibraryRecentlyAddedViewController *recentlyAddedViewController;
%property(strong, nonatomic) UIView *emptyInsertionView;

// returns the recently added manager associated with the library recently added view controller
%new 
- (RecentlyAddedManager *)recentlyAddedManager {
    return [[self recentlyAddedViewController] recentlyAddedManager];
}

// returns whether or not the section with this view is collapsed or not
%new 
- (BOOL)isCollapsed {

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    Section *section = [recentlyAddedManager sectionWithIdentifier:[self identifier]];

    return section ? section.isCollapsed : NO;
}

// create UI items that are used to collapse sections
%new
- (void)createCollapseItems {


    MeloManager *meloManager = [MeloManager sharedInstance];
    WiggleModeManager *wiggleManager = [[self recentlyAddedViewController] wiggleModeManager];

    UIImageView *chevronIndicatorView = [self chevronIndicatorView];
    UITapGestureRecognizer *tapGesture = [self tapGesture];

    // create the chevron indicator image view if it does not exist
    if (!chevronIndicatorView) {
        chevronIndicatorView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right" withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightBold]]];
        chevronIndicatorView.contentMode = UIViewContentModeScaleAspectFit;

        [self setChevronIndicatorView:chevronIndicatorView];
        [self addSubview:chevronIndicatorView];

    // readd the chevron indicator image view if it exists but is not a subview of this view
    } else if (![chevronIndicatorView isDescendantOfView:self]) {
        [chevronIndicatorView removeFromSuperview];
        [self addSubview:chevronIndicatorView];
    }

    // create the tap gesture recognizer if it does not exist
    if (!tapGesture) {
        tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
        tapGesture.numberOfTapsRequired = 1;
        tapGesture.numberOfTouchesRequired = 1;

        [self setTapGesture:tapGesture];
        [self addGestureRecognizer:tapGesture];
    
    // check if the view currently does not have the given tap gesture recognizer
    } else if (![[self gestureRecognizers] containsObject:tapGesture]) {

        // remove all targets from the recognizer and readd it to this view
        [tapGesture removeTarget:nil action:NULL];
        [tapGesture addTarget:self action:@selector(handleTapGesture:)];
        [self addGestureRecognizer:tapGesture];
    }

    tapGesture.enabled = !wiggleManager.inWiggleMode;
    chevronIndicatorView.alpha = wiggleManager.inWiggleMode ? 0 : 1;

    // set the rotation of the chevron indicator image view
    chevronIndicatorView.transform = [self isCollapsed] ? CGAffineTransformMakeRotation(0) :  CGAffineTransformMakeRotation(M_PI_2);
}

// update any children subviews of this view
- (void)layoutSubviews {
    %orig;

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];

    if (recentlyAddedManager && [recentlyAddedManager isReadyForUse]) {

        UIView *emptyInsertionView = [self emptyInsertionView];
        UIImageView *chevronIndicatorView = [self chevronIndicatorView];
        UIView *titleDrawingView = MSHookIvar<UIView *>(self, "titleTextDrawingView");
        UIView *subtitleDrawingView = MSHookIvar<UIView *>(self, "subtitleTextDrawingView");

        CGRect titleFrame = [titleDrawingView frame];
        CGRect subtitleFrame = [subtitleDrawingView frame];

        CGFloat imageViewSizeVal = titleFrame.size.height / 1.25;
        CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;

        if (chevronIndicatorView) {
            
            CGFloat imageViewYOrigin = (titleFrame.origin.y * 2 + titleFrame.size.height - imageViewSizeVal) / 2;
            CGFloat imageViewXOrigin = (subtitleDrawingView ? subtitleFrame.origin.x + subtitleFrame.size.width : titleFrame.origin.x + titleFrame.size.width) + 12;
            //imageViewXOrigin = imageViewXOrigin < screenWidth ? imageViewXOrigin : screenWidth - imageViewSizeVal; // commented out in old code

            if (imageViewXOrigin  + imageViewSizeVal > screenWidth) {
                imageViewXOrigin = screenWidth - imageViewSizeVal - 10;
                UIEdgeInsets currentInsets = [self music_layoutInsets];
                [self music_setLayoutInsets:UIEdgeInsetsMake(currentInsets.top, currentInsets.left, currentInsets.bottom, 40 + imageViewSizeVal)];
            }

            CGRect imageViewFrame = CGRectMake(imageViewXOrigin, imageViewYOrigin, imageViewSizeVal, imageViewSizeVal);
            chevronIndicatorView.frame = imageViewFrame;

            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.2];
                chevronIndicatorView.transform = [self isCollapsed] ? CGAffineTransformMakeRotation(0) :  CGAffineTransformMakeRotation(M_PI_2);
            [UIView commitAnimations];
        }

        if (emptyInsertionView) {
            //CGRect dragDetectionFrame = CGRectMake(0, titleFrame.origin.y, screenWidth, titleFrame.size.height);
            //emptyInsertionView.frame = dragDetectionFrame;
            emptyInsertionView.frame = CGRectMake(0,0, screenWidth, [self frame].size.height);
            // TODO: just make this equal to the title header view's bounds?
        }
    }
}

%new
- (void)createEmptyInsertionView {
    UIView *emptyInsertionView = [self emptyInsertionView];
    if (!emptyInsertionView) {
        emptyInsertionView = [[UIView alloc] initWithFrame:CGRectZero];
        emptyInsertionView.userInteractionEnabled = NO;
        [self setEmptyInsertionView:emptyInsertionView];
        [self addSubview:emptyInsertionView];
    } else if (![emptyInsertionView isDescendantOfView:self]) {
        [emptyInsertionView removeFromSuperview];
        [self addSubview:emptyInsertionView];
    }
}

// handle a single tap gesture performed on this view
%new
- (void)handleTapGesture:(UIGestureRecognizer *)arg1 {

    LibraryRecentlyAddedViewController *lravc = [self recentlyAddedViewController];
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    
    BOOL wasCollapsed = [self isCollapsed];
    NSInteger sectionIndex = [recentlyAddedManager sectionIndexForIdentifier:[self identifier]];

    // do not try to toggle collapsed for an invalid section
    if (sectionIndex < 0) {
        [[Logger sharedInstance] logString:@"TitleSectionHeaderView could not locate it's associated section"];
        return;
    }

    // animate the indicator changing to the new orientation
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
        [self chevronIndicatorView].transform = wasCollapsed ? CGAffineTransformMakeRotation(M_PI_2) : CGAffineTransformMakeRotation(0);
    [UIView commitAnimations];

    // perform additional data and visual updates
    [lravc toggleSectionCollapsedAtIndex:sectionIndex];
}

// // animate a simple flashing highlight of this view that occurs when trying to move an album to an empty section in wiggle mode
%new
- (void)animateEmptySectionInsertionFlash {
   
    // UIColor *origColor = [(UIView *)self backgroundColor];
    UIColor *origColor = [UIColor clearColor];
    UIColor *highlightColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.25];
    NSTimeInterval interval = 0.175;

    UIView *view = [self emptyInsertionView];

    NSDictionary *context = @{
        @"view": view,
        @"origColor": [ColorUtils colorToDict:origColor],
        @"highlightColor": [ColorUtils colorToDict:highlightColor],
        @"interval": [NSNumber numberWithDouble:interval]
    };

    [UIView beginAnimations:@"MELO_ANIMATION_EMPTY_INSERTION_FLASH_PART_1" context:(__bridge_retained void *)context];
    [UIView setAnimationDuration:interval];
    [UIView setAnimationDelegate:[[self recentlyAddedViewController] animationManager]];
    [UIView setAnimationDidStopSelector:@selector(handleAnimationDidStop:finished:context:)];
        [view setBackgroundColor:highlightColor];
    [UIView commitAnimations];
}

%new
- (void)highlightEmptyInsertionView:(BOOL)shouldHighlight {

    // TODO: don't default to clearColor? or even tbh remove the empty insertion view and just highlight the title section view itself 

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
        [self emptyInsertionView].backgroundColor = shouldHighlight ? [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.25] : [UIColor clearColor];
    [UIView commitAnimations];
}

// enabled / disable or show / hide collapse items when toggling wiggle mode
%new
- (void)transitionCollapseItemsForWiggleMode:(BOOL)inWiggleMode {
    
    UITapGestureRecognizer *tapGesture = [self tapGesture];
    UIImageView *chevronIndicatorView = [self chevronIndicatorView];
    
    if (chevronIndicatorView) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.4];
            chevronIndicatorView.alpha = inWiggleMode ? 0.0 : 1.0;
        [UIView commitAnimations];
    }
    
    if (tapGesture) {
        tapGesture.enabled = !inWiggleMode;
    }
}

%end

static LibraryRecentlyAddedViewController *currentLRAVC;

%hook LibraryRecentlyAddedViewController
%property(strong, nonatomic) WiggleModeManager *wiggleModeManager;
%property(strong, nonatomic) RecentlyAddedManager *recentlyAddedManager;
%property(strong, nonatomic) AlbumActionsViewController *albumActionsVC;
%property(strong, nonatomic) AnimationManager *animationManager;

- (id)init {

    RecentlyAddedManager *recentlyAddedManager = [RecentlyAddedManager new];
    WiggleModeManager *wiggleManager = [WiggleModeManager new];   
    AnimationManager *animationManager = [AnimationManager new]; 

    [self setRecentlyAddedManager:recentlyAddedManager];
    [self setWiggleModeManager:wiggleManager];
    [self setAnimationManager:animationManager];
    
    return %orig;
}

- (void)viewWillAppear:(BOOL)arg1 {

    // use this to detect which library view controller it is?
    // need to be able to read the title, which does get set later...able
    // any other way to differentiate them?

    currentLRAVC = self;

    %orig;

    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - viewWillAppear:(%i)", self, arg1]];

    // [[self recentlyAddedManager] loadData];
}

- (void)viewWillDisappear:(BOOL)arg1 {
    %orig;
    // [[self recentlyAddedManager] saveData];
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - viewWillDisappear:(%i)", self, arg1]];

    if ([self wiggleModeManager].inWiggleMode) {
        [self toggleWiggleMode];
    }
}

- (void)viewDidAppear:(BOOL)arg1 {
    %orig;
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - viewDidAppear:(%i)", self, arg1]];

    currentLRAVC = self;
    // was potentially going to put in a check to see if a change was detected from another library recently added view controller instance
    // this would be tracked thru meloManager somehow
    // but this seems to work?
    // nvm it causes lag when going in / out of an album.. need this
    
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];

    if (recentlyAddedManager.unhandledDataChangeOccurred) {

        [[self recentlyAddedManager] loadData];

        UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");
        [collectionView reloadData];

        recentlyAddedManager.unhandledDataChangeOccurred = NO;
    }
}

- (void)viewDidDisappear:(BOOL)arg1 {
    %orig;
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - viewDidDisappear:(%i)", self, arg1]];

    // [[self recentlyAddedManager] setAttemptedDataLoad:NO];
}

- (void)viewDidLoad {
    [[Logger sharedInstance] logStringWithFormat:@"LRAVC: %p - viewDidLoad", self];
    %orig;

    if ([[MeloManager sharedInstance] prefsBoolForKey:@"customActionMenuEnabled"]) {
        
        UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");
        [[Logger sharedInstance] logStringWithFormat:@"collectionView: %p", collectionView];

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapOnAlbum:)];
        tapGesture.numberOfTapsRequired = 1;
        tapGesture.numberOfTouchesRequired = 2;
        
        for (id gesture in [collectionView gestureRecognizers]) {
            // [[Logger sharedInstance] logStringWithFormat:@"gestureRecognizer: %@", gesture];

            [gesture requireGestureRecognizerToFail:tapGesture];
        }
        [collectionView addGestureRecognizer:tapGesture];
    }
}

- (void)setTitle:(NSString *)title {
    [[Logger sharedInstance] logStringWithFormat:@"LRAVC %p - setTitle:(%@)", self, title];

    // when the downloaded music page is opened, this method is called twice
    // the first time is in the init which sets it to "Recently Added"
    // sometime later it gets called again setting it to "Recently Downloaded"
    // so unfortunately, two loads are performed, but it works so oh well

    %orig;

    NSBundle *bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] bundlePath], @"/Frameworks/MusicApplication.framework"]];

    NSString *localizedRecentlyAddedTitle = NSLocalizedStringFromTableInBundle(@"RECENTLY_ADDED_VIEW_TITLE", @"Music", bundle, nil);
    NSString *localizedDownloadedMusicTitle = NSLocalizedStringFromTableInBundle(@"RECENTLY_DOWNLOADED_VIEW_TITLE", @"Music", bundle, nil);

    if ([title isEqualToString:localizedRecentlyAddedTitle]) {
        [[self recentlyAddedManager] setIsDownloadedMusic:NO];
    } else if ([title isEqualToString:localizedDownloadedMusicTitle]) {
        [[self recentlyAddedManager] setIsDownloadedMusic:YES];
    }

    [[self recentlyAddedManager] loadData];
}

/* methods that deal with displaying sections */

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)arg1 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - numberOfSectionsInCollectionView:(%p)", self, arg1]];

    // get the recently added manager
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    
    // check if the manager is not ready to inject fake data
    if (![recentlyAddedManager isReadyForUse]) {
        return %orig;
    }
    
    return [recentlyAddedManager numberOfSections];
}

- (NSInteger)collectionView:(UICollectionView *)arg1 numberOfItemsInSection:(NSInteger)arg2 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) numberOfItemsInSection:(%li)", self, arg1, arg2]];

    // get the recently added manager
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    
    // check if the manager is not ready to inject fake data
    if (![recentlyAddedManager isReadyForUse]) {
        return %orig;
    }

    // return 0 if the section is collapsed, otherwise return the actual number of albums
    Section *section = [recentlyAddedManager sectionAtIndex:arg2];
    return section.isCollapsed ? 0 : [section numberOfAlbums];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)arg1 viewForSupplementaryElementOfKind:(id)arg2 atIndexPath:(NSIndexPath *)arg3 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) viewForSupplementaryElementOfKind:(%@) atIndexPath:<%ld-%ld>", self, arg1, arg2, arg3.section, arg3.item]];
    
    // get the recently added manager
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];

    // check if the manager is not ready to inject fake data
    if (![recentlyAddedManager isReadyForUse]) {
        return %orig;
    }

    Section *section = [recentlyAddedManager sectionAtIndex:arg3.section];

    UICollectionReusableView *orig = %orig;
    TitleSectionHeaderView *titleHeaderView = (TitleSectionHeaderView *)orig;
    [titleHeaderView setRecentlyAddedViewController:self];

    if (section.identifier) {
        [titleHeaderView setIdentifier:section.identifier];
    }

    if (section.title) {
        [titleHeaderView setTitle:section.title];
    }

    if (section.subtitle) {
        [titleHeaderView setSubtitle:section.subtitle];
    }

    if ([[MeloManager sharedInstance] prefsBoolForKey:@"collapsibleSectionsEnabled"]) {
        [titleHeaderView createCollapseItems];
    }

    [titleHeaderView createEmptyInsertionView];

    return orig;
}

// - (void)collectionView:(UICollectionView *)arg1 didEndDisplayingSupplementaryView:(UICollectionReusableView *)arg2 forElementOfKind:(id)arg3 atIndexPath:(NSIndexPath *)arg4 {
- (void)collectionView:(id)arg1 didEndDisplayingSupplementaryView:(id)arg2 forElementOfKind:(id)arg3 atIndexPath:(id)arg4 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) didEndDisplayingSupplementaryView:(%@) forElementOfKind:(%@) atIndexPath:<%@>", self, arg1, arg2, arg3, arg4]];

    // get the recently added manager
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];

    // check if the manager is not ready to inject fake data
    if (![recentlyAddedManager isReadyForUse]) {
        %orig;
        return;
    }

    %orig;
}

/* methods that deal with displaying albums */

- (id)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) cellForItemAtIndexPath:<%ld-%ld>", self, arg1, arg2.section, arg2.item]];

    // in old code, this sets the custom "identifier" property on the AlbumCell returned by %orig(injected)

    id orig;

    // check if recently added manager is ready to inject data
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    if (![recentlyAddedManager isReadyForUse]) {
        orig = %orig;
    } else {
        NSIndexPath *realIndexPath = [recentlyAddedManager translateIndexPath:arg2];
        [[Logger sharedInstance] logString:[NSString stringWithFormat:@"realIndexPath:<%ld-%ld>", realIndexPath.section, realIndexPath.item]];

        // use the injected data
        orig = %orig(arg1, [recentlyAddedManager translateIndexPath:arg2]);
    }
    
    if ([[MeloManager sharedInstance] prefsBoolForKey:@"hideAlbumTextEnabled"]) {
        UIView *textStackView = MSHookIvar<UIView *>(orig, "textStackView");
        [textStackView setHidden:YES];
        // HBLogDebug(@"\ttextStackView:%@", textStackView);
        // [MSHookIvar<UIView *>(orig, "textStackView") setHidden:YES];
    }

    return orig;
}

- (id)collectionView:(UICollectionView *)arg1 contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)arg2 point:(CGPoint)arg3 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) contextMenuConfigurationForItemAtIndexPath:<%ld-%ld> point:(do later if needed)", self, arg1, arg2.section, arg2.item]];

    // check if recently added manager is ready to inject data
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    MeloManager *meloManager = [MeloManager sharedInstance];
    if (![recentlyAddedManager isReadyForUse]) {
        return %orig;
    } else if ([self wiggleModeManager].inWiggleMode) {

        [Logger logString:@"in wiggle mode, preventing context menu generation"];

        // do not allow context menu configurations to be generated at all in wiggle mode
        return nil;
    }

    // get the real index path for the adjusted index path
    NSIndexPath *realIndexPath = [recentlyAddedManager translateIndexPath:arg2];

    // set various values for override
    meloManager.shouldAddCustomContextActions = YES;
    meloManager.indexPathForContextActions = arg2;
    meloManager.indexPathForContextMenuOverride = arg2;

    // use injected data
    id orig = %orig(arg1, realIndexPath, arg3);

    // reset override value
    meloManager.indexPathForContextMenuOverride = nil;

    return orig;
}

- (void)collectionView:(UICollectionView *)arg1 willEndContextMenuInteractionWithConfiguration:(id)arg2 animator:(id)arg3 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) willEndContextMenuInteractionWithConfiguration: (%p) animator:(%p)", self, arg1, arg2, arg3]];

    // no need to use injected data here
    %orig;

    // reset override value
    MeloManager *meloManager = [MeloManager sharedInstance];
    meloManager.shouldAddCustomContextActions = NO;
    //meloManager.indexPathForContextMenuOverride = nil; // TODO: commented out in old code, remove?
}

- (void)collectionView:(UICollectionView *)arg1 willDisplayCell:(id)arg2 forItemAtIndexPath:(NSIndexPath *)arg3 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) willDisplayCell:(%p) forItemAtIndexPath:<%ld-%ld>", self, arg1, arg2, arg3.section, arg3.item]];

    // TODO: in old code, contained some checks for if the requested item is out of bounds for some reason
    // i remember this fixing some crash, due to the system using the default index paths to request but not being able to properly translate them?
    // not really sure, but i bet it'll come up again..
    
    // check if recently added manager is ready to inject data
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    if (![recentlyAddedManager isReadyForUse]) {
        %orig;
        return;
    }
    NSIndexPath *adjustedIndexPath = [recentlyAddedManager translateIndexPath:arg3];

    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"adjustedIndexPath:<%ld-%ld>", adjustedIndexPath.section, adjustedIndexPath.item]];

    // use injected data
    %orig(arg1, arg2, [recentlyAddedManager translateIndexPath:arg3]);

    // [[Logger sharedInstance] logString:@"finished willDisplayCell"];



    // out of bounds check that i used in the old code
    // if (arg3.item >= [self collectionView:MSHookIvar<UICollectionView *>(self, "_collectionView") numberOfItemsInSection:arg3.section]) {
    //     // HBLogDebug(@"\tadjusted indexPath is out of bounds for pinnedSection: %ld? something probably went wrong", arg3.section);
    //     [[Logger sharedInstance] logString:@"failed index path bounds check? just don't call method??"];
    // } else {
    //     %orig(arg1, arg2, [recentlyAddedManager translateIndexPath:arg3]);
    // }
}

- (void)collectionView:(UICollectionView *)arg1 didEndDisplayingCell:(id)arg2 forItemAtIndexPath:(NSIndexPath *)arg3 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) didEndDisplayingCell:(%p) forItemAtIndexPath:<%ld-%ld>", self, arg1, arg2, arg3.section, arg3.item]];
    
    // in old code, this did not ever inject a different index path, it just called %orig, so maybe do that again here as well..
    
    // check if recently added manager is ready to inject data
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    if (![recentlyAddedManager isReadyForUse]) {
        %orig;
        return;
    }

    // use injected data
    // %orig(arg1, arg2, [recentlyAddedManager translateIndexPath:arg3]);
    %orig;
}

- (BOOL)collectionView:(UICollectionView *)arg1 shouldSelectItemAtIndexPath:(NSIndexPath *)arg2 { 
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) shouldSelectItemAtIndexPath:<%ld-%ld>", self, arg1, arg2.section, arg2.item]];

    // check if recently added manager is ready to inject data
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    if (![recentlyAddedManager isReadyForUse]) {
        return %orig;
    }

    [[Logger sharedInstance] logStringWithFormat:@"realIndexPath: %@", [recentlyAddedManager translateIndexPath:arg2]];

    // use injected data
    // BOOL orig = %orig(arg1, [recentlyAddedManager translateIndexPath:arg2]);
    // BOOL orig = %orig;
    // [[Logger sharedInstance] logStringWithFormat:@"result: %i", orig];
    // return orig;
    return YES;

    // is there any situation where i would not want to return YES here? like

    // this method does not translate the paths because if it does, for some reason calling %orig with the real path causes issues with selecting an album
    // my guess for what happens:
    // let's say all of the albums are in the recently added section and none in the pinned section
    // call %orig with the real index path
    // this index path will get passed to [UICollectionView cellForItemAtIndexPath:]
    // now the the translated / real index path has section 0, but the cellForItemAtIndexPath is going off the faked positions of the albums?
    // so it doesn't return anything and then %orig returns NO for shouldSelectItemAtIndexPath
    // thus, if we just pass the adjusted index path to %orig, that will get passed to the UICollectionView method, which will succeed
    // and then it all works out
    // my old code DOES translate the index path tho... so not sure what's different
}

- (void)collectionView:(UICollectionView *)arg1 didSelectItemAtIndexPath:(NSIndexPath *)arg2 { 
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) didSelectItemAtIndexPath:<%ld-%ld>", self, arg1, arg2.section, arg2.item]];
  
    // check if recently added manager is ready to inject data
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    if (![recentlyAddedManager isReadyForUse]) {
        %orig;
        return;
    }

    [[Logger sharedInstance] logStringWithFormat:@"realIndexPath: %@", [recentlyAddedManager translateIndexPath:arg2]];

    // use injected data
    %orig(arg1, [recentlyAddedManager translateIndexPath:arg2]);
}

- (BOOL)collectionView:(UICollectionView *)arg1 shouldHighlightItemAtIndexPath:(NSIndexPath *)arg2 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) shouldHighlightItemAtIndexPath:<%ld-%ld>", self, arg1, arg2.section, arg2.item]];
    
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    WiggleModeManager *wiggleManager = [self wiggleModeManager];
    
    // check if recently added manager is ready to inject data
    if (![recentlyAddedManager isReadyForUse]) {
        return %orig;
    } else if (wiggleManager.inWiggleMode) {
        
        // do not allow selection of albums while in wiggle mode
        return NO;
    }

    // use injected data
    return %orig(arg1, [recentlyAddedManager translateIndexPath:arg2]);
}

// -(id)_collectionView:(id)arg1 indexPathForSectionIndexTitle:(id)arg2 atIndex:(NSInteger)arg3 {
// }

// -(id)_sectionIndexTitlesForCollectionView:(id)arg1 {
// }

// -(id)_collectionView:(id)arg1 canEditItemAtIndexPath:(id)arg2 {
// }

%new
- (void)checkAlbumOrder {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - checkAlbumOrder", self]];

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    MPModelResponse *response = MSHookIvar<MPModelResponse *>(self, "_modelResponse");
    NSMutableArray *realAlbumOrder = [NSMutableArray array];

    if (response) {

        NSInteger realIndex = 0;

        for (id item in [[response results] allItems]) {

            NSString *identifier = [@([[item identifiers] persistentID]) stringValue];
            NSDictionary *info;

            if ([item album]) {
                MPModelAlbum *album = [item album];
                info = @{@"identifier" : identifier, 
                    @"artist" : [[album artist] name] ?: @"TEMP_ARTIST_NAME", 
                    @"title" : [album title] ?: @"TEMP_ALBUM_TITLE",
                    @"realIndex": @(realIndex++)};
            } else if ([item playlist]) {
                MPModelPlaylist *playlist = [item playlist];
                info = @{@"identifier" : identifier, 
                    @"artist" : [[playlist curator] name] ?: @"TEMP_ARTIST_NAME",
                    @"title" : [playlist name] ?: @"TEMP_PLAYLIST_NAME",
                    @"realIndex": @(realIndex++)};
            } else {
                [[Logger sharedInstance] logString:@"could not get either album or playlist from library response"];
            }

            Album *album = [[Album alloc] initWithDictionary:info];

            [realAlbumOrder addObject:album];
            // [[Logger sharedInstance] logString:[NSString stringWithFormat:@"id: %@, artist: %@, title: %@", info[@"identifier"], info[@"artist"], info[@"title"]]];
        }

        [recentlyAddedManager processRealAlbumOrder:realAlbumOrder];
    }
}

%new
- (void)handleMoveToSectionAction:(NSInteger)sectionIndex {
    [[Logger sharedInstance] logStringWithFormat:@"LRAVC: %p - handleMoveToSectionAction:(%ld)", self, sectionIndex];

    // ideally, if moving the album back into the recently added section, it will move it to the album's proper place
    // for now tho, i'll just move it to the first spot, then it will move back whenever the app is refreshed since the recently added section is not saved

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    MeloManager *meloManager = [MeloManager sharedInstance];

    NSIndexPath *sourceAdjustedIndexPath = meloManager.indexPathForContextActions;
    NSIndexPath *destAdjustedIndexPath = [NSIndexPath indexPathForItem:0 inSection:sectionIndex];

    [[Logger sharedInstance] logStringWithFormat:@"indexPathForContextActions: %@", meloManager.indexPathForContextActions];

    // commented out so that the block does not cause a crash while patching with allemand
    // // perform the move operation
    // [self moveAlbumCellFromAdjustedIndexPath:sourceAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath dataUpdateBlock:^(){
    //     [recentlyAddedManager moveAlbumAtAdjustedIndexPath:destAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath];
    // }];        

    [recentlyAddedManager moveAlbumAtAdjustedIndexPath:sourceAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath];
    [self moveAlbumCellFromAdjustedIndexPath:sourceAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath dataUpdateBlock:nil]; 
}

%new 
- (void)handleShiftAction:(BOOL)isMovingLeft {
    [[Logger sharedInstance] logStringWithFormat:@"LRAVC: %p - handleShiftAction:isMovingLeft:(%i)", self, isMovingLeft];

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    MeloManager *meloManager = [MeloManager sharedInstance];

    NSIndexPath *indexPathForContextActions = meloManager.indexPathForContextActions;

    NSIndexPath *sourceAdjustedIndexPath = indexPathForContextActions;
    NSIndexPath *destAdjustedIndexPath;
    
    // the destination is one to the left or right of the current item
    if (isMovingLeft) {
        destAdjustedIndexPath = [NSIndexPath indexPathForItem:indexPathForContextActions.item - 1 inSection:indexPathForContextActions.section];
    } else {
        destAdjustedIndexPath = [NSIndexPath indexPathForItem:indexPathForContextActions.item + 1 inSection:indexPathForContextActions.section];
    }

    // commented out so that the block does not cause a crash while patching with allemand
    // // perform the shift operation
    // [self moveAlbumCellFromAdjustedIndexPath:sourceAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath dataUpdateBlock:^(){
    //     [recentlyAddedManager moveAlbumAtAdjustedIndexPath:sourceAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath];
    // }];

    [recentlyAddedManager moveAlbumAtAdjustedIndexPath:sourceAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath];
    [self moveAlbumCellFromAdjustedIndexPath:sourceAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath dataUpdateBlock:nil]; 
}

%new 
- (void)moveAlbumCellFromAdjustedIndexPath:(NSIndexPath *)sourceIndexPath toAdjustedIndexPath:(NSIndexPath *)destIndexPath dataUpdateBlock:(void (^)())dataUpdateBlock {
    [[Logger sharedInstance] logStringWithFormat:@"LRAVC: %p - moveAlbumCellFromAdjustedIndexPath:%@ toAdjustedIndexPath:%@", self, sourceIndexPath, destIndexPath];

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    MeloManager *meloManager = [MeloManager sharedInstance];
    UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");
    Section *destSection = [recentlyAddedManager sectionAtIndex:destIndexPath.section];

    // uncollapse section if necessary
    if ([meloManager prefsBoolForKey:@"collapsibleSectionsEnabled"] && destSection.isCollapsed) {
        [self toggleSectionCollapsedAtIndex:destIndexPath.section];
    }


    // execute the data update
    // dataUpdateBlock();

    // old code then made source section always "visible" and preserved the state in a variable

    // move the cell
    [collectionView moveItemAtIndexPath:sourceIndexPath toIndexPath:destIndexPath];

    // old code would then restore the source section's visible state 
    // and would also hide the source section if it became empty and that option was enabled

}

%new
- (void)toggleSectionCollapsedAtIndex:(NSInteger)arg1 {

    [Logger logStringWithFormat:@"LRAVC: %p - toggleSectionCollapsedAtIndex:(%li)", self, arg1];
    
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    Section *section = [recentlyAddedManager sectionAtIndex:arg1];
    UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");

    // track the current collapsed state of the section, then flip it
    BOOL isCollapsedCurrentState = section.isCollapsed;
    section.collapsed = !isCollapsedCurrentState;

    // save collapsed changes
    [recentlyAddedManager saveData];

    NSMutableArray *albumIndexPaths = [NSMutableArray array];
    NSInteger numAlbums = [recentlyAddedManager numberOfAlbumsInSection:arg1];

    // generate an index path for every album in the section
    for (NSInteger i = 0; i < numAlbums; i++) {
        [albumIndexPaths addObject:[NSIndexPath indexPathForItem:i inSection:arg1]];
    }

    // either insert or delete all the album cells from the collection view
    if (isCollapsedCurrentState) {
        [collectionView insertItemsAtIndexPaths:albumIndexPaths];
    } else {
        [collectionView deleteItemsAtIndexPaths:albumIndexPaths];
    }

    // TODO:
    // why do i do this rather than just getting the section title view directly?? TODO: could also just pass the view as an argument
    for (UIView *view in [collectionView visibleSupplementaryViewsOfKind:UICollectionElementKindSectionHeader]) {
        
        if ([view isKindOfClass:objc_getClass("MusicApplication.TitleSectionHeaderView")]) {
            TitleSectionHeaderView *sectionHeaderView = (TitleSectionHeaderView *)view;

            if ([[sectionHeaderView identifier] isEqualToString:section.identifier]) {
                [view setNeedsLayout];
            }
        }
    }
}

%new
- (void)handleDoubleTapOnAlbum:(UITapGestureRecognizer *)sender {
    [[Logger sharedInstance] logStringWithFormat:@"LRAVC: %p - handleDoubleTapOnAlbum:(%@)", self, sender];

    if (sender.state == UIGestureRecognizerStateRecognized) {
        // handling code

        [[Logger sharedInstance] logString:@"state recognized"];

        MeloManager *meloManager = [MeloManager sharedInstance];
        RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
        UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");

        // do not attempt to inject custom context actions in the recently downloaded page if pinning there is disabled or if pins are synced from the full library
        if (recentlyAddedManager.isDownloadedMusic && (![meloManager prefsBoolForKey:@"downloadedPinningEnabled"] || [meloManager prefsBoolForKey:@"syncLibraryPinsEnabled"])) {
            return;
        }

        CGPoint point = [sender locationInView:collectionView];
        NSIndexPath *indexPath = [collectionView indexPathForItemAtPoint:point];

        [[Logger sharedInstance] logStringWithFormat:@"indexPath: %@", indexPath];

        Album *album = [recentlyAddedManager albumAtAdjustedIndexPath:indexPath];
        [[Logger sharedInstance] logStringWithFormat:@"album: %@", album];

        // ActionsPresentationController *presController = [ActionsPresentationController new];

        AlbumActionsViewController *albumActionsVC = [AlbumActionsViewController new];
        albumActionsVC.libraryRecentlyAddedViewController = self;
        albumActionsVC.recentlyAddedManager = recentlyAddedManager;
        albumActionsVC.albumAdjustedIndexPath = indexPath;
        meloManager.indexPathForContextActions = indexPath;

        albumActionsVC.modalPresentationStyle = UIModalPresentationPopover;
        albumActionsVC.preferredContentSize = CGSizeMake(280, 230);
        albumActionsVC.popoverPresentationController.delegate = self;

        // albumActionsVC.popoverPresentationController.sourceView = self.view;
        // albumActionsVC.popoverPresentationController.sourceRect = CGRectMake(384, -120, 280, 230);
        [self setAlbumActionsVC:albumActionsVC];

        [self presentViewController:albumActionsVC animated:YES completion:nil];
        // [self pushViewController:albumActionsVC animated:YES];
    }
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] minimumCellSpacing];
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] minimumCellSpacing];
}

// TODO: (just an indicator to update these comments)
// implemented for wiggle mode
%new
- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    [Logger logStringWithFormat:@"LRAVC: %p collectionView canMoveItemAtIndexPath:<%ld,%ld>", self, indexPath.section, indexPath.item];
    return YES;
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

        for (NSInteger i = 0; i < [recentlyAddedManager numberOfSections]; i++) {
            Section *section = [recentlyAddedManager sectionAtIndex:i];
            if (section.isCollapsed) {
                [indexesToUncollapse addObject:@(i)];
            }
        }

        // uncollapse the sections (old code had this in a performBatchUpdates block, necessary?)
        for (NSNumber *index in indexesToUncollapse) {
            [self toggleSectionCollapsedAtIndex:[index integerValue]];
        }

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
        [endWiggleButton setTitle:@"End Wiggle Mode" forState:UIControlStateNormal];
        [endWiggleButton setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
        endWiggleButton.backgroundColor = [ColorUtils dictToColor:[meloManager prefsObjectForKey:@"customTintColor"]];
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

    [Logger logString:@"here1"];

    NSIndexPath *sourceIndexPath = [collectionView indexPathForItemAtPoint:[collectionView convertPoint:arg1 fromView:parentView]];

    [Logger logString:@"here2"];
    [Logger logStringWithFormat:@"sourceIndexPath: %@", sourceIndexPath];

    [self collectionView:collectionView canMoveItemAtIndexPath:sourceIndexPath];

    [Logger logString:@"here if didn't crash"];

    if (sourceIndexPath && [self collectionView:collectionView canMoveItemAtIndexPath:sourceIndexPath]) {

        [Logger logString:@"here3"];

        Album *album = [recentlyAddedManager albumAtAdjustedIndexPath:sourceIndexPath];
        AlbumCell *cell = (AlbumCell *)[collectionView cellForItemAtIndexPath:sourceIndexPath];
        UIView *artworkView = MSHookIvar<UIView *>(MSHookIvar<id>(cell, "artworkComponent"), "imageView");

        [Logger logString:@"here4"];

        //[self setOriginalIndexPath:sourceIndexPath];
        wiggleManager.draggingIndexPath = sourceIndexPath;
        wiggleManager.draggingAlbumIdentifier = album.identifier;

        CGRect draggingViewFrame = [parentView convertRect:cell.frame fromView:collectionView];
        //draggingView.frame = [parentView convertRect:artworkView.frame fromView:cell];

        UIView *draggingWrapperView = [[UIView alloc] initWithFrame:CGRectMake(draggingViewFrame.origin.x, draggingViewFrame.origin.y, draggingViewFrame.size.width, draggingViewFrame.size.width)];
        draggingWrapperView.clipsToBounds = YES;

        [Logger logString:@"here5"];

        UIView *draggingView = [cell snapshotViewAfterScreenUpdates:YES];

        [Logger logString:@"here6"];
        //UIView *draggingView = [artworkView snapshotViewAfterScreenUpdates:YES];
        draggingView.backgroundColor = [UIColor clearColor];

        draggingView.frame = [draggingWrapperView convertRect:draggingViewFrame fromView:parentView];
        //draggingView.frame = draggingWrapperView.bounds;

        [Logger logString:@"here7"];

        [draggingWrapperView addSubview:draggingView];
        [parentView addSubview:draggingWrapperView];

        wiggleManager.draggingView = draggingWrapperView;
        
        [Logger logString:@"here8"];
        //[self setDraggingOffset:CGPointMake(draggingView.center.x - arg1.x, draggingView.center.y - arg1.y)]; // commented out in old code
        // [self setDraggingOffset:CGPointMake(draggingWrapperView.center.x - arg1.x, draggingWrapperView.center.y - arg1.y)];
        wiggleManager.draggingOffset = CGPointMake(draggingWrapperView.center.x - arg1.x, draggingWrapperView.center.y - arg1.y);
        [Logger logString:@"here9"];
        // hiding the cell and making the text disappear with an animation
        artworkView.alpha = 0;

        UIView *textStackView = MSHookIvar<UIView *>(cell, "textStackView");

        NSDictionary *context = @{
            @"cell": cell
        };
            
        [UIView beginAnimations:@"MELO_ANIMATION_HIDE_ALBUM_TEXT_ON_DRAG" context:(__bridge_retained void *)context];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationDelegate:[self animationManager]];
        [UIView setAnimationDidStopSelector:@selector(handleAnimationDidStop:finished:context:)];
            textStackView.alpha = 0;
        [UIView commitAnimations];

        [Logger logString:@"here10"];

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

        [Logger logString:@"here11"];

        [self triggerHapticFeedback];

        //[collectionView.collectionViewLayout invalidateLayout]; // do I need this?
    }

    [Logger logString:@"method done"];
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

    // old code
    //[self draggingView].center = [collectionView convertPoint:CGPointMake(arg1.x + draggingOffset.x, arg1.y + draggingOffset.y) toView:[[self parentViewController] view]];

    wiggleManager.draggingView.center = CGPointMake(arg1.x + draggingOffset.x, arg1.y + draggingOffset.y);

    NSTimer *emptyInsertTimer = wiggleManager.emptyInsertTimer;
    UIView *hitTestView = [collectionView hitTest:[collectionView convertPoint:arg1 fromView:[[self parentViewController] view]] withEvent:nil];
    UIView *hitTestSuperview = [hitTestView superview];
    TitleSectionHeaderView *headerView;

    if ([hitTestView isKindOfClass:objc_getClass("MusicApplication.TitleSectionHeaderView")]) {
        headerView = (TitleSectionHeaderView *)hitTestView;
    } else if ([hitTestSuperview isKindOfClass:objc_getClass("MusicApplication.TitleSectionHeaderView")]) {
        headerView = (TitleSectionHeaderView *)hitTestSuperview;
    }

    // TODO:
    // so the hit test can get either the title section header view or get it as a superview?
    // why do i do this? because I add my own subviews to the header?

    // HBLogDebug(@"hitTestView: %@, SUPERVIEW: %@", hitTestView, [hitTestView superview]);

    if (headerView) {
    //if ([[hitTestView superview] isKindOfClass:objc_getClass("MusicApplication.TitleSectionHeaderView")]) {
        //TitleSectionHeaderView *headerView = (TitleSectionHeaderView *)[hitTestView superview];
        NSString *identifier = [headerView identifier];
        // HBLogError(@"HIT TEST GOT TO HEADER VIEW: %@", headerView);

        if (!emptyInsertTimer){

            //BOOL sectionIsEmpty = [identifier isEqualToString:@"RecentSection"] ? [apManager recentSectionIsEmpty] : [apManager customSectionWithIdentifierIsEmpty:identifier];
            // BOOL sectionIsEmpty = [apManager sectionIsEmptyWithIdentifier:identifier];
            Section *section = [recentlyAddedManager sectionWithIdentifier:identifier];

            if ([section isEmpty]) {
                // TODO: possibly changes these dictionary keys?
                NSDictionary *userInfo = @{@"sectionIdentifier" : identifier, @"headerView" : headerView};
                emptyInsertTimer = [NSTimer scheduledTimerWithTimeInterval:0.75 target:self selector:@selector(handleEmptySectionInsert:) userInfo:userInfo repeats:NO];
                wiggleManager.emptyInsertTimer = emptyInsertTimer;

                [headerView highlightEmptyInsertionView:YES];
            }

        } else if (![identifier isEqualToString:emptyInsertTimer.userInfo[@"sectionIdentifier"]]) {
            [emptyInsertTimer.userInfo[@"headerView"] highlightEmptyInsertionView:NO];
            [emptyInsertTimer invalidate];
            // [self setEmptyInsertTimer:nil];
            wiggleManager.emptyInsertTimer = nil;
        }

    } else {
        if (emptyInsertTimer) {

            [emptyInsertTimer.userInfo[@"headerView"] highlightEmptyInsertionView:NO];

            [emptyInsertTimer invalidate];
            wiggleManager.emptyInsertTimer = nil;
        }
    }

    //NSIndexPath *newIndexPath = [collectionView indexPathForItemAtPoint:arg1];
    NSIndexPath *newIndexPath = [collectionView indexPathForItemAtPoint:[collectionView convertPoint:arg1 fromView:[[self parentViewController] view]]];

    if (newIndexPath && ![newIndexPath isEqual:draggingIndexPath]) {
        //[collectionView moveItemAtIndexPath:draggingIndexPath toIndexPath:newIndexPath];
        //[self setDraggingIndexPath:newIndexPath];
        [self collectionView:collectionView moveItemAtIndexPath:draggingIndexPath toIndexPath:newIndexPath];
        // [self setDraggingIndexPath:[[APManager sharedInstance] adjustedIndexPathForAlbumWithIdentifier:[self draggingAlbumIdentifier]]]; // old code
        // TODO: why do i get the index path using the album identifier here? can i not just use the newIndexPath?
        wiggleManager.draggingIndexPath = newIndexPath;
    }

    [self checkAutoScrollWithPoint:arg1];
}

%new
- (void)endDragAtPoint:(CGPoint)arg1 {
    [Logger logStringWithFormat:@"LRAVC: %p - endDragAtPoint:()", self];

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    WiggleModeManager *wiggleManager = [self wiggleModeManager];

    NSTimer *emptyInsertTimer = wiggleManager.emptyInsertTimer;
    if (emptyInsertTimer) {
        // if ([emptyInsertTimer isValid]) {
        if (emptyInsertTimer.userInfo[@"headerView"]) {
            [emptyInsertTimer.userInfo[@"headerView"] highlightEmptyInsertionView:NO];
        }
    }

    [wiggleManager invalidateTimers];

    UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");

    UIView *draggingView = wiggleManager.draggingView;
    NSIndexPath *draggingIndexPath = wiggleManager.draggingIndexPath;
    //NSIndexPath *originalIndexPath = [self originalIndexPath]; // old code

    AlbumCell *cell = (AlbumCell *)[collectionView cellForItemAtIndexPath:draggingIndexPath];
    UIView *artworkView = MSHookIvar<UIView *>(MSHookIvar<id>(cell, "artworkComponent"), "imageView");
    CGPoint targetCenter = [[[self parentViewController] view] convertPoint:artworkView.center fromView:cell];
    //CGPoint targetCenter = [[[self parentViewController] view] convertPoint:cell.center fromView:collectionView]; // old code

    NSDictionary *context = @{
        @"cell": cell,
        @"artworkView": artworkView,
        @"wiggleManager": wiggleManager,
        @"draggingView": draggingView,
        @"textStackView": MSHookIvar<UIView *>(cell, "textStackView")
    };

    [UIView beginAnimations:@"MELO_ANIMATION_END_DRAG" context:(__bridge_retained void *)context];
    [UIView setAnimationDuration:0.4];
    [UIView setAnimationDelegate:[self animationManager]];
    [UIView setAnimationDidStopSelector:@selector(handleAnimationDidStop:finished:context:)];
    [UIView setAnimationDuration:0.4];

        draggingView.center = targetCenter;
        draggingView.transform = CGAffineTransformIdentity;

    [UIView commitAnimations];

    [recentlyAddedManager saveData];
}

%new
- (void)handleEmptySectionInsert:(NSTimer *)arg1 {
    [Logger logStringWithFormat:@"LRAVC: %p - handleEmptySectionInsert:(%@)", self, arg1];

    // animate the flash highlight on the section header
    [arg1.userInfo[@"headerView"] animateEmptySectionInsertionFlash];

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    WiggleModeManager *wiggleManager = [self wiggleModeManager];

    // top two were commented out in old code
    //NSString *sectionIdentifier = arg1.userInfo[@"sectionIdentifier"];
    //NSInteger sectionIndex = [sectionIdentifier isEqualToString:@"RecentSection"] ? [apManager numberOfVisibleCustomSections] : [apManager visibleIndexForCustomSectionWithIdentifier:sectionIdentifier];
    // NSInteger sectionIndex = [apManager visibleIndexForSectionWithIdentifier:arg1.userInfo[@"sectionIdentifier"]];
    NSInteger sectionIndex = [recentlyAddedManager sectionIndexForIdentifier:arg1.userInfo[@"sectionIdentifier"]];

    NSIndexPath *draggingIndexPath = wiggleManager.draggingIndexPath;
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:0 inSection:sectionIndex];

    if (draggingIndexPath) {
        [self collectionView:MSHookIvar<UICollectionView *>(self, "_collectionView") moveItemAtIndexPath:draggingIndexPath toIndexPath:newIndexPath];
        // [self setDraggingIndexPath:newIndexPath];
        wiggleManager.draggingIndexPath = newIndexPath;
    }

    // [self setEmptyInsertTimer:nil];
    wiggleManager.emptyInsertTimer = nil;
}

%new
- (void)checkAutoScrollWithPoint:(CGPoint)arg1 {

    [Logger logStringWithFormat:@"LRAVC: %p - checkAutoScrollWithPoint:()", self];

    //CGPoint convertedPoint = [[[self parentViewController] view] convertPoint:arg1 fromView:MSHookIvar<UICollectionView *>(self, "_collectionView")];
    //CGPoint convertedPoint = arg1;

    WiggleModeManager *wiggleManager = [self wiggleModeManager];

    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    NSTimer *autoScrollTimer = [wiggleManager autoScrollTimer];

    // TODO: fix this method

    // you can condense this
    if (autoScrollTimer) {
    
        // if the user is holding the album cell in the middle of the screen, delete current autoscroll timer
        if (arg1.y > 0.2 * screenHeight && arg1.y < 0.8 * screenHeight) {
            [autoScrollTimer invalidate];
            wiggleManager.autoScrollTimer = nil;
        }

    } else {

        // CGFloat autoScrollInterval = 0.0025;
        CGFloat autoScrollInterval = 0.5;

        // user is holding the album cell at the top of the screen, autoscroll up
        if (arg1.y <= 0.2 * screenHeight) {

            // autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:.0025 repeats:YES block:^(NSTimer *timer) {
            //     [self autoScrollAction:YES];
            // }];

            NSDictionary *userInfo = @{@"direction" : @"MELO_AUTOSCROLL_DIRECTION_UP"};
            autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:autoScrollInterval target:self selector:@selector(handleAutoScrollTimerFired:) userInfo:userInfo repeats:YES];

        // user is holding the album cell at the bottom of the screen, autoscroll down
        } else if (arg1.y >= 0.8 * screenHeight) {

            NSDictionary *userInfo = @{@"direction" : @"MELO_AUTOSCROLL_DIRECTION_DOWN"};
            // autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:.0025 repeats:YES block:^(NSTimer *timer) {
            //     [self autoScrollAction:NO];
            // }];
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

    // this is what oyu want
    AudioServicesPlaySystemSound(1520);
}

%end

%hook UICollectionView

- (void)setContentSize:(CGRect)arg1 {
    %orig;
}

- (void)moveItemAtIndexPath:(NSIndexPath *)arg1 toIndexPath:(NSIndexPath *)arg2 {
    %orig;
}

- (void)reloadData {
    //%orig; //having it first seems to fix the didEndDisplayingCell crash bug, but then isReadyForUse is not YES in time for when the number of sections is checked

    id dataSource = [self dataSource];

    %orig;

    if (dataSource && [dataSource isKindOfClass:objc_getClass("MusicApplication.LibraryRecentlyAddedViewController")]) {
        [dataSource checkAlbumOrder];
    }

    //%orig;
}

// prevents crashing when opening a context menu in a section other than 0
- (void)reloadItemsAtIndexPaths:(NSArray *)arg1 {

    MeloManager *meloManager = [MeloManager sharedInstance];
    NSIndexPath *overridingIndexPath = meloManager.indexPathForContextMenuOverride;

    // check if overriding index path exists
    if (overridingIndexPath) {
        [[Logger sharedInstance] logString:[NSString stringWithFormat:@"UICollectionView: %p - inject index path during reload", self]];
        arg1 = @[overridingIndexPath];
    }

    %orig;
}

// allows the context menu to pop up with the correct album without crashing
// fairly certain this is just used to find the initial location of the selected cell when called in use of the context menu, but whatever the reason, it's necessary
- (UICollectionViewCell *)cellForItemAtIndexPath:(NSIndexPath *)arg1 {
    [[Logger sharedInstance] logStringWithFormat:@"UICollectionView: %p cellForItemAtIndexPath: %@", self, arg1];

    MeloManager *meloManager = [MeloManager sharedInstance];
    NSIndexPath *overridingIndexPath = meloManager.indexPathForContextMenuOverride;

    // check if overriding index path exists
    if (overridingIndexPath) {
        [[Logger sharedInstance] logStringWithFormat:@"\toverriding index path to: %@", overridingIndexPath];
        return %orig(overridingIndexPath);
    } else {
        return %orig;
    }
}

- (void)performBatchUpdates:(id)arg1 completion:(id)arg2 {
    // HBLogDebug(@"UICollectionView: %p performBatchUpdates", self);
    %orig;
}

%end

// adding custom actions to the context menu
%hook UIMenu

// not the best method to inject custom actions into, but the one i could find that works for the moment
- (UIMenu *)menuByReplacingChildren:(NSArray<UIMenuElement *> *)arg1 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"UIMenu: %@ - menuByReplacingChildren:(%@)", self, arg1]];

    MeloManager *meloManager = [MeloManager sharedInstance];
    RecentlyAddedManager *recentlyAddedManager = [currentLRAVC recentlyAddedManager];

    NSIndexPath *indexPathForContextActions = meloManager.indexPathForContextActions;
    BOOL shouldAddCustomContextActions = meloManager.shouldAddCustomContextActions;

    if ([meloManager prefsBoolForKey:@"customActionMenuEnabled"] || !currentLRAVC) {
        return %orig;
    }

    // [[Logger sharedInstance] logString:@"children:"];
    // for (id child in arg1) {
    //     [[Logger sharedInstance] logStringWithFormat:@"\tchild identifier: %@, child: %@", [child identifier], child];
    // }

    // do not attempt to inject custom context actions in the recently downloaded page if pinning there is disabled or if pins are synced from the full library
    if (recentlyAddedManager.isDownloadedMusic && (![meloManager prefsBoolForKey:@"downloadedPinningEnabled"] || [meloManager prefsBoolForKey:@"syncLibraryPinsEnabled"])) {
        return %orig;
    }

    // without the identifer check, when adding actions to the bottom of the list it worked perfectly, but adding to the top would create 3 duplicate actions. why? who could know..
    if (!shouldAddCustomContextActions) {
        return %orig;
    }

    [[Logger sharedInstance] logStringWithFormat:@"shouldAddCustomContextActions: %i, indexPathForContextActions: %@", shouldAddCustomContextActions, indexPathForContextActions];

    // detect if the menu already has the injected context actions
    BOOL containsInjectedActions = NO;

    // iterate over every child menu element
    for (id child in arg1) {

        // check if the child is an action and if so check its identifier prefix
        if ([child respondsToSelector:@selector(identifier)] && [[child identifier] hasPrefix:@"MELO_ACTION"]) {
            containsInjectedActions = YES;
            break;
        }

        // if child is a submenu, check if every one of its children is an action and if so has the right prefix
        if ([child isKindOfClass:[UIMenu class]]) {
            for (id subchild in [child children]) {
                if ([subchild respondsToSelector:@selector(identifier)] && [[subchild identifier] hasPrefix:@"MELO_ACTION"]) {
                    containsInjectedActions = YES;
                    break;
                }
            }
        }
    }

    // no injected actions were added yet, do so now
    if (!containsInjectedActions) {
        [[Logger sharedInstance] logString:@"no previously injected actions detected"];

        if (!currentLRAVC) {
            [[Logger sharedInstance] logString:@"no current LibraryRecentlyAddedViewController, this shouldn't happen..."];
            return %orig;
        }

        [[Logger sharedInstance] logString:@"here1"];

        NSMutableArray *newActions = [NSMutableArray array];
        // Album *targetAlbum = [recentlyAddedManager albumAtAdjustedIndexPath:indexPathForContextActions];

        /* add the move to section action */

        // place all move actions into a submenu
        BOOL displayMoveActionsInline = YES; // old code had this as a setting, default to yes for now 
        NSMutableArray *subMenuActions = [NSMutableArray array];

        if ([meloManager prefsBoolForKey:@"showMoveActionsEnabled"]) {

            // iterate over every section
            for (NSInteger i = 0; i < [recentlyAddedManager numberOfSections]; i++) {

                [[Logger sharedInstance] logStringWithFormat:@"%ld", i];
                
                // don't have move action to current section
                if (i == indexPathForContextActions.section) {
                    continue;
                }

                Section *section = [recentlyAddedManager sectionAtIndex:i];
                NSString *title = [NSString stringWithFormat:@"Move to '%@'", section.title];
                NSString *ident = [NSString stringWithFormat:@"MELO_ACTION_MOVE_TO_%@", section.identifier];

                [[Logger sharedInstance] logStringWithFormat:@"section: %@", section];

                // create the action
                UIAction *subMenuAction = [UIAction actionWithTitle:title image:[UIImage systemImageNamed:@"arrow.swap"] identifier:ident handler:^(UIAction *action) {
                    [currentLRAVC handleMoveToSectionAction:i];
                }];

                [subMenuActions addObject:subMenuAction];

                [[Logger sharedInstance] logString:@"added to submenuactions array"];
            }

            // only create the submenu if there is more than one action
            if ([subMenuActions count] > 1) {
                UIMenu *subMenu = [UIMenu menuWithTitle:@"Move to Section" image:[UIImage systemImageNamed:@"arrow.swap"] identifier:@"MELO_ACTION_MOVE_TO_SECTION_MENU"
                    options:displayMoveActionsInline ? UIMenuOptionsDisplayInline : 0 children:subMenuActions];

                [newActions addObject:subMenu];
            } else if ([subMenuActions count] == 1) {
                [newActions addObject:subMenuActions[0]];
            }
        }

        if ([meloManager prefsBoolForKey:@"showShiftActionsEnabled"]) {

            // add shift left action if possible
            if ([recentlyAddedManager canShiftAlbumAtAdjustedIndexPath:indexPathForContextActions movingLeft:YES]) {
                UIAction *shiftLeftAction = [UIAction actionWithTitle:@"Shift Left" image:[UIImage systemImageNamed:@"arrow.left"] identifier:@"MELO_ACTION_SHIFT_LEFT" handler:^(UIAction *action) {
                    [currentLRAVC handleShiftAction:YES];
                }];

                [newActions addObject:shiftLeftAction];
            }

            // add shift right action if possible
            if ([recentlyAddedManager canShiftAlbumAtAdjustedIndexPath:indexPathForContextActions movingLeft:NO]) {
                UIAction *shiftRightAction = [UIAction actionWithTitle:@"Shift Right" image:[UIImage systemImageNamed:@"arrow.right"] identifier:@"RIGHT" handler:^(UIAction *action) {
                    [currentLRAVC handleShiftAction:NO];
                }];

                [newActions addObject:shiftRightAction];
            }
        }

        // add wiggle mode action if possible
        if ([meloManager prefsBoolForKey:@"showWiggleModeActionEnabled"]) {
            
            UIAction *wiggleAction = [UIAction actionWithTitle:@"Wiggle Mode" image:[UIImage systemImageNamed:@"wrench.fill"] identifier:@"MELO_ACTION_WIGGLE" handler:^(UIAction *action) {
                [currentLRAVC toggleWiggleMode];
            }];

            [newActions addObject:wiggleAction];
        }

        // placing all custom actions into a submenu
        if ([meloManager prefsBoolForKey:@"allActionsInSubmenuEnabled"]) {
            UIMenu *subMenu = [UIMenu menuWithTitle:@"Melo Actions" image:[UIImage systemImageNamed:@"pin"] identifier:@"MELO_ACTION_SUBMENU"
                options:[meloManager prefsBoolForKey:@"allActionsInSubmenuEnabled"] ? 0 : UIMenuOptionsDisplayInline children:newActions];

            newActions = [NSMutableArray arrayWithObjects:subMenu, nil];
        }

        // placing custom actions at top or bottom
        BOOL placeMenuAtTop = [[meloManager prefsObjectForKey:@"contextActionsLocationValue"] integerValue] == 0;

        if (placeMenuAtTop) {
            arg1 = [newActions arrayByAddingObjectsFromArray:arg1];
        } else {
            arg1 = [arg1 arrayByAddingObjectsFromArray:newActions];
        }
    }

	id orig =  %orig;
    [[Logger sharedInstance] logStringWithFormat:@"UIMenu result: %@", orig];
    return orig;
}

%end

%hook ArtworkPrefetchingController

// ios 14+ needs real index paths injected here as the adjusted index paths seem to be passed during [UICollectionView layoutSubviews]
// this fixes a crash caused by scrolling down (to the point where the injected pinned section title leaves the screen)
- (void)collectionView:(UICollectionView *)arg1 prefetchItemsAtIndexPaths:(id)arg2 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"ArtworkPrefetchingController: %p - collectionView:(%p) prefetchItemsAtIndexPaths:(%@)", self, arg1, arg2]];

    // check if this instance is for the current LibraryRecentlyAddedViewController
    if (currentLRAVC && [currentLRAVC recentlyAddedManager] && [[currentLRAVC recentlyAddedManager] isReadyForUse] && arg1 == MSHookIvar<UICollectionView *>(currentLRAVC, "_collectionView")) {

        // translate all adjusted index paths to their real index path
        NSMutableArray *realIndexPaths = [NSMutableArray array];
        for (NSIndexPath *indexPath in arg2) {
            [realIndexPaths addObject:[[currentLRAVC recentlyAddedManager] translateIndexPath:indexPath]];
        }

        arg2 = realIndexPaths;
    }

    %orig;
}

%end

%hook AlbumCell

- (void)layoutSubviews {
    %orig;

    MeloManager *meloManager = [MeloManager sharedInstance];

    id dataSource = [[self _collectionView] dataSource];
    // BOOL shouldChangeCornerRadius = [dataSource isKindOfClass:objc_getClass("MusicApplication.LibraryRecentlyAddedViewController")] || ([apManager prefsBoolForKey:@"affectAlbumsPagesEnabled"] && ([dataSource isKindOfClass:objc_getClass("MusicApplication.AlbumsViewController")] || [dataSource isKindOfClass:objc_getClass("MusicApplication.ArtistViewController")]));
    // BOOL shouldChangeCornerRadius = [dataSource isKindOfClass:objc_getClass("MusicApplication.LibraryRecentlyAddedViewController")]
    //     && [meloManager prefsBoolForKey:@"customAlbumCellCornerRadiusEnabled"];
    
    BOOL shouldChangeCornerRadius = [meloManager prefsBoolForKey:@"customAlbumCellCornerRadiusEnabled"] && 
    ([dataSource isKindOfClass:objc_getClass("MusicApplication.LibraryRecentlyAddedViewController")] || 
    ([meloManager prefsBoolForKey:@"affectAlbumPagesEnabled"] && 
    ([dataSource isKindOfClass:objc_getClass("MusicApplication.AlbumsViewController")] ||
    [dataSource isKindOfClass:objc_getClass("MusicApplication.ArtistViewController")])));

    if (shouldChangeCornerRadius) {

        CGFloat radius = [[meloManager prefsObjectForKey:@"customAlbumCellCornerRadius"] floatValue] / 100 * [self frame].size.width;

        UIView *artworkView = MSHookIvar<UIView *>(MSHookIvar<id>(self, "artworkComponent"), "imageView");

        [artworkView setClipsToBounds:YES];
        [[artworkView layer] setCornerRadius:radius];
        //[[self layer] setContinuousCorners:YES];
    }

    if ([dataSource isKindOfClass:objc_getClass("MusicApplication.LibraryRecentlyAddedViewController")]) {
        WiggleModeManager *wiggleManager = [dataSource wiggleModeManager];
        // if (wiggleManager) {
            [wiggleManager inWiggleMode] ? [self addShakeAnimation] : [self removeShakeAnimation];
        // }
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

%hook UIView

// set the tint color of all uiviews 
- (void)setTintColor:(id)arg1 {
    
    MeloManager *meloManager = [MeloManager sharedInstance];
    
    if (arg1 && [meloManager prefsBoolForKey:@"customTintColorEnabled"]) {

        // get names of the pink color and current tint color
        NSString *name = [arg1 accessibilityName];
        NSString *pinkName = [[UIColor systemPinkColor] accessibilityName];

        // check if custom tint color is enabled and the names match
        if (name && [pinkName isEqualToString:name]) {
            
            // set the custom tint color
            UIColor *color = [ColorUtils dictToColor:[meloManager prefsObjectForKey:@"customTintColor"]];

            if (color) {
                %orig(color);
                return;
            }
        }
    }

    // call orig if all conditions were not met
    %orig;
}

%end

%hook VerticalStackScrollView
%property(assign, nonatomic) BOOL hasDelayedContentSizeChange;
%property(assign, nonatomic) CGSize delayedContentSize;

// prevents instaneous (and glitchy) shrinking of the main scroll view while in wiggle mode
- (void)setContentSize:(CGSize)arg1 {

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

%hook AlbumsViewController

- (id)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {

    // APManager *apManager = [APManager sharedInstance];
    AlbumCell *orig = %orig;

    //if ([apManager isReadyForUse]) {
        // if ([apManager prefsBoolForKey:@"hideAlbumTextEnabled"] && [apManager prefsBoolForKey:@"affectAlbumsPagesEnabled"]) {
        //     [MSHookIvar<id>(orig, "textStackView") setHidden:YES];
        // }
    //}

    return orig;
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] minimumCellSpacing];
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] minimumCellSpacing];
}

%end

%hook ArtistViewController

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] minimumCellSpacing];
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] minimumCellSpacing];
}

%end

%ctor {

    MeloManager *meloManager = [MeloManager sharedInstance];

    if ([meloManager prefsBoolForKey:@"enabled"]) {
        %init(LibraryRecentlyAddedViewController = objc_getClass("MusicApplication.LibraryRecentlyAddedViewController"), 
            TitleSectionHeaderView = objc_getClass("MusicApplication.TitleSectionHeaderView"),
            ArtworkPrefetchingController = objc_getClass("MusicApplication.ArtworkPrefetchingController"),
            AlbumCell = objc_getClass("MusicApplication.AlbumCell"),
            VerticalStackScrollView = objc_getClass("_TtCC16MusicApplication27VerticalStackViewController10ScrollView"),
            AlbumsViewController = objc_getClass("MusicApplication.AlbumsViewController"),
            ArtistViewController = objc_getClass("MusicApplication.ArtistViewController")
        );
    }
}