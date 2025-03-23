#!/usr/bin/env bash

# re-download all the gitignore templates from the toptal repo
sudo rm -r _repo || true
git clone https://github.com/toptal/gitignore ./_repo

TEMPLATE_STRING="local M = {}\n"
for file in ./_repo/templates/*; do
    if [[ ${file#'./_repo/templates/'} == "order" ]]; then
        order_lines="local M = {\n"
        count=0
        while read -r line
        do
            if [[  $line != "#"* && $line != "" ]];
            then
              order_lines="$order_lines    $line=$count,\n"
              count=$((count + 1))
            fi
        done < "$file"
        order_lines="$order_lines}\nreturn M\n"
        printf "$order_lines" > lua/gitignore/order.lua
    else
        TEMPLATE_STRING+="M[\"${file#'./_repo/templates/'}\"] = [[\n$(cat "$file")\n]]\n"
    fi
done
TEMPLATE_STRING="$TEMPLATE_STRING\nreturn M\n"
printf "$TEMPLATE_STRING" > lua/gitignore/templates.lua

sudo rm -r _repo
