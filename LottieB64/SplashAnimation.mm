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
                self.animationView = [[CompatibleAnimationView alloc] initWithData:data];
            }
        }

        if (self.animationView) {
            self.animationView.frame = CGRectMake(0, 0, 200, 200);
            self.animationView.center = CGPointMake(window.bounds.size.width / 2, window.bounds.size.height / 2);
            self.animationView.contentMode = UIViewContentModeScaleAspectFit;
            
            // 🟢 ใช้คุณสมบัติ Native ตามคู่มือ: พับแอปแล้วแอนิเมชันจะรอ และมาเล่นต่อเองเมื่อกลับเข้าแอป
            self.animationView.backgroundMode = CompatibleBackgroundBehaviorPauseAndRestore;

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

            // 🟢 กำหนดรอบการเล่นให้ตัวแปรต้นทาง (เช่น ส่งมา 1 รอบ ล็อตตี้จะนับ 1 รอบ)
            self.animationView.loopAnimationCount = (CGFloat)count;

            // 🟢 สั่ง Play เพียงครั้งเดียวโดยตรง ไม่ใช้บล็อก Recursive วนลูปเองให้ชนกับระบบเบื้องหลัง
            [self.animationView playWithCompletion:^(BOOL finished) {
                [self hide];
                if (completion) completion();
            }];
        });
    });
}

@end
