rm -r ./build
mkdir build
cd build
cmake ../Hypodermic/ -DCMAKE_BUILD_TYPE=Debug
cmake --build . --config Debug