#/bin/sh

echo "The following command sets up an ssh tunnel."
echo "In that shell:"
echo "  cd /vxboot/siocsrcc/head/FPGA"
echo "Then:"
echo "  sh cable.sh <TARGET_IP_ADDRESS>"
ssh -L2542:127.0.0.1:2542 enorum@access.als.lbl.gov
