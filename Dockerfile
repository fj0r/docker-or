FROM debian:testing-slim

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 TIMEZONE=Asia/Shanghai

ARG openresty_repo=openresty/openresty
ARG nchan_repo=slact/nchan
ARG nvim_repo=neovim/neovim
ARG wasmtime_repo=bytecodealliance/wasmtime
ARG just_repo=casey/just
ARG watchexec_repo=watchexec/watchexec
ARG yq_repo=mikefarah/yq
ARG websocat_repo=vi/websocat
ARG inlets_repo=inlets/inlets
ARG frp_repo=fatedier/frp
ARG pup_repo=ericchiang/pup
ARG rg_repo=BurntSushi/ripgrep
ARG s6overlay_repo=just-containers/s6-overlay

ARG github_header="Accept: application/vnd.github.v3+json"
ARG github_api=https://api.github.com/repos

ENV DEV_DEPS \
        zsh git jq luarocks \
        python3 python3-pip python3-setuptools \
        openssh-server openssh-client apache2-utils \
        pwgen curl rsync tcpdump socat \
        sudo htop procps tree zip unzip xz-utils zstd \
        iproute2 inetutils-ping nftables \
        libpcre3-dev libssl-dev libpq-dev zlib1g-dev

ENV BUILD_DEPS software-properties-common build-essential

ENV PATH=/opt/openresty/bin:$PATH
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
    $BUILD_DEPS \
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
  ; curl -sL https://deb.nodesource.com/setup_14.x | bash - \
  ; apt-get install -y --no-install-recommends nodejs \
  \
  ; nvim_ver=$(curl -sSL -H "'$github_header'" $github_api/${nvim_repo}/releases | jq -r '.[0].tag_name') \
  ; nvim_url=https://github.com/${nvim_repo}/releases/download/${nvim_ver}/nvim-linux64.tar.gz \
  ; curl -sSL ${nvim_url} | tar zxf - -C /usr/local --strip-components=1 \
  ; pip3 --no-cache-dir install neovim neovim-remote invoke \
  \
  ; rg_ver=$(curl -sSL -H "'$github_header'" $github_api/${rg_repo}/releases | jq -r '.[0].tag_name') \
  ; rg_url=https://github.com/${rg_repo}/releases/download/${rg_ver}/ripgrep-${rg_ver}-x86_64-unknown-linux-musl.tar.gz \
  ; curl -sSL ${rg_url} | tar zxf - -C /usr/local/bin --strip-components=1 ripgrep-${rg_ver}-x86_64-unknown-linux-musl/rg \
  \
  ; just_ver=$(curl -sSL -H "'$github_header'" $github_api/${just_repo}/releases | jq -r '.[0].tag_name') \
  ; just_url=https://github.com/${just_repo}/releases/download/${just_ver}/just-${just_ver}-x86_64-unknown-linux-musl.tar.gz \
  ; curl -sSL ${just_url} | tar zxf - -C /usr/local/bin just \
  \
  ; watchexec_ver=$(curl -sSL -H "'$github_header'" $github_api/${watchexec_repo}/releases | jq -r '.[0].tag_name') \
  ; watchexec_url=https://github.com/${watchexec_repo}/releases/download/${watchexec_ver}/watchexec-${watchexec_ver}-x86_64-unknown-linux-musl.tar.xz \
  ; curl -sSL ${watchexec_url} | tar Jxf - --strip-components=1 -C /usr/local/bin watchexec-${watchexec_ver}-x86_64-unknown-linux-musl/watchexec \
  \
  ; yq_ver=$(curl -sSL -H "'$github_header'" $github_api/${yq_repo}/releases | jq -r '.[0].tag_name') \
  ; yq_url=https://github.com/${yq_repo}/releases/download/${yq_ver}/yq_linux_amd64 \
  ; curl -sSLo /usr/local/bin/yq ${yq_url} ; chmod +x /usr/local/bin/yq \
  \
  #; frp_ver=$(curl -sSL -H "'$github_header'" $github_api/${frp_repo}/releases | jq -r '.[0].tag_name' | cut -c 2-) \
  #; frp_url=https://github.com/${frp_repo}/releases/download/v0.36.2/frp_0.36.2_linux_amd64.tar.gz \
  #; curl -sSL ${frp_url} | tar zxf - --strip-components=1 -C /usr/local/bin frp_${frp_ver}_linux_amd64/frps -C /etc frp_${frp_ver}_linux_amd64/frps.ini \
  #; echo 'token = secret' >> /etc/frps.ini \
  \
  ; inlets_ver=$(curl -sSL -H "'$github_header'" $github_api/${inlets_repo}/releases | jq -r '.[0].tag_name') \
  ; inlets_url=https://github.com/inlets/inlets/releases/download/${inlets_ver}/inlets \
  ; curl -sSLo /usr/local/bin/inlets ${inlets_url} ; chmod +x /usr/local/bin/inlets \
  \
  ; websocat_ver=$(curl -sSL -H "'$github_header'" $github_api/${websocat_repo}/releases | jq -r '.[0].tag_name') \
  ; websocat_url=https://github.com/${websocat_repo}/releases/download/${websocat_ver}/websocat_amd64-linux-static \
  ; curl -sSLo /usr/local/bin/websocat ${websocat_url} ; chmod +x /usr/local/bin/websocat \
  \
  ; pup_ver=$(curl -sSL -H "'$github_header'" $github_api/${pup_repo}/releases | jq -r '.[0].tag_name') \
  ; pup_url=https://github.com/${pup_repo}/releases/download/${pup_ver}/pup_${pup_ver}_linux_amd64.zip \
  ; curl -sSLo pup.zip ${pup_url} && unzip pup.zip && rm -f pup.zip && chmod +x pup && mv pup /usr/local/bin/ \
  \
  ; wasmtime_ver=$(curl -sSL -H "'$github_header'" $github_api/${wasmtime_repo}/releases | jq -r '[.[]|select(.prerelease == false)][0].tag_name') \
  ; wasmtime_url=https://github.com/${wasmtime_repo}/releases/download/${wasmtime_ver}/wasmtime-${wasmtime_ver}-x86_64-linux.tar.xz \
  ; curl -sSL ${wasmtime_url} | tar Jxf - --strip-components=1 -C /usr/local/bin wasmtime-${wasmtime_ver}-x86_64-linux/wasmtime \
  \
  ; s6overlay_ver=$(curl -sSL -H "'$github_header'" $github_api/${s6overlay_repo}/releases | jq -r '.[0].tag_name') \
  ; s6overlay_url=https://github.com/${s6overlay_repo}/releases/download/${s6overlay_ver}/s6-overlay-amd64.tar.gz \
  ; curl --fail --silent -L ${s6overlay_url} \
    | tar xzvf - -C / \
  \
  ; OPENRESTY_VER=$(curl -sSL -H "'$github_header'" $github_api/${openresty_repo}/releases | jq -r '.[0].tag_name' | cut -c 2-) \
  ; OPENRESTY_VER=1.19.3.1 \
  ; curl -sSL https://openresty.org/download/openresty-${OPENRESTY_VER}.tar.gz | tar -zxf - \
  ; NCHAN_VER=$(curl -sSL -H "'$github_header'" $github_api/${nchan_repo}/releases | jq -r '.[0].tag_name' | cut -c 2-) \
  ; NCHAN_VER=1.2.8 \
  ; curl -sSL https://github.com/${nchan_repo}/archive/v${NCHAN_VER}.tar.gz | tar -zxf - \
  ; cd openresty-${OPENRESTY_VER} \
  ; ./configure --prefix=/opt/openresty \
        --with-luajit \
        --with-http_v2_module \
        --with-http_auth_request_module \
        --with-http_addition_module \
        --with-http_gzip_static_module \
        --with-http_random_index_module \
        --with-http_iconv_module \
        --with-http_slice_module \
        --with-http_sub_module \
        --with-http_stub_status_module \
        --with-http_realip_module \
        --with-stream_realip_module \
        --with-http_postgres_module \
        --add-dynamic-module=../nchan-${NCHAN_VER} \
  ; make \
  ; make install \
  ; cd .. && rm -rf openresty-${OPENRESTY_VER} nchan-${NCHAN_VER}  \
  ; rm -rf nchan-master nchan.zip \
  ; opm install ledgetech/lua-resty-http \
  ; opm install SkyLothar/lua-resty-jwt \
  #; opm install duhoobo/lua-resty-smtp \
  ; ln -fs /opt/openresty/nginx/conf /etc/openresty \
  ; mkdir -p /etc/openresty/conf.d \
  \
  ; luarocks install lua-resty-auto-ssl \
  ; mkdir /etc/resty-auto-ssl \
  ; chown www-data /etc/resty-auto-ssl \
  ; openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj '/CN=sni-support-required-for-valid-ssl' \
        -keyout /etc/ssl/resty-auto-ssl-fallback.key \
        -out /etc/ssl/resty-auto-ssl-fallback.crt \
  \
  ; apt-get -y remove ${BUILD_DEPS} \
  ; apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# conf
