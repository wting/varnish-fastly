FROM ubuntu:14.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y curl
RUN curl -sfL https://repo.varnish-cache.org/source/varnish-2.1.5.tar.gz | tar xvz -C /tmp/

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

# Using Varnish v2.1.5 based on this Fastly blog post:
# https://www.fastly.com/blog/benefits-using-varnish
WORKDIR /tmp/varnish-2.1.5
COPY ./fix_automake_forwards_incompatibility.patch ./
RUN patch ./configure.ac < ./fix_automake_forwards_incompatibility.patch

# NOTE(wting|2016-09-09): We're vendorizing autogen.sh's contents here to make
# explicit what error code is being suppressed.
RUN aclocal
RUN libtoolize --copy --force
RUN autoheader
# NOTE(wting|2016-09-09): Suppressing a non-zero exit code because it's related to
# varnishtest and not easily fixable.
RUN automake --add-missing --copy --foreign; exit 0
RUN autoconf
RUN mkdir -vp /opt/varnish
RUN ./configure --prefix=/opt/varnish
# NOTE(wting|2016-09-09): This is to fix the @mkdir_p@ macro removed in newer
# versions of automake. Unfortunately AC_SUBST([mkdir_p], ['$(MKDIR_P)']) in
# aclocal.m4 is only partially applied, so we're manually changing missed
# macros via sed.
RUN find . -type f -name 'Makefile.in' -exec sed -i 's:$(mkdir_p):mkdir -vp:g' {} \;
RUN make -j4

RUN make install
RUN ldconfig
