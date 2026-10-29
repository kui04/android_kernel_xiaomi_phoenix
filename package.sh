#!/usr/bin/env bash
# AnyKernel3 packaging script for Xiaomi Phoenix (SM7150)

set -e

yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
gre='\e[0;32m'

OUTPUT_DIR="./out/final_output"
AK3_DIR="./out/AnyKernel3"
ZIP_NAME="KernelSU-Next-phoenix-$(date +%Y%m%d_%H%M%S).zip"
LATEST_ZIP="${OUTPUT_DIR}/KernelSU-Next-phoenix.zip"
TARGET_ZIP="${OUTPUT_DIR}/${ZIP_NAME}"

run_docker=false
push_adb=false
reboot_rec=false

for arg in "$@"; do
    case "$arg" in
        --docker)
            run_docker=true
            ;;
        --push)
            push_adb=true
            ;;
        --reboot-recovery)
            reboot_rec=true
            ;;
        --help|-h)
            cat <<EOF
Usage: $0 [options]
Options:
    --docker           Run packaging inside Docker container
    --push             Push generated zip to device via adb
    --reboot-recovery  Reboot device into recovery after packaging/pushing
    --help, -h         Show this help message
EOF
            exit 0
            ;;
    esac
done

if $run_docker; then
    echo -e "${yellow}Running packaging inside Docker container...${white}"
    docker run --rm --network=host \
        -v "$PWD:/home/kernel-builder/work" \
        -w /home/kernel-builder/work \
        phoenix-kernel-builder:latest ./package.sh
    
    if $push_adb || $reboot_rec; then
        if [ -f "$LATEST_ZIP" ]; then
            if $push_adb; then
                echo -e "${yellow}Pushing $LATEST_ZIP to /sdcard/Download/...${white}"
                adb push "$LATEST_ZIP" /sdcard/Download/
            fi
            if $reboot_rec; then
                echo -e "${yellow}Rebooting device into recovery...${white}"
                adb reboot recovery
            fi
        fi
    fi
    exit 0
fi

# 1. Check build artifacts
if [ ! -f "${OUTPUT_DIR}/Image.gz" ]; then
    echo -e "${red}Error: ${OUTPUT_DIR}/Image.gz not found! Build kernel first.${white}"
    exit 1
fi

if [ ! -f "${OUTPUT_DIR}/dtb" ]; then
    echo -e "${red}Error: ${OUTPUT_DIR}/dtb not found! Build kernel first.${white}"
    exit 1
fi

if [ ! -f "${OUTPUT_DIR}/dtbo.img" ]; then
    echo -e "${red}Error: ${OUTPUT_DIR}/dtbo.img not found! Build kernel first.${white}"
    exit 1
fi

# 2. Prepare AnyKernel3 template
if [ ! -d "$AK3_DIR" ]; then
    echo -e "${yellow}Cloning AnyKernel3...${white}"
    git clone --depth=1 https://github.com/osm0sis/AnyKernel3.git "$AK3_DIR"
fi

# 3. Create configured anykernel.sh
cat > "${AK3_DIR}/anykernel.sh" << 'EOF'
### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=KernelSU-Next for Redmi K30 / POCO X2 (phoenix)
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=phoenix
device.name2=phoenixin
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# boot shell variables
BLOCK=boot;
IS_SLOT_DEVICE=auto;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# boot install
dump_boot;

write_boot;
## end boot install
EOF

# 4. Copy payload files into AnyKernel3
cp -f "${OUTPUT_DIR}/Image.gz" "${AK3_DIR}/Image.gz"
cp -f "${OUTPUT_DIR}/dtb" "${AK3_DIR}/dtb"
cp -f "${OUTPUT_DIR}/dtbo.img" "${AK3_DIR}/dtbo.img"

# 5. Build zip
echo -e "${yellow}Creating AnyKernel3 flashable zip...${white}"
mkdir -p "$OUTPUT_DIR"
rm -f "$TARGET_ZIP" "$LATEST_ZIP"

(
    cd "$AK3_DIR"
    zip -r9 "../../${TARGET_ZIP}" * -x .git\* -x .github\* -x README.md -x \*placeholder -x \*.zip
)

cp -f "$TARGET_ZIP" "$LATEST_ZIP"
echo -e "${gre}Successfully created flashable zip: ${TARGET_ZIP}${white}"
echo -e "${gre}Latest zip pointer: ${LATEST_ZIP}${white}"

# 6. Push via ADB if requested
if $push_adb; then
    if which adb &>/dev/null && adb devices | grep -q "device$"; then
        echo -e "${yellow}Pushing ${LATEST_ZIP} to /sdcard/Download/...${white}"
        adb push "$LATEST_ZIP" /sdcard/Download/
        echo -e "${gre}Pushed to device successfully.${white}"
    else
        echo -e "${yellow}ADB device not found, skipping push.${white}"
    fi
fi

if $reboot_rec; then
    if which adb &>/dev/null && adb devices | grep -q "device$"; then
        echo -e "${yellow}Rebooting device into recovery...${white}"
        adb reboot recovery
    fi
fi
