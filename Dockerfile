FROM ubuntu:14.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y curl

# Using Varnish v2.1.5 based on this Fastly blog post:
# https://www.fastly.com/blog/benefits-using-varnish
ENV VARNISH_VERSION=2.1.5
ENV VARNISH_SHA256SUM=2d8049be14ada035d0e3a54c2b519143af40d03d917763cf72d53d8188e5ef83
RUN curl -sfL https://repo.varnish-cache.org/source/varnish-${VARNISH_VERSION}.tar.gz -o /tmp/varnish.tar.gz

# Varnish dependencies
RUN apt-get install -y \
	patch \
	automake \
	libtool \
	pkg-config \
	libpcre3-dev \
	make \
	libncurses-dev \
	xsltproc \
	groff-base \
	python-docutils \
	subversion

WORKDIR /tmp
RUN echo "${VARNISH_SHA256SUM} varnish.tar.gz" | sha256sum -c -
RUN tar xzf varnish.tar.gz

WORKDIR /tmp/varnish-${VARNISH_VERSION}
COPY ./fix_automake_forwards_incompatibility.patch ./
RUN patch ./configure.ac < ./fix_automake_forwards_incompatibility.patch

# NOTE(wting|2016-09-09): We're duplicating autogen.sh's contents here to make
# explicit what error code is being suppressed.
RUN aclocal
RUN libtoolize --copy --force
RUN autoheader
# NOTE(wting|2016-09-09): Suppressing a non-zero exit code because it's related to
# varnishtest and not easily fixable.
RUN automake --add-missing --copy --foreign; exit 0
RUN autoconf
# By default it installs to /usr/local
RUN ./configure --prefix=/

# NOTE(wting|2016-09-09): This is to fix the @mkdir_p@ macro removed in newer
# versions of automake. Unfortunately AC_SUBST([mkdir_p], ['$(MKDIR_P)']) in
# aclocal.m4 is only partially applied, so we're manually changing missed
# macros via sed.
RUN find . -type f -name 'Makefile.in' -exec sed -i 's:$(mkdir_p):mkdir -vp:g' {} \;

RUN make -j4
RUN make install
RUN ldconfig
