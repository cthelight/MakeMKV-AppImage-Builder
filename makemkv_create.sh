#! /bin/bash
MM_APPDIR='/MakeMKV.AppDir/'
MM_AI_OUTDIR="/out"
MM_AI_NAME="MakeMKV.AppImage"
MM_LINUX_FORUM='https://forum.makemkv.com/forum/viewtopic.php?f=3&t=224'
MM_OSS_TAR="/makemkv-oss.tar.gz"
MM_BIN_TAR="/makemkv-bin.tar.gz"
MM_OUTDIR_USR="$(stat -c "%u" "$MM_AI_OUTDIR")"
MM_OUTDIR_GRP="$(stat -c "%g" "$MM_AI_OUTDIR")"
# Default to root ownership
: "${MM_OUTDIR_USR:="root"}"
: "${MM_OUTDIR_GRP:="root"}"


MM_FORUM_CONT="$(curl -s "$MM_LINUX_FORUM")"

DL_LINKS="$(sed -rn 's#^.*href="(https://www\.makemkv\.com/download/makemkv.*\.tar\.gz)".*$#\1#p' <<< "$MM_FORUM_CONT")"
NEC_PACKAGES="$(sed -rn 's#^.*<code>.*apt-get install (.*)</code>.*$#\1#p' <<< "$MM_FORUM_CONT")"

apt update
apt install $NEC_PACKAGES -y

DL_OSS="$(grep makemkv-oss <<< "$DL_LINKS")"
DL_BIN="$(grep makemkv-bin <<< "$DL_LINKS")"

wget "$DL_OSS" -O "$MM_OSS_TAR"
wget "$DL_BIN" -O "$MM_BIN_TAR"

pushd /

tar -xvf "$MM_OSS_TAR"
mv /makemkv-oss-* /makemkv-oss
tar -xvf "$MM_BIN_TAR"
mv /makemkv-bin-* /makemkv-bin

popd
pushd /makemkv-oss

./configure
# Installs in appimage appdir
sed -i 's#DESTDIR=#DESTDIR='"$MM_APPDIR"'/#' Makefile
make -j $(nproc)
make install

popd
pushd /makemkv-bin

# Force-accept EULA
sed -i -r 's#(^.*install:.*)tmp/eula_accepted(.*$)#\1\2#' Makefile
# Installs in appimage appdir
sed -i 's#DESTDIR=#DESTDIR='"$MM_APPDIR"'/#' Makefile
make install

popd
pushd "$MM_APPDIR"


cat > AppRun << 'EOL'
#! /bin/sh
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin/:${HERE}/usr/sbin/:${HERE}/usr/games/:${HERE}/bin/:${HERE}/sbin/${PATH:+:$PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib/:${HERE}/usr/lib/i386-linux-gnu/:${HERE}/usr/lib/x86_64-linux-gnu/:${HERE}/usr/lib32/:${HERE}/usr/lib64/:${HERE}/lib/:${HERE}/lib/i386-linux-gnu/:${HERE}/lib/x86_64-linux-gnu/:${HERE}/lib32/:${HERE}/lib64/${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PYTHONPATH="${HERE}/usr/share/pyshared/${PYTHONPATH:+:$PYTHONPATH}"
export XDG_DATA_DIRS="${HERE}/usr/share/${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
export PERLLIB="${HERE}/usr/share/perl5/:${HERE}/usr/lib/perl5/${PERLLIB:+:$PERLLIB}"
export GSETTINGS_SCHEMA_DIR="${HERE}/usr/share/glib-2.0/schemas/${GSETTINGS_SCHEMA_DIR:+:$GSETTINGS_SCHEMA_DIR}"
export QT_PLUGIN_PATH="${HERE}/usr/lib/qt4/plugins/:${HERE}/usr/lib/i386-linux-gnu/qt4/plugins/:${HERE}/usr/lib/x86_64-linux-gnu/qt4/plugins/:${HERE}/usr/lib32/qt4/plugins/:${HERE}/usr/lib64/qt4/plugins/:${HERE}/usr/lib/qt5/plugins/:${HERE}/usr/lib/i386-linux-gnu/qt5/plugins/:${HERE}/usr/lib/x86_64-linux-gnu/qt5/plugins/:${HERE}/usr/lib32/qt5/plugins/:${HERE}/usr/lib64/qt5/plugins/${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
exec $HERE/usr/bin/makemkv $@
EOL
chmod +x AppRun

cat > makemkv.desktop << EOL
[Desktop Entry]
Name=MakeMKV
Exec=makemkv
Icon=makemkv
Type=Application
Categories=Utility;
EOL

cp usr/share/icons/hicolor/32x32/apps/makemkv.png .

popd
pushd /

wget https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage -O appimagetool
chmod +x appimagetool
[ -d "$MM_AI_OUTDIR" ] || mkdir -p "$MM_AI_OUTDIR"
./appimagetool --appimage-extract-and-run "$MM_APPDIR" "$MM_AI_OUTDIR/$MM_AI_NAME"
chown "$MM_OUTDIR_USR:$MM_OUTDIR_GRP" "$MM_AI_OUTDIR/$MM_AI_NAME"
popd
