#!/usr/bin/env bash

# re-download all the gitignore templates from the toptal repo
git clone https://github.com/toptal/gitignore ./_repo
rm -r ./templates/*
mv _repo/templates/* ./templates/
sudo rm -r _repo
mv ./templates/order .
