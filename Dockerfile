FROM debian:jessie

RUN sed -i 's/httpredir.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list && find /var/lib/apt -type f -exec rm {} \+ 

ENV MYSQL_VERSION=mysql-5.5.18 MYSQL_HOME=/usr/local/mysql PERCONA_XTRABACKUP_VERSION=percona-xtrabackup-2.2.13 PERCONA_XTRABACKUP_HOME=/usr/local/xtrabackup
ENV PATH $PATH:$MYSQL_HOME/bin:$PERCONA_XTRABACKUP_HOME/bin

#compile tool
ENV MYSQL_COMPILE_TOOL "wget gcc make cmake g++"
RUN apt-get update && apt-get install -y $MYSQL_COMPILE_TOOL --no-install-recommends --fix-missing
#runtime dep
RUN apt-get update && apt-get install -y libncurses5 --fix-missing
#compile dep
ENV MYSQL_COMPILE_DEP "libncurses5-dev"
RUN apt-get update && apt-get install -y $BACKUP_COMPILE_TOOL --no-install-recommends  --fix-missing
#runtime dep
RUN apt-get update && apt-get install -y libaio1 libncurses5 zlib1g libgcrypt20 libpod2-base-perl --fix-missing
#compile dep
ENV BACKUP_COMPILE_DEP "libaio-dev libncurses-dev zlib1g-dev libgcrypt11-dev"
RUN apt-get update && apt-get install -y $BACKUP_COMPILE_DEP --no-install-recommends --fix-missing

RUN cd /home && wget "http://cdn.mysql.com/archives/mysql-5.5/$MYSQL_VERSION.tar.gz" \
	&& apt-get update && apt-get install -y ca-certificates --fix-missing \
	&& wget "https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-2.2.13/source/tarball/$PERCONA_XTRABACKUP_VERSION.tar.gz" 

RUN cd /home && tar -xzf $MYSQL_VERSION.tar.gz && cd $MYSQL_VERSION \
        && cmake -DCMAKE_INSTALL_PREFIX=$MYSQL_HOME \
        -DEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci \
        -DSYSCONFDIR=$MYSQL_HOME/conf \
        && make -j"$(nproc)" && make install \
        && useradd mysql -M -s /usr/sbin/nologin
VOLUME ["/usr/local/mysql/conf","/usr/local/mysql/data"]

RUN cd /home && tar -xzf $PERCONA_XTRABACKUP_VERSION.tar.gz && cd $PERCONA_XTRABACKUP_VERSION \
	&& cmake -DBUILD_CONFIG=xtrabackup_release -DWITH_MAN_PAGES=OFF \
	&& make -j"$(nproc)" && make install

RUN apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
        -o APT::AutoRemove::SuggestsImportant=false \
        $BACKUP_COMPILE_TOOL $BACKUP_COMPILE_DEP $MYSQL_COMPILE_TOOL $MYSQL_COMPILE_DEP \
        && apt-get clean \
        && rm -rf /home/*          \
        && rm -rf /var/lib/apt/*
COPY mysql_start.sh /mysql_start.sh
COPY xtrabackup_start.sh /xtrabackup_start.sh
COPY mysql_client.sh /mysql_client.sh
EXPOSE 3306
CMD        ["/mysql_start.sh"]
