// hook.mm
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <sys/mman.h>
#include <cstdio>
#include <unistd.h>
#include <pthread.h>
#include <string.h>
#include <stdint.h>

#define PATCH_ADDR 0x101E3069C
#define IS_IN_MATCH_ADDR 0x102F805C4
#define IS_IN_LOBBY_ADDR 0x1012A09CC
#define SSCANF_ADDR 0x1012E0B4C

bool patched = false;
void* (*orig_sscanf)(const char*, const char*, ...);

bool isInMatchGame() {
    return *(uint8_t*)IS_IN_MATCH_ADDR == 1;
}

bool isInLobby() {
    return *(uint8_t*)IS_IN_LOBBY_ADDR == 1;
}

void patchMemory(uint64_t address, const uint8_t* bytes, size_t size) {
    uint64_t pageStart = address & ~(getpagesize() - 1);
    mprotect((void*)pageStart, getpagesize(), PROT_READ | PROT_WRITE | PROT_EXEC);
    memcpy((void*)address, bytes, size);
    __builtin___clear_cache((char*)address, (char*)(address + size));
    mprotect((void*)pageStart, getpagesize(), PROT_READ | PROT_EXEC);
}

int sscanf_hook(const char* str, const char* fmt, ...) {
    va_list args;
    va_start(args, fmt);
    int result = vsscanf(str, fmt, args);
    va_end(args);
    printf("[HOOKED sscanf] Format: %s\n", fmt);
    return result;
}

void hook_sscanf() {
    uint64_t *target = (uint64_t*)SSCANF_ADDR;
    uint64_t *hookFunc = (uint64_t*)&sscanf_hook;
    patchMemory((uint64_t)target, (uint8_t*)&hookFunc, sizeof(hookFunc));
}

void* monitor_thread(void*) {
    const uint8_t patch_bytes[] = { 0x20, 0x00, 0x08, 0xD2, 0xC0, 0x03, 0x5F, 0xD6 };
    const uint8_t original_bytes[8];
    memcpy((void*)original_bytes, (void*)PATCH_ADDR, 8);

    while (true) {
        if (!patched && isInMatchGame()) {
            patchMemory(PATCH_ADDR, patch_bytes, sizeof(patch_bytes));
            hook_sscanf();
            patched = true;
            printf("[+] Patched for match\n");
        } else if (patched && isInLobby()) {
            patchMemory(PATCH_ADDR, original_bytes, sizeof(original_bytes));
            patched = false;
            printf("[-] Unpatched in lobby\n");
        }
        usleep(500000); // 0.5 sec
    }
    return NULL;
}

__attribute__((constructor))
void init() {
    pthread_t t;
    pthread_create(&t, NULL, monitor_thread, NULL);
}
