set -e

tag=$(date '+%s')
DOCKER_BUILDKIT=1 docker buildx build -t clang:${tag} .
echo "docker run -it clang:$tag bash"
