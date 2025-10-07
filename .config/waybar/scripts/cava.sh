#!/usr/bin/env bash

cava -p ~/.config/cava/config | while read -r line; do
  echo "{\"text\":\"$line\"}"
done
