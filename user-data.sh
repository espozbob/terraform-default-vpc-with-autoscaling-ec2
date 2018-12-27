#!/bin/bash

cat > index.html <<ECHO
<h1>Hello World!</h1>
ECHO

nohup busybox httpd -f -p "${server_port}" &
