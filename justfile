# List available recipes
default:
    @just --list

# Initial setup: Initialize west workspace and fetch modules
setup:
    @bash scripts/setup.sh

# Build all targets (dax2_R, dax2_L, settings_reset)
build:
    @bash scripts/build.sh

# Build specific target (e.g., just build-target dax2_R)
build-target TARGET="dax2_R":
    @bash scripts/build-target.sh {{TARGET}}

# Flash firmware to device (e.g., just flash dax2_R)
flash TARGET="dax2_R":
    @bash scripts/flash.sh {{TARGET}}

# Quick iteration: Build and flash right hand (dax2_R)
quick:
    @bash scripts/build-target.sh dax2_R
    @bash scripts/flash.sh dax2_R

# Quick iteration: Build and flash left hand (dax2_L)
quick-left:
    @bash scripts/build-target.sh dax2_L
    @bash scripts/flash.sh dax2_L

# Clean build artifacts
clean:
    @echo "Cleaning build artifacts..."
    @rm -rf build/
    @echo "Build artifacts cleaned"

# Complete cleanup including west workspace (for recovery from broken states)
pristine:
    @echo "Performing complete cleanup..."
    @docker-compose run --rm zmk bash -c "west forall -c 'git clean -fdx' || true"
    @rm -rf build/ .west/ modules/ zephyr/ zmk/ bootloader/
    @echo "Complete cleanup done. Run 'just setup' to reinitialize."
