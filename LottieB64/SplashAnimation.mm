#import "SplashAnimation.h"
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

- (void)show {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.hudContainer) {
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
            return;
        }

        self.hudContainer = [[UIView alloc] initWithFrame:window.bounds];
        self.hudContainer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        self.hudContainer.userInteractionEnabled = YES;
        self.hudContainer.alpha = 0.0;

        NSData *data = [[NSData alloc] initWithBase64EncodedString:cv options:0];
        if (data) {
            NSError *error = nil;
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (jsonDict) {
                self.animationView = [[CompatibleAnimationView alloc] initWithDictionary:jsonDict];

            }
        }

        if (self.animationView) {
            self.animationView.frame = CGRectMake(0, 0, 200, 200);
            self.animationView.center = CGPointMake(window.bounds.size.width / 2, window.bounds.size.height / 2);
            self.animationView.contentMode = UIViewContentModeScaleAspectFit;

self.animationView.loopMode = LottieLoopModePlayOnce;

            [self.hudContainer addSubview:self.animationView];
        }

        [window addSubview:self.hudContainer];
        [UIView animateWithDuration:0.3 animations:^{
            self.hudContainer.alpha = 1.0;
        }];
    });
}

- (void)hide {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.hudContainer) return;
        [UIView animateWithDuration:0.25 animations:^{
            self.hudContainer.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (self.animationView) {
                [self.animationView stop];
            }
            [self.hudContainer removeFromSuperview];
            self.hudContainer = nil;
            self.animationView = nil;
        }];
    });
}

- (void)showWithRepeatCount:(NSInteger)count completion:(void (^)(void))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self show];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            if (!self.animationView) {
                [self hide];
                if (completion) completion();
                return;
            }

            __block NSInteger remainingRounds = count;
            __block void (^playRecursive)(void);
            __weak __block void (^weakPlayRecursive)(void);
            
            playRecursive = ^{
                [self.animationView playWithCompletion:^(BOOL finished) {
                    remainingRounds--;
                    if (remainingRounds > 0) {
                        if (weakPlayRecursive) weakPlayRecursive();
                    } else {
                        [self hide];
                        if (completion) completion();
                        playRecursive = nil; 
                    }
                }];
            };

            weakPlayRecursive = playRecursive;
            playRecursive();
        });
    });
}

@end
