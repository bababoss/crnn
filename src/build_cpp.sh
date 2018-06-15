#!/bin/bash
cd cpp/
mkdir build
cd build/
cmake ..
make -j7
cp *.so ../../
