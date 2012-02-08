@@
@@  Copyright (C) 2012 Roman Pauer
@@
@@  Permission is hereby granted, free of charge, to any person obtaining a copy of
@@  this software and associated documentation files (the "Software"), to deal in
@@  the Software without restriction, including without limitation the rights to
@@  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
@@  of the Software, and to permit persons to whom the Software is furnished to do
@@  so, subject to the following conditions:
@@
@@  The above copyright notice and this permission notice shall be included in all
@@  copies or substantial portions of the Software.
@@
@@  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
@@  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
@@  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
@@  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
@@  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
@@  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
@@  SOFTWARE.
@@

.arm

.include "neon_normalxx.Sinc"

.global neon_normal4x_8_8
.global neon_normal4x_16_16
.global neon_normal4x_8_16

.align 4
neon_normal4x_8_8:

@ r0     = const uint8_t *src
@ r1     = uint8_t *dst
@ r2     = unsigned int width (pixels)
@ r3     = unsigned int srcstride (bytes)
@ [sp]   = unsigned int dststride (bytes)
@ [sp+4] = unsigned int height
@ lr     = return address

        ldr	ip, [sp]                    @ ip = dststride
        push {r4-r9}
        ldr	r4, [sp, #(7*4)]            @ r4 = height
        sub r3, r3, r2                  @ r3 = srcstride - width
        add r7, r1, ip                  @ r7 = dst + dststride
        add r8, r1, ip, lsl #1          @ r8 = dst + 2 * dststride
        add r9, r7, ip, lsl #1          @ r9 = dst + 3 * dststride
        sub ip, ip, r2                  @ ip = dststride - width
        lsl ip, #2                      @ ip = 4 * dststride - 4 * width

@ r0 = src
@ r1 = dst
@ r2 = width
@ r3 = srcdiff (srcstride - width)
@ r4 = height
@ r5 = counter
@ r6 = tmpreg
@ r7 = dst + dststride
@ r8 = dst + 2 * dststride
@ r9 = dst + 3 * dststride
@ ip = dstdiff (4 * dststride - 4 * width)

    101:
        mov r5, r2                      @ counter = width

    @ first 1-15 pixels - align counter to 16 bytes
        andS r6, r5, #15                @ r6 = counter & 15
        beq 102f

        vld1.8 {q8}, [r0], r6           @ S1 = [src]; src += counter & 15
        bic r5, r5, #15                 @ counter &= ~15

        lsl r6, #2
        vmov q9, q8                     @ S2 = S1

        sub r6, r6, #(4*8)
        vmov q10, q8                    @ S3 = S1

        vmov q11, q8                    @ S4 = S1

        vst4.8 {d16,d18,d20,d22}, [r1]!     @ [dst] = S1[0]-S4[0]; dst += 4*8

        vst4.8 {d17,d19,d21,d23}, [r1], r6  @ [dst] = S1[1]-S4[1]; dst += r6

        vst4.8 {d16,d18,d20,d22}, [r7]!     @ [dst + dststride] = S1[0]-S4[0]; dst1 += 4*8

        vst4.8 {d17,d19,d21,d23}, [r7], r6  @ [dst + dststride] = S1[1]-S4[1]; dst1 += r6

        vst4.8 {d16,d18,d20,d22}, [r8]!     @ [dst + 2 * dststride] = S1[0]-S4[0]; dst2 += 4*8

        vst4.8 {d17,d19,d21,d23}, [r8], r6  @ [dst + 2 * dststride] = S1[1]-S4[1]; dst2 += r6

        vst4.8 {d16,d18,d20,d22}, [r9]!     @ [dst + 3 * dststride] = S1[0]-S4[0]; dst3 += 4*8

        vst4.8 {d17,d19,d21,d23}, [r9], r6  @ [dst + 3 * dststride] = S1[1]-S4[1]; dst3 += r6

    @ the rest of the line
    102:
        vld1.8 {q8}, [r0]!              @ S1 = [src]; src += 16
        subS r5, r5, #16                @ counter -= 16

        vmov q9, q8                     @ S2 = S1

        vmov q10, q8                    @ S3 = S1

        vmov q11, q8                    @ S4 = S1

        vst4.8 {d16,d18,d20,d22}, [r1]!     @ [dst] = S1[0]-S4[0]; dst += 4*8

        vst4.8 {d17,d19,d21,d23}, [r1]!     @ [dst] = S1[1]-S4[1]; dst += 4*8

        vst4.8 {d16,d18,d20,d22}, [r7]!     @ [dst + dststride] = S1[0]-S4[0]; dst1 += 4*8

        vst4.8 {d17,d19,d21,d23}, [r7]!     @ [dst + dststride] = S1[1]-S4[1]; dst1 += 4*8

        vst4.8 {d16,d18,d20,d22}, [r8]!     @ [dst + 2 * dststride] = S1[0]-S4[0]; dst2 += 4*8

        vst4.8 {d17,d19,d21,d23}, [r8]!     @ [dst + 2 * dststride] = S1[1]-S4[1]; dst2 += 4*8

        vst4.8 {d16,d18,d20,d22}, [r9]!     @ [dst + 3 * dststride] = S1[0]-S4[0]; dst3 += 4*8

        vst4.8 {d17,d19,d21,d23}, [r9]!     @ [dst + 3 * dststride] = S1[1]-S4[1]; dst3 += 4*8
        bne 102b


        subS r4, r4, #1                 @ height--
        add r1, r1, ip                  @ dst += dstdiff
        add r0, r0, r3                  @ src += srcdiff
        add r7, r7, ip                  @ dst2 += dstdiff
        add r8, r8, ip                  @ dst3 += dstdiff
        add r9, r9, ip                  @ dst4 += dstdiff
        bne 101b

        pop {r4-r9}
        bx lr

@ end procedure neon_normal4x_8_8


neon_normal4x_16_16:

@ r0     = const uint16_t *src
@ r1     = uint16_t *dst
@ r2     = unsigned int width (pixels)
@ r3     = unsigned int srcstride (bytes)
@ [sp]   = unsigned int dststride (bytes)
@ [sp+4] = unsigned int height
@ lr     = return address

        ldr	ip, [sp]                    @ ip = dststride
        push {r4-r9}
        ldr	r4, [sp, #(7*4)]            @ r4 = height
        sub r3, r3, r2, lsl #1          @ r3 = srcstride - 2 * width
        add r7, r1, ip                  @ r7 = dst + dststride
        add r8, r1, ip, lsl #1          @ r8 = dst + 2 * dststride
        add r9, r7, ip, lsl #1          @ r9 = dst + 3 * dststride
        sub ip, ip, r2, lsl #1          @ ip = dststride - 2 * width
        lsl ip, #2                      @ ip = 4 * dststride - 8 * width

@ r0 = src
@ r1 = dst
@ r2 = width
@ r3 = srcdiff (srcstride - 2 * width)
@ r4 = height
@ r5 = counter
@ r6 = tmpreg
@ r7 = dst + dststride
@ r8 = dst + 2 * dststride
@ r9 = dst + 3 * dststride
@ ip = dstdiff (4 * dststride - 8 * width)

    101:
        mov r5, r2                      @ counter = width

    @ first 1-7 pixels - align counter to 16 bytes
        andS r6, r5, #7                 @ r6 = counter & 7
        beq 102f

        vld1.16 {q8}, [r0]              @ S1 = [src]
        bic r5, r5, #7                  @ counter &= ~7

        add r0, r0, r6, lsl #1          @ src += 2 * r6
        vmov q9, q8                     @ S2 = S1

        lsl r6, #3
        vmov q10, q8                    @ S3 = S1

        sub r6, r6, #(4*2*4)
        vmov q11, q8                    @ S4 = S1

        vst4.16 {d16,d18,d20,d22}, [r1]!    @ [dst] = S1[0]-S4[0]; dst += 4*2*4

        vst4.16 {d17,d19,d21,d23}, [r1], r6 @ [dst] = S1[1]-S4[1]; dst += r6

        vst4.16 {d16,d18,d20,d22}, [r7]!    @ [dst + dststride] = S1[0]-S4[0]; dst1 += 4*2*4

        vst4.16 {d17,d19,d21,d23}, [r7], r6 @ [dst + dststride] = S1[1]-S4[1]; dst1 += r6

        vst4.16 {d16,d18,d20,d22}, [r8]!    @ [dst + 2 * dststride] = S1[0]-S4[0]; dst2 += 4*2*4

        vst4.16 {d17,d19,d21,d23}, [r8], r6 @ [dst + 2 * dststride] = S1[1]-S4[1]; dst2 += r6

        vst4.16 {d16,d18,d20,d22}, [r9]!    @ [dst + 3 * dststride] = S1[0]-S4[0]; dst3 += 4*2*4

        vst4.16 {d17,d19,d21,d23}, [r9], r6 @ [dst + 3 * dststride] = S1[1]-S4[1]; dst3 += r6

    @ the rest of the line
    102:
        vld1.16 {q8}, [r0]!             @ S1 = [src]; src += 2*8
        subS r5, r5, #8

        vmov q9, q8                     @ S2 = S1

        vmov q10, q8                    @ S3 = S1

        vmov q11, q8                    @ S4 = S1

        vst4.16 {d16,d18,d20,d22}, [r1]!    @ [dst] = S1[0]-S4[0]; dst += 4*2*4

        vst4.16 {d17,d19,d21,d23}, [r1]!    @ [dst] = S1[1]-S4[1]; dst += 4*2*4

        vst4.16 {d16,d18,d20,d22}, [r7]!    @ [dst + dststride] = S1[0]-S4[0]; dst1 += 4*2*4

        vst4.16 {d17,d19,d21,d23}, [r7]!    @ [dst + dststride] = S1[1]-S4[1]; dst1 += 4*2*4

        vst4.16 {d16,d18,d20,d22}, [r8]!    @ [dst + 2 * dststride] = S1[0]-S4[0]; dst2 += 4*2*4

        vst4.16 {d17,d19,d21,d23}, [r8]!    @ [dst + 2 * dststride] = S1[1]-S4[1]; dst2 += 4*2*4

        vst4.16 {d16,d18,d20,d22}, [r9]!    @ [dst + 3 * dststride] = S1[0]-S4[0]; dst3 += 4*2*4

        vst4.16 {d17,d19,d21,d23}, [r9]!    @ [dst + 3 * dststride] = S1[1]-S4[1]; dst3 += 4*2*4
        bne 102b


        subS r4, r4, #1                 @ height--
        add r1, r1, ip                  @ dst += dstdiff
        add r0, r0, r3                  @ src += srcdiff
        add r7, r7, ip                  @ dst2 += dstdiff
        add r8, r8, ip                  @ dst3 += dstdiff
        add r9, r9, ip                  @ dst4 += dstdiff
        bne 101b

        pop {r4-r9}
        bx lr

@ end procedure neon_normal4x_16_16


neon_normal4x_8_16:

@ r0     = const uint8_t *src
@ r1     = uint8_t *dst
@ r2     = const uint32_t *palette
@ r3     = unsigned int width (pixels)
@ [sp]   = unsigned int srcstride (bytes)
@ [sp+4] = unsigned int dststride (bytes)
@ [sp+8] = unsigned int height
@ lr     = return address

        ldr	ip, [sp]                @ ip = srcstride
        push {r4-r11,lr}
        ldr lr, [sp, #(4*10)]       @ lr = dststride
        ldr r5, [sp, #(4*11)]       @ r5 = height
        sub sp, sp, #(4*4)
        sub ip, ip, r3              @ ip = srcstride - width
        str r3, [sp, #12]
        sub r4, lr, r3, lsl #1      @ r4 = dststride - 2 * width
        str ip, [sp, #4]
        lsl r4, #2                  @ r4 = 4 * dststride - 8 * width
        str r5, [sp]
        str r4, [sp, #8]

@ r3      = counter
@ lr      = dststride
@ [sp]    = height
@ [sp+4]  = srcdiff (srcstride - width)
@ [sp+8]  = dstdiff (4 * dststride - 8 * width)
@ [sp+12] = width

    101:
        neon_normal4x_8_16_line r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, ip, lr

        ldr r4, [sp]                @ r4 = height
        ldr r5, [sp, #4]            @ r5 = srcdiff
        ldr r6, [sp, #8]            @ r6 = dstdiff
        ldr r3, [sp, #12]           @ counter = width
        subS r4, r4, #1             @ height--
        add r0, r0, r5              @ src += srcdiff
        str r4, [sp]                @ height = r4
        add r1, r1, r6              @ dst += dstdiff
        bne 101b

        add sp, sp, #(4*4)
        pop {r4-r11,lr}
        bx lr

@ end procedure neon_normal4x_8_16

