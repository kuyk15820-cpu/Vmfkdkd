#import <CoreText/CoreText.h>
#import "SplashAnimation.h"
#import <Lottie/Lottie-Swift.h>
#import "si.h"

@implementation SplashAnimation

+ (instancetype)sharedInstance {
    static SplashAnimation *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)showWithCompletion:(void (^)(void))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.splashContainer) {
            if (completion) completion();
            return;
        }

        UIWindow *window = self.targetWindow;
        if (!window) {
            if (@available(iOS 13.0, *)) {
                for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                    if (scene.activationState == UISceneActivationStateForegroundActive) {
                        window = ((UIWindowScene *)scene).windows.firstObject;
                        break;
                    }
                }
            } else {
                window = [UIApplication sharedApplication].keyWindow;
            }
        }
        
        if (!window) {
            if (completion) completion();
            return;
        }

        self.splashContainer = [[UIView alloc] initWithFrame:window.bounds];
        self.splashContainer.backgroundColor = [UIColor blackColor];
        self.splashContainer.userInteractionEnabled = YES;
        self.splashContainer.alpha = 1.0;

        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:cv options:NSDataBase64DecodingIgnoreUnknownCharacters];
        
        if (decodedData) {
            CompatibleAnimationView *lottieView = [[CompatibleAnimationView alloc] initWithData:decodedData];
            if (lottieView) {
                lottieView.frame = CGRectMake(0, 0, 200, 200);
                lottieView.center = CGPointMake(window.bounds.size.width / 2, window.bounds.size.height / 2);
                lottieView.contentMode = UIViewContentModeScaleAspectFit;
                
                [self.splashContainer addSubview:lottieView];
                self.animationView = lottieView;
            }
        }

        [window addSubview:self.splashContainer];

        if (self.animationView) {
            [(CompatibleAnimationView *)self.animationView playWithCompletion:^(BOOL animationFinished) {
                [UIView animateWithDuration:0.3 animations:^{
                    self.splashContainer.alpha = 0.0;
                } completion:^(BOOL finished) {
                    [self hide];
                    if (completion) completion();
                }];
            }];
        } else {
            [self hide];
            if (completion) completion();
        }
    });
}

- (void)hide {
    if (self.animationView) {
        [(CompatibleAnimationView *)self.animationView stop];
    }
    if (self.splashContainer) {
        [self.splashContainer removeFromSuperview];
    }
    self.splashContainer = nil;
    self.animationView = nil;
}

@end
