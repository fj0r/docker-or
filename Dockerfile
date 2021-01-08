FROM ubuntu:focal

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 TIMEZONE=Asia/Shanghai

ARG nvim_repo=neovim/neovim
ARG wasmtime_repo=bytecodealliance/wasmtime
ARG just_repo=casey/just
ARG watchexec_repo=watchexec/watchexec
ARG yq_repo=mikefarah/yq
ARG websocat_repo=vi/websocat
ARG pup_repo=ericchiang/pup
ARG s6overlay_repo=just-containers/s6-overlay

ARG github_header="Accept: application/vnd.github.v3+json"
ARG github_api=https://api.github.com/repos

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
  ; curl -sL https://deb.nodesource.com/setup_14.x | bash - \
  ; apt-get install -y --no-install-recommends nodejs \
  \
  ; nvim_version=$(curl -sSL -H $github_header $github_api/${nvim_repo}/releases | jq -r '.[0].tag_name') \
  ; nvim_url=https://github.com/${nvim_repo}/releases/download/${nvim_version}/nvim-linux64.tar.gz \
  ; curl -sSL ${nvim_url} | tar zxf - -C /usr/local --strip-components=1 \
  ; pip3 --no-cache-dir install neovim neovim-remote \
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
  ; just_version=$(curl -sSL -H $github_header $github_api/${just_repo}/releases | jq -r '.[0].tag_name') \
  ; just_url=https://github.com/${just_repo}/releases/download/${just_version}/just-${just_version}-x86_64-unknown-linux-musl.tar.gz \
  ; wget -q -O- ${just_url} \
    | tar zxf - -C /usr/local/bin just \
  ; watchexec_version=$(curl -sSL -H $github_header $github_api/${watchexec_repo}/releases | jq -r '.[0].tag_name') \
  ; watchexec_url=https://github.com/${watchexec_repo}/releases/download/${watchexec_version}/watchexec-${watchexec_version}-x86_64-unknown-linux-musl.tar.xz \
  ; wget -q -O- ${watchexec_url} \
    | tar Jxf - --strip-components=1 -C /usr/local/bin watchexec-${watchexec_version}-x86_64-unknown-linux-musl/watchexec \
  ; yq_version=$(curl -sSL -H $github_header $github_api/${yq_repo}/releases | jq -r '.[0].tag_name') \
  ; yq_url=https://github.com/${yq_repo}/releases/download/${yq_version}/yq_linux_amd64 \
  ; wget -q -O /usr/local/bin/yq ${yq_url} \
    ; chmod +x /usr/local/bin/yq \
  ; websocat_version=$(curl -sSL -H $github_header $github_api/${websocat_repo}/releases | jq -r '.[0].tag_name') \
  ; websocat_url=https://github.com/${websocat_repo}/releases/download/${websocat_version}/websocat_amd64-linux-static \
  ; wget -q -O /usr/local/bin/websocat ${websocat_url} \
    ; chmod +x /usr/local/bin/websocat \
  ; wasmtime_version=$(curl -sSL -H $github_header $github_api/${wasmtime_repo}/releases | jq -r '[.[]|select(.prerelease == false)][0].tag_name') \
  ; wasmtime_url=https://github.com/${wasmtime_repo}/releases/download/${wasmtime_version}/wasmtime-${wasmtime_version}-x86_64-linux.tar.xz \
  ; wget -O- ${wasmtime_url} | tar Jxf - --strip-components=1 -C /usr/local/bin \
    wasmtime-${wasmtime_version}-x86_64-linux/wasmtime \
  ; pup_version=$(curl -sSL -H $github_header $github_api/${pup_repo}/releases | jq -r '.[0].tag_name') \
  ; pup_url=https://github.com/${pup_repo}/releases/download/${pup_version}/pup_${pup_version}_linux_amd64.zip \
  ; wget -O pup.zip ${pup_url} && unzip pup.zip && rm -f pup.zip && chmod +x pup && mv pup /usr/local/bin/ \
  \
  ; s6overlay_version=$(curl -sSL -H $github_header $github_api/${s6overlay_repo}/releases | jq -r '.[0].tag_name') \
  ; s6overlay_url=https://github.com/${s6overlay_repo}/releases/download/${s6overlay_version}/s6-overlay-amd64.tar.gz \
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
