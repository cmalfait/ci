#!/usr/bin/env bash
###############################################################################
# Infrastructure Engineering Cloud - debian build / packaging plugin
#
# *Not for direct execution!*
#
###############################################################################
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_PARENT=$(ps -p ${PPID} -o cmd=)
EXIT_VAL=0

SCRIPT_VER=1.0.0

###############################################################################
echo ""
echo "###############################################################################"
echo "-- Infrastructure Cloud - ${IE_BUILDTGT} build / packaging plugin v${SCRIPT_VER}"
echo ""

###############################################################################
echo "==============================================================================="
echo "-- Setting/checking variables"
echo ""

echo "-- Parent      = $PPID \"${SCRIPT_PARENT}\""
echo "-- REPO_DIR    = \"${REPO_DIR}\""
echo "-- ROOT_DIR    = \"${ROOT_DIR}\""

OPT_VERBOSE=false
OPT_NO_PATCHES=true
OPT_NO_DEPENDENCIES=true

if [ ${OPT_NO_PATCHES} == true ]; then
    echo "-- OPT: Deleting patches from the debian folder prior to build"
fi

if [ ${OPT_NO_DEPENDENCIES} == true ]; then
    echo "-- OPT: Disabling dependency checking"
fi

if [ ${OPT_VERBOSE} == true ]; then
    echo "-- OPT: Enabling verbose output"
    set -vx
fi

echo ""

###############################################################################
IE_SRC_TARBALL=${BLD_TEMP}/${PKG_NAME}_${PKG_VERSION}.orig-${IE_BUILDTGT}.tar.gz
echo "==============================================================================="
echo "-- Creating the source tarball (will be used to build)"
echo ""

echo "-- Tarball = ${IE_SRC_TARBALL}"
echo "-- Package version = \"${PKG_VERSION}\""
echo "-- Target  version = \"${TGT_VERSION}\""
echo ""

pushd ${ROOT_DIR}
echo ""

mkdir -p ${BLD_TEMP}/temp/dist
cp -rp ${REPO_DIR} ${BLD_TEMP}/temp/dist/${PKG_NAME}-${PKG_VERSION}

tar czvf ${IE_SRC_TARBALL} \
    --exclude=${BLD_CTRL} \
    --exclude-vcs \
    -C ${BLD_TEMP}/temp/dist \
    .

echo ""

###############################################################################
echo "==============================================================================="
echo "-- Staging the source and and target-specific areas"
echo ""

BLD_ROOT=${BLD_TEMP}/${PKG_NAME}-${PKG_VERSION}

rm -rf ${BLD_TEMP}/temp

tar xzf ${IE_SRC_TARBALL} \
    -C ${BLD_TEMP}

if [ -d "${REPO_DIR}/${BLD_CTRL}/debian" ]; then
    echo "-- Using the debian folder found in ${BLD_CTRL}"
    cp -rp ${REPO_DIR}/${BLD_CTRL}/debian ${BLD_ROOT}
elif [ -f "${REPO_DIR}/${BLD_CTRL}/${DEB_CTRL_TARBALL}" ]; then
    echo "-- Using the debian tarball found in ${BLD_CTRL}"
    tar xzf ${REPO_DIR}/${BLD_CTRL}/${DEB_CTRL_TARBALL} \
            -C ${BLD_ROOT}
else
    echo ""
    echo "!! Error: Cannot find necessary control files for this target! Exiting (1)"
    echo ""
    exit 1
fi

if [ "${OPT_NO_PATCHES}" == true ]; then
    echo "-- Deleting the debian/patch folder"
    rm -rf ${BLD_ROOT}/debian/patches/*
fi

echo ""

###############################################################################
echo "==============================================================================="
echo "-- Update control files, clean and build the package"
echo ""

pushd ${BLD_ROOT}
echo ""

debchange --newversion ${TGT_VERSION} \
          --distribution precise \
          --force-distribution \
          --preserve \
          --force-bad-version \
          "${TGT_CHGLOG}"

EXIT_VAL=$?
if [ ${EXIT_VAL} -ne 0 ]; then
    echo ""
    echo "!! Error: Changelog update failed! Exiting (${EXIT_VAL})"
    echo ""
    exit ${EXIT_VAL}
fi

dh clean

EXIT_VAL=$?
if [ ${EXIT_VAL} -ne 0 ]; then
    echo ""
    echo "!! Error: Clean failed! Exiting (${EXIT_VAL})"
    echo ""
    exit ${EXIT_VAL}
fi

sed 's?^\(Maintainer:\).*$?\1 '"${TGT_EMAIL}"'?;s?^\(Homepage:\).*$?\1 '"${TGT_WEBHP}"'?' \
    < debian/control \
    > debian/control.new
mv debian/control.new debian/control

SPECIAL_DPKG_OPTS=
if [ ${OPT_NO_DEPENDENCIES} == true ]; then
    SPECIAL_DPKG_OPTS="${SPECIAL_DPKG_OPTS} -d"
fi

DEB_BUILD_OPTIONS="nodocs,nocheck" dpkg-buildpackage \
    ${SPECIAL_DPKG_OPTS} \
    -b \
    -nc \
    -m"${TGT_EMAIL}" \
    -e"${TGT_EMAIL}"

EXIT_VAL=$?
if [ ${EXIT_VAL} -ne 0 ]; then
    echo ""
    echo "!! Error: Build package failed! Exiting (${EXIT_VAL})"
    echo ""
    exit ${EXIT_VAL}
fi

echo ""
popd
echo ""

###############################################################################
echo "==============================================================================="
echo "-- Move packages to ${BLD_DIST}"
echo ""

mv ${IE_SRC_TARBALL} \
   ${BLD_TEMP}/*.deb \
   ${BLD_TEMP}/*.changes \
   ${BLD_DIST}

###############################################################################
pushd ${BLD_DIST}
echo ""
echo "==============================================================================="
echo "-- Artifact details for this build"
echo ""
for MYARTIFACT in `ls`; do
    md5sum "${MYARTIFACT}"
done
echo ""
echo "==============================================================================="
echo ""
popd
echo ""

###############################################################################
echo "==============================================================================="
echo "-- Build sub-process for ${IE_BUILDTGT} finished. Exiting (${EXIT_VAL})"
echo ""

exit ${EXIT_VAL}

###############################################################################

