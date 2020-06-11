#!/bin/bash
# make virtual com port pair com1, com2.
#ref: https://github.com/esmi/docs/blob/master/linux_modbus%E6%A8%A1%E6%93%AC%E5%99%A8%E6%B8%AC%E8%A9%A6%E7%92%B0%E5%A2%83.md

echo "Run vserp.sh to Create /dev/ttyUSBLocal and /dev/ttyUSBRemote"
./vserp.sh --create

echo "Run regedit to create com1, com2 registry."

cat <<HERE > mkcom.reg
REGEDIT4

[HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM]
"COM1"="COM1"
"COM2"="COM2"
HERE

wine regedit ./mkcom.reg

#將com1,com2 連結至 "vserp.sh" 所產生的"tty"檔案
if [[ -a $HOME/.wine/dosdevices/com1 && -a $HOME/.wine/dosdevices/com2 ]]; then
  echo "com1, com2 alreay exist!"
else
  echo "Link /dev/ttyUSBLocal, /dev/ttyUSBRemote to com1, com2"
  ln -s /dev/ttyUSBRemote ~/.wine/dosdevices/com1
  ln -s /dev/ttyUSBLocal ~/.wine/dosdevices/com2
fi
