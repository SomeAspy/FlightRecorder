#!/bin/bash

getEnv() {
    grep "$1" .env | cut -d "=" -f2;
}

executeSSH() {
    ssh -q "$(getEnv ideviceSSH)" -p "$(getEnv idevicePort)" -t "$1" || { echo "SSH Failure"; exit 22; }
}

ideviceIP=$(getEnv ideviceIP);

AppName=$(getEnv AppName);
AppIdentifier=$(getEnv AppIdentifier);

IPAServer=$(getEnv IPAServer);

build=$(executeSSH "plutil -key CFBundleVersion /var/containers/Bundle/Application/**/${AppName}.app/Info.plist" | tr -d '\n' | tr -d '\r');
version=$(executeSSH "plutil -key CFBundleShortVersionString /var/containers/Bundle/Application/**/${AppName}.app/Info.plist" | tr -d '\n' | tr -d '\r');

FullIPAFile="${AppName}"_"${version}"_"${build}".ipa;

IPAHostStatus=$(curl -Is "${IPAServer}"/"${FullIPAFile}" | awk '/^HTTP/{print $2}');

if [[ "$IPAHostStatus" == "200" ]]
    then
        echo "${FullIPAFile} exists already!";
        exit 0;
fi

# Sometimes Frida cannot open the app for whatever reason
executeSSH "open ${AppIdentifier}"

# shellcheck disable=SC1091
source frida-ios-dump/.venv/bin/activate

python frida-ios-dump/decrypter.py -H "${ideviceIP}":"$(getEnv FridaPort)" -N "${AppIdentifier}"

# Close the app so it can update in the background
executeSSH "launchctl list | grep discord | cut -f 1 | xargs -I{} kill {}"

echo "Moving IPA file to server directory as ${FullIPAFile}"
mv  "${AppIdentifier}"*.ipa "$(getEnv UploadDirectory)"/"${FullIPAFile}" || { echo "Could not move downloaded IPA"; exit 44; };

# OPTIONAL SEND TO DISCORD #

curl -H "Content-Type: application/json" -d "{\"content\":\"${AppName} v${version} (${build}) - ${IPAServer}/${FullIPAFile}\"}" "$(getEnv DiscordWebhook)" || { echo "Failed to send webhook!"; }