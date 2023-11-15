#import <UIKit/UIKit.h>
#import <AppKit/AppKit.h>
#import <Accelerate/Accelerate.h>
#import "hooks.h"
#import "../objc/objc_classes.h"
#import "../interfaces/interfaces.h"

// hooks focused on customizing the library experience
%group LibraryGroup 

%hook LibraryMenuViewController
%property(assign, nonatomic) BOOL shouldInjectCustomData;

// default initializer
- (id)init {
    id orig = %orig;

    [orig setShouldInjectCustomData:YES]; // TODO: should default to NO until ready?

    return orig;
}

// helper method to get the dataSource ivar
%new
- (id)dataSource {
    return MSHookIvar<id>(self, "dataSource");
}

- (void)viewWillAppear:(BOOL)arg1 {
    %orig;
}

// handle selection of one of the rows in the menu
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    LibraryMenuDataSource *dataSource = [self dataSource];
    LibraryMenuManager *libraryMenuManager = [LibraryMenuManager sharedInstance];
    
    NSInteger numberOfRows = [dataSource tableView:tableView numberOfRowsInSection:indexPath.section];
    BOOL rowIsAddedPage = indexPath.row >= numberOfRows - [libraryMenuManager numberOfAddedPages];

    // do not inject data if not ready or if the row is a stock page
    if (![self shouldInjectCustomData] || !rowIsAddedPage) {
        %orig;
        return;
    }

    // get the cell info for the given row
    NSInteger addedPageIndex = [libraryMenuManager numberOfAddedPages] - (numberOfRows - indexPath.row);
    NSMutableDictionary *pageInfo = libraryMenuManager.addedPages[addedPageIndex];
    
    if (pageInfo[@"viewController"]) {

        // UIViewController *lastSongsViewController = meloManager.lastSongsViewController;
        UIViewController *viewController = pageInfo[@"viewController"];
        [[self navigationController] pushViewController:viewController animated:YES];
        // [lastSongsViewController.navigationItem setRightBarButtonItems:meloManager.lastSongsNavItem animated:YES];
    }
}


%end

%hook LibraryMenuDataSource
%property(assign, nonatomic) BOOL shouldInjectCustomData;

// default intializer
- (id)init {

    id orig = %orig;

    [orig setShouldInjectCustomData:YES]; // TODO: should default to NO?

    return orig;
}

// get the number of rows in the given section 
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // do not inject data if not ready
    // if (![self shouldInjectCustomData]) {
    //     return %orig;
    // }

    LibraryMenuManager *libraryMenuManager = [LibraryMenuManager sharedInstance];
    return %orig + [libraryMenuManager numberOfAddedPages];
}

// get the table view cell for a given row in the library menu table view
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    LibraryMenuManager *libraryMenuManager = [LibraryMenuManager sharedInstance];
    
    NSInteger numberOfRows = [self tableView:tableView numberOfRowsInSection:indexPath.section];
    // BOOL rowIsAddedPage = indexPath.row >= numberOfRows - [libraryMenuManager numberOfAddedPages];
    BOOL rowIsStockPage = indexPath.row < numberOfRows - [libraryMenuManager numberOfAddedPages];
    
    // do not inject data if not ready or if the row is a stock page
    // if (![self shouldInjectCustomData] || rowIsStockPage) {
    //     return %orig;
    // }

    if (rowIsStockPage) {
        return %orig;
    }

    NSInteger addedPageIndex = [libraryMenuManager numberOfAddedPages] - (numberOfRows - indexPath.row);
    NSDictionary *pageInfo = libraryMenuManager.addedPages[addedPageIndex];

    id cell = [[objc_getClass("_TtCC16MusicApplication25LibraryMenuViewController4Cell") alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LibraryMenuViewController.Cell"];
    [cell setText:pageInfo[@"title"]];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];

    if (pageInfo[@"imageName"]) {
        // UIImageSymbolConfiguration *imageConfig = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightUnspecified scale:UIImageSymbolScaleDefault];
        UIImageSymbolConfiguration *imageConfig = [UIImageSymbolConfiguration configurationWithTextStyle:UIFontTextStyleTitle2 scale:UIImageSymbolScaleMedium];
        UIImage *image = [UIImage systemImageNamed:pageInfo[@"imageName"] withConfiguration:imageConfig];

        MSHookIvar<UIImage *>(cell, "symbol") = image;
        MSHookIvar<UIImageView *>(cell, "symbolView").image = image;
    }

    return cell;
}

