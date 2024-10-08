ARG ASTERISK_VERSION

FROM debian:11-slim as builder
ARG ASTERISK_VERSION
ENV ASTERISK_VERSION=${ASTERISK_VERSION:-20.9.0}
RUN apt update && \
    apt upgrade -y && \
    apt install -y \
        curl \
        patch \
        make \
        gcc \
        g++ \
        bzip2 \
        libedit-dev \
        libjansson-dev \
        liblua5.4-dev \
        libpopt-dev \
        libsqlite3-dev \
        libsrtp2-dev \
        libssl-dev \
        libxml2-dev \
        libz-dev \
        lua5.4 \
        uuid-dev && \
    curl -L https://github.com/asterisk/asterisk/releases/download/${ASTERISK_VERSION}/asterisk-${ASTERISK_VERSION}.tar.gz \
        -o asterisk.tar.gz && \
    curl -L https://raw.githubusercontent.com/usecallmanagernz/patches/master/asterisk/cisco-usecallmanager-${ASTERISK_VERSION}.patch \
        -o cisco-usecallmanager.patch && \
    tar xvf asterisk.tar.gz && \
    cd asterisk-${ASTERISK_VERSION} && \
    patch -p1 <../cisco-usecallmanager.patch && \
    ./configure \
        --libdir=/usr/lib \
        --localstatedir=/var \
        --with-crypto \
        --with-gsm=internal \
        --with-popt \
        --with-z \
        --with-libedit \
        --with-ssl \
        --with-pjproject \
        --disable-xmldoc && \
    export MAKEOPTS=" \
        NOISY_BUILD=yes \
        ASTDBDIR=\$(ASTDATADIR)/astdb \
        ASTVARRUNDIR=/run/asterisk \
        ASTCACHEDIR=/var/cache/asterisk \
        OPTIMIZE= \
        DEBUG= \
        DESTDIR=/app \
        CONFIG_SRC=configs/samples \
        CONFIG_EXTEN=.sample \
        AST_FORTIFY_SOURCE= \
    " && \
    export CFLAGS=" \
        -DENABLE_SRTP_AES_GCM \
        -DENABLE_SRTP_AES_256 \
    " && \
    make ${MAKEOPTS} menuselect.makeopts && \
    menuselect/menuselect --disable astdb2sqlite3 menuselect.makeopts && \
    menuselect/menuselect --disable astdb2bdb menuselect.makeopts && \
    menuselect/menuselect --disable build_native menuselect.makeopts && \
    menuselect/menuselect --disable chan_ooh323 menuselect.makeopts && \
    menuselect/menuselect --enable smsq menuselect.makeopts && \
    menuselect/menuselect --enable streamplayer menuselect.makeopts && \
    menuselect/menuselect --enable aelparse menuselect.makeopts && \
    menuselect/menuselect --enable astman menuselect.makeopts && \
    menuselect/menuselect --enable chan_mgcp menuselect.makeopts && \
    menuselect/menuselect --enable res_pktccops menuselect.makeopts && \
    menuselect/menuselect --enable pbx_dundi menuselect.makeopts && \
    menuselect/menuselect --enable func_aes menuselect.makeopts && \
    menuselect/menuselect --enable chan_iax2 menuselect.makeopts && \
    menuselect/menuselect --enable cdr_sqlite3_custom menuselect.makeopts && \
    menuselect/menuselect --enable cel_sqlite3_custom menuselect.makeopts && \
    menuselect/menuselect --disable astdb2bdb menuselect.makeopts && \
    menuselect/menuselect --enable app_macro menuselect.makeopts && \
    menuselect/menuselect --enable chan_sip menuselect.makeopts && \
    menuselect/menuselect --enable res_monitor menuselect.makeopts && \
    menuselect/menuselect --enable pbx_lua menuselect.makeopts && \
    make ${MAKEOPTS} install && \
    rm -rf /app/share /app/var/run && \
    chown -R 1000:1000 /app/etc/asterisk /app/var/lib/asterisk

FROM debian:11-slim
COPY --from=builder /app /app
RUN apt update && \
    apt upgrade -y && \
    apt install -y \
        curl \
        libedit2 \
        libjansson4 \
        liblua5.4-0 \
        libpopt0 \
        libsrtp2-1 \
        libxml2 \
        libxslt1.1 \
        lua5.4 \
        openssl \
        sqlite3 && \
    cp -rv /app/* / && \
    rm -rf /app && \
    mkdir -p /run/asterisk && \
    chown 1000:1000 /run/asterisk /var/lib/asterisk /var/cache/asterisk /var/spool/asterisk && \
    chmod 0750 /run/asterisk && \
    mv /var/lib/asterisk /var/lib/.asterisk && \
    mv /var/log/asterisk /var/log/.asterisk && \
    sed -e 's/^MinProtocol = TLSv1\.2/MinProtocol = TLSv1.0/' \
        -e 's/^CipherString = DEFAULT@SECLEVEL=2/CipherString = DEFAULT@SECLEVEL=1/' \
        -i /etc/ssl/openssl.cnf && \
    rm -rf /var/lib/apt/lists/* && \
    dpkg --remove --force-all apt dpkg

EXPOSE 5060
EXPOSE 5061

VOLUME /etc/asterisk
VOLUME /var/lib/asterisk

WORKDIR /var/lib/asterisk
USER 1000:1000
COPY --chown=0:0 --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["-c"]
