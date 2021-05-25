set -e
docker container rm dev-container -f || true
docker build . -t dev-container
docker container run -d -v $1:/home/user/projects -u 1000:1000 --name dev-container dev-container
