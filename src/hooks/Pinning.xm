
#import <UIKit/UIKit.h>
#import <HBLog.h>
#import "hooks.h"
#import "../objc/objc_classes.h"
#import "../interfaces/interfaces.h"

%group PinningGroup

// unlock the total number of albums in the recently added section
%hook MPModelLibraryRequest

- (void)setContentRange:(NSRange)arg1 {
    [[Logger sharedInstance] logStringWithFormat:@"MPModelLibraryRequest: %p - setContentRange: %@", self, arg1];
    [[Logger sharedInstance] logStringWithFormat:@"length: %li", (long)arg1.length];

    // TODO: check if length == 60? since i believe that's the default when getting recently added albums
    // however this also doesn't seem to affect anything? so idk. 
    // but it could do something, perhaps with albums returned for an artist, or retrieved for some other shelf display

    // override the default content length
    if (arg1.length > 0 && [[MeloManager sharedInstance] prefsBoolForKey:@"removeAlbumLimitEnabled"]) {
        arg1.length = 10000;
    }

    %orig;
}

%end


// response object containing results from a library request
%hook MPModelLibraryResponse 

// the results of a request are complete
- (void)setResults:(MPSectionedCollection *)arg1 {

    %orig;

    MeloManager *meloManager = [MeloManager sharedInstance];

    // get the identifier of the library of the request
    NSString *libraryIdentifier = [[self libraryAssertion] identifier];

    // get the localized titles of the two libraries that are requested
    NSString *localizedRecentlyAddedTitle = [MeloManager localizedRecentlyAddedTitle];
    NSString *localizedDownloadedMusicTitle = [MeloManager localizedDownloadedMusicTitle];

    // send a notification to recently added managers containing the new results
    if ([localizedRecentlyAddedTitle isEqualToString:libraryIdentifier] || [localizedDownloadedMusicTitle isEqualToString:libraryIdentifier]) {

        NSDictionary *userInfo = @{
            @"identifier" : libraryIdentifier,
            @"results": [arg1 copy]
        };

        [[NSNotificationCenter defaultCenter] postNotificationName:@"MELO_NOTIFICATION_LIBRARY_RESPONSE_RESULTS_UPDATED" object:self userInfo:userInfo];
    }
}

%end

// header views in the recently added sections
%hook TitleSectionHeaderView
%property(strong, nonatomic) UIImageView *chevronIndicatorView;
%property(strong, nonatomic) NSString *identifier;
%property(strong, nonatomic) UITapGestureRecognizer *tapGesture;
%property(strong, nonatomic) LibraryRecentlyAddedViewController *recentlyAddedViewController;
%property(assign, nonatomic) BOOL shouldApplyCollapseItems;

// default initializer
- (id)initWithFrame:(CGRect)arg1 {
    id orig = %orig;
    [orig setShouldApplyCollapseItems:NO];
    return orig;
}

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

    if ([self shouldApplyCollapseItems]) {

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

%hook LibraryRecentlyAddedViewController
%property(strong, nonatomic) WiggleModeManager *wiggleModeManager;
%property(strong, nonatomic) RecentlyAddedManager *recentlyAddedManager;
%property(strong, nonatomic) AlbumActionsViewController *albumActionsVC;
%property(strong, nonatomic) AnimationManager *animationManager;
%property(assign) BOOL shouldInjectPinningData;

// default initializer
- (id)init {

    [Logger logStringWithFormat:@"LRAVC: %p - init", self];
    
    RecentlyAddedManager *recentlyAddedManager = [RecentlyAddedManager new];
    WiggleModeManager *wiggleManager = [WiggleModeManager new];   
    AnimationManager *animationManager = [AnimationManager new]; 

    recentlyAddedManager.lravc = self;

    [self setRecentlyAddedManager:recentlyAddedManager];
    [self setWiggleModeManager:wiggleManager];
    [self setAnimationManager:animationManager];
    [self setShouldInjectPinningData:NO];

    id orig = %orig;

    // add an observer for whenever a pinning preferences change was detected
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePinningPrefsUpdate:) name:@"MELO_NOTIFICATION_PREFS_UPDATED_PINNING" object:[MeloManager sharedInstance]];
    
    return orig;
}

