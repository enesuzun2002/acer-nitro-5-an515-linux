#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Set default undervolt values for the CPU
echo "Setting default undervolt values for CPU..."
if ! command_exists "amdctl"; then
    echo "Couldn't set default undervolt values for CPU."
    echo "amdctl could not be found!"
else
    echo "Successfully set default undervolt values for CPU."
    amdctl -m
    if amdctl -g -p 0 -v 70 && amdctl -g -p 1 -v 102 && amdctl -g -p 2 -v 118; then
        echo "Undervolt values set successfully."
    else
        echo "Failed to set undervolt values."
    fi
fi

# Check if the script received an argument
if [ -z "$1" ]; then
    echo "No argument provided. Please pass either 'true' or 'false'."
    exit 1
fi

# Set power save or default values based on the argument
if [ "$1" == "true" ]; then
    echo "Setting power save values..."

    # Set CPU power limits
    echo "Setting CPU power limit..."
    if ! command_exists "ryzenadj"; then
        echo "Couldn't set CPU power limit."
        echo "ryzenadj could not be found!"
    else
        echo "Successfully set power limits for CPU."
        if ryzenadj --stapm-limit=10000 --fast-limit=10000 --slow-limit=6000 --tctl-temp=60; then
            echo "Power limits set successfully."
        else
            echo "Failed to set power limits."
        fi
    fi

    # Disable NVIDIA GPU
    echo "Disabling NVIDIA GPU..."
    if /usr/local/bin/graphic_card.sh off; then
        echo "NVIDIA GPU disabled successfully."
    else
        echo "Failed to disable NVIDIA GPU."
    fi

    # Set values for AMDGPU
    echo "Setting values for AMDGPU..."
    if echo "low" > /sys/class/drm/card1/device/power_dpm_force_performance_level; then
        echo "AMDGPU set to low performance level."
    else
        echo "Failed to set AMDGPU performance level."
    fi

    # Disable CPU turbo boost
    echo "Disabling CPU turbo boost..."
    if echo "0" > /sys/devices/system/cpu/cpufreq/boost; then
        echo "CPU turbo boost disabled."
    else
        echo "Failed to disable CPU turbo boost."
    fi

elif [ "$1" == "false" ]; then
    echo "Setting default values..."

    # Set CPU power limits
    echo "Setting CPU power limit..."
    if ! command_exists "ryzenadj"; then
        echo "Couldn't set CPU power limit."
        echo "ryzenadj could not be found!"
    else
        echo "Successfully set power limits for CPU."
        if ryzenadj --stapm-limit=25000 --fast-limit=25000 --slow-limit=12000 --tctl-temp=80; then
            echo "Power limits set successfully."
        else
            echo "Failed to set power limits."
        fi
    fi

    # Enable NVIDIA GPU
    echo "Enabling NVIDIA GPU..."
    if /usr/local/bin/graphic_card.sh on; then
        echo "NVIDIA GPU enabled successfully."
    else
        echo "Failed to enable NVIDIA GPU."
    fi

    # Set values for AMDGPU
    echo "Setting values for AMDGPU..."
    if echo "auto" > /sys/class/drm/card1/device/power_dpm_force_performance_level; then
        echo "AMDGPU set to auto performance level."
    else
        echo "Failed to set AMDGPU performance level."
    fi

    # Enable CPU turbo boost
    echo "Enabling CPU turbo boost..."
    if echo "1" > /sys/devices/system/cpu/cpufreq/boost; then
        echo "CPU turbo boost enabled."
    else
        echo "Failed to enable CPU turbo boost."
    fi
else
    echo "Invalid argument. Please pass either 'true' or 'false'."
    exit 1
fi
