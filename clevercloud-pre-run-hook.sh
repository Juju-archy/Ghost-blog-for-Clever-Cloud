#!/bin/sh
npm install -g ghost-cli # install ghost-cli on Clever Cloud
mkdir ghost # create a folder for a new local instance of Ghost
cd ghost
ghost install local
ghost stop
cp ../config.production.json .
npm install ghost-storage-adapter-s3
mkdir -p ./content/adapters/storage
cp -r ../node_modules/ghost-storage-adapter-s3 content/adapters/storage/s3
rm -R content/themes/source
cp -r ../content/themes/source content/themes/