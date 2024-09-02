#!/bin/bash

usage="Usage: ./graphic_card [option] \nOPTION: \n- off \n- on"

if [ $# -ne 1 ]; then
    echo -e $usage
else
    if lsmod | grep -q acpi_call; then
	echo 'acpi_call found'
    else
	echo 'acpi_call not found!'
	exit 1
    fi
    if [ $1 = 'on' ]; then
	echo '\_SB.PCI0.GPP0.PG00._ON' > /proc/acpi/call
	echo 'Discrete graphic card ENABLED !'
    elif [ $1 = 'off' ]; then
	echo '\_SB.PCI0.GPP0.PG00._OFF' > /proc/acpi/call
	echo 'Discrete graphic card DISABLED !'
    else
	echo -e $usage
    fi
fi
