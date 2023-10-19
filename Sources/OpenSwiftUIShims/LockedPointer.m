//
//  LockedPointer.c
//  
//
//  Created by Kyle on 2023/10/19.
//

#import "LockedPointer.h"

// TODO: 汇编对照下，加单元测试
LockedPointer _LockedPointerCreate(size_t size, size_t alignment) {
    // alignment is expected to be a power of 2.
    // If alignment > 8,
    //  eg. 0x1_0000: 0x1111_1111_1111_0000 & 0x1_0111 = 0x1_0000 = alignment
    // elseif alignment == 8:
    //  eg. 0x0_1000: 0x1111_1111_1111_1000 & 0x0_1111 = 0x0_1000 = alignment
    // else (alignment < 8):
    //  eg. 0x0_0010: 0x1111_1111_1111_1110 & 0x0_1001 = 0x0_1000 = 0x8
    // The result would be LCM(alignment, sizeof(LockedPointerData))
    size_t offset = (size == 0)
    ? sizeof(LockedPointerData)
    : ((-alignment) & (alignment + sizeof(LockedPointerData) - 1));

    LockedPointer ptr = malloc(size + offset);
    if (ptr == NULL) { abort(); }
    ptr->lock = OS_UNFAIR_LOCK_INIT;
    ptr->offset = (uint32_t)offset;
    return ptr;
}

void *_LockedPointerGetAddress(LockedPointer ptr) {
    return (void *)((uintptr_t)ptr + (uintptr_t)(ptr->offset));
}

void _LockedPointerDelete(LockedPointer ptr) {
    free(ptr);
}

void _LockedPointerUnlock(LockedPointer ptr) {
    os_unfair_lock_unlock(&ptr->lock);
}

void _LockedPointerLock(LockedPointer ptr) {
    os_unfair_lock_lock(&ptr->lock);
}
