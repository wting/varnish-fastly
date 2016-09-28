#!/bin/bash
exec varnishd \
    -F \
    -f /etc/varnish/default.vcl \
    -n /etc/varnish \
    -s malloc,${VARNISH_MEMORY} \
    -a 0.0.0.0:${VARNISH_PORT} \
    ${VARNISH_OPTS}
