FROM ubuntu:focal

ARG NVIM_VERSION
ARG nvim_url=https://github.com/neovim/neovim/releases/download/${NVIM_VERSION:-nightly}/nvim-linux64.tar.gz
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 TIMEZONE=Asia/Shanghai
ENV websocat_version=1.6.0
ENV just_version=0.8.3
ENV yq_version=4.2.1
ENV wasmtime_version=0.21.0
ENV watchexec_version=1.14.1
ENV s6overlay_version=2.1.0.2

ARG websocat_url=https://github.com/vi/websocat/releases/download/v${websocat_version}/websocat_amd64-linux-static
ARG s6overlay_url=https://github.com/just-containers/s6-overlay/releases/download/v${s6overlay_version}/s6-overlay-amd64.tar.gz
ARG just_url=https://github.com/casey/just/releases/download/v${just_version}/just-v${just_version}-x86_64-unknown-linux-musl.tar.gz
ARG yq_url=https://github.com/mikefarah/yq/releases/download/v${yq_version}/yq_linux_amd64
ARG wasmtime_url=https://github.com/bytecodealliance/wasmtime/releases/download/v${wasmtime_version}/wasmtime-v${wasmtime_version}-x86_64-linux.tar.xz
ARG watchexec_url=https://github.com/watchexec/watchexec/releases/download/${watchexec_version}/watchexec-${watchexec_version}-x86_64-unknown-linux-musl.tar.xz

ENV DEV_DEPS \
        zsh git mlocate jq ripgrep \
        python3 python3-pip python3-setuptools \
        gnupg openssh-server openssh-client \
        pwgen curl rsync wget tcpdump socat \
        sudo procps tree unzip xz-utils zstd \
        iproute2 net-tools inetutils-ping iptables

ENV PYTHONUNBUFFERED=x

RUN set -eux \
  ; apt-get update \
  ; apt-get upgrade -y \
  ; DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    tzdata \
    locales \
    $DEV_DEPS \
  \
  ; curl -sSL ${nvim_url} | tar zxf - -C /usr/local --strip-components=1 \
  ; curl -sL https://deb.nodesource.com/setup_14.x | bash - \
  ; apt-get install -y --no-install-recommends \
      nodejs python3-neovim \
  ; pip3 --no-cache-dir install neovim-remote \
  \
  ; sed -i 's/^.*\(%sudo.*\)ALL$/\1NOPASSWD:ALL/g' /etc/sudoers \
  ; ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime \
  ; echo "$TIMEZONE" > /etc/timezone \
  ; sed -i /etc/locale.gen \
    -e 's/# \(en_US.UTF-8 UTF-8\)/\1/' \
    -e 's/# \(zh_CN.UTF-8 UTF-8\)/\1/' \
  ; locale-gen \
  \
  ; mkdir -p /var/run/sshd \
  ; sed -i /etc/ssh/sshd_config \
        -e 's!.*\(AuthorizedKeysFile\).*!\1 /etc/authorized_keys/%u!' \
        -e 's!.*\(GatewayPorts\).*!\1 yes!' \
        -e 's!.*\(PasswordAuthentication\).*yes!\1 no!' \
  \
  ; wget -O - https://openresty.org/package/pubkey.gpg | apt-key add - \
  ; echo "deb http://openresty.org/package/ubuntu focal main" \
      | tee /etc/apt/sources.list.d/openresty.list \
  ; apt-get update \
  ; apt-get -y install --no-install-recommends openresty openresty-opm \
  ; opm install ledgetech/lua-resty-http \
  ; mkdir -p /etc/openresty/conf.d \
  \
  ; wget -q -O /usr/local/bin/websocat ${websocat_url} \
    ; chmod a+x /usr/local/bin/websocat \
  ; wget -q -O- ${just_url} \
      | tar zxf - -C /usr/local/bin just \
  ; wget -q -O /usr/local/bin/yq ${yq_url} \
      ; chmod +x /usr/local/bin/yq \
  ; wget -O- ${wasmtime_url} | tar Jxf - --strip-components=1 -C /usr/local/bin \
      wasmtime-v${wasmtime_version}-x86_64-linux/wasmtime \
  ; wget -q -O- ${watchexec_url} \
      | tar Jxf - --strip-components=1 -C /usr/local/bin watchexec-${watchexec_version}-x86_64-unknown-linux-musl/watchexec \
  \
  ; curl --fail --silent -L ${s6overlay_url} > /tmp/s6overlay.tar.gz \
  ; tar xzf /tmp/s6overlay.tar.gz -C / --exclude="./bin" \
  ; tar xzf /tmp/s6overlay.tar.gz -C /usr ./bin \
  ; rm -f /tmp/s6overlay.tar.gz \
  \
  ; apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# conf
RUN set -eux \
  ; mkdir /root/.zshrc.d \
  ; git clone --depth=1 https://github.com/murphil/.zshrc.d.git /root/.zshrc.d \
  ; mv /root/.zshrc.d/_zshrc /root/.zshrc \
  ; mkdir /root/.config \
  ; git clone --depth=1 https://github.com/murphil/nvim-coc.git /root/.config/nvim \
  ; NVIM_SETUP_PLUGINS=1 \
    nvim -u /root/.config/nvim/init.vim --headless +'PlugInstall' +qa \
  ; rm -rf /root/.config/nvim/plugged/*/.git \
  ; for x in $(cat /root/.config/nvim/coc-core-extensions) \
  ; do nvim -u /root/.config/nvim/init.vim --headless +"CocInstall -sync coc-$x" +qa; done \
  #; npm config set registry https://registry.npm.taobao.org \
  ; npm cache clean -f

COPY services.d /etc/services.d
COPY reload-nginx /usr/local/bin
COPY nginx.conf /etc/openresty
COPY nginx-site.conf /etc/openresty/conf.d/default.conf
WORKDIR /srv

VOLUME [ "/srv" ]
EXPOSE 80

ENTRYPOINT [ "/init" ]

ENV WEB_SERVERNAME=
ENV WEB_ROOT=
ENV WS_FIXED=
