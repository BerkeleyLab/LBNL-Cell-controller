#!/bin/bash
#
set -ueo pipefail

SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

usage () {
    echo "Usage:" >&2
    echo "  $1 [-d DEST] [-s SRC] -i IP " >&2
    echo >&2
    echo " Options:" >&2
    echo "  -d                  Destination bitstream name [CCTRL_A.bit]" >&2
    echo "  -s                  Source bitstream name [CCTRL_A.bit]" >&2
    echo "  -i                  IP" >&2
}

while getopts ":d:s:i:" opt; do
  case ${opt} in
    d) DEST="${OPTARG}" ;;
    s) SRC="${OPTARG}" ;;
    i) IP="${OPTARG}" ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      usage $0
      exit 1
      ;;
    :)
      echo "Option -${OPTARG} requires an argument." >&2
      usage $0
      exit 1
      ;;
  esac
done

# if getopts did not process all inputs
if [ "${OPTIND}" -le "$#" ]; then
    echo "Invalid argument at index '${OPTIND}' does not have a corresponding option." >&2
    usage $0
    exit 1
fi

set +u

# check if needed options were passed
if [ -z "${IP}" ]; then
    echo "IP option was not set." >&2
    usage $0
    exit 1
fi

# Use defaults if not set
if [ -z "${DEST}" ]; then
   DEST="CCTRL_A.bit"
fi

if [ -z "${SRC}" ]; then
   SRC="CCTRL_A.bit"
fi

set -u

REAL_SRC=$(realpath ${SRC})

# exacute commands now
cd ${SCRIPTPATH}

if [ ! -f "${REAL_SRC}" ]; then
    echo "No such file: ${REAL_SRC}"
    exit 1
fi

REAL_SRC_SIZE=$(wc -c "${REAL_SRC}" | awk '{print $1}')

echo "REAL_SRC: ${REAL_SRC}"
echo "REAL_SRC_SIZE: ${REAL_SRC_SIZE}"

tftp -v -m binary "${IP}" -c put "${REAL_SRC}" "${DEST}"
sleep 5
tftp -v -m binary "${IP}" -c get "${DEST}" chk.bit

if cmp -n ${REAL_SRC_SIZE} "${REAL_SRC}" chk.bit; then
    echo "Flash write succeeded."
    rm chk.bit
    exit 0
else
    echo "Flash write may have failed!"
    exit 1
fi
