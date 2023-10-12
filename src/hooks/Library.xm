#import <UIKit/UIKit.h>
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

    [orig setShouldInjectCustomData:NO];

    return orig;
}

// helper method to get the dataSource ivar
%new
- (id)dataSource {
    return MSHookIvar<id>(self, "dataSource");
}

- (void)viewWillAppear:(BOOL)arg1 {
    %orig;

    // id dataSource = MSHookIvar<id>(self, "dataSource");
    // id diffDataSource = MSHookIvar<id>(dataSource, "_impl");

    // [diffDataSource appendItemsWithIdentifiers:@[@"test"]];

    // [[self tableView] reloadData];
}

// handle selection of one of the rows in the menu
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    LibraryMenuDataSource *dataSource = [self dataSource];
    MeloManager *meloManager = [MeloManager sharedInstance];

    if (![self shouldInjectCustomData]) {
        %orig;
        return;
    }
    
    if (indexPath.row == [dataSource tableView:tableView numberOfRowsInSection:indexPath.section] - 1) {

        UIViewController *lastSongsViewController = meloManager.lastSongsViewController;
        
        [[self navigationController] pushViewController:lastSongsViewController animated:YES];
        [lastSongsViewController.navigationItem setRightBarButtonItems:meloManager.lastSongsNavItem animated:YES];

    } else {
        %orig;
    }
}


%end

%hook LibraryMenuDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return %orig + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1) {
        // id cell = [[objc_getClass("_TtCC16MusicApplication25LibraryMenuViewController4Cell") alloc] initWithReuseIdentifier:@"LibraryMenuViewController.Cell"];
        id cell = [[objc_getClass("_TtCC16MusicApplication25LibraryMenuViewController4Cell") alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LibraryMenuViewController.Cell"];
        [cell setText:@"Show Last Viewed Album"];

        // UIImageSymbolConfiguration *imageConfig = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightUnspecified scale:UIImageSymbolScaleDefault];
        UIImageSymbolConfiguration *imageConfig = [UIImageSymbolConfiguration configurationWithTextStyle:UIFontTextStyleTitle2 scale:UIImageSymbolScaleMedium];
        UIImage *image = [UIImage systemImageNamed:@"clock.arrow.circlepath" withConfiguration:imageConfig];

        MSHookIvar<UIImage *>(cell, "symbol") = image;
        MSHookIvar<UIImageView *>(cell, "symbolView").image = image;
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];

        return cell;
    } else {
        return %orig;
    }
}

%new 
- (id)impl {
    return MSHookIvar<id>(self, "_impl");
}

%end


%hook ContainerDetailSongsViewController

- (void)viewDidAppear:(BOOL)arg1 {
    %orig;

    UIViewController *controller = self;
    UIViewController *parent;
    BOOL foundNavController = NO;

    for (NSInteger i = 0; i < 10; i++) {
        parent = [controller parentViewController];

        if ([parent isKindOfClass:[UINavigationController class]]) {
            
            // NSData *tempArchiveViewController = [NSKeyedArchiver archivedDataWithRootObject:controller];
            // UIViewController *newController = [NSKeyedUnarchiver unarchiveObjectWithData:tempArchiveViewController];

            [MeloManager sharedInstance].lastSongsViewController = controller;
            [MeloManager sharedInstance].lastSongsNavItem = [NSArray arrayWithArray:controller.navigationItem.rightBarButtonItems];
            foundNavController = YES;
            break;
        }

        controller = parent;
    }

    if (!foundNavController) {
        [MeloManager sharedInstance].lastSongsViewController = self;
    }
}

%end


%hook UITabBarController

- (void)transitionFromViewController:(id)arg1 toViewController:(id)arg2 {
    [Logger logStringWithFormat:@"UITabBarController transitionFromViewController:%@ toViewController:%@", arg1, arg2];

    if (!arg1) {
        %orig;
        return;
    }

    MeloManager *meloManager = [MeloManager sharedInstance];
    RecentlyViewedPageManager *recentlyViewedPageManager = meloManager.recentlyViewedPageManager;

    // save the view controller stack of the navigation controller that was just left
    if ([arg1 isKindOfClass:objc_getClass("MusicApplication.NavigationController")]) {
        [recentlyViewedPageManager addNavControllerToMap:arg1];
    }

    // load the view controllers stack of the navitation controller that is about to be shown
    if ([arg2 isKindOfClass:objc_getClass("MusicApplication.NavigationController")]) {

        NSArray *viewControllers = [recentlyViewedPageManager viewControllersForMappedNavController:arg2];

        // TODO: check if the navigation controllers saved stack includes a view controller that was pushed in another navigation controller?
        // just so you don't always reset the view controllers list - possible performance hit

        if (viewControllers) {
            [arg2 setViewControllers:viewControllers animated:NO];
        }
    }

    %orig;
}


%end

%hook UINavigationController
%property(strong, nonatomic) NSString *identifier;

- (id)init {
    
    id orig = %orig;

    NSString *ident = [[NSProcessInfo processInfo] globallyUniqueString];
    [orig setIdentifier:ident];

    return orig;
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