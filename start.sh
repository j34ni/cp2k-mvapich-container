#!/bin/bash

. /opt/conda/etc/profile.d/conda.sh
conda activate base

if [ -f /opt/cp2k_deps/setup ]; then
    source /opt/cp2k_deps/setup
fi

export PATH="/opt/cp2k/bin:$PATH"

if [ $# -eq 0 ]; then
    /bin/bash
else
    exec "$@"
fi
