#import "SplashAnimation.h"
#import "si.h"

// 🟢 สร้าง Custom View สำหรับ hudContainer เพื่อดักจับจังหวะการวาดหน้าจอใหม่ตอนกลับเข้าแอป
@interface SplashHUDContainer : UIView
@property (nonatomic, weak) CompatibleAnimationView *attachedAnimationView;
@end

@implementation SplashHUDContainer
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    // ทันทีที่แอปกลับมาแสดงผล (Foreground) และมีการวาดวิวใหม่ ถ้าแอนิเมชันหยุดอยู่ ให้สั่งเล่นต่อจากจุดเดิม
    if (self.attachedAnimationView && self.attachedAnimationView.isAnimationPlaying == NO) {
        [self.attachedAnimationView play];
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

        // 🟢 เปลี่ยนมาใช้คลาส container ดักจับแทนตัววิวเดิม
        SplashHUDContainer *container = [[SplashHUDContainer alloc] initWithFrame:window.bounds];
        container.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        container.userInteractionEnabled = YES;
        container.alpha = 0.0;
        self.hudContainer = container;

        NSData *data = [[NSData alloc] initWithBase64EncodedString:cv options:0];
        if (data) {
            NSError *error = nil;
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (jsonDict) {
                // เรียกใช้คลาสเดิมตามปกติ ไม่ฝืน subclass ให้ติดเออร์เรอร์คอมไพล์
                self.animationView = [[CompatibleAnimationView alloc] initWithData:data];
            }
        }

        if (self.animationView) {
            self.animationView.frame = CGRectMake(0, 0, 200, 200);
            self.animationView.center = CGPointMake(window.bounds.size.width / 2, window.bounds.size.height / 2);
            self.animationView.contentMode = UIViewContentModeScaleAspectFit;
            
            // ใช้ Pause เพื่อหยุดการสร้างลูปจำลองฝั่ง Swift ตอนพับแอป
            self.animationView.backgroundMode = CompatibleBackgroundBehaviorPause;
            self.animationView.loopAnimationCount = 1;

            [self.hudContainer addSubview:self.animationView];
            
            // ผูกความสัมพันธ์ให้ออนเนอร์ container รู้จักตัวแอนิเมชันเพื่อคุมงานต่อ
            container.attachedAnimationView = self.animationView;
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
                    
                    // ป้องกันลักไก่ปิดหน้าจอขณะที่ตัวแอปยังไม่ได้กลับขึ้นมาเบื้องหน้าแบบเต็มร้อย
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
