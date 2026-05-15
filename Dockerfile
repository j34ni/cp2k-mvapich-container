FROM ubuntu:22.04

ENV TZ="Europe/Paris"
ENV PATH="/opt/conda/bin:$PATH"

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates tzdata wget git build-essential && \
    rm -rf /var/lib/apt/lists/*

RUN wget -q -nc --no-check-certificate -P /var/tmp https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh && \
    bash /var/tmp/Miniforge3-Linux-x86_64.sh -b -p /opt/conda && \
    rm /var/tmp/Miniforge3-Linux-x86_64.sh

RUN . /opt/conda/etc/profile.d/conda.sh && \
    mamba install -y python=3.11 cmake gcc_linux-64=13 gxx_linux-64=13 gfortran_linux-64=13 make mvapich=4.1 pkg-config zlib && \
    conda clean -afy

RUN ln -s /opt/conda/lib /opt/conda/lib64 && \
    ln -s /opt/conda/bin/x86_64-conda-linux-gnu-gcc /opt/conda/bin/gcc && \
    ln -s /opt/conda/bin/x86_64-conda-linux-gnu-g++ /opt/conda/bin/g++ && \
    ln -s /opt/conda/bin/x86_64-conda-linux-gnu-gfortran /opt/conda/bin/gfortran && \
    ln -s /opt/conda/bin/x86_64-conda-linux-gnu-ar /opt/conda/bin/ar && \
    ln -s /opt/conda/bin/x86_64-conda-linux-gnu-ranlib /opt/conda/bin/ranlib

RUN wget -q -nc --no-check-certificate -P /var/tmp https://github.com/cp2k/cp2k/archive/refs/tags/v2026.1.tar.gz && \
    tar -xf /var/tmp/v2026.1.tar.gz -C /var/tmp && \
    mkdir -p /opt/cp2k_toolchain && \
    cp -r /var/tmp/cp2k-2026.1/tools/toolchain/* /opt/cp2k_toolchain/ && \
    cd /opt/cp2k_toolchain && \
    bash ./install_cp2k_toolchain.sh \
         --mpi-mode=mpich \
         --with-cosma=install \
         --with-elpa=install \
         --with-fftw=install \
         --with-gcc=/opt/conda \
         --with-libint=install \
         --with-libxc=install \
         --with-mpich=/opt/conda \
         --with-openblas=install \
         --with-scalapack=install \
         -j $(nproc) && \
    /bin/bash -c "source install/setup && \
    cd /var/tmp/cp2k-2026.1 && \
    cmake -S . -B build \
          -DCMAKE_PREFIX_PATH="/opt/cp2k_toolchain/install;/opt/conda" \
          -DCP2K_USE_COSMA=ON \
          -DCP2K_USE_ELPA=ON \
          -DCP2K_USE_EVERYTHING=OFF \
          -DCP2K_USE_FFTW3=ON \
          -DCP2K_USE_LIBINT=ON \
          -DCP2K_USE_LIBXC=ON \
          -DCP2K_USE_MPI=ON \
          -DCP2K_USE_OPENMP=ON \
          -DCP2K_USE_SCALAPACK=ON \
          -DCMAKE_INSTALL_PREFIX=/opt/cp2k && \
    cmake --build build -j $(nproc) && \
    cmake --install build && \
    rm -rf /var/tmp/cp2k-2026.1 /var/tmp/v2026.1.tar.gz

ENV LD_LIBRARY_PATH="/opt/cp2k/lib:/opt/cp2k_toolchain/install/openblas-0.3.30/lib:${LD_LIBRARY_PATH}"

COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh
CMD ["/opt/start.sh"]
