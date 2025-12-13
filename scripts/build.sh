#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Environment variables for Zephyr
export ZEPHYR_ENV="
  export ZEPHYR_BASE=/workspace/zephyr
  export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
  export ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk-0.16.9
"

# Build dax2_R in parallel
echo "Starting parallel build for dax2_R..."
docker-compose run --rm zmk bash -c "
  set -e
  $ZEPHYR_ENV
  echo 'Building: dax2_R'
  west build -s zmk/app -b xiao_ble -d build/dax2_R -- \
    -DBOARD_ROOT=/workspace \
    -DSHIELD='dax2_R;rgbled_adapter' \
    -DSNIPPET=studio-rpc-usb-uart \
    -DZMK_CONFIG=/workspace/config \
    -DCMAKE_PREFIX_PATH='/workspace/zephyr/share/zephyr-package/cmake;/opt/zephyr-sdk-0.16.9/cmake' \
    -DCMAKE_BUILD_PARALLEL_LEVEL=2
" > /tmp/build-dax2_R.log 2>&1 &
PID_R=$!

# Build dax2_L in parallel
echo "Starting parallel build for dax2_L..."
docker-compose run --rm zmk bash -c "
  set -e
  $ZEPHYR_ENV
  echo 'Building: dax2_L'
  west build -s zmk/app -b xiao_ble -d build/dax2_L -- \
    -DBOARD_ROOT=/workspace \
    -DSHIELD='dax2_L;rgbled_adapter' \
    -DZMK_CONFIG=/workspace/config \
    -DCMAKE_PREFIX_PATH='/workspace/zephyr/share/zephyr-package/cmake;/opt/zephyr-sdk-0.16.9/cmake' \
    -DCMAKE_BUILD_PARALLEL_LEVEL=2
" > /tmp/build-dax2_L.log 2>&1 &
PID_L=$!

# Build settings_reset in parallel
echo "Starting parallel build for settings_reset..."
docker-compose run --rm zmk bash -c "
  set -e
  $ZEPHYR_ENV
  echo 'Building: settings_reset'
  west build -s zmk/app -b xiao_ble -d build/settings_reset -- \
    -DBOARD_ROOT=/workspace \
    -DSHIELD=settings_reset \
    -DZMK_CONFIG=/workspace/config \
    -DCMAKE_PREFIX_PATH='/workspace/zephyr/share/zephyr-package/cmake;/opt/zephyr-sdk-0.16.9/cmake' \
    -DCMAKE_BUILD_PARALLEL_LEVEL=2
" > /tmp/build-settings_reset.log 2>&1 &
PID_RESET=$!

echo ""
echo "All builds started. Waiting for completion..."
echo "  - dax2_R (PID: $PID_R)"
echo "  - dax2_L (PID: $PID_L)"
echo "  - settings_reset (PID: $PID_RESET)"
echo ""

# Wait for all builds to complete
EXIT_CODE=0
wait $PID_R || EXIT_CODE=$?
wait $PID_L || EXIT_CODE=$?
wait $PID_RESET || EXIT_CODE=$?

# Check if any build failed
if [ $EXIT_CODE -ne 0 ]; then
  echo ""
  echo "ERROR: One or more builds failed. Check logs:"
  echo "  - /tmp/build-dax2_R.log"
  echo "  - /tmp/build-dax2_L.log"
  echo "  - /tmp/build-settings_reset.log"
  exit $EXIT_CODE
fi

echo ""
echo "All builds completed successfully!"

# Copy UF2 files to build root for easier access
echo "Copying UF2 files..."
cp build/dax2_R/zephyr/zmk.uf2 build/dax2_R.uf2
cp build/dax2_L/zephyr/zmk.uf2 build/dax2_L.uf2
cp build/settings_reset/zephyr/zmk.uf2 build/settings_reset.uf2

echo ""
echo "Build artifacts:"
echo "  build/dax2_R.uf2"
echo "  build/dax2_L.uf2"
echo "  build/settings_reset.uf2"
