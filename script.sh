#!/bin/bash
set -o errexit
set -o pipefail
set -o xtrace

COMMONFLAGS="--disable-win16 --disable-tests --without-x --without-freetype --disable-largefile"

rmgcc () {
    if [ "$(which gcc)" = "" ]; then return; fi
    sudo apt-get autoremove --purge -yy gcc g++
    sudo rm -f /usr/bin/nm
}
copytool () {
    mkdir -p $(dirname $1) && cp ../build_native/$1 $1 && chmod +x $1
}

repo_clone () {
    if [ ! -d wine_js ]; then
        git clone https://github.com/wine-mirror/wine.git wine_js
        cd wine_js && git checkout wine-1.7.9 && cd ..
    fi
    rsync -ar --delete wine_js wine_native >/dev/null
}

native_configure () {
    ../wine_native/configure $COMMONFLAGS --prefix=$(pwd)/dist
}
native_make () {
    make
}

js_configure () {
    rmgcc
    emconfigure ../wine_js/configure \
        CXX="emcc" \
        CFLAGS="-D__i386__ -std=gnu89 -g -Wno-unknown-attributes" \
        $COMMONFLAGS
}
js_make () {
    rmgcc
    #sed -i 's/^CFLAGS\W.*/\0 -U__GNUC__/' $(find . -name Makefile)
    copytool tools/makedep
    copytool tools/widl/widl
    copytool tools/make_xftmpl
    copytool tools/winebuild/winebuild
    copytool tools/winegcc/winegcc
    # emmake make || true
    # copytool tools/widl/widl
    # copytool tools/make_xftmpl
    # copytool tools/winebuild/winebuild
    # copytool tools/winegcc/winegcc
    # copytool tools/makedep
    emmake make
}

case "$1" in
    clone)
        repo_clone;;
    *)
        cd "build_$1"
        "${1}_${2}";;
esac
