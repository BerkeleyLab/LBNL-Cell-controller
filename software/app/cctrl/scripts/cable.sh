#/bin/sh

IP="192.168.1.222"

usage() {
    echo "Usage: $0 [IP_ADDRESS]" >&2
    exit 1
}

for i
do
    case "$i" in
    [0-9]*.[0-9]*.[0-9]*.[0-9]*) IP="$i"  ;;
    *) echo $i ; usage ;;
    esac
done

echo "In Hardware Manager Tcl Console:"
echo "connect_hw_server "
echo "open_hw_target -xvc_url 127.0.0.1:2542"

python2.7 tools/xilinx_virtual_cable.py -t "$IP"
