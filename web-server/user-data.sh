#!/bin/bash
echo "Hello, world" > indx.html
nohup busybox httpd -f -p ${server_port} &
