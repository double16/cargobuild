FROM ubuntu:24.04 AS cargobuild
ONBUILD ARG TARGETARCH
ONBUILD ENV TARGETARCH=$TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive
USER root
COPY apt_proxy_configure.sh apt_proxy_clean.sh /usr/local/sbin
ONBUILD RUN bash /usr/local/sbin/apt_proxy_configure.sh
RUN <<EOF
/usr/local/sbin/apt_proxy_configure.sh
apt-get update && apt-get install -y build-essential curl gcc-x86-64-linux-gnu gcc-aarch64-linux-gnu
/usr/local/sbin/apt_proxy_clean.sh
EOF
RUN curl -sSf -o /root/rustup.sh https://sh.rustup.rs && bash /root/rustup.sh -y -t x86_64-unknown-linux-gnu,aarch64-unknown-linux-gnu
COPY <<EOF /root/.cargo/config.toml
[target.x86_64-unknown-linux-gnu]
    linker = "x86_64-linux-gnu-gcc"
[target.aarch64-unknown-linux-gnu]
    linker = "aarch64-linux-gnu-gcc"
EOF
ONBUILD RUN <<EOF
#!/usr/bin/env bash
if [[ "${TARGETARCH}" == "arm64" ]]; then
    TARGET="aarch64-unknown-linux-gnu"
elif [[ "${TARGETARCH}" == "amd64" ]]; then
    TARGET="x86_64-unknown-linux-gnu"
else
    TARGET="${TARGETARCH}-unknown-linux-gnu"
fi
echo "TARGET=${TARGET}" >> /etc/environment
EOF
