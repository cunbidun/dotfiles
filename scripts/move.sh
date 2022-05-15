#!/bin/bash
for dir in */; do
	echo "$dir"
	mkdir -p "$dir/macos"
	all=$(\ls -a $dir)
	for entry in $all; do
		if [ $entry != '.' ] && [ $entry != '..' ]; then
			mv "$dir/$entry" "$dir/macos"
		fi
	done
done
