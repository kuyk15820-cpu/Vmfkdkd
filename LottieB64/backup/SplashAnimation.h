#import <UIKit/UIKit.h>

@interface SplashAnimation : NSObject

@property (nonatomic, strong) UIView *splashContainer;
@property (nonatomic, strong) id animationView; 
@property (nonatomic, weak) UIWindow *targetWindow;

+ (instancetype)sharedInstance;

- (void)showWithCompletion:(void (^)(void))completion;
- (void)hide;

@end
