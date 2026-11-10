# Sonic 3 AIR on Switch 2 (devkitPro + libounce)

This branch builds the Switch port of Sonic 3 AIR (`v22.09.10.0-switch-rel1`) for the
Switch 2 using the devkitPro toolchain with the libounce SDK (libnx-compatible library,
OunceVK for Vulkan / EGL / OpenGL). It has been run on hardware: the game boots, renders
with OpenGL and is playable.

## Build

Requirements: devkitPro with `switch-dev` and `switch-zlib`, plus the Switch 2 SDK
(`$DEVKITPRO/libounce`, `$DEVKITPRO/portlibs/switch2`), and portlibs `switch-sdl2`,
`switch-libvorbis`, `switch-minizip`, `switch-glad`.

    cd Oxygen/sonic3air/build/_make
    ./build_switch2.sh

The result is `bin/Switch/sonic3air.nro`. `Makefile_cfgs/Platforms/Switch.cfg` includes
`$(DEVKITPRO)/libounce/switch2_rules` and uses the switch2 pkg-config.

## Changes compared to the original Switch release

- `Makefile`: the hand-written source list was out of date (14 files no longer exist).
  Sources are now globbed from the same directories as the CMake build.
  Fixed the `version.inc` path and added `Oxygen/sonic3air/source/external` to the includes.
- `Switch.cfg`: use `libounce/switch2_rules` and the switch2 portlibs.
- `Sockets.cpp`: libnx has no `sockaddr_in6`; the IPv6 branch is skipped on Switch
  (connections fall back to IPv4).
- `main.cpp`: initialize the libnx socket service in non-debug builds
  (`socketInitializeDefault`), otherwise networking fails with `socket failed with error: -1`.
- lemonscript: upstream commit `165eef6d` ("method-like function calls") is reverted.
  With it, the script core hash is 358 and the shipped `data/scripts.bin` (hash 356,
  as in the release package) is rejected. The compiler also crashed on ARM with
  `Invalid reference count of genericmanager::Element` when compiling scripts on the console.
  The cause of the crash was not analysed further. Keep lemonscript at this state
  unless you also rebuild `scripts.bin`.

## Running

Copy to the SD card, e.g. `/switch/sonic3air_switch/`:
`sonic3air.nro`, `config.json`, `data/` (from the release package), and
`Sonic_Knuckles_wSonic3.bin` (your own ROM, not distributed here).
The game writes `savedata/logfile.txt` next to the NRO.

## Getting a working .NRO from the upstream repo

Step by step, starting from [ultra-azu/sonic3air](https://github.com/ultra-azu/sonic3air)
tag `v22.09.10.0-switch-rel1` (commit `f211f353`). These are the steps that produced the
tested NRO.

1. **Install devkitPro** with its pacman (<https://devkitpro.org/wiki/devkitPro_pacman>), then
   the Switch toolchain and portlibs:

       sudo dkp-pacman -S switch-dev switch-zlib switch-sdl2 switch-libvorbis switch-minizip switch-glad switch-pkg-config

2. **Install the Switch 2 SDK** (libounce and OunceVK). In the SDK folder run `sh install.sh`.
   It adds `$DEVKITPRO/libounce` and `$DEVKITPRO/portlibs/switch2`. Set `DEVKITPRO`
   if devkitPro is not in `/opt/devkitpro`. On macOS, put `export DEVKITPRO=/opt/devkitpro` in
   `~/.zshenv` so that non-interactive shells (SSH, scripts) see it as well.

3. **Get the code**, either:

   * clone this fork and use the default branch, which has all changes below:

         git clone https://github.com/NerdsMcGee/sonic3air-s2.git

   * or apply the changes to the upstream tag:

         git clone https://github.com/ultra-azu/sonic3air.git
         cd sonic3air
         git checkout v22.09.10.0-switch-rel1
         git remote add s2 https://github.com/NerdsMcGee/sonic3air-s2.git
         git fetch s2
         git diff v22.09.10.0-switch-rel1 s2/switch2-libounce | git apply

4. **Build**:

       cd Oxygen/sonic3air/build/_make
       ./build_switch2.sh

   The result is `bin/Switch/sonic3air.nro` (about 22 MB). A clean build takes a few minutes.
   Do not mix in newer lemonscript code, see the changes list above.

5. **Get the game data.** The repository only has unpacked data. Download
   `sonic3air_switch.zip` from the upstream release
   <https://github.com/ultra-azu/sonic3air/releases/tag/v22.09.10.0-switch-rel1> and take its
   `data/` folder and `config.json`. `data/scripts.bin` in that package matches this build.
   Or use `sonic3air_switch2.zip` from this fork's Releases page, which already has them.

6. **Copy to the SD card**, e.g. `/switch/sonic3air_switch/`:

       sonic3air.nro      (your build)
       config.json
       data/              (from the release package)
       Sonic_Knuckles_wSonic3.bin   (your own ROM)

   Launch `sonic3air.nro` from the homebrew menu. If the screen stays black after the
   warning screen, read `savedata/logfile.txt` next to the NRO. A line such as
   `Failed to load 'scripts.bin'` means the data and the code are from different versions.
