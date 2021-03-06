#!/bin/bash

if ! grep -q "^unixsocket /var/run/redis/redis.sock" /etc/redis/redis.conf ; then
    sed -i -e 's/^\(#.\)\?port.*$/port 0/' /etc/redis/redis.conf
    sed -i -e 's/^\(#.\)\?unixsocket \/.*$/unixsocket \/var\/run\/redis\/redis.sock/' /etc/redis/redis.conf
    sed -i -e 's/^\(#.\)\?unixsocketperm.*$/unixsocketperm 700/' /etc/redis/redis.conf
fi

openvas-manage-certs -V 2>/dev/null
if [ $? -ne 0 ]; then
    openvas-manage-certs -a
fi

greenbone-nvt-sync
greenbone-scapdata-sync
greenbone-certdata-sync

service openvas-manager stop 
service openvas-scanner stop 

openvassd
openvasmd --migrate
openvasmd --rebuild --progress
killall openvassd
sleep 15
service openvas-scanner start
service openvas-manager start
service greenbone-security-assistant restart
if ! openvasmd --get-users | grep -q ^admin$ ; then
    openvasmd --create-user=admin
fi
