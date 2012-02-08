# create static library
$PNDSDK/bin/arm-none-linux-gnueabi-gcc -Os -pipe -march=armv7-a -mcpu=cortex-a8 -mtune=cortex-a8 -mfpu=neon -mfloat-abi=softfp -std=c99 -Wall -c *.S
$PNDSDK/bin/arm-none-linux-gnueabi-ar -cqs lib/libneon_scalers.a *.o
rm *.o

# create shared library
$PNDSDK/bin/arm-none-linux-gnueabi-gcc -Os -pipe -march=armv7-a -mcpu=cortex-a8 -mtune=cortex-a8 -mfpu=neon -mfloat-abi=softfp -std=c99 -Wall -fPIC -c *.S
$PNDSDK/bin/arm-none-linux-gnueabi-gcc -shared -Wl,-soname,libneon_scalers.so.1 -o lib/libneon_scalers.so.1.0 *.o
ln -sf libneon_scalers.so.1.0 lib/libneon_scalers.so
ln -sf libneon_scalers.so.1.0 lib/libneon_scalers.so.1
rm *.o
