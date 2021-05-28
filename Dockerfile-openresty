FROM fj0rd/io:foundation

ARG openresty_repo=openresty/openresty
ARG nchan_repo=slact/nchan
ARG inlets_repo=inlets/inlets
ARG frp_repo=fatedier/frp
ARG s6overlay_repo=just-containers/s6-overlay

ARG github_header="Accept: application/vnd.github.v3+json"
ARG github_api=https://api.github.com/repos

ENV DEV_DEPS \
        luarocks apache2-utils \
        libpcre3-dev libssl-dev \
        libpq-dev zlib1g-dev

ENV BUILD_DEPS software-properties-common build-essential

ENV PATH=/opt/openresty/bin:$PATH

RUN set -eux \
  ; apt-get update \
  ; apt-get upgrade -y \
  ; DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
    $DEV_DEPS \
    $BUILD_DEPS \
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
  ; s6overlay_ver=$(curl -sSL -H "'$github_header'" $github_api/${s6overlay_repo}/releases | jq -r '.[0].tag_name') \
  ; s6overlay_url=https://github.com/${s6overlay_repo}/releases/download/${s6overlay_ver}/s6-overlay-amd64.tar.gz \
  ; curl --fail --silent -L ${s6overlay_url} | tar xzvf - -C / \
  \
  ; OPENRESTY_VER=$(curl -sSL -H "'$github_header'" $github_api/${openresty_repo}/tags | jq -r '.[0].name' | cut -c 2-) \
  ; curl -sSL https://openresty.org/download/openresty-${OPENRESTY_VER}.tar.gz | tar -zxf - \
  ; NCHAN_VER=$(curl -sSL -H "'$github_header'" $github_api/${nchan_repo}/tags | jq -r '.[0].name' | cut -c 2-) \
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
  ; opm install ledgetech/lua-resty-http \
  ; opm install SkyLothar/lua-resty-jwt \
  #; opm install duhoobo/lua-resty-smtp \
  ; ln -fs /opt/openresty/nginx/conf /etc/openresty \
  ; mkdir -p /etc/openresty/conf.d \
  ; echo 'hash -d o="/etc/openresty"' >> /etc/skel/.ext.zsh \
  ; echo 'hash -d l="/opt/openresty/nginx/logs"' >> /etc/skel/.ext.zsh \
  \
  ; luarocks install lua-resty-auto-ssl \
  ; mkdir /etc/resty-auto-ssl \
  ; chown www-data /etc/resty-auto-ssl \
  ; openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj '/CN=sni-support-required-for-valid-ssl' \
        -keyout /etc/ssl/resty-auto-ssl-fallback.key \
        -out /etc/ssl/resty-auto-ssl-fallback.crt \
  \
  ; ln -sf /etc/skel/.config /root \
  ; ln -sf /etc/skel/.zshrc /root \
  ; ln -sf /etc/skel/.zshrc.d /root \
  \
  ; apt-get -y remove ${BUILD_DEPS} \
  ; apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

COPY services.o /etc/services.d
COPY config.o /etc/openresty
COPY reload-openresty /usr/local/bin
WORKDIR /srv

VOLUME [ "/srv" ]
EXPOSE 80 443

ENTRYPOINT [ "/init" ]

ENV WEB_SERVERNAME=
ENV WEB_ROOT=
ENV WS_FIXED=
