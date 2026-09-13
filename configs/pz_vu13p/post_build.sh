#!/bin/sh
set -eu

target=${1:?Buildroot target directory is required}
test -d "$target/etc"
stamp=$(date -u +%Y%m%d-%H%M%S)
build_id=${CVA6_IMAGE_BUILD_ID:-pz-vu13p-sdk-$stamp}

# Identify the complete image, not just a potentially reused kernel binary.
printf 'BUILD_ID=%s\nBOARD=pz_vu13p\nPROFILE=dual-ddr4-16g\nEXPECTED_RAM_BYTES=17179869184\nBUILT_AT=%s\n' \
    "$build_id" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    > "$target/etc/cva6-image-release"
