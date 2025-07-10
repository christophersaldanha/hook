#import <UIKit/UIKit.h>
#import "fishhook.h"

// Save original sscanf
int (*original_sscanf)(const char *str, const char *format, ...);

// Hooked version
int my_sscanf(const char *str, const char *format, ...) {
    NSLog(@"[HOOKED] sscanf was blocked");
    return 0; // block completely
}

// Run-time hook function
void activateHook() {
    NSLog(@"[HOOK] Activating sscanf hook...");

    struct rebinding hook;
    hook.name = "sscanf";
    hook.replacement = my_sscanf;
    hook.replaced = (void *)&original_sscanf;
    rebind_symbols(&hook, 1);
}

// Create a floating UIButton
void showFloatingButton() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;

        UIButton *hookButton = [UIButton buttonWithType:UIButtonTypeSystem];
        hookButton.frame = CGRectMake(20, 100, 120, 40);
        [hookButton setTitle:@"Hook sscanf" forState:UIControlStateNormal];
        hookButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.6 blue:1 alpha:0.8];
        [hookButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        hookButton.layer.cornerRadius = 10;
        hookButton.layer.borderWidth = 1;
        hookButton.layer.borderColor = [UIColor whiteColor].CGColor;
        hookButton.clipsToBounds = YES;

        [hookButton addTarget:[NSBlockOperation blockOperationWithBlock:^{
            activateHook();
        }] action:@selector(main) forControlEvents:UIControlEventTouchUpInside];

        [keyWindow addSubview:hookButton];
    });
}

// Dylib entry
__attribute__((constructor))
static void initializer() {
    NSLog(@"[INIT] Dylib loaded. Showing hook button...");
    showFloatingButton();
}
