#!/bin/bash

devices_before=$(ls /dev/ttyACM* 2>/dev/null)

echo "Будь ласка, підключіть Barcode Scanner і натисніть Enter..."
read

# Save new list of serial devices
devices_after=$(ls /dev/ttyACM* 2>/dev/null)

# New device found
new_device=$(comm -13 <(echo "$devices_before") <(echo "$devices_after"))

if [ -z "$new_device" ]; then
    echo "Новий пристрій не знайдено."
    exit 1
else
    echo "Знайдено новий пристрій: $new_device"
fi

# Check and remove existing udev rule file if it exists
udev_file="/etc/udev/rules.d/99-barcode-scanner.rules"
if [ -f "$udev_file" ]; then
    echo "Файл $udev_file вже існує. Видаляю..."
    sudo rm "$udev_file"
fi

vendor=$(udevadm info -a -n $new_device | grep "ATTRS{idVendor}" | head -n1 | awk -F'==' '{print $2}')
product=$(udevadm info -a -n $new_device | grep "ATTRS{idProduct}" | head -n1 | awk -F'==' '{print $2}')
serial=$(udevadm info -a -n $new_device | grep "ATTRS{serial}" | head -n1 | awk -F'==' '{print $2}')

echo "Vendor: $vendor; product: $product; serial: $serial"

comment="# Barcode Scanner"
rule="SUBSYSTEM==\"tty\", ATTRS{idVendor}==$vendor, ATTRS{idProduct}==$product, ATTRS{serial}==$serial, SYMLINK+=\"barcode_scanner\""

udev_rules_dir="/etc/udev/rules.d/"

existing_rule_file=$(grep -r "SYMLINK+=\"barcode_scanner\"" $udev_rules_dir | cut -d: -f1)
if [ -n "$existing_rule_file" ]; then
    echo "Правило з SYMLINK+=\"barcode_scanner\" вже існує в файлі: $existing_rule_file"
    exit 0
fi

{
    echo $comment
    echo $rule
} | sudo tee -a $udev_file

sudo udevadm control --reload-rules
sudo udevadm trigger

echo "Правило створене. Тепер пристрій має постійну назву barcode_scanner [/dev/barcode_scanner]"
