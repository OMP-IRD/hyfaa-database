TAG=10-3.1
IMAGE=hyfaa-postgis

all: docker-build docker-push

docker-build:
	docker build -t pigeosolutions/${IMAGE}:${TAG} .

docker-push:
	docker push pigeosolutions/${IMAGE}:${TAG}
