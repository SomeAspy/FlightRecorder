#!/bin/bash

function getEnv() {
    grep "$1" .env | cut -d "=" -f2;
}

ideviceIP=$(getEnv ideviceIP);
idevicePort=$(getEnv idevicePort)
SSH=$(getEnv ideviceSSH);

AppName=$(getEnv AppName)
AppIdentifier=$(getEnv AppIdentifier)

IPAServer=$(getEnv IPAServer)

echo "Logging into ${SSH}:${idevicePort}..."

build=$(ssh -q "$SSH" -p "${idevicePort}" -t "plutil -key CFBundleVersion /var/containers/Bundle/Application/**/${AppName}.app/Info.plist" | tr -d '\n' | tr -d '\r') || exit 22;
version=$(ssh -q "$SSH" -p "${idevicePort}" -t "plutil -key CFBundleShortVersionString /var/containers/Bundle/Application/**/${AppName}.app/Info.plist" | tr -d '\n' | tr -d '\r') || exit 22;

FullIPAFile="${AppName}"_"${version}"_"${build}".ipa

IPAHostStatus=$(curl -Is "${IPAServer}"/"${FullIPAFile}" | awk '/^HTTP/{print $2}');

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

# Close the app so it can update in the background
ssh -q "$SSH" -p "${idevicePort}" -t "launchctl list | grep discord | cut -f 1 | xargs -I{} kill {}"

echo "Renaming IPA file to ${FullIPAFile}"
mv  "${AppIdentifier}"*.ipa "${FullIPAFile}"

mv "${FullIPAFile}" "$(getEnv UploadDirectory)" || exit 44

# OPTIONAL SEND TO DISCORD #

if [ "$(getEnv DiscordWebhook)" == "true" ]
    then
        curl -H "Content-Type: application/json" -d "{\"username\": \"$(getEnv WebhookUsername)\", \"content\":\"${AppName} v${version} (${build}) - ${IPAServer}/${FullIPAFile}\"}" "$(getEnv DiscordWebhook)"
fi