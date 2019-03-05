#!/bin/bash

if [[ $# -eq 0 ]] ; then
    echo "Please specific environment. (dev,staging,prod)"
    exit 1
fi

if [ "$1" = "staging" ]; then
	export BUILD_ENV=staging
elif [ "$1" = "prod" ]; then
	export BUILD_ENV=prod
elif [ "$1" = "dev" ]; then
	export BUILD_ENV=dev
else
	echo "Please specific environment. (dev,staging,prod)"
	exit 1
fi

IMAGE=legaldrive/itax-wealthcare-rails

RAILS_ENV=production JAVA_OPTS='-Xmx1024m -Xmx4096m' bundle exec rake assets:precompile

ID=$(docker build  -t ${IMAGE}  .  | tail -1 | sed 's/.*Successfully built \(.*\)$/\1/')
VERSION=$(docker images | awk '($1 == "'${IMAGE}'") {print $2 += .01}' | sort -nrk2 | head -1)

docker tag ${ID} ${IMAGE}:latest
docker tag ${ID} ${IMAGE}:${BUILD_ENV}
docker push ${IMAGE}:${BUILD_ENV}
