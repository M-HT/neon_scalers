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

.global neon_normal1x_8_8
.global neon_normal1x_16_16
.global neon_normal1x_8_16

.align 4
neon_normal1x_8_8:

@ r0     = const uint8_t *src
@ r1     = uint8_t *dst
@ r2     = unsigned int width (pixels)
@ r3     = unsigned int srcstride (bytes)
@ [sp]   = unsigned int dststride (bytes)
@ [sp+4] = unsigned int height
@ lr     = return address

        ldr	ip, [sp]                @ ip = dststride
        push {r4-r6}
        ldr	r4, [sp, #(4*4)]        @ r4 = height
        sub r3, r3, r2              @ r3 = srcstride - width
        sub ip, ip, r2              @ ip = dststride - width

@ r0 = src
@ r1 = dst
@ r2 = width
@ r3 = srcdiff (srcstride - width)
@ r4 = height
@ r5 = counter
@ r6 = tmpreg
@ ip = dstdiff (dststride - width)

    101:
        mov r5, r2                  @ counter = width

    @ first 1-15 pixels - align counter to 16 bytes
        andS r6, r5, #15
        beq 102f

        vld1.8 {q8}, [r0], r6       @ S1 = [src]; src += counter & 15
        bic r5, r5, #15             @ counter &= ~15

        vst1.8 {q8}, [r1], r6       @ [dst] = S1; dst += counter & 15

    @ the rest of the line (16 pixels per iteration)
    102:
        vld1.8 {q8}, [r0]!          @ S1 = [src]; src += 16
        subS r5, r5, #16            @ counter -= 16

        vst1.8 {q8}, [r1]!          @ [dst] = S1; dst += 16
        bne 102b


        subS r4, r4, #1             @ height --
        add r0, r0, r3              @ src += srcdiff
        add r1, r1, ip              @ dst += dstdiff
        bne 101b

        pop {r4-r6}
        bx lr

@ end procedure neon_normal1x_8_8


neon_normal1x_16_16:

@ r0     = const uint16_t *src
@ r1     = uint16_t *dst
@ r2     = unsigned int width (pixels)
@ r3     = unsigned int srcstride (bytes)
@ [sp]   = unsigned int dststride (bytes)
@ [sp+4] = unsigned int height
@ lr     = return address

        ldr	ip, [sp]                @ ip = dststride
        push {r4-r6}
        ldr	r4, [sp, #(4*4)]        @ r4 = height
        sub r3, r3, r2, lsl #1      @ r3 = srcstride - 2 * width
        sub ip, ip, r2, lsl #1      @ ip = dststride - 2 * width

@ r0 = src
@ r1 = dst
@ r2 = width
@ r3 = srcdiff (srcstride - 2 * width)
@ r4 = height
@ r5 = counter
@ r6 = tmpreg
@ ip = dstdiff (dststride - 2 * width)

    101:
        mov r5, r2                  @ counter = width

    @ first 1-7 pixels - align counter to 16 bytes
        andS r6, r5, #7
        beq 102f

        vld1.8 {q8}, [r0]           @ S1 = [src]
        bic r5, r5, #7              @ counter &= ~7

        add r0, r0, r6, lsl #1      @ src += 2 * r6
        vst1.8 {q8}, [r1]           @ [dst] = S1

        add r1, r1, r6, lsl #1      @ dst += 2 * r6

    @ the rest of the line (8 pixels per iteration)
    102:
        vld1.16 {q8}, [r0]!         @ S1 = [src]; src += 8
        subS r5, r5, #8             @ counter -= 8

        vst1.16 {q8}, [r1]!         @ [dst] = S1; dst += 8
        bne 102b


        subS r4, r4, #1             @ height--
        add r0, r0, r3              @ src += srcdiff
        add r1, r1, ip              @ dst += dstdiff
        bne 101b

        pop {r4-r6}
        bx lr

@ end procedure neon_normal1x_16_16


neon_normal1x_8_16:

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
        ldr r4, [sp, #(4*10)]       @ r4 = dststride
        ldr lr, [sp, #(4*11)]       @ lr = height
        sub sp, sp, #(3*4)
        sub ip, ip, r3              @ ip = srcstride - width
        str r3, [sp, #8]
        sub r4, r4, r3, lsl #1      @ r4 = dststride - 2 * width
        str ip, [sp]
        str r4, [sp, #4]

@ r3     = counter
@ lr     = height
@ [sp]   = srcdiff (srcstride - width)
@ [sp+4] = dstdiff (dststride - 2 * width)
@ [sp+8] = width

    101:
        neon_normal1x_8_16_line r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, ip

        ldr r4, [sp]                @ r4 = srcdiff
        ldr r5, [sp, #4]            @ r5 = dstdiff
        ldr r3, [sp, #8]            @ counter = width
        subS lr, lr, #1             @ height--
        add r0, r0, r4              @ src += srcdiff
        add r1, r1, r5              @ dst += dstdiff
        bne 101b

        add sp, sp, #(3*4)
        pop {r4-r11,lr}
        bx lr

@ end procedure neon_normal1x_8_16

