# Sonic 3 AIR on Switch 2 (devkitPro + libounce)

This branch builds Sonic 3 AIR for the Nintendo Switch 2 with the devkitPro toolchain and the Switch 2 SDK
(`ounce-devkit`: libounce, a libnx-compatible library, and OunceVK for Vulkan / EGL / OpenGL).
It is based on [Eukaryot/sonic3air](https://github.com/Eukaryot/sonic3air) at the commit of the test build
`v26.08.15.0-test` (`016d72f8`), plus a small set of changes listed below. It has been run on hardware:
the game boots, renders with OpenGL at 1920 x 1080 and is playable.

**The code and the game data must come from the same upstream release.** The compiled `data/scripts.bin` is tied to the
exact set of built-in script functions of the engine. If the code is newer or older than the data, the log shows
`Failed to load 'scripts.bin'` and the screen stays black after the splash screen.

## Build

Requirements: devkitPro with `switch-dev` and `switch-zlib`, the Switch 2 SDK (`$DEVKITPRO/libounce`,
`$DEVKITPRO/portlibs/switch2`), and the portlibs `switch-sdl2`, `switch-libogg`, `switch-libvorbis`,
`switch-libtheora`, `switch-glad`.

    cd Oxygen/sonic3air/build/_make
    ./build_switch2.sh

The result is `bin/Switch/sonic3air.nro` (about 23 MB). A clean build takes a few minutes. `make` does not track
header changes, so delete `obj/Switch` after editing a header. `Makefile_cfgs/Platforms/Switch.cfg` includes
`$(DEVKITPRO)/libounce/switch2_rules`, uses the SDK's `SWITCH2_CPU` compiler flags (Cortex-A78C, so the NRO does not
run on a Switch 1) and the Switch 2 pkg-config.

Tested with `ounce-devkit 20261114` (see `$DEVKITPRO/ounce-devkit-version.txt`).

## Changes compared to upstream

- `Makefile`: upstream's hand-written source list is out of date again, so the sources are globbed from the same
  directories as the CMake build (`rmxbase` and `rmxmedia` recursively). Added `Oxygen/sonic3air/source/external` to the includes.
- `Switch.cfg`: `libounce/switch2_rules`, `SWITCH2_CPU` and the switch2 portlibs.
- `Sockets.cpp`: libnx has no `sockaddr_in6`, so the IPv6 branch in `UDPSocket::sendData` is skipped on Switch.
- `main.cpp`: start the libnx socket service in `userAppInit` / `userAppExit`, otherwise networking fails with
  `socket failed with error: -1`. The two functions are declared by hand, because libnx's `<switch.h>` defines a
  `Framebuffer` struct that clashes with the engine's `Framebuffer` class.
- `EngineMain.cpp`: delete the OpenGL context in `destroyWindow()` on Switch. Without it a second launch from hbmenu
  can fail with `Could not initialize EGL`.
- `Configuration.h` / `Configuration.cpp`: on Switch default to borderless fullscreen (1920 x 1080) and the smooth screen
  filter ("Soft 1"), see "Resolution and display" below.
- `ImGuiIntegration.cpp`: cherry-picked upstream commit `87fed540` (a compile error without ImGui, fixed upstream after the test build).
- `.gitignore`: ignore `obj/`, `bin/` and `.DS_Store` of the Make build.

## Running

Copy to the SD card, e.g. `/switch/sonic3air_switch/`:

    sonic3air.nro
    config.json
    data/                          (enginedata.bin, gamedata.bin, audiodata.bin, scripts.bin, metadata.json)
    savedata/Sonic_Knuckles_wSonic3.bin   (your own ROM, not distributed here)

The game writes `savedata/logfile.txt` next to the NRO. The ROM can also be copied next to the NRO; the engine uses the one in `savedata/`.

## Resolution and display (Switch 2)

The Switch 2 screen is 1080p. On Switch the engine defaults to:

- **Borderless fullscreen**, so the window takes the display's real size. Fallback window size: 1920 x 1080.
- **Smooth scaling** (Options > Screen Filter: "Soft 1") instead of "Sharp". The game picture is 400 x 224, which
  scales 4.8x to fit 1920 wide, so integer pixel scaling is not possible. The picture is aspect-fit
  (1920 x 1075, with a 5 px bar at the top and bottom).

Both are only defaults. A saved `savedata/settings.json` (Options menu) overrides them. Delete that file to get the defaults back.
The internal game resolution is unchanged (400 x 224).

## Troubleshooting

- **Black screen after the splash screen, `Failed to load 'scripts.bin'` in `savedata/logfile.txt`:** the data and the code are
  from different upstream versions. Build the commit of the release whose `sonic3air_game.zip` you took the data from.
- **`Could not initialize EGL` in the log when starting the game a second time:** on Switch the process outlives the app
  (hbmenu hosts it). The game now deletes its OpenGL context on exit. After an earlier session that hung or crashed,
  relaunch hbmenu and start the game again; if it keeps failing, reboot the console.
- **Build fails with `SDL.h: No such file or directory`:** a module in the pkg-config list is missing, so the whole list
  returns nothing. Check `$DEVKITPRO/portlibs/switch2/bin/aarch64-none-elf-pkg-config --exists <module>` for
  `sdl2 ogg vorbis theora vorbisfile theoradec zlib minizip libglad egl`. Installing the Switch 2 SDK can leave
  `$DEVKITPRO/portlibs/switch` empty even though pacman lists the packages as installed. Reinstall them:
  `sudo dkp-pacman -S switch-sdl2 switch-libogg switch-libvorbis switch-libtheora switch-glad switch-zlib switch-pkg-config`
  (there is no separate `switch-minizip` package; minizip comes with zlib).
- **`-Wstringop-overflow` compiler warnings** in `librmx` string classes with the newer GCC are false positives.

## Getting a working .NRO from the upstream repo

1. **Install devkitPro** with its pacman (<https://devkitpro.org/wiki/devkitPro_pacman>), then the Switch toolchain and portlibs:

       sudo dkp-pacman -S switch-dev switch-zlib switch-sdl2 switch-libogg switch-libvorbis switch-libtheora switch-glad switch-pkg-config

2. **Install the Switch 2 SDK** (`ounce-devkit`). In the SDK folder run `sh install.sh` (or unpack the `.tar.xz` into `$DEVKITPRO`).
   It adds `$DEVKITPRO/libounce` and `$DEVKITPRO/portlibs/switch2`. Set `DEVKITPRO` if devkitPro is not in `/opt/devkitpro`.
   On macOS, put `export DEVKITPRO=/opt/devkitpro` in `~/.zshenv` so that non-interactive shells (SSH, scripts) see it.

3. **Get the code**, either:

   * clone this repository and check out the branch of the release you want:

         git clone https://github.com/NerdsMcGee/sonic3air-s2.git

   * or apply the changes to the upstream release commit:

         git clone https://github.com/Eukaryot/sonic3air.git
         cd sonic3air
         git checkout 016d72f8
         git remote add s2 https://github.com/NerdsMcGee/sonic3air-s2.git
         git fetch s2
         git diff 016d72f8 s2/switch2-libounce-v26 | git apply

4. **Build**: `cd Oxygen/sonic3air/build/_make && ./build_switch2.sh`. The result is `bin/Switch/sonic3air.nro`.

5. **Get the game data.** The repository only has unpacked data. Download `sonic3air_game.zip` from the upstream release with the
   same version as the code, <https://github.com/Eukaryot/sonic3air/releases/tag/v26.08.15.0-test>, and take its
   `data/` folder and `config.json`. Do not use the `.exe` or `.dll` files. Or use `sonic3air_switch2.zip` from this
   repository's Releases page, which already has them.

6. **Copy to the SD card** as described under "Running" and launch `sonic3air.nro` from the homebrew menu.