// helper method to access the model response ivar
%new
- (MPModelResponse *)modelResponse {
    MPModelResponse *response = MSHookIvar<MPModelResponse *>(self, "_modelResponse");
    return response;
}

// update the collection view when a change to the album order or pinning order (from another manager) is changed
%new
- (void)reloadDataForAlbumUpdate {
    [Logger logStringWithFormat:@"LRAVC: %p - handlePinningDataIsReady: ", self];

    MeloManager *meloManager = [MeloManager sharedInstance];
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];

    BOOL isDownloadedMusic = [recentlyAddedManager isDownloadedMusic];
    BOOL shouldInjectPinningData = !isDownloadedMusic || (isDownloadedMusic && [meloManager prefsBoolForKey:@"downloadedPinningEnabled"]);

    [self setShouldInjectPinningData:shouldInjectPinningData];

    UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");
    if (collectionView) {
        [collectionView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }
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

- (void)viewWillAppear:(BOOL)arg1 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - viewWillAppear:(%i)", self, arg1]];

    // use this to detect which library view controller it is?
    // need to be able to read the title, which does get set later...able
    // any other way to differentiate them?

    [[MeloManager sharedInstance] setCurrentLRAVC:self];
    %orig;
}

- (void)viewDidAppear:(BOOL)arg1 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - viewDidAppear:(%i)", self, arg1]];

    [[MeloManager sharedInstance] setCurrentLRAVC:self];
    %orig;
}

- (void)viewWillDisappear:(BOOL)arg1 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - viewWillDisappear:(%i)", self, arg1]];
    %orig;
    // [[self recentlyAddedManager] saveData];

    if ([self wiggleModeManager].inWiggleMode) {
        [self toggleWiggleMode];
    }
}

- (void)viewDidDisappear:(BOOL)arg1 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - viewDidDisappear:(%i)", self, arg1]];
    %orig;

    // [[self recentlyAddedManager] setAttemptedDataLoad:NO];
    [[MeloManager sharedInstance] setCurrentLRAVC:nil];
}

- (void)setTitle:(NSString *)title {
    [[Logger sharedInstance] logStringWithFormat:@"LRAVC %p - setTitle:(%@)", self, title];

    // when the downloaded music page is opened, this method is called twice
    // the first time is in the init which sets it to "Recently Added"
    // sometime later it gets called again setting it to "Recently Downloaded"
    // so unfortunately, two loads are performed, but it works so oh well

    %orig;

    NSString *localizedRecentlyAddedTitle = [MeloManager localizedRecentlyAddedTitle];
    NSString *localizedDownloadedMusicTitle = [MeloManager localizedDownloadedMusicTitle];

    if ([title isEqualToString:localizedRecentlyAddedTitle]) {
        [[self recentlyAddedManager] setIsDownloadedMusic:NO];
    } else if ([title isEqualToString:localizedDownloadedMusicTitle]) {
        [[self recentlyAddedManager] setIsDownloadedMusic:YES];
    }

    [[self recentlyAddedManager] loadData];
}

// update the view when pinning preferences were changed
%new
- (void)handlePinningPrefsUpdate:(NSNotification *)arg1 {

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");

    [recentlyAddedManager loadData];
    [collectionView reloadData];
}

/* methods that deal with displaying sections */

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)arg1 {
    // [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - numberOfSectionsInCollectionView:(%p)", self, arg1]];

    // get the recently added manager
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    
    // check if the manager is not ready to inject fake data
    if (![self shouldInjectPinningData]) {
        return %orig;
    }
    
    return [recentlyAddedManager numberOfSections];
}

