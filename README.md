# RpiDude Image Builder

A tool to build disk images for RpiDude.
Currently the disk images don't do much,
it's mostly a blank raspbian image made
to work with the Retroflag GPi case that
tries to automatically connect to wifi.

# Building

First configure your wifi ssid and password by
renaming `rpidude-image-builder/overlay/etc/wpa_supplicant/wpa_supplicant-wlan0.conf.example`
to `rpidude-image-builder/overlay/etc/wpa_supplicant/wpa_supplicant-wlan0.conf`
and modifying it to include the correct 
ssid and password.

You can then build an image by running this:

```
    sudo ./build.sh
```

Which should create a disk image under
`rpidude-image-builder/build/rpidude.img`
which you can write to an sd-card like
this:

```
    sudo dd status=progress if=build/rpidude.img of=/dev/sdX
```

making sure to replace `/dev/sdX` with 
the correct disk. **This deletes ALL
data on this disk.** You can now transfer
the sd-card to your Raspberry Pi and boot
it. Once your Raspberry Pi has booted it
should try connecting to the specified wifi
network. It runs an ssh server with the 
username `rpidude` and the
password `rpidude` which you can connect
to like this:

```
    ssh rpidude@rpidude
```

That's all for now.
