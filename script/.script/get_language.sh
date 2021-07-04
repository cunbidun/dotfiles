#!/bin/bash
EN_ibus="xkb:us::eng"
VN_ibus="Bamboo"
lang=`ibus engine`

if [ "$lang" = "$EN_ibus" ];then
  echo "en"
fi
if [ "$lang" = "$VN_ibus" ];then
  echo "vi"
fi
