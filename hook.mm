#import <UIKit/UIKit.h>
#import "fishhook.h"

// Declare a pointer to the original sscanf function
int (*original_sscanf)(const char *, const char *, ...);

// Your custom hook function
int my_sscanf(const char *input, const char *format, ...) {
    NSLog(@"[HOOK] sscanf intercepted!");
    
    // You can modify `input` or `format` here if needed

    va_list args;
    va_start(args, format);
    int result = vsscanf(input, format, args);
    va_end(args);

    return result;
}

__attribute__((constructor))
static void initialize() {
    NSLog(@"[+] Hook loaded, applying fishhook...");

    struct rebinding hook;
    hook.name = "sscanf";
    hook.replacement = (void *)my_sscanf;
    hook.replaced = (void **)&original_sscanf;

    rebind_symbols(&hook, 1);

    // Optional: Test if we're in the app context
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = nil;
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }

        if (keyWindow) {
            NSLog(@"[+] Key window acquired, hook appears successful.");
        } else {
            NSLog(@"[-] Could not find key window.");
        }
    });
}

