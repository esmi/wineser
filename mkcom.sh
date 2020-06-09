#!/bin/bash
# make virtual com port pair com1, com2.
#ref: https://drive.google.com/file/d/1_Rd07q_CrOmX6iY4vl6fa1DzcqPtgESG/view?usp=sharing
echo "Run vserp.sh to Create /dev/ttyUSBLocal and /dev/ttyUSBRemote"
vserp.sh --create
echo "Run regedit to create com1, com2 registry."
wine regedit ./wineCom.reg
#將com1,com2 連結至 "vserp.sh" 所產生的"tty"檔案
if [[ -a $HOME/.wine/dosdevices/com1 && -a $HOME/.wine/dosdevices/com2 ]]; then
  echo "com1, com2 alreay exist!"
else
  echo "Link /dev/ttyUSBLocal, /dev/ttyUSBRemote to com1, com2"
  ln -s /dev/ttyUSBRemote ~/.wine/dosdevices/com1
  ln -s /dev/ttyUSBLocal ~/.wine/dosdevices/com2
fi
