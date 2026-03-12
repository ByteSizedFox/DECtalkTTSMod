#!/bin/bash
set -e

JAVA_HOME=${JAVA_HOME:-/usr/lib/jvm/java-25-openjdk}
OUTPUT_DIR="../resources/natives"

echo "=== Building Windows x64 DLL with MinGW ==="
echo "Using JAVA_HOME: $JAVA_HOME"

if ! command -v x86_64-w64-mingw32-gcc &> /dev/null; then
    echo "ERROR: x86_64-w64-mingw32-gcc not found!"
    echo "Install it with: sudo dnf install mingw64-gcc"
    exit 1
fi

if [ ! -f "$JAVA_HOME/include/jni.h" ]; then
    echo "ERROR: jni.h not found at $JAVA_HOME/include/jni.h"
    exit 1
fi

JNI_MD_DIR=""
if [ -f "$JAVA_HOME/include/linux/jni_md.h" ]; then
    JNI_MD_DIR="$JAVA_HOME/include/linux"
elif [ -f "$JAVA_HOME/include/win32/jni_md.h" ]; then
    JNI_MD_DIR="$JAVA_HOME/include/win32"
else
    echo "ERROR: jni_md.h not found"
    exit 1
fi

echo "Found jni_md.h in: $JNI_MD_DIR"

mkdir -p ${OUTPUT_DIR}/win64

echo "Compiling JNI wrapper for Windows x64..."

CFLAGS="-O2 -I$JAVA_HOME/include -I$JNI_MD_DIR -I."

x86_64-w64-mingw32-gcc -shared $CFLAGS \
    -o ${OUTPUT_DIR}/win64/tts_jni_win64.dll \
    TTSNative.c \
    libdectalk.dll \
    -lws2_32 -static-libgcc

echo ""
echo "Checking dependencies:"
x86_64-w64-mingw32-objdump -p ${OUTPUT_DIR}/win64/tts_jni_win64.dll | grep "DLL Name"

if [ -f libdectalk.dll ]; then
    cp libdectalk.dll ${OUTPUT_DIR}/win64/dtc.dll
    echo ""
    echo "Copied libdectalk.dll -> dtc.dll"
else
    echo ""
    echo "WARNING: libdectalk.dll not found in current directory"
fi

echo ""
echo "Windows x64 build complete!"
echo "Output: ${OUTPUT_DIR}/win64/"
ls -lh ${OUTPUT_DIR}/win64/
