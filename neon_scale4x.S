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

.include "neon_scale2x.Sinc"
.include "neon_normalxx.Sinc"

.global neon_scale4x_8_8
.global neon_scale4x_16_16
.global neon_scale4x_8_16

.align 4
neon_scale4x_8_8:

@ r0     = const uint8_t *src
@ r1     = uint8_t *dst
@ r2     = unsigned int width (pixels)
@ r3     = unsigned int srcstride (bytes)
@ [sp]   = unsigned int dststride (bytes)
@ [sp+4] = unsigned int height
@ lr     = return address

@ four temporary lines

        ldr ip, [sp]                @ ip = dststride
        push {r4-r11,lr}
        ldr lr, [sp, #(4*10)]       @ lr = height
        mov r11, sp                 @ r11 = sp
        bic sp, sp, #31             @ align sp to 32 bytes
        sub r4, r0, r3              @ r4 = src - srcstride
        sub sp, sp, r2, lsl #1      @ sp -= 2 * width
        add r5, r0, r3              @ r5 = src + srcstride
        mov r10, sp                 @ tmpline4 = sp
        add r6, r1, ip              @ r6 = dst + dststride
        bic sp, sp, #31             @ align sp to 32 bytes
        sub r3, r3, r2              @ r3 = srcstride - width
        sub sp, sp, r2, lsl #1      @ sp -= 2 * width
        sub ip, ip, r2, lsl #1      @ ip = dststride - 2 * width
        mov r9, sp                  @ tmpline3 = sp
        lsl ip, #1                  @ ip = 2 * dststride - 4 * width
        bic sp, sp, #31             @ align sp to 32 bytes
        sub lr, lr, #2              @ height -= 2
        sub sp, sp, r2, lsl #1      @ sp -= 2 * width
        mov r8, sp                  @ tmpline2 = sp
        bic sp, sp, #31             @ align sp to 32 bytes
        sub sp, sp, r2, lsl #1      @ sp -= 2 * width
        mov r7, sp                  @ tmpline1 = sp
        bic sp, sp, #31             @ align sp to 32 bytes
        sub sp, sp, #20
        str lr, [sp]                @ height = lr
        str r3, [sp, #4]            @ srcdiff = r3
        str ip, [sp, #8]            @ dstdiff = ip
        str r2, [sp, #12]           @ width = r2
        str r11, [sp, #16]          @ oldsp = r11

@ r0        = src
@ r1        = dst
@ r2        = counter
@ r3        = reg1
@ r4        = src - srcstride
@ r5        = src + srcstride
@ r6        = dst + dststride
@ r7        = tmpline1
@ r8        = tmpline2
@ r9        = tmpline3
@ r10       = tmpline4
@ r11       = bufptr1
@ ip        = bufptr2
@ lr        = bufptr3
@ [sp]      = height
@ [sp, #4]  = srcdiff (srcstride - width)
@ [sp, #8]  = dstdiff (2 * dststride - 4 * width)
@ [sp, #12] = width
@ [sp, #16] = oldsp

        mov ip, r8                  @ bufptr2 = tmpline2
        mov r11, r7                 @ bufptr1 = tmpline1

    @ first line
        neon_scale2x_8_8_line first, r4, r0, r5, r2, r11, ip, r3, 0, 1

        ldr r3, [sp, #4]            @ reg1 = srcdiff
        mov ip, r7                  @ bufptr2 = tmpline1

        ldr r2, [sp, #12]           @ counter = width
        mov lr, r8                  @ bufptr3 = tmpline2

        add r4, r4, r3              @ src1 += srcdiff
        add r0, r0, r3              @ src2 += srcdiff

        add r5, r5, r3              @ src3 += srcdiff
        lsl r2, #1                  @ counter = 2 * width

    @ first temporary line
        neon_scale2x_8_8_line first, r11, ip, lr, r2, r1, r6, r3, 1, 0

        ldr r3, [sp, #8]            @ reg1 = dstdiff
        mov r11, r9                 @ bufptr1 = tmpline3

        ldr r2, [sp, #12]           @ counter = width
        mov ip, r10                 @ bufptr2 = tmpline4

        add r1, r1, r3              @ dst1 += dstdiff
        add r6, r6, r3              @ dst2 += dstdiff

    100:
    @ line n+1
        neon_scale2x_8_8_line middle, r4, r0, r5, r2, r11, ip, r3, 0, 1

        ldr r3, [sp, #4]            @ reg1 = srcdiff
        mov r11, r7                 @ bufptr1 = tmpline1

        ldr r2, [sp, #12]           @ counter = width
        mov ip, r8                  @ bufptr2 = tmpline2

        mov lr, r9                  @ bufptr3 = tmpline3

        add r4, r4, r3              @ src1 += srcdiff
        add r0, r0, r3              @ src2 += srcdiff

        add r5, r5, r3              @ src3 += srcdiff
        lsl r2, #1                  @ counter = 2 * width

    @ temporary line 2*n
        neon_scale2x_8_8_line middle, r11, ip, lr, r2, r1, r6, r3, 1, 0

        ldr r3, [sp, #8]            @ reg1 = dstdiff
        mov r11, r8                 @ bufptr1 = tmpline2

        ldr r2, [sp, #12]           @ counter = width
        mov ip, r9                  @ bufptr2 = tmpline3

        mov lr, r10                 @ bufptr3 = tmpline4

        add r1, r1, r3              @ dst1 += dstdiff
        add r6, r6, r3              @ dst2 += dstdiff

        lsl r2, #1                  @ counter = 2 * width

    @ temporary line 2*n+1
        neon_scale2x_8_8_line middle, r11, ip, lr, r2, r1, r6, r3, 1, 0

        ldr lr, [sp]                @ lr = height
        mov r11, r7                 @ bufptr1 = tmpline1

        ldr r3, [sp, #8]            @ reg1 = dstdiff
        mov ip, r8                  @ bufptr2 = tmpline2

        ldr r2, [sp, #12]           @ counter = width
        mov r7, r9                  @ tmpline1 = tmpline3

        mov r8, r10                 @ tmpline2 = tmpline4
        subS lr, lr, #1             @ height--

        mov r9, r11                 @ tmpline3 = bufptr1
        add r1, r1, r3              @ dst1 += dstdiff

        mov r10, ip                 @ tmpline4 = bufptr2
        add r6, r6, r3              @ dst2 += dstdiff

        str lr, [sp]                @ height = lr
        bne 100b


    @ last line
        neon_scale2x_8_8_line last, r4, r0, r5, r2, r11, ip, r3, 0, 1

        ldr r2, [sp, #12]           @ counter = width
        mov r11, r7                 @ bufptr1 = tmpline1

        mov ip, r8                  @ bufptr2 = tmpline2
        mov lr, r9                  @ bufptr3 = tmpline3

        lsl r2, #1                  @ counter = 2 * width

    @ last - 2 temporary line
        neon_scale2x_8_8_line middle, r11, ip, lr, r2, r1, r6, r3, 1, 0

        ldr r3, [sp, #8]            @ reg1 = dstdiff
        mov r11, r8                 @ bufptr1 = tmpline2

        ldr r2, [sp, #12]           @ counter = width
        mov ip, r9                  @ bufptr2 = tmpline3

        mov lr, r10                 @ bufptr3 = tmpline4

        add r1, r1, r3              @ dst1 += dstdiff
        add r6, r6, r3              @ dst2 += dstdiff

        lsl r2, #1                  @ counter = 2 * width

    @ last - 1 temporary line
        neon_scale2x_8_8_line middle, r11, ip, lr, r2, r1, r6, r3, 1, 0

        ldr r3, [sp, #8]            @ reg1 = dstdiff
        mov r11, r9                 @ bufptr1 = tmpline3

        ldr r2, [sp, #12]           @ counter = width
        mov ip, r10                 @ bufptr2 = tmpline4

        add r1, r1, r3              @ dst1 += dstdiff
        add r6, r6, r3              @ dst2 += dstdiff

        lsl r2, #1                  @ counter = 2 * width

    @ last temporary line
        neon_scale2x_8_8_line last, r11, ip, lr, r2, r1, r6, r3, 1, 0


        ldr sp, [sp, #16]           @ sp = oldsp
        pop {r4-r11,lr}
        bx lr

@ end procedure neon_scale4x_8_8


neon_scale4x_16_16:

@ r0     = const uint16_t *src
@ r1     = uint16_t *dst
@ r2     = unsigned int width (pixels)
@ r3     = unsigned int srcstride (bytes)
@ [sp]   = unsigned int dststride (bytes)
@ [sp+4] = unsigned int height
@ lr     = return address

@ four temporary lines

        ldr ip, [sp]                @ ip = dststride
        push {r4-r11,lr}
        ldr lr, [sp, #(4*10)]       @ lr = height
        mov r11, sp                 @ r11 = sp
        bic sp, sp, #31             @ align sp to 32 bytes
        sub r4, r0, r3              @ r4 = src - srcstride
        sub sp, sp, r2, lsl #2      @ sp -= 4 * width
        add r5, r0, r3              @ r5 = src + srcstride
        mov r10, sp                 @ tmpline4 = sp
        add r6, r1, ip              @ r6 = dst + dststride
        bic sp, sp, #31             @ align sp to 32 bytes
        sub r3, r3, r2, lsl #1      @ r3 = srcstride - 2 * width
        sub sp, sp, r2, lsl #2      @ sp -= 4 * width
        sub ip, ip, r2, lsl #2      @ ip = dststride - 4 * width
        mov r9, sp                  @ tmpline3 = sp
        lsl ip, #1                  @ ip = 2 * dststride - 8 * width
        bic sp, sp, #31             @ align sp to 32 bytes
        sub lr, lr, #2              @ height -= 2
        sub sp, sp, r2, lsl #2      @ sp -= 4 * width
        mov r8, sp                  @ tmpline2 = sp
        bic sp, sp, #31             @ align sp to 32 bytes
        sub sp, sp, r2, lsl #2      @ sp -= 4 * width
        mov r7, sp                  @ tmpline1 = sp
        bic sp, sp, #31             @ align sp to 32 bytes
        sub sp, sp, #20
        str lr, [sp]                @ height = lr
        str r3, [sp, #4]            @ srcdiff = r3
        str ip, [sp, #8]            @ dstdiff = ip
        str r2, [sp, #12]           @ width = r2
        str r11, [sp, #16]          @ oldsp = r11

@ r0        = src
@ r1        = dst
@ r2        = counter
@ r3        = reg1
@ r4        = src - srcstride
@ r5        = src + srcstride
@ r6        = dst + dststride
@ r7        = tmpline1
@ r8        = tmpline2
@ r9        = tmpline3
@ r10       = tmpline4
@ r11       = bufptr1
@ ip        = bufptr2
@ lr        = bufptr3
@ [sp]      = height
@ [sp, #4]  = srcdiff (srcstride - 2 * width)
@ [sp, #8]  = dstdiff (2 * dststride - 8 * width)
@ [sp, #12] = width
@ [sp, #16] = oldsp

        mov ip, r8                  @ bufptr2 = tmpline2
        mov r11, r7                 @ bufptr1 = tmpline1

    @ first line
        neon_scale2x_16_16_line first, r4, r0, r5, r2, r11, ip, r3, 0, 1

        ldr r3, [sp, #4]            @ reg1 = srcdiff
        mov ip, r7                  @ bufptr2 = tmpline1

        ldr r2, [sp, #12]           @ counter = width
        mov lr, r8                  @ bufptr3 = tmpline2

        add r4, r4, r3              @ src1 += srcdiff
        add r0, r0, r3              @ src2 += srcdiff

        add r5, r5, r3              @ src3 += srcdiff
        lsl r2, #1                  @ counter = 2 * width

    @ first temporary line
        neon_scale2x_16_16_line first, r11, ip, lr, r2, r1, r6, r3, 1, 0

        ldr r3, [sp, #8]            @ reg1 = dstdiff
        mov r11, r9                 @ bufptr1 = tmpline3

        ldr r2, [sp, #12]           @ counter = width
        mov ip, r10                 @ bufptr2 = tmpline4

        add r1, r1, r3              @ dst1 += dstdiff
        add r6, r6, r3              @ dst2 += dstdiff

    100:
    @ line n+1
        neon_scale2x_16_16_line middle, r4, r0, r5, r2, r11, ip, r3, 0, 1

        ldr r3, [sp, #4]            @ reg1 = srcdiff
        mov r11, r7                 @ bufptr1 = tmpline1

        ldr r2, [sp, #12]           @ counter = width
        mov ip, r8                  @ bufptr2 = tmpline2

        mov lr, r9                  @ bufptr3 = tmpline3

        add r4, r4, r3              @ src1 += srcdiff
        add r0, r0, r3              @ src2 += srcdiff

        add r5, r5, r3              @ src3 += srcdiff
        lsl r2, #1                  @ counter = 2 * width

    @ temporary line 2*n
        neon_scale2x_16_16_line middle, r11, ip, lr, r2, r1, r6, r3, 1, 0

        ldr r3, [sp, #8]            @ reg1 = dstdiff
        mov r11, r8                 @ bufptr1 = tmpline2

        ldr r2, [sp, #12]           @ counter = width
        mov ip, r9                  @ bufptr2 = tmpline3

        mov lr, r10                 @ bufptr3 = tmpline4

        add r1, r1, r3              @ dst1 += dstdiff
        add r6, r6, r3              @ dst2 += dstdiff

        lsl r2, #1                  @ counter = 2 * width

    @ temporary line 2*n+1
        neon_scale2x_16_16_line middle, r11, ip, lr, r2, r1, r6, r3, 1, 0

        ldr lr, [sp]                @ lr = height
        mov r11, r7                 @ bufptr1 = tmpline1

        ldr r3, [sp, #8]            @ reg1 = dstdiff
        mov ip, r8                  @ bufptr2 = tmpline2

        ldr r2, [sp, #12]           @ counter = width
        mov r7, r9                  @ tmpline1 = tmpline3

        mov r8, r10                 @ tmpline2 = tmpline4
        subS lr, lr, #1             @ height--

        mov r9, r11                 @ tmpline3 = bufptr1
        add r1, r1, r3              @ dst1 += dstdiff

        mov r10, ip                 @ tmpline4 = bufptr2
        add r6, r6, r3              @ dst2 += dstdiff

        str lr, [sp]                @ height = lr
        bne 100b


    @ last line
        neon_scale2x_16_16_line last, r4, r0, r5, r2, r11, ip, r3, 0, 1

        ldr r2, [sp, #12]           @ counter = width
        mov r11, r7                 @ bufptr1 = tmpline1

        mov ip, r8                  @ bufptr2 = tmpline2
        mov lr, r9                  @ bufptr3 = tmpline3

        lsl r2, #1                  @ counter = 2 * width

    @ last - 2 temporary line
        neon_scale2x_16_16_line middle, r11, ip, lr, r2, r1, r6, r3, 1, 0

        ldr r3, [sp, #8]            @ reg1 = dstdiff
        mov r11, r8                 @ bufptr1 = tmpline2

        ldr r2, [sp, #12]           @ counter = width
        mov ip, r9                  @ bufptr2 = tmpline3

        mov lr, r10                 @ bufptr3 = tmpline4

        add r1, r1, r3              @ dst1 += dstdiff
        add r6, r6, r3              @ dst2 += dstdiff

        lsl r2, #1                  @ counter = 2 * width

    @ last - 1 temporary line
        neon_scale2x_16_16_line middle, r11, ip, lr, r2, r1, r6, r3, 1, 0

        ldr r3, [sp, #8]            @ reg1 = dstdiff
        mov r11, r9                 @ bufptr1 = tmpline3

        ldr r2, [sp, #12]           @ counter = width
        mov ip, r10                 @ bufptr2 = tmpline4

        add r1, r1, r3              @ dst1 += dstdiff
        add r6, r6, r3              @ dst2 += dstdiff

        lsl r2, #1                  @ counter = 2 * width

    @ last temporary line
        neon_scale2x_16_16_line last, r11, ip, lr, r2, r1, r6, r3, 1, 0


        ldr sp, [sp, #16]           @ sp = oldsp
        pop {r4-r11,lr}
        bx lr

@ end procedure neon_scale4x_16_16


neon_scale4x_8_16:

@ r0     = const uint8_t *src
@ r1     = uint8_t *dst
@ r2     = const uint32_t *palette
@ r3     = unsigned int width (pixels)
@ [sp]   = unsigned int srcstride (bytes)
@ [sp+4] = unsigned int dststride (bytes)
@ [sp+8] = unsigned int height
@ lr     = return address

@ three temporary lines
@ four temporary2 lines

        ldr	ip, [sp]                @ ip = srcstride
        push {r4-r11,lr}
        ldr r4, [sp, #(4*10)]       @ r4 = dststride
        ldr r5, [sp, #(4*11)]       @ r5 = height
        mov r6, sp                  @ r6 = sp
        sub ip, ip, r3              @ ip = srcstride - width
        bic sp, sp, #31             @ align sp to 32 bytes
        sub r7, r4, r3, lsl #2      @ r7 = dststride - 4 * width
        mov r9, sp                  @ r9 = sp
        sub sp, sp, r3, lsl #1      @ sp -= 2 * width
        sub r5, r5, #2              @ height -= 2
        mov r10, sp                 @ tmpline3 = sp
        lsl r7, #1                  @ r7 = 2 * dststride - 8 * width
        bic sp, sp, #31             @ align sp to 32 bytes
        rsb r9, sp, r9              @ r9 = tmpstride
        sub sp, sp, r9, lsl #1      @ sp -= 2 * tmpstride
        mov lr, sp                  @ lr = sp
        sub sp, sp, r3, lsl #2      @ sp -= 4 * width
        mov r11, sp                 @ tmp2line4 = sp
        bic sp, sp, #31             @ align sp to 32 bytes
        rsb lr, sp, lr              @ lr = tmp2stride
        sub sp, sp, lr              @ sp -= tmp2stride
        sub sp, sp, lr, lsl #1      @ sp -= 2 * tmp2stride
        sub r8, sp, #64             @ r8 = sp - 64
        vst1.64 {d8-d11}, [r8:256]  @ save q4,q5
        sub sp, sp, #32             @ sp -= 32
        vst1.64 {d12-d15}, [sp:256] @ save q6,q7
        sub sp, r8, #52             @ sp = r8 - 52
        sub r8, r10, r9             @ tmpline2 = tmpline3 - tmpstride
        str r6, [sp]                @ oldsp = r6
        sub r9, r10, r9, lsl #1     @ tmpline1 = tmpline3 - 2 * tmpstride
        str r5, [sp, #4]            @ height = r5
        str ip, [sp, #8]            @ srcdiff = ip
        str r7, [sp, #12]           @ dstdiff = r7
        str r4, [sp, #16]           @ dststride = r4
        str r9, [sp, #20]           @ tmpline1 = r9
        str r8, [sp, #24]           @ tmpline2 = r8
        sub r6, r11, lr             @ tmp2line3 = tmp2line4 - tmp2stride
        str r10, [sp, #28]          @ tmpline3 = r10
        sub r8, r6, lr, lsl #1      @ tmp2line1 = tmp2line3 - 2 * tmp2stride
        str r3, [sp, #32]           @ width = r3
        sub r9, r11, lr, lsl #1     @ tmp2line2 = tmp2line4 - 2 * tmp2stride
        str r8, [sp, #36]           @ tmp2line1 = r8
        str r9, [sp, #40]           @ tmp2line2 = r9
        str r6, [sp, #44]           @ tmp2line3 = r6
        str r11, [sp, #48]          @ tmp2line4 = r11

@ r0  = src
@ r1  = dst
@ r2  = palette
@ r3  = counter
@ r4  = dst2

@ r11 = bufptr1
@ ip  = bufptr2
@ lr  = bufptr3

@ [sp]      = oldsp
@ [sp, #4]  = height
@ [sp, #8]  = srcdiff (srcstride - width)
@ [sp, #12] = dstdiff (2 * dststride - 8 * width)
@ [sp, #16] = dststride
@ [sp, #20] = tmpline1
@ [sp, #24] = tmpline2
@ [sp, #28] = tmpline3
@ [sp, #32] = width
@ [sp, #36] = tmp2line1
@ [sp, #40] = tmp2line2
@ [sp, #44] = tmp2line3
@ [sp, #48] = tmp2line4

    @ r3 = counter

        ldr lr, [sp, #20]           @ bufptr3 = tmpline1

    @ first line
        neon_normal1x_8_16_line r0, lr, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, ip

        ldr r7, [sp, #8]            @ r7 = srcdiff
        ldr r3, [sp, #32]           @ counter = width
        ldr lr, [sp, #24]           @ bufptr3 = tmpline2
        add r0, r0, r7              @ src += srcdiff

    @ second line
        neon_normal1x_8_16_line r0, lr, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, ip

        ldr r3, [sp, #32]           @ counter = width
        ldr ip, [sp, #20]           @ bufptr2 = tmpline1
        ldr lr, [sp, #24]           @ bufptr3 = tmpline2
        ldr r7, [sp, #36]           @ r7 = tmp2line1
        ldr r8, [sp, #40]           @ r8 = tmp2line2

    @ first temporary line
        neon_scale2x_16_16_line first, r11, ip, lr, r3, r7, r8, r9, 1, 1

        ldr r9, [sp, #16]           @ r9 = dststride
        ldr r3, [sp, #32]           @ counter = width
        ldr ip, [sp, #36]           @ bufptr2 = tmp2line1
        ldr lr, [sp, #40]           @ bufptr3 = tmp2line2
        add r4, r1, r9              @ dst2 = dst + dststride
        lsl r3, #1                  @ counter = 2 * width

    @ first temporary2 line
        neon_scale2x_16_16_line first, r11, ip, lr, r3, r1, r4, r5, 1, 0

        ldr r7, [sp, #8]            @ r7 = srcdiff
        ldr r8, [sp, #12]           @ r8 = dstdiff
        ldr r3, [sp, #32]           @ counter = width
        ldr lr, [sp, #28]           @ bufptr3 = tmpline3
        add r0, r0, r7              @ src += srcdiff
        add r1, r1, r8              @ dst += dstdiff

    100:

    @ line n+2
        neon_normal1x_8_16_line r0, lr, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, ip

        ldr r11, [sp, #20]          @ bufptr1 = tmpline1
        ldr ip, [sp, #24]           @ bufptr2 = tmpline2
        ldr lr, [sp, #28]           @ bufptr3 = tmpline3
        ldr r3, [sp, #32]           @ counter = width
        ldr r7, [sp, #44]           @ r7 = tmp2line3
        ldr r8, [sp, #48]           @ r8 = tmp2line4
        str r11, [sp, #28]          @ tmpline3 = bufptr1
        str ip, [sp, #20]           @ tmpline1 = bufptr2
        str lr, [sp, #24]           @ tmpline2 = bufptr3

    @ temporary line n+1
        neon_scale2x_16_16_line middle, r11, ip, lr, r3, r7, r8, r9, 1, 1

        ldr r9, [sp, #16]           @ r9 = dststride
        ldr r3, [sp, #32]           @ counter = width
        ldr r11, [sp, #36]          @ bufptr1 = tmp2line1
        ldr ip, [sp, #40]           @ bufptr2 = tmp2line2
        add r4, r1, r9              @ dst2 = dst + dststride
        ldr lr, [sp, #44]           @ bufptr3 = tmp2line3
        lsl r3, #1                  @ counter = 2 * width

    @ temporary line2 2*n
        neon_scale2x_16_16_line middle, r11, ip, lr, r3, r1, r4, r5, 1, 0

        ldr r8, [sp, #12]           @ r8 = dstdiff
        ldr r9, [sp, #16]           @ r9 = dststride
        ldr r3, [sp, #32]           @ counter = width
        ldr r6, [sp, #36]           @ r6 = tmp2line1
        ldr r11, [sp, #40]          @ bufptr1 = tmp2line2
        add r1, r1, r8              @ dst += dstdiff
        ldr ip, [sp, #44]           @ bufptr2 = tmp2line3
        add r4, r1, r9              @ dst2 = dst + dststride
        ldr lr, [sp, #48]           @ bufptr3 = tmp2line4
        lsl r3, #1                  @ counter = 2 * width
        str r6, [sp, #44]           @ tmp2line3 = r6
        str r11, [sp, #48]          @ tmp2line4 = bufptr1
        str ip, [sp, #36]           @ tmp2line1 = bufptr2
        str lr, [sp, #40]           @ tmp2line2 = bufptr3

    @ temporary line2 2*n+1
        neon_scale2x_16_16_line middle, r11, ip, lr, r3, r1, r4, r5, 1, 0

        ldr r6, [sp, #4]            @ r6 = height
        ldr r7, [sp, #8]            @ r7 = srcdiff
        ldr r8, [sp, #12]           @ r8 = dstdiff
        ldr r3, [sp, #32]           @ counter = width
        subS r6, r6, #1             @ height--
        ldr lr, [sp, #28]           @ bufptr3 = tmpline3
        add r0, r0, r7              @ src += srcdiff
        add r1, r1, r8              @ dst += dstdiff
        str r6, [sp, #4]            @ height = r6
        bne 100b


        ldr r9, [sp, #16]           @ r9 = dststride
        ldr r7, [sp, #44]           @ r7 = tmp2line3
        ldr r8, [sp, #48]           @ r8 = tmp2line4
        ldr r11, [sp, #20]          @ bufptr1 = tmpline1
        ldr ip, [sp, #24]           @ bufptr2 = tmpline2
        add r4, r1, r9              @ dst2 = dst + dststride

    @ last temporary line
        neon_scale2x_16_16_line last, r11, ip, lr, r3, r7, r8, r9, 1, 1

        ldr r9, [sp, #16]           @ r9 = dststride
        ldr r3, [sp, #32]           @ counter = width
        ldr r11, [sp, #36]          @ bufptr1 = tmp2line1
        ldr ip, [sp, #40]           @ bufptr2 = tmp2line2
        add r4, r1, r9              @ dst2 = dst + dststride
        ldr lr, [sp, #44]           @ bufptr3 = tmp2line3
        lsl r3, #1                  @ counter = 2 * width

    @ last - 2 temporary2 line
        neon_scale2x_16_16_line middle, r11, ip, lr, r3, r1, r4, r5, 1, 0

        ldr r8, [sp, #12]           @ r8 = dstdiff
        ldr r9, [sp, #16]           @ r9 = dststride
        ldr r3, [sp, #32]           @ counter = width
        ldr r11, [sp, #40]          @ bufptr1 = tmp2line2
        add r1, r1, r8              @ dst += dstdiff
        ldr ip, [sp, #44]           @ bufptr2 = tmp2line3
        add r4, r1, r9              @ dst2 = dst + dststride
        ldr lr, [sp, #48]           @ bufptr3 = tmp2line4
        lsl r3, #1                  @ counter = 2 * width

    @ last - 1 temporary2 line
        neon_scale2x_16_16_line middle, r11, ip, lr, r3, r1, r4, r5, 1, 0

        ldr r8, [sp, #12]           @ r8 = dstdiff
        ldr r9, [sp, #16]           @ r9 = dststride
        ldr r3, [sp, #32]           @ counter = width
        ldr r11, [sp, #44]          @ bufptr1 = tmp2line3
        add r1, r1, r8              @ dst += dstdiff
        ldr ip, [sp, #48]           @ bufptr2 = tmp2line4
        add r4, r1, r9              @ dst2 = dst + dststride
        lsl r3, #1                  @ counter = 2 * width

    @ last temporary2 line
        neon_scale2x_16_16_line last, r11, ip, lr, r3, r1, r4, r5, 1, 0


        add r6, sp, #52             @ r6 = sp + 52
        ldr sp, [sp]                @ sp = oldsp
        vld1.64 {d8-d11}, [r6:256]  @ restore q4,q5
        add ip, r6, #32             @ ip = r6 + 32
        vld1.64 {d12-d15}, [ip:256] @ restore q6,q7
        pop {r4-r11,lr}
        bx lr

@ end procedure neon_scale4x_8_16

