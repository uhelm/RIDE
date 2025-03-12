#!/bin/bash

cp /etc/nginx/default_200.conf /etc/nginx/conf.d/default.conf
nginx -g 'daemon off;' &
bash /lbcheck.sh