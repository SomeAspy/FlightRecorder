# FlightRecorder

Dump IPAs off a jailbroken iOS device automatically.

## Setup

### On idevice

1. Jailbreak the device
2. Using your favorite package manager, add and install Frida using the Frida repo <https://build.frida.re> ([Install docs](https://frida.re/docs/ios/))
3. on the device, install the following:
    - `open`
    - `plutil`
    - An SSH server
4. Run `frida-server` (By default this will listen on `0.0.0.0:27042` - use `-l ip:port` to override)

> [!IMPORTANT]  
> The idevice must be **awake**, otherwise the app cannot open.

## On server

1. Clone this repo
2. Copy `.env.example` to `.env`
3. Fill out `.env`
    - `ideviceIP`: IP of the idevice to SSH into and use Frida from
    - `ideviceUser`: User for SSH (This is generally `mobile`)
    - `idevicePort`: SSH port for the idevice (This is generally `2222` or `22`)
    - `FridaPort`: The port for the Frida server (`frida-server` runs on `27042` by default)
    - `IPAServer`: The web directory where you host IPAs (Should return `200` if the IPA exists, `404` otherwise)
    - `UploadDirectory`: The directory the IPAs are hosted from for `IPAServer`
    - `AppName`: The app's name (The first letter is usually capitalized)
    - `AppIdentifier`: The app's identifier (This usually looks like `TLD.company.app`)
4. Run `setup.sh` (You may need to `chmod +x` the file)
    - This script does the following:
    1. Clones required submodules into the repository
    2. Adds execution permission to `GetIPA.sh`
    3. Initializes a Python virtual environment
    4. Installs required Python dependencies
5. Run `GetIPA.sh`
    - This script does the following:
    1. Grabs variables from the `.env` file
    2. SSHs into the idevice to get the app version information
    3. Checks whether the IPA exists already on the server
        - If it does, exit.
    4. SSHs into the idevice and uses `open` to open the specified app
    5. Runs [`frida-ios-dump`](https://github.com/miticollo/frida-ios-dump)'s [`decrypter.py`](https://github.com/miticollo/frida-ios-dump/blob/master/decrypter.py)
        - This places the IPA file into the current folder
    6. Rename the IPA file to `{name}_{semver}_{build}.ipa`
    7. Move the IPA into the web server directory