// helper method to get the impl ivar
%new 
- (id)impl {
    id impl = MSHookIvar<id>(self, "_impl");
    return impl;
}

%end


%hook ContainerDetailSongsViewController

// - (void)viewDidAppear:(BOOL)arg1 {
//     %orig;

//     UIViewController *controller = self;
//     UIViewController *parent;
//     BOOL foundNavController = NO;

//     for (NSInteger i = 0; i < 10; i++) {
//         parent = [controller parentViewController];

//         if ([parent isKindOfClass:[UINavigationController class]]) {
            
//             [MeloManager sharedInstance].lastSongsViewController = controller;
//             [MeloManager sharedInstance].lastSongsNavItem = [NSArray arrayWithArray:controller.navigationItem.rightBarButtonItems];
//             foundNavController = YES;
//             break;
//         }

//         controller = parent;
//     }

//     if (!foundNavController) {
//         [MeloManager sharedInstance].lastSongsViewController = self;
//     }
// }

%end


%hook UITabBarController

- (void)transitionFromViewController:(id)arg1 toViewController:(id)arg2 {
    [Logger logStringWithFormat:@"UITabBarController transitionFromViewController:%@ toViewController:%@", arg1, arg2];

    // if (!arg1) {
    //     %orig;
    //     return;
    // }

    // RecentlyViewedPageManager *recentlyViewedPageManager = [RecentlyViewedPageManager sharedInstance];

    // // save the view controller stack of the navigation controller that was just left
    // if ([arg1 isKindOfClass:objc_getClass("MusicApplication.NavigationController")]) {
    //     [recentlyViewedPageManager addNavControllerToMap:arg1];
    // }

    // // load the view controllers stack of the navitation controller that is about to be shown
    // if ([arg2 isKindOfClass:objc_getClass("MusicApplication.NavigationController")]) {

    //     NSArray *viewControllers = [recentlyViewedPageManager viewControllersForMappedNavController:arg2];

    //     // TODO: check if the navigation controllers saved stack includes a view controller that was pushed in another navigation controller?
    //     // just so you don't always reset the view controllers list - possible performance hit

    //     if (viewControllers) {
    //         [arg2 setViewControllers:viewControllers animated:NO];
    //     }
    // }

    %orig;
}


%end

%hook UINavigationController
%property(strong, nonatomic) NSString *identifier;

- (id)init {
    
    id orig = %orig;

    // generate a unique identifier for each navigation controller
    NSString *ident = [[NSProcessInfo processInfo] globallyUniqueString];
    [orig setIdentifier:ident];

    return orig;
}

%end


%hook MPCPlaybackEngine

// TODO: is this needed? check if there are any cases where this would be set to NO (playing a song had it set to yes? but idk)
- (BOOL)isAudioAnalyzerEnabled {
    return YES;
}

%end

%hook MPCAudioSpectrumAnalyzer

- (void)_analyzeSamples:(AudioBufferList *)bufferList numberFrames:(NSInteger)numFrames {

    // [Logger logStringWithFormat:@"number of frames: %ld, bufferList: %p, number of buffers: %ld", numFrames, bufferList, bufferList->mNumberBuffers];
    %orig;

    // TODO: don't always do your analyzing of the data, do a check with prefs

    // if ([[MeloManager sharedInstance] prefsBoolForKey:@"visualizerPageEnabled"]) {
    //     [[VisualizerManager sharedInstance] processAudioBuffers:bufferList numberFrames:numFrames];
    // }

    VisualizerManager *visualizerManager = [VisualizerManager sharedInstance];

    if ([visualizerManager isAnyVisualizerActive]) {
        [visualizerManager processAudioBuffers:bufferList numberFrames:numFrames];
    }
}

- (void)configurePlayerItem:(id)arg1 {
    %orig;

    // [Logger logStringWithFormat:@"configure player item: %@", arg1];
}

