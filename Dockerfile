# This is a simple tool grown out of the simple fact that su and sudo have very strange and often
# annoying TTY and signal-forwarding behavior. They're also somewhat complex to setup and use
# (especially in the case of sudo), which allows for a great deal of expressivity, but falls flat
# if all you need is "run this specific application as this specific user and get out of the pipeline".

FROM unionpos/ubuntu:16.04

ENV GOSU_VERSION 1.11
ENV GOSU_KEY B42F6819007F00F88E364FD4036A9C25BF357DD4

# If you're diligent, you'll check this key against what's listed on
# https://github.com/tianon/gosu

RUN set -ex \
	&& buildDeps=' \
	wget \
	' \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends $buildDeps \
	&& dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
	&& wget -O /gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
	&& wget -O /gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& for server in $(shuf -e ha.pool.sks-keyservers.net \
	hkp://p80.pool.sks-keyservers.net:80 \
	keyserver.ubuntu.com \
	hkp://keyserver.ubuntu.com:80 \
	pgp.mit.edu) ; do \
	gpg --keyserver "$server" --recv-keys $GOSU_KEY && break || : ; \
	done \
	&& gpg --batch --verify /gosu.asc /gosu \
	&& chmod +x /gosu \
	&& /gosu nobody true \
	&& apt-get purge --auto-remove -y $buildDeps \
	&& rm -rf /var/lib/apt/lists/*

#  output an image which includes only the gosu binary
FROM scratch
COPY --from=0 /gosu /
