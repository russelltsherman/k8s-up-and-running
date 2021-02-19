#!/usr/bin/env bash

echo ""
echo "start haproxy service"
echo "#########################################################"

service haproxy restart || true