- (NSInteger)collectionView:(UICollectionView *)arg1 numberOfItemsInSection:(NSInteger)arg2 {
    // [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) numberOfItemsInSection:(%li)", self, arg1, arg2]];

    // get the recently added manager
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    
    // check if the manager is not ready to inject fake data
    if (![self shouldInjectPinningData]) {
        return %orig;
    }

    // return 0 if the section is collapsed, otherwise return the actual number of albums
    Section *section = [recentlyAddedManager sectionAtIndex:arg2];
    return section.isCollapsed ? 0 : [section numberOfAlbums];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)arg1 viewForSupplementaryElementOfKind:(id)arg2 atIndexPath:(NSIndexPath *)arg3 {
    // [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) viewForSupplementaryElementOfKind:(%@) atIndexPath:<%ld-%ld>", self, arg1, arg2, arg3.section, arg3.item]];
    
    // get the recently added manager
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];

    // check if the manager is not ready to inject fake data
    if (![self shouldInjectPinningData]) {
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
        [titleHeaderView setShouldApplyCollapseItems:YES];
    }

    return orig;
}

// - (void)collectionView:(UICollectionView *)arg1 didEndDisplayingSupplementaryView:(UICollectionReusableView *)arg2 forElementOfKind:(id)arg3 atIndexPath:(NSIndexPath *)arg4 {
- (void)collectionView:(id)arg1 didEndDisplayingSupplementaryView:(id)arg2 forElementOfKind:(id)arg3 atIndexPath:(id)arg4 {
    // [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) didEndDisplayingSupplementaryView:(%@) forElementOfKind:(%@) atIndexPath:<%@>", self, arg1, arg2, arg3, arg4]];

    // get the recently added manager
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];

    // check if the manager is not ready to inject fake data
    if (![self shouldInjectPinningData]) {
        %orig;
        return;
    }

    %orig;
}

/* methods that deal with displaying albums */

- (id)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {
    // [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) cellForItemAtIndexPath:<%ld-%ld>", self, arg1, arg2.section, arg2.item]];

    id orig;

    // check if recently added manager is ready to inject data
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    if (![self shouldInjectPinningData]) {
        orig = %orig;
    } else {
        Album *album = [recentlyAddedManager albumAtAdjustedIndexPath:arg2];
        // NSIndexPath *realIndexPath = [recentlyAddedManager translateIndexPath:arg2];
        // [[Logger sharedInstance] logString:[NSString stringWithFormat:@"realIndexPath:<%ld-%ld>", realIndexPath.section, realIndexPath.item]];

        // use the injected data
        orig = %orig(arg1, [album realIndexPath]);
        [orig setIdentifier:album.identifier];
        
        if ([album isFakeAlbum]) {
            [orig createWiggleModeFakeAlbumView];
        }
    }

    return orig;
}

- (id)collectionView:(UICollectionView *)arg1 contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)arg2 point:(CGPoint)arg3 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) contextMenuConfigurationForItemAtIndexPath:<%ld-%ld> point:(do later if needed)", self, arg1, arg2.section, arg2.item]];

    // check if recently added manager is ready to inject data
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    MeloManager *meloManager = [MeloManager sharedInstance];

    if (![self shouldInjectPinningData]) {
        return %orig;
    
    // do not allow context menu configurations to be generated at all in wiggle mode
    } else if ([self wiggleModeManager].inWiggleMode) {
        [Logger logString:@"in wiggle mode, preventing context menu generation"];
        return nil;
    }

    // set index path override to prevent collection view crash
    meloManager.indexPathForContextMenuOverride = arg2;

    // use injected data
    UIContextMenuConfiguration *orig = %orig(arg1, [recentlyAddedManager translateIndexPath:arg2], arg3);

    // reset override value
    meloManager.indexPathForContextMenuOverride = nil;

    // inject custom context menu actions
    if (![meloManager prefsBoolForKey:@"customActionMenuEnabled"] && [recentlyAddedManager shouldAllowDownloadedMusicContextMenu]) {
        
        // create a new block that uses the current action provider
        UIContextMenuActionProvider actionProvider = [orig actionProvider];
        UIContextMenuActionProvider providerWrapper = ^UIMenu *(NSArray<UIMenuElement *> *suggestedActions) {

            UIMenu *origMenu = actionProvider(suggestedActions);
            NSArray *customActions = [self customContextActionsForAlbumAtIndexPath:arg2];
            NSArray *newChildren;

            // placing custom actions at top or bottom of the menu
            BOOL placeMenuAtTop = [meloManager prefsIntForKey:@"contextActionsLocationValue"] == 0;
            if (placeMenuAtTop) {
                newChildren = [customActions arrayByAddingObjectsFromArray:[origMenu children]];
            } else {
                newChildren = [[origMenu children] arrayByAddingObjectsFromArray:customActions];
            }

            MSHookIvar<NSArray *>(origMenu, "_children") = newChildren;
            return origMenu;
        };

        [orig setActionProvider:providerWrapper];
    }

    return orig;
}

