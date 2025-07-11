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
bool (*IsInLobby)() = (bool(*)())0x1012A09CC;

const uint64_t targetPatchAddr = 0x101E3069C;
uint8_t originalBytes[8] = {0}; // Placeholder
uint8_t patchBytes[8] = {0x20, 0x00, 0x08, 0xD2, 0xC0, 0x03, 0x5F, 0xD6};

void patchMemory(uint8_t *bytes) {
    vm_prot_t prot;
    vm_prot_t prot_max;
    mach_port_t task = mach_task_self();
    vm_address_t pageStart = targetPatchAddr & ~(vm_page_size - 1);
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t info_count = VM_REGION_BASIC_INFO_COUNT_64;
    memory_object_name_t object;
    kern_return_t kr;

    kr = vm_region_64(task, &pageStart, (vm_size_t[]){0}, VM_REGION_BASIC_INFO,
                      (vm_region_info_t)&info, &info_count, &object);

    if (kr == KERN_SUCCESS) {
        kr = vm_protect(task, pageStart, vm_page_size, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY | VM_PROT_EXECUTE);
        if (kr == KERN_SUCCESS) {
            memcpy((void*)targetPatchAddr, bytes, sizeof(patchBytes));
            vm_protect(task, pageStart, vm_page_size, false, info.protection);
        }
    }
}

int my_sscanf(const char *str, const char *fmt, ...) {