- (void)_prepareTap:(id)arg1 maxFrames:(NSInteger)arg2 processingFormat:(const AudioStreamBasicDescription *)arg3 {
    %orig;

    // [Logger logString:@"LOGGING TAP OMG OMG OMG OMG OMG OMG"];
    // [Logger logStringWithFormat:@"_prepareTap: %@, maxFrames: %ld", arg1, arg2];

    // [Logger logStringWithFormat:@"PREPARE TAP!! mBytesPerFrame: %ld", arg3->mBytesPerFrame];
    // [Logger logStringWithFormat:@"sizeof(int): %ld, sizeof(float): %ld, sizeof(short): %ld, sizeof(NSInteger): %ld, sizeof(CGFloat): %ld", sizeof(int), sizeof(float), sizeof(short), sizeof(NSInteger), sizeof(CGFloat)];
    // [Logger logStringWithFormat:@"isFloatFlag: %i, isBigEndian: %i, signedInt: %i", arg3->mFormatFlags & kAudioFormatFlagIsFloat, arg3->mFormatFlags & kAudioFormatFlagIsBigEndian,  arg3->mFormatFlags & kAudioFormatFlagIsSignedInteger];
    // [Logger logStringWithFormat:@"SAMPLE RATE: %lf, FRAMES PER PACKET: %ld", arg3->mSampleRate, arg3->mFramesPerPacket];
    // [Logger logStringWithFormat:@"packet duration (s): %lf", (1 / arg3->mSampleRate) * arg3->mFramesPerPacket];
    // [Logger logStringWithFormat:@"mBytesPerFrame: %ld", arg3->mBytesPerFrame];
    // [Logger logStringWithFormat:@"mBytesPerPacket: %ld", arg3->mBytesPerPacket];
    // [Logger logStringWithFormat:@"mChannelsPerFrame: %ld", arg3->mChannelsPerFrame];

    VisualizerManager *visualizerManager = [VisualizerManager sharedInstance];
    visualizerManager.sampleRate = arg3->mSampleRate;
}

%end

%hook MusicNowPlayingControlsViewController
// %property(strong, nonatomic) VisualizerView *vizView;
// %property(assign, nonatomic) BOOL shouldShowVizView;

- (id)init {

    id orig = %orig;

    return orig;
}

- (void)viewDidLoad {
    %orig;
    

    // BOOL shouldShowVizView = [[MeloManager sharedInstance] prefsBoolForKey:@"visualizerShowInMusicPlayerEnabled"];
    // [self setShouldShowVizView:shouldShowVizView];

    // VisualizerView *vizView = [[VisualizerView alloc] initWithFrame:CGRectZero];
    
    // vizView.userInteractionEnabled = NO;
    // vizView.hidden = !shouldShowVizView;

    // [self setVizView:vizView];
    // [[self view] addSubview:vizView];

        // VisualizerView *vizView = [self vizView];
    // UIView *titleContainer = MSHookIvar<UIView *>(self, "topContainerView");
    // UIView *artworkView = MSHookIvar<UIView *>(self, "artworkView");
    // UIView *timeControl = MSHookIvar<UIView *>(self, "timeControl");

    // UILayoutGuide *vizLayoutGuide = [UILayoutGuide new];

    // /*NSLayoutConstraint *topConstraint =*/ [vizView.topAnchor constraintEqualToAnchor:artworkView.bottomAnchor].active = YES;
//    /* NSLayoutConstraint *bottomConstraint =*/ [titleContainer.layoutMarginsGuide.topAnchor constraintEqualToAnchor:vizView.bottomAnchor].active = YES;
    
    // [vizView addConstraint:topConstraint];
    // [vizView addConstraint:bottomConstraint];
    // [vizView addLayoutGuide:vizLayoutGuide];

    // [NSLayoutConstraint 
    //     constraintWithItem:vizView 
    //     attribute:NSLayoutAttributeWidth
    //     relatedBy:NSLayoutRelationEqual
    //     toItem:timeControl
    //     attribute:NSLayoutAttributeWidth
    //     multiplier:1
    //     constant:0
    // ].active = YES;

    // [NSLayoutConstraint 
    //     constraintWithItem:vizView 
    //     attribute:NSLayoutAttributeHeight
    //     relatedBy:NSLayoutRelationEqual
    //     toItem:timeControl
    //     attribute:NSLayoutAttributeHeight
    //     multiplier:1
    //     constant:0
    // ].active = YES;
    // [vizView addConstraint:topConstraint];
    // [vizView addConstraint:bottomConstraint];
    // [vizView addConstraint:vizWidthConstraint];
    // vizWidthConstraint.active = YES;
    

    // add an observer for whenever a library preferences change was detected
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLibraryPrefsUpdate:) name:@"MELO_NOTIFICATION_PREFS_UPDATED_LIBRARY" object:nil];
}

