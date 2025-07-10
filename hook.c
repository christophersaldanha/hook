// hook.c
#include <stdio.h>
#include <stdarg.h>
#include "fishhook.h"

// Save the original function (optional, in case you ever want to call it)
int (*original_sscanf)(const char *str, const char *format, ...);

// Replacement function for sscanf
int my_sscanf(const char *str, const char *format, ...) {
    printf("[HOOKED] sscanf() was blocked\n");

    // Completely block sscanf by always returning 0 (no matches)
    return 0;
}

// Automatically runs when the dylib is loaded
__attribute__((constructor))
void init() {
    printf("[HOOK INIT] Injecting sscanf blocker...\n");

    // Hook sscanf using fishhook
    struct rebinding hook;
    hook.name = "sscanf";
    hook.replacement = my_sscanf;
    hook.replaced = (void *)&original_sscanf;

    rebind_symbols(&hook, 1);
}
