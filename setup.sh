#!/bin/bash
git submodule update --init --recursive;
cd src/frida-ios-dump || echo "Failed to enter frida-ios-dump!" && exit 1;
python -m venv ./.venv;
# shellcheck disable=SC1091
source ./venv/bin/activate;
pip install frida frida-tools;
chmod +x src/GetIPA.sh
echo done!;

exit 0;