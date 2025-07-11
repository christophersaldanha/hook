#import <Foundation/Foundation.h>
#include "fishhook.h"
#include <dlfcn.h>
#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <unistd.h>
#include <sys/mman.h>

typedef int (*sscanf_ptr_t)(const char *, const char *, ...);
sscanf_ptr_t orig_sscanf = NULL;

bool (*IsInMatchGame)() = (bool(*)())0x102F805C4;
bool (*IsInLobby)()     = (bool(*)())0x1012A09CC;

// Patch 1: Main mod
const uint64_t patch1Addr = 0x101E3069C;
uint8_t patch1Bytes[8]    = {0x20, 0x00, 0x08, 0xD2, 0xC0, 0x03, 0x5F, 0xD6};
uint8_t original1[8]      = {0};

// Patch 2: sscanf override/bypass
const uint64_t patch2Addr = 0x1012E0B4C;
uint8_t patch2Bytes[8]    = {0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6};
uint8_t original2[8]      = {0};

void patchMemory(uint64_t address, uint8_t *bytes) {
    vm_address_t pageStart = address & ~(vm_page_size - 1);
    mach_port_t task = mach_task_self();

    kern_return_t kr = vm_protect(task, pageStart, vm_page_size, false, PROT_READ | PROT_WRITE | PROT_EXEC);
    if (kr == KERN_SUCCESS) {
        memcpy((void*)address, bytes, 8);
        vm_protect(task, pageStart, vm_page_size, false, PROT_READ | PROT_EXEC); // optional restore
    }
}

int my_sscanf(const char *str, const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    int result = vsscanf(str, fmt, args);
    va_end(args);
    return result;
}

void manageHooks() {
    bool hooked = false;

    while (true) {
        if (IsInMatchGame() && !hooked) {
            hooked = true;

            patchMemory(patch1Addr, patch1Bytes);
            patchMemory(patch2Addr, patch2Bytes);

            rebind_symbols((struct rebinding[1]) {
                {"sscanf", (void *)my_sscanf, (void **)&orig_sscanf}
            }, 1);

        } else if (IsInLobby() && hooked) {
            hooked = false;

            patchMemory(patch1Addr, original1);
            patchMemory(patch2Addr, original2);

            rebind_symbols((struct rebinding[1]) {
                {"sscanf", (void *)orig_sscanf, NULL}
            }, 1);
        }
        usleep(500000); // 0.5s polling
    }
}

__attribute__((constructor))
void init() {
    memcpy(original1, (void*)patch1Addr, sizeof(original1));
    memcpy(original2, (void*)patch2Addr, sizeof(original2));

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        manageHooks();
    });
}
