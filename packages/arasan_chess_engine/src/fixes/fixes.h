#ifndef _FIXES_H_
#define _FIXES_H_

#if defined(__arm__) || defined(__aarch64__)
#include <arm_neon.h>
#endif

#include "stream_fix.h"

#if !defined(__aarch64__) && (defined(__arm__) || defined(__thumb__) || defined(_M_ARM))
inline int32x4_t vmull_high_s16(int16x8_t x, int16x8_t y) {
    return vmull_s16(vget_high_s16(x), vget_high_s16(y));
}
inline int32x4_t vpaddq_s32(int32x4_t low, int32x4_t high) {
    int32x2_t r1 = vpadd_s32(vget_low_s32(low), vget_high_s32(low));
    int32x2_t r2 = vpadd_s32(vget_low_s32(high), vget_high_s32(high));
    return vcombine_s32(r1, r2);
}
#endif

#endif
