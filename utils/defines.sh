#!/bin/bash

function isNumber() { 
if [[ -z "${1##*[!0-9]*}" ]] ; then 
   return 1 
else
   return 0
fi
}

function isBoolean() { 
if [[ $1  = "true" || $1 = "false" ]]  ; then 
   return 0 
	else
   return 1
fi
}

function setupEclipse(){
[ ! -d "$1" ] && echo "Missing working directory folder" && exit $E_BADARGS

# exits when a command returned non 0 value
set -e
export E_BADARGS=64

export TURNUS_WD="$1"

ARCH=`uname -m`
BUILDTYPE="tests"


if [ "$ARCH" == "x86_64" ]; then
	ECLIPSE_ARCH="-x86_64"
else
	ECLIPSE_ARCH=""
fi

# Used to download the base platform version of eclipse
export ECLIPSEURL="http://mirror.ibcp.fr/pub/eclipse/eclipse/downloads/drops4/R-4.3.2-201402211700/eclipse-platform-4.3.2-linux-gtk$ECLIPSE_ARCH.tar.gz"
# Used to download dependencies (both runtime and build eclipse)
ECLIPSEVERSION=kepler
export ECLIPSEREPOSITORY=http://download.eclipse.org/releases/$ECLIPSEVERSION

export ECLIPSE_FRESH=$TURNUS_WD/eclipse.fresh
export ECLIPSE_BUILD=$TURNUS_WD/eclipse.build

export BUILDDIR=$TURNUS_WD/build.dir.$BUILDTYPE
export PLUGINSDIR=$BUILDDIR/plugins
export FEATURESDIR=$BUILDDIR/features

# Get the path of the current script. This script is necessary to resolve symlinks to this script
# see http://stackoverflow.com/a/246128/1887976
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Set the path of the p2-admin binary, generated from orcc_eclipse_setup script
if [ "$ARCH" == "x86_64" ]; then
	P2ADMIN_ARCH="x86_64"
else
	P2ADMIN_ARCH="x86"
fi

export P2ADMIN=$DIR/../utils/p2-admin/org.eclipselabs.equinox.p2.admin.product/target/products/org.eclipse.equinox.p2.admin.rcp.product/linux/gtk/$P2ADMIN_ARCH/p2-admin/p2-admin

# Setup eclipse classpath
ECLIPSECP=$(echo $ECLIPSE_BUILD/plugins/*.jar | sed -e "s/ /:/g")
# Add the missing junit4 plugin, to allow compiling xtend in tests plugin
ECLIPSECP=$ECLIPSECP:$(echo $ECLIPSE_BUILD/plugins/org.junit_4*/junit.jar)

# Setup Xtext MWE2 classpath
MWECP=$ECLIPSECP
MWECP=$(echo $DIR/../utils/antlr-generator-*.jar | sed -e "s/ /:/g"):$MWECP
export MWECP

# Setup Xtend classpath
for i in $(ls $PLUGINSDIR 2>/dev/null)
do
    [ -d "$PLUGINSDIR/$i/src" ] && SOURCEFOLDERS=$SOURCEFOLDERS:$PLUGINSDIR/$i/src
    [ -d "$PLUGINSDIR/$i/src-gen" ] && SOURCEFOLDERS=$SOURCEFOLDERS:$PLUGINSDIR/$i/src-gen
done
# Remove the first ':'
SOURCEFOLDERS=$(echo $SOURCEFOLDERS | sed -e "s/^://g")
export SOURCEFOLDERS
}

