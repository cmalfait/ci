#!/usr/bin/env bash
###############################################################################
# Infrastructure Engineering Cloud - rpm build / packaging plugin
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
echo "-- Infrastructure Engineering Cloud- ${IE_BUILDTGT} build / packaging plugin v${SCRIPT_VER}"
echo ""

###############################################################################
echo "==============================================================================="
echo "-- Setting/checking variables"
echo ""

echo "-- Parent      = $PPID \"${SCRIPT_PARENT}\""
echo "-- REPO_DIR    = \"${REPO_DIR}\""
echo "-- ROOT_DIR    = \"${ROOT_DIR}\""

OPT_VERBOSE=false

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
echo "-- Staging the source and target-specific areas"
echo ""

BLD_ROOT=${BLD_TEMP}/${PKG_NAME}-${PKG_VERSION}

rm -rf ${BLD_TEMP}/temp

mkdir -p ${BLD_ROOT}/SOURCES

tar xzf ${IE_SRC_TARBALL} \
        -C ${BLD_ROOT}/SOURCES

if [ -d "${REPO_DIR}/${BLD_CTRL}/rpm" ]; then
    echo "-- Using the rpm folder found in ${BLD_CTRL}"
    cp -rp ${REPO_DIR}/${BLD_CTRL}/rpm/* ${BLD_ROOT}/SOURCES
elif [ -f "${REPO_DIR}/${BLD_CTRL}/${RPM_CTRL_TARBALL}" ]; then
    echo "-- Using the rpm tarball found in ${BLD_CTRL}"
    tar xzf ${REPO_DIR}/${BLD_CTRL}/${RPM_CTRL_TARBALL} \
            -C ${BLD_ROOT}/SOURCES
else
    echo ""
    echo "!! Error: Cannot find necessary control files for this target! Exiting (1)"
    echo ""
    exit 1
fi

echo ""

###############################################################################
echo "==============================================================================="
echo "-- Update control files, clean and build the package"
echo ""

pushd ${BLD_ROOT}
echo ""

# Update SPEC file version release number
sed -i "s/^Version:.*/Version:\t ${PKG_VERSION}/" \
    ${BLD_ROOT}/SOURCES/${RPM_CTRL_SPECFILE}
sed -i "s/^Release:.*/Release:\t ${IE_BUILDNUM}.${TGT_SUFFIX}/" \
    ${BLD_ROOT}/SOURCES/${RPM_CTRL_SPECFILE}

# Get arch from SPEC file
RPM_ARCH=$(cat ${BLD_ROOT}/SOURCES/${RPM_CTRL_SPECFILE}|grep ^BuildArch:|awk '{print $2}')
if [ -z "${RPM_ARCH}" ]; then
    RPM_ARCH=x86_64
fi
echo "-- Architecture: ${RPM_ARCH}"

#clean old tar.gz file
pushd ${BLD_ROOT}/SOURCES

cp ${IE_SRC_TARBALL} ${BLD_ROOT}/SOURCES/${PKG_NAME}-${PKG_VERSION}.tar.gz

if [ ! -d ${BLD_ROOT}/BUILD ]; then
    mkdir -p ${BLD_ROOT}/BUILD
fi

if [ ! -d ${BLD_ROOT}/RPMS ]; then
    mkdir -p ${BLD_ROOT}/RPMS
fi

if [ ! -d ${BLD_ROOT}/SPECS ]; then
    mkdir -p ${BLD_ROOT}/SPECS
fi

if [ ! -d ${BLD_ROOT}/SRPMS ]; then
    mkdir -p ${BLD_ROOT}/SRPMS
fi

rpmbuild \
    --define "_topdir ${BLD_ROOT}" \
    -ba ${BLD_ROOT}/SOURCES/${RPM_CTRL_SPECFILE}

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
   ${BLD_ROOT}/RPMS/${RPM_ARCH}/*.rpm \
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

