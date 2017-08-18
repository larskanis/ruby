#!/bin/bash
set -e
set -x
cd "$(dirname "$0")"

ruby_path=/c/Ruby${ruby_version/-x86/}
export PATH=${ruby_path}/bin:$PATH
JOBS=${NUMBER_OF_PROCESSORS}

case $1 in
  install_script)
    # Install rubyinstaller package repository for gdbm-1.10 and openssl-1.1
    pacman-key --recv-keys BE8BF1C5
    pacman-key --lsign-key BE8BF1C5
    repman add ci.ri2 'http://dl.bintray.com/larskanis/rubyinstaller2-packages'

    # Install ruby dependencies
    pacman --sync --refresh --noconfirm
    pacman --sync --noconfirm --needed \
      "${MINGW_PACKAGE_PREFIX}-toolchain" \
      "${MINGW_PACKAGE_PREFIX}-gcc-libs" \
      "${MINGW_PACKAGE_PREFIX}-gdbm<=1.10" \
      "${MINGW_PACKAGE_PREFIX}-libffi" \
      "${MINGW_PACKAGE_PREFIX}-libyaml" \
      "${MINGW_PACKAGE_PREFIX}-openssl>=1.1" \
      "${MINGW_PACKAGE_PREFIX}-zlib" \
      "bison"

    ruby --version
    gcc --version
    env | sort
    ;;

  build_script)
    autoreconf -fi
    mkdir -p build && cd build
    ../configure \
      --prefix=${MINGW_PREFIX} \
      --build=${MINGW_CHOST} \
      --host=${MINGW_CHOST} \
      --target=${MINGW_CHOST} \
      --with-out-ext=readline,pty,syslog

    make -j$JOBS
    make -j$JOBS DESTDIR=/ install-nodoc

    ${MINGW_PREFIX}/bin/ruby -v -e "p :locale => Encoding.find('locale'), :filesystem => Encoding.find('filesystem')"
    ;;

  test_script)
    cd build
    make "TESTOPTS=-v -q" btest
    make "TESTOPTS=-v -q" test-basic
    make "MSPECOPT=-j" test-spec
    make "TESTOPTS=-q -j$JOBS --show-skip" test-all
    ;;

esac
