#!/bin/bash

## Copy paccache hook to /etc/pacman.d/hooks
sudo cp src/pacman/* /etc/pacman.d/hooks/

## Change 'native' to 'znver3' in /etc/makepkg.conf
sudo sed -i 's/-march=native/-march=znver3/g' /etc/makepkg.conf

## Add GAMEMODERUNEXEC variable to /etc/environment
sudo cp src/etc/environment /etc/environment

## Install BORE-LTO kernel & uninstall old kernel (and vi, it's awful. VIM FTW!)
sudo pacman -Sy linux-cachyos-bore-lto linux-cachyos-bore-lto-headers
sudo pacman -Rsn linux-cachyos linux-cachyos-headers vi

## Fix brightness control
sudo sed -i 's/rw/rw nvidia.NVreg_RegistryDwords=EnableBrightnessControl=1/g' /boot/loader/entries/linux-cachyos-bore-lto.conf

## systemd sleep stuff
sudo sed -i 's/#Allow/Allow/g' /etc/systemd/sleep.conf
sudo sed -i 's/#SuspendMode=/SuspendMode=suspend/g' /etc/systemd/sleep.conf
sudo sed -i 's/#SuspendState=mem standby freeze/SuspendState=disk/g' /etc/systemd/sleep.conf
sudo sed -i 's/#HibnernateMode=platform shutdown/HibernateMode=suspend/g' /etc/systemd/sleep.conf
sudo sed -i 's/#HibernateState/HibernateState/g' /etc/systemd/sleep.conf
sudo sed -i 's/#Hybrid/Hybrid/g' /etc/systemd/sleep.conf

## Add AMDGPU and NVIDIA to MODULES in /etc/mkinitcpio.conf
sudo sed -i 's/MODULES=""/MODULES=(amdgpu nvidia)/g' /etc/mkinitcpio.conf

## Tweak /etc/mkinitcpio.conf
sudo sed -i 's/filesystems fsck/filesystems resume fsck/g' /etc/mkinitcpio.conf
sudo sed -i 's/#COMPRESSION="zstd"/COMPRESSION="zstd/g' /etc/mkinitcpio.conf
sudo sed -i 's/#COMPRESSION_OPTIONS=()/COMPRESSION_OPTIONS=(-9)/g' /etc/mkinitcpio.conf
sudo sed -i 's/#MODULES_DECOMPRESS/MODULES_DECOMPRESS/g' /etc/mkinitcpio.conf
mkinitcpio -P

## Copy brightness and CPU governer scripts to /usr/local/bin
sudo cp -avr src/bin/* /usr/local/bin/

## Make scripts executable
sudo chmod +x /usr/local/bin/brightness_down
sudo chmod +x /usr/local/bin/brightness_up
sudo chmod +x /usr/local/bin/conservation_mode
sudo chmod +x /usr/local/bin/powersaving_mode

## Copy UDEV rules to /etc/udev/rules.d
sudo cp -avr src/udev/* /etc/udev/rules.d/

## Copy Xorg confs to /etc/X11/xorg.conf.d
sudo cp -avr src/xorg/* /etc/X11/xorg.conf.d/

## Copy modprobe confs to /etc/modprobe.d
sudo cp src/modprobe/* /etc/modprobe.d/

## Enable bluetooth
sudo systemctl enable bluetooth

## Set wireless regdom
sudo iw reg set GB

## Enable auto-cpufreq & power-profiles-daemon
sudo systemctl enable auto-cpufreq
sudo systemctl enable power-profiles-daemon

## Set power for NVIDIA GPU to auto
sudo bash -c 'echo "auto" >> /sys/bus/pci/devices/0000:01:00.0/power/control'

## Set battery conservation mode
sudo bash -c 'echo 1 > /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode'

## Install packages from pkgs.txt
while IFS='' read -r pkg || [ -n "${pkg}" ];
do
    PKGS+="$pkg "
done < pkgs.txt

sudo pacman --noconfirm -Sy ${PKGS}

## Install AUR packages from aur.txt
AUR=""
while IFS='' read -r pkg || [ -n "${pkg}" ];
do
    AUR+="$pkg "
done < aur.txt

yay --sudoloop --noconfirm -Sy ${AUR}

## Create virtual desktops in Plasma
dbus org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.setDesktopName 1 Browsing
dbus org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.createDesktop 2 Social
dbus org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.createDesktop 3 Gaming
dbus org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.createDesktop 4 "Workspace Alef"
dbus org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.createDesktop 5 "Workspace Bet"
dbus org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.createDesktop 6 "Workspace Gimel"
