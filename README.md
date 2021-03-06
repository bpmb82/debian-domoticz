# debian-domoticz
Docker image based on debian-slim

This docker image is based on Debian (buster-slim) and incorporates the toonapilib4domoticz plugin made by John van de Vrugt: https://github.com/JohnvandeVrugt/toonapilib4domoticz

To do's:

* Add user support (currently running as root) while being able to deal with User Namespaces setting in Docker

# Build from source

Clone the repository into a directory of your choosing:

`git clone https://github.com/bpmb82/debian-domoticz.git && cd debian-domoticz`

Then, build the image with Docker:

`docker build --no-cache --tag debian-domoticz:1.0 .`

This will tag the image as 'debian-domoticz:1.0'. You can choose another name if you wish.
Note down the id of the image once built, we need it in the next step.

# Run

`docker container run -p 8080:8080 <id of image>`

or

`docker pull bpmbee/debian-domoticz`

`docker run -p 8080:8080 bpmbee/debian-domoticz`

You should now be able to login.

**NOTE**
If your docker container shows to be 'unhealthy', please add 127.0.0.* to the local networks in Domoticz -> Settings

# Docker-compose

You can also use this docker-compose.yml:

```
version: '3.3'

services:

  domoticz:
    image: bpmbee/debian-domoticz:1.0
    labels:
      - "com.centurylinklabs.watchtower.enable=true" # optional when using Watchtower
    container_name: domoticz
    security_opt:
      - "no-new-privileges:true" # optional but recommended
    environment:
      - TZ=Europe/Amsterdam
      - VIRTUAL_HOST=my-domoticz.example.com # optional, for nginx-proxy
      - VIRTUAL_PORT=8080 # optional, for nginx-proxy
      - LETSENCRYPT_HOST=my-domoticz.example.com # optional, for letsencrypt
      - LETSENCRYPT_EMAIL=my-email@example.com # optional, for letsencrypt
    volumes:
      - <local path>/data:/data
    expose:
      - "8080"
    ports:
      - 8118:8080 # for local access, remove if not needed
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0 # for RFXCom or ZWave dongles, remove if not needed
    restart: unless-stopped
```

## Docker-compose with nginx proxy and letsencrypt

```
version: '3.3'

services:

  proxy:
    image: jwilder/nginx-proxy:alpine
    labels:
      - "com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy=true"
    container_name: domoticz-proxy
    networks:
      - domoticz_network
    ports:
      - 80:80
      - 443:443
    volumes:
      - <local path>/conf.d:/etc/nginx/conf.d:rw
      - <local path>/vhost.d:/etc/nginx/vhost.d:rw
      - <local path>/html:/usr/share/nginx/html:rw
      - <local path>/certs:/etc/nginx/certs:ro
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/tmp/docker.sock:ro
    restart: unless-stopped

  letsencrypt:
    image: jrcs/letsencrypt-nginx-proxy-companion
    container_name: domoticz-letsencrypt
    depends_on:
      - proxy
    networks:
      - domoticz_network
    volumes:
      - <same local path of nginx-proxy>/certs:/etc/nginx/certs:rw
      - <same local path of nginx-proxy>/vhost.d:/etc/nginx/vhost.d:rw
      - <same local path of nginx-proxy>html:/usr/share/nginx/html:rw
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    restart: unless-stopped


  domoticz:
    image: bpmbee/debian-domoticz:latest
    container_name: domoticz
    depends_on:
      - proxy
    environment:
      - TZ=Europe/Amsterdam
      - VIRTUAL_HOST=my-host.example.com
      - VIRTUAL_PORT=8080
      - LETSENCRYPT_HOST=my-host.example.com
      - LETSENCRYPT_EMAIL=john@my-host.example.com
    networks:
      - domoticz_network
    volumes:
      - <local path>/data:/data
    expose:
      - "8080"
    ports:
      - 8118:8080 # only if you want local network access
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0 # used for ZWave or RFX 433 dongles
    restart: unless-stopped

networks:
  domoticz_network:
```
