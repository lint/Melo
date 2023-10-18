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
    NSInteger addedPageIndex = numberOfRows - indexPath.row - 1;
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

    NSInteger addedPageIndex = numberOfRows - indexPath.row;
    addedPageIndex = 0;
    NSDictionary *pageInfo = libraryMenuManager.addedPages[addedPageIndex];

    // id cell = [[objc_getClass("_TtCC16MusicApplication25LibraryMenuViewController4Cell") alloc] initWithReuseIdentifier:@"LibraryMenuViewController.Cell"];
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

    if (!arg1) {
        %orig;
        return;
    }

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