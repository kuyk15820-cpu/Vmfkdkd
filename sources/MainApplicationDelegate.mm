#import "MainApplicationDelegate.h"
#import "RootViewController.h"
#import "SplashAnimation.h"

@implementation MainApplicationDelegate {
    RootViewController *_rootViewController;
    UIViewController *_mainContainer; 
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    self.window.windowLevel = UIWindowLevelNormal;
    
    if (@available(iOS 13.0, *)) {
        self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }
    
    _mainContainer = [[UIViewController alloc] init];
    _mainContainer.view.backgroundColor = [UIColor blackColor];
    [self.window setRootViewController:_mainContainer];
    
    UIViewController *launchVC = [[UIViewController alloc] init];
    launchVC.view.backgroundColor = [UIColor blackColor];
    [_mainContainer addChildViewController:launchVC];
    [_mainContainer.view addSubview:launchVC.view];
    [launchVC didMoveToParentViewController:_mainContainer];
    
    [self.window makeKeyAndVisible];

    [SplashAnimation sharedInstance].targetWindow = self.window;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[SplashAnimation sharedInstance] showWithRepeatCount:1 completion:^{
            
            self->_rootViewController = [[RootViewController alloc] init];
            
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self->_rootViewController];
            navController.navigationBar.prefersLargeTitles = NO;
            navController.navigationBar.translucent = YES;
            
            [UIView transitionWithView:self->_mainContainer.view
                              duration:0.5
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                
                for (UIViewController *child in self->_mainContainer.childViewControllers) {
                    [child willMoveToParentViewController:nil];
                    [child.view removeFromSuperview];
                    [child removeFromParentViewController];
                }
                
                [self->_mainContainer addChildViewController:navController];
                navController.view.frame = self->_mainContainer.view.bounds;
                [self->_mainContainer.view addSubview:navController.view];
                [navController didMoveToParentViewController:self->_mainContainer];
                
            } completion:nil];
            
        }];
    });

    return YES;
}

@end
