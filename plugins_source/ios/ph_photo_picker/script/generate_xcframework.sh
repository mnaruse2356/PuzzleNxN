#!/bin/bash
set -e

libname="ph_photo_picker"
# Compile static libraries

# ARM64 Device
scons target=$1 arch=arm64
# x86_64 Simulator
scons target=$1 arch=x86_64 simulator=yes
# ARM64 Simulator
scons target=$1 arch=arm64 simulator=yes

# Creating a fat libraries for device and simulator
# lib<plugin>.<arch>-<simulator|ios>.<release|debug|release_debug>.a
lipo -create "./bin/lib$libname.x86_64-simulator.$1.a" "./bin/lib$libname.arm64-simulator.$1.a" -output "./bin/$libname-simulator.$1.a"
lipo -create "./bin/lib$libname.arm64-ios.$1.a" -output "./bin/$libname-device.$1.a"

# Creating a xcframework 
xcodebuild -create-xcframework \
    -library "./bin/$libname-device.$1.a" \
    -library "./bin/$libname-simulator.$1.a" \
    -output "./bin/$libname.$1.xcframework"
