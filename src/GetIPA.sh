#!/bin/bash

function getEnv() {
    grep "$1" ./../.env | cut -d "=" -f2;
}

ideviceIP=$(getEnv ideviceIP);
SSH="$(getEnv ideviceUser)@${ideviceIP} -p $(getEnv idevicePort)";
IPAServer=$(getEnv IPAServer);

build=$(ssh -q "$SSH" -t "plutil -key CFBundleVersion /var/containers/Bundle/Application/654EF313-6AC0-45D2-BB2A-BC328A920F26/Discord.app/Info.plist" | tr -d '\n' | tr -d '\r');
version=$(ssh -q "$SSH" -t "plutil -key CFBundleShortVersionString /var/containers/Bundle/Application/654EF313-6AC0-45D2-BB2A-BC328A920F26/Discord.app/Info.plist" | tr -d '\n' | tr -d '\r');

IPAHostStatus=$(curl -Is "${IPAServer}"/Discord_"${version}"_"${build}".ipa | awk '/^HTTP/{print $2}');

if [ "$IPAHostStatus" == "200" ]
    then
        echo "Discord_${version}_${build}.ipa exists already!";
        exit 0;
fi

ssh -q "$SSH" -t "open ${1}"

# shellcheck disable=SC1091
source src/frida-ios-dump/.venv/bin/activate

python src/frida-ios-dump/decrypter.py -H "${FridaIP}" -N "${1}" -O IPAs/Discord_"${version}"_"${build}".ipa 

rsync -aPe "ssh -p $(getEnv UploadServerPort)" --stats IPAs/Discord_"${version}"_"${build}".ipa "$(getEnv UploadServerUser)"@"$(getEnv UploadServerIP)":"$(getEnv UploadDirectory)"