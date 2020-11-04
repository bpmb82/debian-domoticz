# debian-domoticz
Docker image based on debian-slim

This docker image is based on Debian (buster-slim) and incorporates the toonapilib4domoticz plugin made by John van de Vrugt: https://github.com/JohnvandeVrugt/toonapilib4domoticz

To do's:

* Add user support (currently running as root)
* Be able to deal with User Namespaces setting in Docker

# installation

Clone the repository into a directory of your choosing:

`git clone https://github.com/bpmb82/debian-domoticz.git && cd debian-domoticz`

Then, build the image with Docker:

`docker build --no-cache --tag debian-domoticz:1.0 .`

This will tag the image as 'debian-domoticz:1.0'. You can choose another name if you wish.
Note down the id of the image once built, we need it in the next step.

Next, we run the image:

`docker container run -p 8080:8080 <id of image>`

You should now be able to login.

# docker-compose

You can also use this docker-compose.yml:

```version: '3.3'

services:

  domoticz:
    image: bpmbee/debian-domoticz:1.0
    labels:
      - "com.centurylinklabs.watchtower.enable=true" # optional when using Watchtower
    container_name: domoticz
    userns_mode: "host" #optional but recommended
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
    restart: unless-stopped```
