set -ex
# SET THE FOLLOWING VARIABLES
# docker hub username
USERNAME=sudocarlos
# image name
IMAGE=tailscale-socaddy-proxy
# platforms
PLATFORM=linux/amd64,linux/386
# bump version
#docker run --rm -v "$PWD":/app treeder/bump patch
version=0.1
echo "Building version: $version"
# run build
docker buildx build -t $USERNAME/$IMAGE:latest -t $USERNAME/$IMAGE:$version --push .
# tag it
git add -A
git commit -m "tailscale-socaddy-proxy version $version"
git tag -a "dockerhub-$version" -m "tailscale-socaddy-proxy version $version"
git push
git push --tags