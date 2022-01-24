# clang-docker

## Step

1. clone this repo
2. `./build.sh`
3. wait build

## Description

- `ninja.sh`: using inside Dockerfile

## Dump

```shell
# on your pc
docker run -it IMAGE_ID bash

# on docker
cd /tmp/clang-build/src/clang/include/clang/Basic
/tmp/clang-build/build/bin/clang-tblgen --dump-json ./Diagnostic.td > ~/dump.json

# on your pc
docker cp CONTAINER_ID:/root/dump.json ./dump.json
```
