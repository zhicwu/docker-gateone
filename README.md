# docker-gateone
Docker image for GateOne(pure HTML5 SSH client). https://hub.docker.com/r/zhicwu/gateone/

# Changes
Here below are changes I made to official release(v1.2):
* Disabled Google Analytics tracking
* Disabled auto update(via git pull)
* Changed default theme to white
* Run as non-root user
* Basic authentication behind reverse proxy(only test on Apache httpd 2.4+)
* Shared bookmarks.json for all users

# Usage
```bash
$ git clone https://github.com/zhicwu/docker-gateone.git
$ cd docker-gateone
$ docker-compose up -d
$ docker-compose logs -f
```
You should be able to access http://localhost:8000/ssh now.