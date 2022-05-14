	read -p "Target disk (e.g. /dev/sda /dev/sdb /dev/block/mmcblk0): " TARGET_DISK
	TARGET_DISK=${TARGET_DISK:-/dev/sdb}
	read -p "Target ESP partition (e.g. /dev/sda1 /dev/sdb1 /dev/block/mmcblk0p1): " TARGET_PARTITION
	TARGET_PARTITION=${TARGET_PARTITION:-/dev/sdb1}
echo "boot0af (boot0 Active First) - MBR sector that search for active partition in MBR table (then GPT table). Origin from Apple's boot132 project. This version of boot0af implements hybrid GUID/MBR partition scheme support. Written by Tamás Kosárszky on 2008-03-10

boot0ss (boot0 Signature Scanning) - MBR sector that search for partition with valid PBR signature regardless if it's active or not. Good for Windows that wants to have its partition active. It share the same code as boot0af. Only scanning is done in different order. Written by JrCs on 2013-05-08.

boot1h - PBR sector for HFS+ formatted partition. Search for file 'boot' in the root of the partiton.  Origin from Apple's boot132 project. Written by Tamás Kosárszky on 2008-04-14. This is mod by Slice to support large boot file. Not 440kb as origin but 472k needed to boot Clover-64.

boot1h2 - PBR sector for HFS+ formatted partition with alternative booting with choice of key pressed. File to boot = 'boot{key}'. Coded by dmazar based on boot1h.

boot1f32 - PBR sector for FAT32 formatted partition. Search for file 'boot' in the root of the partiton. Useful for EFI partition or USB stick. Written by mackerintel on 2009-01-26.

boot1f32alt - PBR sector for FAT32 formatted partition with alternative booting with choice of key pressed. File to boot = 'boot{key}'. Modded by Slice based on 
boot1f32 and boot1h2.

boot1x - PBR sector for exFat formatted partition. Search for file 'boot' in the root of the partiton. Useful for EFI partition or USB stick.  Written by Zenith432 on 2014-11-19."
	read -p "Target MBR (Master Boot Record), default boot0af: " NEWMBR
	NEWMBR=${NEWMBR:-boot0af}
	read -p "Target PBR (Partition Boot Record), default boot1f32: " NEWMBR
	NEWPBR=${NEWPBR:-boot1f32}
	read -p "Clover bootfile, default boot6, set to boot7 if cannot initialize hdd: " BOOTFILE
	BOOTFILE=${NEWPBR:-boot6}
	cp ../BootSectors/$NEWMBR ./boot0
	cp ../BootSectors/$NEWPBR ./boot1
	cp ../Bootloaders/x64/"$BOOTFILE" ./boot
	sudo dd if="$TARGET_DISK" bs=512 count=1 >./origMBR
	cp ./origMBR ./newMBR
	dd if=./boot0 of=./newMBR bs=440 count=1 conv=notrunc
	sudo dd if="$TARGET_PARTITION" bs=512 count=1 >./origPBR1
	cp ./boot1 ./newPBR1
	dd if=./origPBR1 of=./newPBR1 skip=3 seek=3 bs=1 count=87 conv=notrunc
	
	# Assume the backup boot sector is located at 0xC00.
	# Hope you have backed up your important files in case I guessed it wrong.
	sudo dd if="$TARGET_PARTITION" skip=6 bs=512 count=1 >./origPBR2
	cp ./boot1 ./newPBR2
	dd if=./origPBR2 of=./newPBR2 skip=3 seek=3 bs=1 count=87 conv=notrunc
	
	sudo dd if=./newPBR1 of="$TARGET_PARTITION" bs=512 count=1 conv=nocreat,notrunc
	sudo dd if=./newPBR2 of="$TARGET_PARTITION" seek=6 bs=512 count=1 conv=nocreat,notrunc
	sudo dd if=./newMBR of="$TARGET_DISK" bs=512 count=1 conv=nocreat,notrunc
	sleep 2
