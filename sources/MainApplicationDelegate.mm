#import "MainApplicationDelegate.h"
#import "RootViewController.h"
#import "SplashAnimation.h"

@implementation MainApplicationDelegate {
    RootViewController *_rootViewController;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    
    if (@available(iOS 13.0, *)) {
        self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }
    
    UIViewController *launchVC = [[UIViewController alloc] init];
    launchVC.view.backgroundColor = [UIColor blackColor];
    [self.window setRootViewController:launchVC];
    [self.window makeKeyAndVisible];

    [[SplashAnimation sharedInstance] showWithRepeatCount:1 completion:^{
        
        _rootViewController = [[RootViewController alloc] init];
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:_rootViewController];
        navController.navigationBar.prefersLargeTitles = NO;
        navController.navigationBar.translucent = YES;
        
        [UIView transitionWithView:self.window
                          duration:0.5
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
            self.window.rootViewController = navController;
        } completion:nil];
    }];

    return YES;
}

@end