# Copyright (C) 2017-2024 NXP
# Copyright (C) 2024 Variscite LTD

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:var-som = " \
    file://0001-iMX8M-soc-allow-dtb-override.patch \
    file://0002-iMX8M-soc-change-padding-of-DDR4-and-LPDDR4-DMEM-fir.patch \
    "

SRC_URI:append:imx8mm-var-dart = " \
    file://0001-iMX8M-soc-imx8mm-move-TEE_LOAD_ADDR-to-512mb-memory-.patch \
    file://0003-iMX8M-soc-add-variscite-imx8mm-support.patch \
"

SRC_URI:append:imx8mq-var-dart = " file://0001-iMX8M-soc-imx8mq-move-TEE_LOAD_ADDR-to-512mb-memory.patch"

do_compile:var-som() {
    echo "Copying DTBs"
    if [ "mx8m" = "${SOC_FAMILY}" ]; then
        cp ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/${UBOOT_DTB_NAME} ${BOOT_STAGING}

        for UBOOT_DTB_EXTRA_FILE in ${UBOOT_DTB_EXTRA}; do
            cp ${DEPLOY_DIR_IMAGE}/${BOOT_TOOLS}/${UBOOT_DTB_EXTRA_FILE} ${BOOT_STAGING}
        done
    fi

    # mkimage for i.MX8
    # Copy TEE binary to SoC target folder to mkimage
    if ${DEPLOY_OPTEE}; then
        cp ${DEPLOY_DIR_IMAGE}/tee.bin ${BOOT_STAGING}
    fi
    # Copy OEI firmware to SoC target folder to mkimage
    if [ "${OEI_ENABLE}" = "YES" ]; then
        cp ${DEPLOY_DIR_IMAGE}/${OEI_NAME}               ${BOOT_STAGING}
    fi

    # workaround: make UBOOT_CONFIG_EXTRA equal to UBOOT_CONFIG if UBOOT_CONFIG_EXTRA is not set
    if [ -z "${UBOOT_CONFIG_EXTRA}" ]; then
        UBOOT_CONFIG_EXTRA=${UBOOT_CONFIG}
    fi
    bbnote "UBOOT_CONFIG=${UBOOT_CONFIG}"
    bbnote "UBOOT_CONFIG_EXTRA=${UBOOT_CONFIG_EXTRA}"

    # workaround: make UBOOT_DTB_NAME_EXTRA equal to UBOOT_DTB_NAME if UBOOT_DTB_NAME_EXTRA is not set
    if [ -z "${UBOOT_DTB_NAME_EXTRA}" ]; then
        UBOOT_DTB_NAME_EXTRA=${UBOOT_DTB_NAME}
    fi
    bbnote "UBOOT_DTB_NAME=${UBOOT_DTB_NAME}"
    bbnote "UBOOT_DTB_NAME_EXTRA=${UBOOT_DTB_NAME_EXTRA}"

    # workaround: make UBOOT_NAME_EXTRA equal to UBOOT_NAME if UBOOT_NAME_EXTRA is not set
    if [ -z "${UBOOT_NAME_EXTRA}" ]; then
        UBOOT_NAME_EXTRA=${UBOOT_NAME}
    fi
    bbnote "UBOOT_NAME=${UBOOT_NAME}"
    bbnote "UBOOT_NAME_EXTRA=${UBOOT_NAME_EXTRA}"

    # workaround: make BOOT_CONFIG_MACHINE_EXTRA equal to BOOT_CONFIG_MACHINE if BOOT_CONFIG_MACHINE_EXTRA is not set
    if [ -z "${BOOT_CONFIG_MACHINE_EXTRA}" ]; then
        BOOT_CONFIG_MACHINE_EXTRA=${BOOT_CONFIG_MACHINE}
    fi
    bbnote "BOOT_CONFIG_MACHINE=${BOOT_CONFIG_MACHINE}"
    bbnote "BOOT_CONFIG_MACHINE_EXTRA=${BOOT_CONFIG_MACHINE_EXTRA}"

    for target in ${IMXBOOT_TARGETS}; do
        compile_${SOC_FAMILY}
        case $target in
        *no_v2x)
            # Special target build for i.MX 8DXL with V2X off
            bbnote "building ${IMX_BOOT_SOC_TARGET} - ${REV_OPTION} V2X=NO ${target}"
            make SOC=${IMX_BOOT_SOC_TARGET} ${REV_OPTION} V2X=NO \
                 dtbs="${UBOOT_DTB_NAME} ${UBOOT_DTB_EXTRA}" \
                 flash_linux_m4
        ;;
        *)
            bbnote "building ${IMX_BOOT_SOC_TARGET} - ${REV_OPTION} ${MKIMAGE_EXTRA_ARGS} ${target}"
            make SOC=${IMX_BOOT_SOC_TARGET} ${REV_OPTION} ${MKIMAGE_EXTRA_ARGS} \
                 dtbs="${UBOOT_DTB_NAME} ${UBOOT_DTB_EXTRA}" \
                 ${target}
        ;;
        esac

        if [ -e "${BOOT_STAGING}/flash.bin" ]; then
            cp ${BOOT_STAGING}/flash.bin ${S}/${BOOT_CONFIG_MACHINE}-${target}
        fi
    done
}
