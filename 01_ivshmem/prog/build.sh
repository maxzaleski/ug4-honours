#!/usr/bin/env bash

for file in $(ls); do
  if [[ $file == *.c ]]; then
    gcc -Wall $file -o /usr/local/bin/__${file%.*}
  fi
done