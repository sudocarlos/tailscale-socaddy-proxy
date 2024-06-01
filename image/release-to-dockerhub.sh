set -ex
# SET THE FOLLOWING VARIABLES
# docker hub username
USERNAME=sudocarlos
# image name
IMAGE=tailscale-caddy-socat
# platforms
PLATFORM=linux/amd64,linux/386
# bump version
#docker run --rm -v "$PWD":/app treeder/bump patch
version=`awk -F "=" '/TAILSCALE_VERSION=/{print $NF}' Dockerfile`
echo "Building version: $version"
# run build
docker buildx build -t $USERNAME/$IMAGE:latest -t $USERNAME/$IMAGE:$version --push .
# tag it
git add -A
git commit -m "tailscale-caddy-socat version $version"
git tag -a "dockerhub-$version" -m "tailscale-caddy-socat version $version"
git push
git push --tags