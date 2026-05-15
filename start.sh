#!/bin/bash

if [ -f /opt/cp2k_toolchain/install/setup ]; then
    source /opt/cp2k_toolchain/install/setup
fi

export LD_LIBRARY_PATH="/opt/cp2k/lib:$LD_LIBRARY_PATH"

exec "$@"

