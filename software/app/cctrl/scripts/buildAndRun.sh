#!/bin/sh

set -ex
make
sh downloadImage.sh "$@"
