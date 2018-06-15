#!/bin/bash -e
#
#  Copyright (c) 2014, Facebook, Inc.
#  All rights reserved.
#
#  This source code is licensed under the BSD-style license found in the
#  LICENSE file in the root directory of this source tree. An additional grant
#  of patent rights can be found in the PATENTS file in the same directory.
#

# Modified for 14.04 installation.
echo
echo This script will install fblualib and all its dependencies.
echo It has been tested on Ubuntu 13.10 and Ubuntu 14.04, Linux x86_64.
echo

set -e
set -x


if [[ $(arch) != 'x86_64' ]]; then
    echo "x86_64 required" >&2
    exit 1
fi

issue=$(cat /etc/issue)
extra_packages=
current=0
if [[ $issue =~ ^Ubuntu\ 13\.10 ]]; then
    :
elif [[ $issue =~ ^Ubuntu\ 14 ]]; then
    extra_packages=libiberty-dev
elif [[ $issue =~ ^Ubuntu\ 15\.04 ]]; then
    extra_packages=libiberty-dev
elif [[ $issue =~ ^Ubuntu\ 16\.04 ]]; then
    extra_packages=libiberty-dev
    current=1
else
    echo "Ubuntu 13.10, 14.*, 15.04 or 16.04 required" >&2
    exit 1
fi

dir=$(mktemp --tmpdir -d fblualib-build.XXXXXX)

echo Working in $dir
echo
cd $dir

echo Installing required packages
echo
sudo apt-get update && sudo apt-get install -y \
    git \
    curl \
    wget \
    g++ \
    automake \
    autoconf \
    autoconf-archive \
    libtool \
    libboost-all-dev \
    libevent-dev \
    libdouble-conversion-dev \
    libgoogle-glog-dev \
    libgflags-dev \
    liblz4-dev \
    liblzma-dev \
    libsnappy-dev \
    make \
    zlib1g-dev \
    binutils-dev \
    libjemalloc-dev \
    $extra_packages \
    flex \
    bison \
    libkrb5-dev \
    libsasl2-dev \
    libnuma-dev \
    pkg-config \
    libssl-dev \
    libedit-dev \
    libmatio-dev \
    python-dev \
    python3-dev \
    python-numpy \
    python3-pip \
    python-pip 

echo
echo Cloning repositories
echo
if [ $current -eq 1 ]; then
    git clone --depth 1 https://github.com/facebook/folly
    git clone --depth 1 https://github.com/facebook/fbthrift
    git clone https://github.com/bharatsush/thpp.git
    git clone https://github.com/facebook/fblualib
    git clone https://github.com/facebook/wangle
else
    git clone -b v0.35.0  --depth 1 https://github.com/facebook/folly
    git clone -b v0.24.0  --depth 1 https://github.com/facebook/fbthrift
    git clone https://github.com/bharatsush/thpp.git
    git clone -b v1.0 https://github.com/facebook/fblualib
fi

echo
echo Building folly
echo

cd $dir/folly/folly
autoreconf -ivf
./configure
make -j7
sudo make install
sudo ldconfig # reload the lib paths after freshly installed folly. fbthrift needs it.
#pip install six>=1.6.0
if [ $current -eq 1 ]; then
    echo
    echo Wangle
    echo

    cd $dir/wangle/wangle
    cmake .
    make -j7
    sudo make install
fi

echo
echo Building fbthrift
echo
pip install --upgrade six>=1.6.0
cd $dir/fbthrift/thrift
autoreconf -ivf
./configure
if [ $current -eq 1 ]; then
    pushd lib/cpp2/fatal/internal
    ln -s folly_dynamic-inl-pre.h folly_dynamic-inl.h
    popd
fi
make -j7
sudo make install

echo
echo 'Installing TH++'
echo

cd $dir/thpp/thpp
if [ $current -eq 0 ]; then
  mv /root/thpp_build.sh build.sh
  chmod +x build.sh
fi
./build.sh

echo
echo 'Installing FBLuaLib'
echo

cd $dir/fblualib/fblualib
./build.sh

echo
echo 'All done!'
echo
