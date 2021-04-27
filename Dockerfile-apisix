FROM fj0rd/io:foundation

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 TIMEZONE=Asia/Shanghai

ARG openresty_repo=openresty/openresty
ARG nchan_repo=slact/nchan
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
  ; s6overlay_version=$(curl -sSL -H "'$github_header'" $github_api/${s6overlay_repo}/releases | jq -r '.[0].tag_name') \
  ; s6overlay_url=https://github.com/${s6overlay_repo}/releases/download/${s6overlay_version}/s6-overlay-amd64.tar.gz \
  ; curl --fail --silent -L ${s6overlay_url} \
    | tar xzvf - -C / \
  \
  ; OPENRESTY_VER=$(curl -sSL -H "'$github_header'" $github_api/${openresty_repo}/tags | jq -r '.[0].name' | cut -c 2-) \
  ; curl -sSL https://openresty.org/download/openresty-${OPENRESTY_VER}.tar.gz | tar -zxf - \
  ; NCHAN_VER=$(curl -sSL -H "'$github_header'" $github_api/${nchan_repo}/tags | jq -r '.[0].name' | cut -c 2-) \
  ; curl -sSL https://github.com/${nchan_repo}/archive/v${NCHAN_VER}.tar.gz | tar -zxf - \
  ; cd openresty-${OPENRESTY_VERSION} \
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
        --add-dynamic-module=../nchan-${NCHAN_VERSION} \
  ; make \
  ; make install \
  ; cd .. && rm -rf openresty-${OPENRESTY_VERSION} nchan-${NCHAN_VERSION} \
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
  ; luarocks install apisix \
  ; yq --inplace e '.etcd.host[0]="http://${{ETCD_HOST}}"|.etcd.host[] style="double"' /usr/local/apisix/conf/config.yaml \
  \
  ; apt-get -y remove ${BUILD_DEPS} \
  ; apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*


COPY services.as /etc/services.d
COPY nginx.d /etc/openresty
COPY reload-nginx /usr/local/bin
WORKDIR /srv

VOLUME [ "/srv" ]
EXPOSE 80 443

ENTRYPOINT [ "/init" ]

ENV WEB_SERVERNAME=
ENV WEB_ROOT=
