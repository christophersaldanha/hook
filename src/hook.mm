#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <dlfcn.h>
#import <objc/runtime.h>

// === Replace with actual addresses ===
#define PATCH_LEN 8

void *sscanf_addr    = (void *)0x101E3069C; // 🛑 Replace with actual sscanf address
void *observer_addr  = (void *)0x1012E0B4C; // 🛑 Replace with actual observer address

uint8_t patch_sscanf[PATCH_LEN]   = { 0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6 }; // MOV X0, #0; RET
uint8_t patch_observer[PATCH_LEN] = { 0x20, 0x00, 0x08, 0xD2, 0xC0, 0x03, 0x5F, 0xD6 }; // MOV W0, #1; RET

// === Patch logic ===
void patch_memory(void *addr, const uint8_t *bytes) {
    vm_address_t page = (vm_address_t)addr & ~(vm_page_size - 1);
    vm_prot_t prot, max;
    kern_return_t kr;

    kr = vm_remap(mach_task_self(), &page, vm_page_size, 0, VM_FLAGS_OVERWRITE,
                  mach_task_self(), page, FALSE, &prot, &max, VM_INHERIT_COPY);
    if (kr == KERN_SUCCESS) {
        mprotect((void *)page, vm_page_size, PROT_READ | PROT_WRITE | PROT_EXEC);
        memcpy(addr, bytes, PATCH_LEN);
        mprotect((void *)page, vm_page_size, PROT_READ | PROT_EXEC);
        NSLog(@"[+] Patched at %p", addr);
    } else {
        NSLog(@"[-] vm_remap failed for %p", addr);
    }
}

void apply_all_patches() {
    patch_memory(sscanf_addr, patch_sscanf);
    patch_memory(observer_addr, patch_observer);
    NSLog(@"[+] All patches applied");
}

// === Floating Button ===
void create_patch_button() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        NSSet *connectedScenes = [UIApplication sharedApplication].connectedScenes;

        for (UIScene *scene in connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                NSArray *windows = windowScene.windows;
                if (windows.count > 0) {
                    window = windows.firstObject;
                    break;
                }
            }
        }

        if (!window) {
            NSLog(@"[-] No UIWindow found");
            return;
        }

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(20, 100, 180, 50);
        [btn setTitle:@"Apply COD Patches" forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor colorWithRed:0 green:0.5 blue:0 alpha:0.75];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.layer.cornerRadius = 12;

        [btn addTarget:nil action:@selector(triggerPatches) forControlEvents:UIControlEventTouchUpInside];

        [window addSubview:btn];
        NSLog(@"[+] Patch button added");
    });
}

// Button tap = call patcher
void triggerPatches() {
    apply_all_patches();
}

// === Entry Point ===
__attribute__((constructor))
void init_patch_ui() {
    NSLog(@"[+] COD Patcher dylib loaded");
    create_patch_button();
}
