# Lenovo Legion Slim 7 16APH8 Linux Issues
https://psref.lenovo.com/Product/Legion/Legion_Slim_7_16APH8

## Laptop details
```
AMD Ryzen™ 7 7840HS
Up to Windows® 11 Pro
NVIDIA® GeForce RTX™ 4060
Up to 32GB DDR5-5600, 1x Soldered + 1x SO-DIMM
Up to two M.2 PCIe® NVMe® SSD
Up to 16.0" 3.2K (2560x1600) IPS, 430nits 100% DCI-P3, 165Hz, Dolby® Vision™, G-Sync, FreeSync™, X-Rite® factory color calibration
```

## My laptop model
https://psref.lenovo.com/Detail/Legion/Legion_Slim_7_16APH8?M=82Y4001UMZ

## 1. No audio in Fedora 39, Kernel 6.6.11
In Fedora 39 / Kernel 6.6, audio doesn't work by default. Several fixes are available in the Linux Kernel upstream. The solution is to bring those fixes into the Kernel version that Fedora 39 is using. These are the files i'm backporting:
```
include/sound/cs35l41*
sound/pci/hda/cirrus*
sound/pci/hda/cs35l41*
sound/pci/hda/patch_realtek.c
sound/soc/codecs/cs35l41*
Documentation/devicetree/bindings/sound/cirrus,cs35l41.yaml
sound/pci/hda/Makefile
```
Example of upstream Kernel fixes:
- `ALSA: hda/realtek: enable SND_PCI_QUIRK for Lenovo Legion Slim 7 Gen 8 (2023) serie` - 
https://github.com/torvalds/linux/commits/master/sound/pci/hda/patch_realtek.c

- `ALSA: hda: cs35l41: Prevent firmware load if SPI speed too low` - 
https://github.com/torvalds/linux/commits/master/sound/pci/hda/cs35l41_hda.c

Follow the steps in `audio-fix.sh` one by one to build a custom kernel. You will have to adjust some values like `kernel-6.6.12/linux-6.6.12-200.fc39.x86_64` according to your situation.


### Discussions related to this issue
- [No sound from speakers](https://bugzilla.kernel.org/show_bug.cgi?id=216194#c130)
- [cs35l41: Platform not supported -EINVAL](https://bugzilla.kernel.org/show_bug.cgi?id=208555)
- [Ubuntu and legion pro 7 16IRX8H - audio issues](https://forums.lenovo.com/t5/Ubuntu/Ubuntu-and-legion-pro-7-16IRX8H-audio-issues/m-p/5210709?page=1
)
- [No sound from internal speakers](https://forums.lenovo.com/t5/Other-Linux-Discussions/No-sound-from-internal-speakers-on-Lenovo-Slim-7i-16IRH8-82Y30016BM/m-p/5258964?page=1)
- [How to solve the speaker problem - Intel version](https://github.com/xuwd1/lenovo-legion-slim7i-gen7-knowledges/wiki/How-to-solve-the-speaker-problem)


## 2. Whenever Fn + f2-12 is pressed system immediately crashes.
Adjusting the volume using Fn+F2/F3 or changing the screen brightness with Fn+F5/F6 causes the system to crash.

You need to disable `ideapad_laptop` module to fix this:
```
sudo sh -c 'echo -e "blacklist ideapad_laptop" >> /etc/modprobe.d/blacklist.conf'
cat /etc/modprobe.d/blacklist.conf
```

### Related threads
- [Legion Slim 5/16APH8 fn keys and suspend crash system](https://forums.lenovo.com/t5/Other-Linux-Discussions/Legion-Slim-5-16APH8-fn-keys-and-suspend-crashes-system/m-p/5263948)


## 3. dmesg errors
```
journalctl -p 3 -xb > journalctl-errors.log
cat journalctl-errors.log
```
