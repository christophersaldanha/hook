#import <Foundation/Foundation.h>
#include "fishhook.h"
#include <dlfcn.h>
#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <unistd.h>
#include <sys/mman.h>

typedef int (*sscanf_ptr_t)(const char *, const char *, ...);
sscanf_ptr_t orig_sscanf = NULL;

// Patch: Main mod
const uint64_t patch1Addr = 0x101E3069C;
uint8_t patch1Bytes[8]    = {0x20, 0x00, 0x08, 0xD2, 0xC0, 0x03, 0x5F, 0xD6};
uint8_t original1[8]      = {0};

// Hooked sscanf
int my_sscanf(const char *str, const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    int result = vsscanf(str, fmt, args);
    va_end(args);
    return result;
}

// Patch memory (8 bytes)
void patchMemory(uint64_t address, uint8_t *bytes) {
    vm_address_t pageStart = address & ~(vm_page_size - 1);
    mach_port_t task = mach_task_self();

    kern_return_t kr = vm_protect(task, pageStart, vm_page_size, false, PROT_READ | PROT_WRITE | PROT_EXEC);
    if (kr == KERN_SUCCESS) {
        memcpy((void*)address, bytes, 8);
        vm_protect(task, pageStart, vm_page_size, false, PROT_READ | PROT_EXEC);
    }
}

// Setup both hook and memory patch on delay
void setupHooksAndPatches() {
    // Backup original memory
    memcpy(original1, (void*)patch1Addr, sizeof(original1));

    // After 2 minutes: hook sscanf globally
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(120 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        rebind_symbols((struct rebinding[1]) {
            {"sscanf", (void *)my_sscanf, (void **)&orig_sscanf}
        }, 1);
    });

    // After 3 minutes: patch memory
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(180 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        patchMemory(patch1Addr, patch1Bytes);
    });
}

__attribute__((constructor))
void init() {
    setupHooksAndPatches();
}
