# Varnish-Fastly

This is a port of Varnish v2.1.5 to Ubuntu 14.04. Varnish v2.1.5 was chosen
to maintain VCL compatibility with Fastly ([docs](https://docs.fastly.com/guides/vcl/guide-to-vcl)).

For newer versions of Varnish, [newsdev/docker-varnish](https://github.com/newsdev/docker-varnish)
is recommended.

## What is Varnish?

[Varnish Cache](https://www.varnish-cache.org/) is a web application
accelerator also known as a caching HTTP reverse proxy. You install it in front
of any server that speaks HTTP and configure it to cache the contents. Varnish
Cache is really, really fast. It typically speeds up delivery with a factor of
300 - 1000x, depending on your architecture.

> [wikipedia.org/wiki/Varnish_(software)](https://en.wikipedia.org/wiki/Varnish_(software))

## How to use this image.

This image is intended as a base image for other images to built on.

### Create a `Dockerfile` in your Varnish project

```dockerfile
FROM wting/varnish-fastly
```

### Create a `default.vcl` in your Varnish project

```vcl
vcl 2.1.5;

backend default {
    .host = "www.reddit.com";
    .port = "80";
}
```

Then, run the commands to build and run the Docker image:

```console
$ docker build -t my-varnish .
$ docker run -it --rm --name my-running-varnish my-varnish
```

### Customize configuration

You can override the port Varnish serves in your Dockerfile.

```dockerfile
FROM wting/varnish-fastly

ENV VARNISH_PORT 8080
ENV VARNISH_OPTS "additional varnish options here"
EXPOSE 8080
```

For valid VARNISH_OPTS, see the [varnish options
documentation](https://www.varnish-cache.org/docs/2.1/reference/varnishd.html#options).

You can override the size of the cache.

```dockerfile
FROM wting/varnish-fastly

ENV VARNISH_MEMORY 1G
```

## How to install VMODs (Varnish Modules)

[Varnish Modules](https://www.varnish-cache.org/vmods) are extensions written for Varnish Cache.

To install Varnish Modules, you will need the Varnish source to compile
against. This is why we install Varnish from source in this image rather than
using a package manager.

Install VMODs in your Varnish project's Dockerfile. For example, to install the
Querystring module:

```dockerfile
FROM wting/varnish-fastly

# Install Querystring Varnish module
ENV QUERYSTRING_VERSION=0.3
RUN \
  cd /usr/local/src/ && \
  curl -sfL https://github.com/Dridi/libvmod-querystring/archive/v$QUERYSTRING_VERSION.tar.gz -o libvmod-querystring-$QUERYSTRING_VERSION.tar.gz && \
  tar -xzf libvmod-querystring-$QUERYSTRING_VERSION.tar.gz && \
  cd libvmod-querystring-$QUERYSTRING_VERSION && \
  ./autogen.sh && \
  ./configure VARNISHSRC=/usr/local/src/varnish-$VARNISH_VERSION && \
  make install && \
  rm -r ../libvmod-querystring-$QUERYSTRING_VERSION*
```

# License

BSD 3-clause. Visit `LICENSE` for more information.

# Supported Docker versions

This image is supported on Docker version 1.11.2.

Support for older versions (down to 1.6) is provided on a best-effort basis.

Please see [the Docker installation
documentation](https://docs.docker.com/installation/) for details on how to
upgrade your Docker daemon.

## Issues

If you have any problems with or questions about this image, please contact us
through a [GitHub issue](https://github.com/wting/varnish-fastly/issues).

## Contributing

You are invited to contribute new features, fixes, or updates, large or small;
we are always thrilled to receive pull requests, and do our best to process
them as fast as we can.