- (void)viewWillAppear:(BOOL)arg1 {
    %orig;

    // if (![self shouldShowVizView]) {
    //     return;
    // }

    // [self layoutVizView];
}

- (void)viewDidAppear:(BOOL)arg1 {
    %orig;

    // if (![self shouldShowVizView]) {
    //     return;
    // }

    // VisualizerView *vizView = [self vizView];

    // NSDictionary *context = @{
    //     @"vizView": vizView,
    // };

    // [UIView beginAnimations:@"MELO_ANIMATION_ANIMATE_MUSIC_PLAYER_VISUALIZER" context:(__bridge_retained void *)context];
    // [UIView setAnimationDuration:0.2];
    // [UIView setAnimationDelegate:[AnimationManager new]];
    // [UIView setAnimationDidStopSelector:@selector(handleAnimationDidStop:finished:context:)];
    // // [UIView setAnimationBeginsFromCurrentState:YES];

    // vizView.alpha = 1;

    // [UIView commitAnimations];

    // VisualizerManager *visualizerManager = [VisualizerManager sharedInstance];
    // visualizerManager.numVisualizersActive++;
}

- (void)viewDidDisappear:(BOOL)arg1 {
    %orig;

    // [[self vizView] invalidateUpdateTimer];
    // [self vizView].alpha = 0;

    // VisualizerManager *visualizerManager = [VisualizerManager sharedInstance];
    // visualizerManager.numVisualizersActive--;
}

- (void)viewDidLayoutSubviews {
    %orig;

    // if (![self shouldShowVizView]) {
    //     return;
    // }
    
    // [self layoutVizView];
}

// %new 
// - (void)layoutVizView {
//     // VisualizerView *vizView = [self vizView];
//     // UIView *titleContainer = MSHookIvar<UIView *>(self, "topContainerView");
//     // UIView *artworkView = MSHookIvar<UIView *>(self, "artworkView");
//     // UIView *timeControl = MSHookIvar<UIView *>(self, "timeControl");

//     // CGRect vizFrame = CGRectMake(
//     //     timeControl.frame.origin.x,
//     //     artworkView.frame.origin.y + artworkView.frame.size.height,
//     //     timeControl.frame.size.width,
//     //     titleContainer.frame.origin.y - (artworkView.frame.origin.y + artworkView.frame.size.height) + 10
//     // );

//     // vizView.frame = vizFrame;
// }

%new
- (void)handleLibraryPrefsUpdate:(NSNotification *)arg1 {

    // VisualizerView *vizView = [self vizView];
    // BOOL newShouldShowViz = [[MeloManager sharedInstance] prefsBoolForKey:@"visualizerShowInMusicPlayerEnabled"];

    // if (newShouldShowViz != [self shouldShowVizView]) {
    //     [self setShouldShowVizView:newShouldShowViz];

    //     if (newShouldShowViz) {
    //         [vizView startUpdateTimer];
    //     } else {
    //         [vizView invalidateUpdateTimer];
    //     }

    //     vizView.hidden = !newShouldShowViz;

    //     [[self view] setNeedsLayout];
    // }
}

%end


// LibraryGroup end
%end

// theming hooks constructor
extern "C" void InitLibrary() {

    MeloManager *meloManager = [MeloManager sharedInstance];

    if ([meloManager prefsBoolForKey:@"libraryHooksEnabled"]) {
        %init(LibraryGroup,
            LibraryMenuViewController = objc_getClass("MusicApplication.LibraryMenuViewController"),
            LibraryMenuDataSource = objc_getClass("_TtGC5UIKit29UITableViewDiffableDataSourceSSOV9MusicCore11LibraryMenu10Identifier_"),
            ContainerDetailSongsViewController = objc_getClass("MusicApplication.ContainerDetailSongsViewController")
        );
    }
}