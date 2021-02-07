#!/usr/bin/env bash

revision=`git describe --tags --always`
name="4store-${revision}"

(cd src && make clean)
rm -f tests/{query,import}/results/*
rm -rf /tmp/${name}
cp -r . /tmp/${name}
echo "echo -n ${revision}" > /tmp/${name}/version.sh
chmod 755 /tmp/${name}/version.sh
(cd /tmp && tar cvfz ${name}.tar.gz -h --exclude .git --exclude .gitignore --exclude dawg --exclude '*.tar.gz' --exclude '*.dmg' --exclude '*.app' --exclude '*.o' ${name})
mv /tmp/${name}.tar.gz .
rm -rf /tmp/${name}
