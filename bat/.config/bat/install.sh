#!/bin/bash
# Script to install bat themes and rebuild cache

echo "Building bat cache with new themes..."
bat cache --build

echo "Bat cache rebuilt successfully!"
echo "Available themes:"
bat --list-themes | grep -i catppuccin