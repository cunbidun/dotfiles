#!/usr/bin/env bash
EN_ibus="xkb:us::eng"
VN_ibus="Bamboo"
lang=`ibus engine`

if [ $lang = $EN_ibus ];then
  ibus engine $VN_ibus
  notify-send "[vi] xin chào" -t 1000 -a "System"
fi
if [ $lang = $VN_ibus ];then
  notify-send "[en] welcome" -t 1000 -a "System"
  ibus engine $EN_ibus
fi

