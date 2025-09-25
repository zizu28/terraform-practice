#!/bin/bash
cat > index.html <<EOF
<h1>${server_text}!!!</h1>
<p>MYSQL DB ADDRESS: ${db_address}</p>
<p>MYSQL DB PORT: ${db_port}</p>
EOF
nohup busybox httpd -f -p ${server_port} &
