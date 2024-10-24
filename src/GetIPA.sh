#!/bin/bash

function getEnv() {
    grep "$1" ./../.env | cut -d "=" -f2;
}

SSH=$(getEnv FridaUser)@$(getEnv FridaIP);
IPAServer=$(getEnv IPAServer);

build=$(ssh -q "$SSH" -t "plutil -key CFBundleVersion /var/containers/Bundle/Application/654EF313-6AC0-45D2-BB2A-BC328A920F26/Discord.app/Info.plist" | tr -d '\n' | tr -d '\r');
version=$(ssh -q "$SSH" -t "plutil -key CFBundleShortVersionString /var/containers/Bundle/Application/654EF313-6AC0-45D2-BB2A-BC328A920F26/Discord.app/Info.plist" | tr -d '\n' | tr -d '\r');

IPAHostStatus=$(curl -Is "${IPAServer}"/Discord_"${version}"_"${build}".ipa | awk '/^HTTP/{print $2}');

if [ "$IPAHostStatus" == "200" ]
    then
        echo "Discord_${version}_${build}.ipa exists already!"
        exit 0;
fi

