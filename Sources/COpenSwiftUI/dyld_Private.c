//
//  dyld_Private.c
//  COpenSwiftUI

#include "dyld_Private.h"

#if !OPENSWIFTUI_TARGET_OS_DARWIN
bool dyld_program_sdk_at_least(dyld_build_version_t version) {
    return true;
}
#endif
