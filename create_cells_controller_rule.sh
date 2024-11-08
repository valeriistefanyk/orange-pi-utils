#!/bin/bash

devices_before=$(ls /dev/ttyUSB* 2>/dev/null)

echo "Будь ласка, підключіть Cells Controller і натисніть Enter..."
read

# Save new list of serial devices
devices_after=$(ls /dev/ttyUSB* 2>/dev/null)

# New device found
new_device=$(comm -13 <(echo "$devices_before") <(echo "$devices_after"))

if [ -z "$new_device" ]; then
    echo "Новий пристрій не знайдено."
    exit 1
else
    echo "Знайдено новий пристрій: $new_device"
fi

vendor=$(udevadm info -a -n $new_device | grep "ATTRS{idVendor}" | head -n1 | awk -F'==' '{print $2}')
product=$(udevadm info -a -n $new_device | grep "ATTRS{idProduct}" | head -n1 | awk -F'==' '{print $2}')
serial=$(udevadm info -a -n $new_device | grep "ATTRS{serial}" | head -n1 | awk -F'==' '{print $2}')

echo "Vendor: $vendor; product: $product; serial: $serial"

comment="# Cells Controller"
rule="SUBSYSTEM==\"tty\", ATTRS{idVendor}==$vendor, ATTRS{idProduct}==$product, ATTRS{serial}==$serial, SYMLINK+=\"cells_controller\""

udev_rules_dir="/etc/udev/rules.d/"

existing_rule_file=$(grep -r "SYMLINK+=\"cells_controller\"" $udev_rules_dir | cut -d: -f1)
if [ -n "$existing_rule_file" ]; then
    echo "Правило з SYMLINK+=\"cells_controller\" вже існує в файлі: $existing_rule_file"
    exit 0
fi

udev_file="/etc/udev/rules.d/99-cells-controller.rules"
{
    echo $comment
    echo $rule
} | sudo tee -a $udev_file

sudo udevadm control --reload-rules
sudo udevadm trigger

echo "Правило створене. Тепер пристрій має постійну назву cells_controller [/dev/cells_controller]"