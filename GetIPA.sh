#!/bin/bash

function getEnv() {
    grep "$1" .env | cut -d "=" -f2;
}

ideviceIP=$(getEnv ideviceIP);
idevicePort=$(getEnv idevicePort)
SSH=$(getEnv ideviceUser)@${ideviceIP};

AppName=$(getEnv AppName)
AppIdentifier=$(getEnv AppIdentifier)

echo "Logging into ${SSH}:${idevicePort}..."

build=$(ssh -q "$SSH" -p "${idevicePort}" -t "plutil -key CFBundleVersion /var/containers/Bundle/Application/**/${AppName}.app/Info.plist" | tr -d '\n' | tr -d '\r');
version=$(ssh -q "$SSH" -p "${idevicePort}" -t "plutil -key CFBundleShortVersionString /var/containers/Bundle/Application/**/${AppName}.app/Info.plist" | tr -d '\n' | tr -d '\r');

FullIPAFile="${AppName}"_"${version}"_"${build}".ipa

IPAHostStatus=$(curl -Is "$(getEnv IPAServer)"/"${FullIPAFile}" | awk '/^HTTP/{print $2}');

if [ "$IPAHostStatus" == "200" ]
    then
        echo "${FullIPAFile} exists already!";
        exit 0;
fi

# Sometimes Frida cannot open the app for whatever reason
ssh -q "$SSH" -p "${idevicePort}" -t "open ${AppIdentifier}"

# shellcheck disable=SC1091
source frida-ios-dump/.venv/bin/activate

python frida-ios-dump/decrypter.py -H "${ideviceIP}":"$(getEnv FridaPort)" -N "${AppIdentifier}"

echo "Renaming IPA file to ${FullIPAFile}"
mv  "${AppIdentifier}"*.ipa "${FullIPAFile}"

mv "${FullIPAFile}" "$(getEnv UploadDirectory)"