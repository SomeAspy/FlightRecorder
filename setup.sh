#!/bin/bash
git submodule update --init --recursive;
chmod +x GetIPA.sh
cd frida-ios-dump || exit 1
python -m venv ./.venv
# shellcheck disable=SC1091
source ./.venv/bin/activate
pip install frida frida-tools

echo done!
exit 0