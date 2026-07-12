#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import <Lottie/Lottie-Swift.h>

@interface SplashAnimation : NSObject

@property (nonatomic, strong) UIView *hudContainer;
@property (nonatomic, strong) CompatibleAnimationView *animationView; 
@property (nonatomic, strong) UIWindow *targetWindow; 

+ (instancetype)sharedInstance;
- (void)show;
- (void)hide;
- (void)showWithRepeatCount:(NSInteger)count completion:(void (^)(void))completion;

@end
