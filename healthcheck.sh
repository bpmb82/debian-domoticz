#!/bin/sh
curl -f "http://127.0.0.1:${WWW}/json.htm?type=command&param=getversion" && curl api.ipify.org || exit 1