RUN set -eux \
  ; cfg_home=/root \
  ; mkdir $cfg_home/.zshrc.d \
  ; git clone --depth=1 https://github.com/murphil/.zshrc.d.git $cfg_home/.zshrc.d \
  ; cp $cfg_home/.zshrc.d/_zshrc $cfg_home/.zshrc \
  ; mkdir $cfg_home/.config \
  ; nvim_home=$cfg_home/.config/nvim \
  ; git clone --depth=1 https://github.com/murphil/nvim-coc.git $nvim_home \
  ; NVIM_SETUP_PLUGINS=1 \
    nvim -u $nvim_home/init.vim --headless +'PlugInstall' +qa \
  ; rm -rf $nvim_home/plugged/*/.git \
  ; for x in $(cat $nvim_home/coc-core-extensions) \
  ; do nvim -u $nvim_home/init.vim --headless +"CocInstall -sync coc-$x" +qa; done \
  ; mkdir -p /opt/vim \
  ; mv $nvim_home/coc-data /opt/vim && chmod -R 777 /opt/vim/coc-data \
  ; ln -sf /opt/vim/coc-data $nvim_home \
  ; mv $nvim_home/plugged /opt/vim \
  ; ln -sf /opt/vim/plugged $nvim_home \
  ; coc_lua_bin_repo=josa42/coc-lua-binaries \
  ; lua_ls_ver=$(curl -sSL -H "'$github_header'" $github_api/${coc_lua_bin_repo}/releases | jq -r '.[0].tag_name') \
  ; lua_ls_url=https://github.com/${coc_lua_bin_repo}/releases/download/${lua_ls_ver}/lua-language-server-linux.tar.gz \
  ; lua_coc_data=$nvim_home/coc-data/extensions/coc-lua-data \
  ; mkdir -p $lua_coc_data \
  ; curl -sSL ${lua_ls_url} | tar zxf - -C $lua_coc_data \
  #; npm config set registry https://registry.npm.taobao.org \
  ; npm cache clean -f

COPY services.d /etc/services.d
COPY conf.d /etc/openresty/conf.d
COPY nginx.d /etc/openresty
COPY reload-nginx /usr/local/bin
WORKDIR /srv

VOLUME [ "/srv" ]
EXPOSE 80 443

ENTRYPOINT [ "/init" ]

ENV WEB_SERVERNAME=
ENV WEB_ROOT=
ENV WS_FIXED=
