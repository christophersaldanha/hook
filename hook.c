#include <stdio.h>
#include <stdarg.h>
#include <unistd.h>     // for sleep()
#include <pthread.h>    // for threading
#include "fishhook.h"

// Save the original sscanf (optional)
int (*original_sscanf)(const char *str, const char *format, ...);

// Replacement sscanf
int my_sscanf(const char *str, const char *format, ...) {
    printf("[HOOKED] sscanf() was blocked\n");
    return 0;  // Always block
}

// Thread function to delay the hook
void *delayed_hook_thread(void *arg) {
    printf("[HOOK] Waiting 2 minutes before hooking sscanf...\n");
    sleep(120);  // Wait 120 seconds

    struct rebinding hook;
    hook.name = "sscanf";
    hook.replacement = my_sscanf;
    hook.replaced = (void *)&original_sscanf;

    rebind_symbols(&hook, 1);
    printf("[HOOK] sscanf has now been hooked!\n");

    return NULL;
}

// Runs automatically when the dylib is loaded
__attribute__((constructor))
void init() {
    printf("[HOOK INIT] Setting up delayed sscanf hook...\n");

    pthread_t thread;
    pthread_create(&thread, NULL, delayed_hook_thread, NULL);
    pthread_detach(thread);  // Optional: don’t wait for thread to finish
}
