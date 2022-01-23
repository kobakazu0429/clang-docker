set -e

tag=$(date '+%s')
# docker build -t clang:${tag} --progress=plain .
docker build -t clang:${tag} .
