#!/bin/sh

set -ex
(
cd ../src
make
)
(
cd ../Release
make all
)
sh createBitfile.sh
sh downloadImage.sh "$@"