- (void)collectionView:(UICollectionView *)arg1 willEndContextMenuInteractionWithConfiguration:(id)arg2 animator:(id)arg3 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) willEndContextMenuInteractionWithConfiguration: (%p) animator:(%p)", self, arg1, arg2, arg3]];

    // no need to use injected data here
    %orig;

    // reset override value
    // MeloManager *meloManager = [MeloManager sharedInstance];
    // meloManager.indexPathForContextMenuOverride = nil; // TODO: commented out in old code, remove?
}

- (void)collectionView:(UICollectionView *)arg1 willDisplayCell:(id)arg2 forItemAtIndexPath:(NSIndexPath *)arg3 {
    // [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) willDisplayCell:(%p) forItemAtIndexPath:<%ld-%ld>", self, arg1, arg2, arg3.section, arg3.item]];

    // TODO: in old code, contained some checks for if the requested item is out of bounds for some reason
    // i remember this fixing some crash, due to the system using the default index paths to request but not being able to properly translate them?
    // not really sure, but i bet it'll come up again..
    
    // check if recently added manager is ready to inject data
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    if (![self shouldInjectPinningData]) {
        %orig;
        return;
    }
    NSIndexPath *adjustedIndexPath = [recentlyAddedManager translateIndexPath:arg3];

    // [[Logger sharedInstance] logString:[NSString stringWithFormat:@"adjustedIndexPath:<%ld-%ld>", adjustedIndexPath.section, adjustedIndexPath.item]];

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
    // [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) didEndDisplayingCell:(%p) forItemAtIndexPath:<%ld-%ld>", self, arg1, arg2, arg3.section, arg3.item]];
    
    // in old code, this did not ever inject a different index path, it just called %orig, so maybe do that again here as well..
    
    // check if recently added manager is ready to inject data
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    if (![self shouldInjectPinningData]) {
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
    if (![self shouldInjectPinningData]) {
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
    if (![self shouldInjectPinningData]) {
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
    
    // check if recently added manager is ready to inject data
    if (![self shouldInjectPinningData]) {
        return %orig;
    } else if ([self wiggleModeManager].inWiggleMode) {
        
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
- (void)handleActionMoveAlbumAtIndexPath:(NSIndexPath *)sourceAdjustedIndexPath toSection:(NSInteger)sectionIndex {
    [[Logger sharedInstance] logStringWithFormat:@"LRAVC: %p - handleMoveToSectionAction:(%ld)", self, sectionIndex];

    // TODO: eh do i really worry about this?
    // ideally, if moving the album back into the recently added section, it will move it to the album's proper place
    // for now tho, i'll just move it to the first spot, then it will move back whenever the app is refreshed since the recently added section is not saved

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    NSIndexPath *destAdjustedIndexPath = [NSIndexPath indexPathForItem:0 inSection:sectionIndex];

    // commented out so that the block does not cause a crash while patching with allemand
    // // perform the move operation
    // [self moveAlbumCellFromAdjustedIndexPath:sourceAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath dataUpdateBlock:^(){
    //     [recentlyAddedManager moveAlbumAtAdjustedIndexPath:destAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath];
    // }];        

    [recentlyAddedManager moveAlbumAtAdjustedIndexPath:sourceAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath];
    [self moveAlbumCellFromAdjustedIndexPath:sourceAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath dataUpdateBlock:nil]; 
}

%new 
- (void)handleActionShiftAlbumAtIndexPath:(NSIndexPath *)sourceAdjustedIndexPath movingLeft:(BOOL)isMovingLeft {
    [[Logger sharedInstance] logStringWithFormat:@"LRAVC: %p - handleShiftAction:isMovingLeft:(%i)", self, isMovingLeft];

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    NSIndexPath *destAdjustedIndexPath;
    
    // the destination is one to the left or right of the current item
    if (isMovingLeft) {
        destAdjustedIndexPath = [NSIndexPath indexPathForItem:sourceAdjustedIndexPath.item - 1 inSection:sourceAdjustedIndexPath.section];
    } else {
        destAdjustedIndexPath = [NSIndexPath indexPathForItem:sourceAdjustedIndexPath.item + 1 inSection:sourceAdjustedIndexPath.section];
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

    // move the cell
    [collectionView moveItemAtIndexPath:sourceIndexPath toIndexPath:destIndexPath];
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

// generate a UIMenu with actions to be added to the context menu for an album at an adjusted index path
%new
- (NSArray *)customContextActionsForAlbumAtIndexPath:(NSIndexPath *)indexPathForContextActions {

    MeloManager *meloManager = [MeloManager sharedInstance];
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];

    NSMutableArray *actions = [NSMutableArray array];

    // add the move to section actions 
    if ([meloManager prefsBoolForKey:@"showMoveActionsEnabled"]) {
        
        // place all move actions into a submenu
        BOOL displayMoveActionsInline = YES;
        NSMutableArray *subMenuActions = [NSMutableArray array];

        // iterate over every section
        for (NSInteger i = 0; i < [recentlyAddedManager numberOfSections]; i++) {

            [[Logger sharedInstance] logStringWithFormat:@"%ld", i];
            
            // don't have move action to current section
            if (i == indexPathForContextActions.section) {
                continue;
            }

            Section *section = [recentlyAddedManager sectionAtIndex:i];
            NSString *title = [NSString stringWithFormat:@"Move to '%@'", [section displayTitle]];
            NSString *ident = [NSString stringWithFormat:@"MELO_ACTION_MOVE_TO_%@", section.identifier];

            [[Logger sharedInstance] logStringWithFormat:@"section: %@", section];

            // create the action
            UIAction *subMenuAction = [UIAction actionWithTitle:title image:[UIImage systemImageNamed:@"arrow.swap"] identifier:ident handler:^(UIAction *action) {
                [self handleActionMoveAlbumAtIndexPath:indexPathForContextActions toSection:i];
            }];
            [subMenuActions addObject:subMenuAction];

            [[Logger sharedInstance] logString:@"added to submenuactions array"];
        }

        UIMenu *subMenu = [UIMenu menuWithTitle:@"Move to Section" image:[UIImage systemImageNamed:@"arrow.swap"] identifier:@"MELO_ACTION_MOVE_TO_SECTION_MENU"
            options:displayMoveActionsInline ? UIMenuOptionsDisplayInline : 0 children:subMenuActions];
        [actions addObject:subMenu];
    }

    // shift left / right actions
    if ([meloManager prefsBoolForKey:@"showShiftActionsEnabled"]) {

        // place all move actions into a submenu
        BOOL displayShiftActionsInline = YES;
        NSMutableArray *subMenuActions = [NSMutableArray array];

        // add shift left action if possible
        if ([recentlyAddedManager canShiftAlbumAtAdjustedIndexPath:indexPathForContextActions movingLeft:YES]) {
            UIAction *shiftLeftAction = [UIAction actionWithTitle:@"Shift Left" image:[UIImage systemImageNamed:@"arrow.left"] identifier:@"MELO_ACTION_SHIFT_LEFT" handler:^(UIAction *action) {
                [self handleActionShiftAlbumAtIndexPath:indexPathForContextActions movingLeft:YES];
            }];
            [subMenuActions addObject:shiftLeftAction];
        }

        // add shift right action if possible
        if ([recentlyAddedManager canShiftAlbumAtAdjustedIndexPath:indexPathForContextActions movingLeft:NO]) {
            UIAction *shiftRightAction = [UIAction actionWithTitle:@"Shift Right" image:[UIImage systemImageNamed:@"arrow.right"] identifier:@"RIGHT" handler:^(UIAction *action) {
                [self handleActionShiftAlbumAtIndexPath:indexPathForContextActions movingLeft:NO];
            }];
            [subMenuActions addObject:shiftRightAction];
        }

        UIMenu *subMenu = [UIMenu menuWithTitle:@"Shift Left/Right" image:[UIImage systemImageNamed:@"arrow.left.arrow.right"] identifier:@"MELO_ACTION_SHIFT_MENU"
            options:displayShiftActionsInline ? UIMenuOptionsDisplayInline : 0 children:subMenuActions];
        [actions addObject:subMenu];
    }

    // add wiggle mode action
    if ([meloManager prefsBoolForKey:@"showWiggleModeActionEnabled"]) {
        UIAction *wiggleAction = [UIAction actionWithTitle:@"Wiggle Mode" image:[UIImage systemImageNamed:@"wrench.fill"] identifier:@"MELO_ACTION_WIGGLE" handler:^(UIAction *action) {
            [self toggleWiggleMode];
        }];
        
        UIMenu *subMenu = [UIMenu menuWithTitle:@"Wiggle Mode" image:[UIImage systemImageNamed:@"wrench.fill"] identifier:@"MELO_ACTION_WIGGLE_MENU"
            options:UIMenuOptionsDisplayInline children:@[wiggleAction]];
        [actions addObject:subMenu];
    }

    // placing all custom actions into a submenu
    UIMenu *subMenu = [UIMenu menuWithTitle:@"Melo Actions" image:[UIImage systemImageNamed:@"pin"] identifier:@"MELO_ACTION_SUBMENU" 
        options:[meloManager prefsBoolForKey:@"allActionsInSubmenuEnabled"] ? 0 : UIMenuOptionsDisplayInline children:actions];
    
    return @[subMenu];
}

%end


%hook UICollectionView

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
    // [[Logger sharedInstance] logStringWithFormat:@"UICollectionView: %p cellForItemAtIndexPath: %@", self, arg1];

    MeloManager *meloManager = [MeloManager sharedInstance];
    NSIndexPath *overridingIndexPath = meloManager.indexPathForContextMenuOverride;

    // check if overriding index path exists
    if (overridingIndexPath) {
        [[Logger sharedInstance] logStringWithFormat:@"\toverriding [UICollectionView cellForItemAtIndexPath:%@] index path to: %@", arg1, overridingIndexPath];
        return %orig(overridingIndexPath);
    } else {
        return %orig;
    }
}

%end


%hook ArtworkPrefetchingController

// ios 14+ needs real index paths injected here as the adjusted index paths seem to be passed during [UICollectionView layoutSubviews]
// this fixes a crash caused by scrolling down (to the point where the injected pinned section title leaves the screen)
- (void)collectionView:(UICollectionView *)arg1 prefetchItemsAtIndexPaths:(id)arg2 {
    // [[Logger sharedInstance] logString:[NSString stringWithFormat:@"ArtworkPrefetchingController: %p - collectionView:(%p) prefetchItemsAtIndexPaths:(%@)", self, arg1, arg2]];

    LibraryRecentlyAddedViewController *currentLRAVC = [[MeloManager sharedInstance] currentLRAVC];

    // check if this instance is for the current LibraryRecentlyAddedViewController
    if (currentLRAVC && [currentLRAVC shouldInjectPinningData] && arg1 == MSHookIvar<UICollectionView *>(currentLRAVC, "_collectionView")) {

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

%end

// pinning hooks constructor
extern "C" void InitPinning() {

    MeloManager *meloManager = [MeloManager sharedInstance];

    if ([meloManager prefsBoolForKey:@"pinningHooksEnabled"]) {
        %init(PinningGroup,
            LibraryRecentlyAddedViewController = objc_getClass("MusicApplication.LibraryRecentlyAddedViewController"), 
            TitleSectionHeaderView = objc_getClass("MusicApplication.TitleSectionHeaderView"),
            ArtworkPrefetchingController = objc_getClass("MusicApplication.ArtworkPrefetchingController")
        );
    }
}