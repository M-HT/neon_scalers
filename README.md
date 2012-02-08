# neon_scalers

Implementation of various scalers with following properties:
 - written in pure assembler
 - uses ARMv7 and NEON instructions
 - uses instruction scheduling for Cortex-A8 processors
 - no checking for corectness of parameters
 - no clipping
 - MIT license


The scaler function definitions are in the header files in the include directory.<br/>
Compiled libaries (static and shared) are in the lib directory.


##Description of scaler function names
neon_NAME_SP_DP

where NAME is the scaler name,<br/>
SP is the number of bits per source pixel,<br/>
DP is the number of bits per destination pixel

list of values:<br/>
NAME: normal1x, normal2x, normal3x, normal4x, scale2x, scale3x, scale4x, eagle2x<br/>
SP->DP: 8->8, 8->16, 16->16


##Description of scaler function parameters
**src**<br/>
pointer to the first source pixel<br/>
if bits per source pixel is 16 then src must be aligned to 16 bits (2 bytes)<br/>
**dst**<br/>
pointer to the first destination pixel<br/>
if bits per destination pixel is 16 then dst must be aligned to 16 bits (2 bytes)<br/>
**palette**<br/>
pointer to an array of 256 32-bit values<br/>
upper 16 bits of every value must be zero<br/>
must be aligned to 32 bits (4 bytes)<br/>
**width**<br/>
width of the source image (in pixels)<br/>
minimum width is 32<br/>
**srcstride**<br/>
stride of the source image (in bytes) = distance between two lines in the source image<br/>
**dststride**<br/>
stride of the destination image (in bytes) = distance between two lines in the destination image<br/>
**height**<br/>
height of the source image<br/>
minimum height is 3


##Example
Scaling 320x200 image (16-bits per pixel) using scale2x to the center of a 800x480 frame

```c_cpp
uint16_t src[320*200];
uint16_t dst[800x480];

neon_scale2x_16_16(&(src[0]), &(dst[((480 - 2*200) / 2) * 800 + (800 - 320 * 2) / 2]), 320, 320*2, 800*2, 200);
```
