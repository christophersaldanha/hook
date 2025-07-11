#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <sys/mman.h>
#import <stdarg.h>
#import <substrate.h>

#define IN_MATCH_ADDR 0x102F805C4
#define IN_LOBBY_ADDR 0x1012A09CC
#define PATCH_ADDR    0x101E3069C
#define PATCH_SIZE    8

#define SSCANF_ADDR   0x1012E0B4C

static bool isInMatch() {
    return *(bool *)IN_MATCH_ADDR;
}

static bool isInLobby() {
    return *(bool *)IN_LOBBY_ADDR;
}

static bool patched = false;
static uint8_t orig_bytes[PATCH_SIZE];
static void *sscanf_orig = NULL;

int sscanf_hook(const char *str, const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    int result = vsscanf(str, fmt, args);
    va_end(args);
    return result;
}

void patchMemory(uint64_t addr, const uint8_t *bytes, size_t size) {
    uint64_t page = addr & ~(getpagesize() - 1);
    mprotect((void *)page, getpagesize(), PROT_READ | PROT_WRITE | PROT_EXEC);
    memcpy((void *)addr, bytes, size);
    __builtin___clear_cache((char *)addr, (char *)(addr + size));
    mprotect((void *)page, getpagesize(), PROT_READ | PROT_EXEC);
}

void *monitor_thread(void *) {
    const uint8_t patch_bytes[PATCH_SIZE] = {0x20, 0x00, 0x08, 0xD2, 0xC0, 0x03, 0x5F, 0xD6};

    while (true) {
        if (!patched && isInMatch()) {
            memcpy(orig_bytes, (void *)PATCH_ADDR, PATCH_SIZE);
            patchMemory(PATCH_ADDR, patch_bytes, PATCH_SIZE);
            MSHookFunction((void *)SSCANF_ADDR, (void *)sscanf_hook, &sscanf_orig);
            patched = true;
        } else if (patched && isInLobby()) {
            patchMemory(PATCH_ADDR, orig_bytes, PATCH_SIZE);
            MSHookFunction((void *)SSCANF_ADDR, sscanf_orig, NULL); // Unhook
            patched = false;
        }
        usleep(100000); // 100ms
    }
    return NULL;
}

__attribute__((constructor))
static void init() {
    pthread_t t;
    pthread_create(&t, NULL, monitor_thread, NULL);
}
