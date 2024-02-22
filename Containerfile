ARG ASTERISK_VERSION

FROM debian:11-slim as builder
ARG ASTERISK_VERSION
ENV ASTERISK_VERSION ${ASTERISK_VERSION}
RUN apt update && \
    apt upgrade && \
    apt install -y curl patch make gcc g++ libedit-dev uuid-dev libjansson-dev libxml2-dev libsqlite3-dev libpopt-dev libssl-dev libz-dev bzip2 && \
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
    make ${MAKEOPTS} install && \
    rm -rf /app/share /app/var/run && \
    chown -R 1000:1000 /app/etc/asterisk /app/var/lib/asterisk

FROM debian:11-slim
COPY --from=builder /app /app
RUN apt update && \
    apt upgrade && \
    apt install -y libxml2 sqlite3 libjansson4 libedit2 libpopt0 libsrtp2-1 openssl && \
    cp -rv /app/* / && \
    rm -rf /app && \
    mkdir -p /run/asterisk && \
    chown 1000:1000 /run/asterisk /var/lib/asterisk /var/cache/asterisk /var/spool/asterisk && \
    chmod 0750 /run/asterisk && \
    rm -rf /var/lib/apt/lists/* && \
    dpkg --remove --force-all apt dpkg

EXPOSE 5060
EXPOSE 5061

VOLUME /app/etc/asterisk
VOLUME /app/var/lib/asterisk

WORKDIR /app/var/lib/asterisk
USER 1000:1000
COPY --chown=0:0 --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["-c"]
