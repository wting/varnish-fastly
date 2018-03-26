FROM ubuntu:14.04
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		curl \
		ca-certificates \
		patch \
		# Varnish dependencies
		automake \
		groff-base \
		libtool \
		pkg-config \
		libpcre3-dev \
		libncurses-dev \
		make \
		python-docutils \
		subversion \
		xsltproc

# Using Varnish v2.1.5 based on this Fastly blog post:
# https://www.fastly.com/blog/benefits-using-varnish
ENV VARNISH_VERSION=2.1.5
ENV VARNISH_SHA256SUM=2d8049be14ada035d0e3a54c2b519143af40d03d917763cf72d53d8188e5ef83
RUN curl -sfL https://varnish-cache.org/_downloads/varnish-2.1.5.tgz -o /tmp/varnish.tgz
WORKDIR /tmp
RUN echo "${VARNISH_SHA256SUM} varnish.tgz" | sha256sum -c - \
	&& tar xzf varnish.tgz
WORKDIR /tmp/varnish-${VARNISH_VERSION}
COPY ./fix_automake_forwards_incompatibility.patch ./
RUN patch ./configure.ac < ./fix_automake_forwards_incompatibility.patch

# NOTE(wting|2016-09-09): Suppressing a non-zero exit code from automake because
# it's related to varnishtest/Makefile.am using $(srcdir) and not quickly fixable.
RUN ./autogen.sh; exit 0
# By default it installs to /usr/local
RUN ./configure --prefix=/
# NOTE(wting|2016-09-09): This is to fix the @mkdir_p@ macro removed in newer
# versions of automake. Unfortunately AC_SUBST([mkdir_p], ['$(MKDIR_P)']) in
# aclocal.m4 is only partially applied, so we're manually changing missed
# macros via sed.
RUN find . -type f -name 'Makefile.in' -exec sed -i 's:$(mkdir_p):mkdir -vp:g' {} \; \
	&& make -j4 \
	&& make install \
	&& ldconfig

COPY start-varnishd.sh /usr/local/bin/start-varnishd
ENV VARNISH_PORT 80
ENV VARNISH_MEMORY 100m
ENV VARNISH_OPTS ''

EXPOSE 80
CMD ["start-varnishd"]

ONBUILD COPY default.vcl /etc/varnish/default.vcl
