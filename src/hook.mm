#import <dlfcn.h>
#import <mach/mach.h>
#import <pthread.h>
#import <sys/time.h>
#include <stdio.h>
#include <unistd.h>

void *(*original_sscanf)(const char *, const char *, ...);

void *hooked_sscanf(const char *input, const char *fmt, ...) {
    printf("[HOOKED sscanf] Called with input: %s, fmt: %s\n", input, fmt);
    va_list args;
    va_start(args, fmt);
    void *result = vsscanf(input, fmt, args);
    va_end(args);
    return result;
}

void patchMemory(uint64_t address, const uint8_t *bytes, size_t size) {
    vm_prot_t orig_protection;
    vm_prot_t unused;
    mach_port_t task = mach_task_self();

    if (vm_remap(task, (vm_address_t *)&address, size, 0, VM_FLAGS_FIXED | VM_FLAGS_OVERWRITE,
                 task, address, false, &orig_protection, &unused, VM_INHERIT_COPY) == KERN_SUCCESS) {
        vm_protect(task, address, size, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);
        memcpy((void *)address, bytes, size);
        vm_protect(task, address, size, false, orig_protection);
    }
}

void *manageHooks(void *arg) {
    sleep(120); // wait 2 minutes
    void *handle = dlopen(NULL, RTLD_NOW);
    if (handle) {
        void *sscanf_addr = dlsym(handle, "sscanf");
        if (sscanf_addr) {
            printf("[*] Hooking sscanf() at %p\n", sscanf_addr);
            original_sscanf = (typeof(original_sscanf))sscanf_addr;

            // Simple overwrite — not safe across all iOS versions; better to use function rebinding libs
            mprotect((void *)((uintptr_t)sscanf_addr & ~0xFFF), 0x1000, PROT_READ | PROT_WRITE | PROT_EXEC);
            *(void **)sscanf_addr = (void *)hooked_sscanf;
        }
        dlclose(handle);
    }

    sleep(60); // wait 1 more minute (total 3 mins)
    uint64_t patchAddr = 0x101E3069C;
    uint8_t patchBytes[] = {0x20, 0x00, 0x08, 0xD2, 0xC0, 0x03, 0x5F, 0xD6};
    patchMemory(patchAddr, patchBytes, sizeof(patchBytes));
    printf("[*] Patched memory at 0x%llx\n", patchAddr);

    return NULL;
}

__attribute__((constructor))
static void initializer() {
    pthread_t thread;
    pthread_create(&thread, NULL, manageHooks, NULL);
}
