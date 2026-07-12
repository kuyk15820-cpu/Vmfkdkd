#import "SplashAnimation.h"
#import "si.h"

// 🟢 สร้าง Subclass เล็กๆ ขึ้นมาเพื่อดักจังหวะตอนแอปสลับกลับมาหน้าจอโดยเฉพาะ
@interface LottieActiveView : CompatibleAnimationView
@end

@implementation LottieActiveView
// เมื่อแอปกลับมาเปิด (Foreground) ตัววิวจะถูกวาดใหม่บน Window อีกครั้ง
- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window && self.isAnimationPlaying == NO) {
        // สั่งให้เล่นต่อทันทีจากเฟรมเดิมอย่างนุ่มนวล
        [self play];
    }
}
@end


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
                // 🟢 เปลี่ยนมาใช้คลาสดักจับความเคลื่อนไหวที่เราสร้างไว้ด้านบน
                self.animationView = [[LottieActiveView alloc] initWithData:data];
            }
        }

        if (self.animationView) {
            self.animationView.frame = CGRectMake(0, 0, 200, 200);
            self.animationView.center = CGPointMake(window.bounds.size.width / 2, window.bounds.size.height / 2);
            self.animationView.contentMode = UIViewContentModeScaleAspectFit;
            
            // 🛑 เปลี่ยนเป็น Pause (หยุดไว้เมื่อพับแอป) เพื่อตัดขาดตัวสร้างอนิเมชันเบิ้ลของ Swift
            self.animationView.backgroundMode = CompatibleBackgroundBehaviorPause;
            self.animationView.loopAnimationCount = 1;

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

            __block BOOL isCompleted = NO;
            __block NSInteger remainingRounds = count;
            __block void (^playRecursive)(void);
            __weak __block void (^weakPlayRecursive)(void);
            
            playRecursive = ^{
                [self.animationView playWithCompletion:^(BOOL finished) {
                    
                    if (isCompleted) return;
                    
                    // ป้องกันการลักไก่ปิดหน้าจอขณะแอปกำลังพับอยู่เบื้องหลัง
                    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                        return;
                    }
                    
                    remainingRounds--;
                    if (remainingRounds > 0) {
                        if (weakPlayRecursive) weakPlayRecursive();
                    } else {
                        isCompleted = YES;
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
