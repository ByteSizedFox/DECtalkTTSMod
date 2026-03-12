#!/bin/bash
set -e

JAVA_HOME=/usr/lib/jvm/java-25-openjdk
OUTPUT_DIR="../resources/natives"

echo "Using JAVA_HOME: $JAVA_HOME"

# Verify jni.h exists
if [ ! -f "$JAVA_HOME/include/jni.h" ]; then
    echo "ERROR: jni.h not found at $JAVA_HOME/include/jni.h"
    exit 1
fi

OS=$(uname -s)

CFLAGS="-fPIC -O2 -I$JAVA_HOME/include -I."

if [ "$OS" = "Linux" ]; then
    echo "Building JNI wrapper for Linux x64..."
    CFLAGS="$CFLAGS -I$JAVA_HOME/include/linux"
    
    mkdir -p ${OUTPUT_DIR}/linux64

    gcc -shared $CFLAGS \
        -o ${OUTPUT_DIR}/linux64/libtts_jni_linux64.so \
        TTSNative.c \
        libdectalk.so \
        -Wl,-rpath,'$ORIGIN' \
        -lpthread
    
    echo "Checking dependencies:"
    ldd ${OUTPUT_DIR}/linux64/libtts_jni_linux64.so
    
    if [ -f libdectalk.so ]; then
        cp libdectalk.so ${OUTPUT_DIR}/linux64/
    else
        echo "WARNING: libdectalk.so not found in current directory"
    fi
    
    echo "Linux build complete"
    echo "Output: ${OUTPUT_DIR}/linux64/"
    
elif [ "$OS" = "Darwin" ]; then
    echo "Building JNI wrapper for macOS..."
    CFLAGS="$CFLAGS -I$JAVA_HOME/include/darwin"
    
    mkdir -p ${OUTPUT_DIR}/macos
    
    gcc -shared $CFLAGS \
        -o ${OUTPUT_DIR}/macos/libtts_jni_macos.dylib \
        TTSNative.c \
        libdectalk.dylib \
        -Wl,-rpath,@loader_path \
        -lpthread
    
    if [ -f libdectalk.dylib ]; then
        cp libdectalk.dylib ${OUTPUT_DIR}/macos/
    else
        echo "WARNING: libdectalk.dylib not found in current directory"
    fi
    
    echo "macOS build complete"
    echo "Output: ${OUTPUT_DIR}/macos/"
fi
