#!/bin/bash
source $(dirname $0)/../utils/defines.sh
setupEclipse $1

echo "***START*** $0 $(date -R)"

BUILDDEPS="org.eclipse.pde.feature.group,org.eclipse.emf.sdk.feature.group,org.eclipse.xtext.sdk.feature.group,org.eclipse.graphiti.sdk.feature.feature.group,org.eclipse.jgit.feature.group"

mkdir -p $TURNUS_WD

rm -fr $ECLIPSE_FRESH
rm -fr $ECLIPSE_BUILD

mkdir $ECLIPSE_FRESH

pushd $TURNUS_WD

echo "Downloading Eclipse..."
wget --progress=dot:mega $ECLIPSEURL

ECLIPSEARCHIVE=$(echo eclipse-platform-*.tar.gz)

echo "Uncompressing the Eclipse archive..."
tar -xzaf $ECLIPSEARCHIVE

echo "Update java max heap size"
sed -i -e "s/-Xmx384m/-Xmx512m/g" eclipse/eclipse.ini

echo "Copying eclipse/* into $ECLIPSE_FRESH"
cp -r eclipse/* $ECLIPSE_FRESH

echo "Installing plugins required for build step into eclipse.build"
eclipse/eclipse  -nosplash -consoleLog \
                        -application org.eclipse.equinox.p2.director \
                        -destination $ECLIPSE_FRESH \
                        -repository  $ECLIPSEREPOSITORY \
                        -followReferences \
                        -installIU   $BUILDDEPS

echo "Deleting 'Eclipse' directory and archive downloaded"
rm -rf eclipse
rm $ECLIPSEARCHIVE
popd

pushd $DIR/../utils/p2-admin
mvn package
popd

echo "Create a build version on $ECLIPSE_BUILD"
rm -fr $ECLIPSE_BUILD
mkdir  $ECLIPSE_BUILD

echo "Copying $ECLIPSE_FRESH/* into $ECLIPSE_BUILD"
cp -r $ECLIPSE_FRESH/* $ECLIPSE_BUILD

echo "***END*** $0 $(date -R)"

