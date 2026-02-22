# Laptop Firmware Files

This directory holds proprietary firmware files extracted from the Windows installation
on the Lenovo Yoga 9 2-in-1 14ILL10 (Intel Lunar Lake). These files are **not committed
to git** because they contain proprietary binary blobs.

## Directory Structure

```
firmware/
  ish/          Intel Sensor Hub firmware (*.bin)
  audio/        Audio topology and firmware files (preserves subdirectory structure)
```

## Staging Firmware Before Building

The extracted firmware files are stored on the build host at:

```
/mnt/docker-swarm-volumes/firmware/yoga9-14ill10/
```

Before building the laptop image, copy them into this directory:

```bash
cp -a /mnt/docker-swarm-volumes/firmware/yoga9-14ill10/* build_files/firmware/
```

The `install-laptop-firmware.sh` build script will warn (but not fail) if firmware
files are missing, so builds without firmware are still possible for testing.

## Extraction Process

Firmware files are extracted from the laptop's Windows partition. The relevant files are:

- **ISH firmware**: Intel Sensor Hub binary blobs (`*.bin`) — required for sensor hub
  functionality (lid state, ambient light, accelerometer passthrough)
- **Audio firmware**: SOF topology files and codec firmware — required for the Lunar Lake
  audio subsystem to function correctly
