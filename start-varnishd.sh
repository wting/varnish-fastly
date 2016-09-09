#!/bin/bash
exec varnishd \
    -F \
    -f /etc/varnish/default.vcl \
    -s malloc,${VARNISH_MEMORY} \
    -a 0.0.0.0:${VARNISH_PORT} \
    ${VARNISH_OPTS}
