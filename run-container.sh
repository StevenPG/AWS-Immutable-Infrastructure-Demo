docker build -t image-to-run-in-because-windows:1.0 ./docker
docker run -it --rm -v /Users/sgantz/.aws:/root/.aws -v /Users/sgantz/Development/Github/AWS-Immutable-Infrastructure-Demo:/working-directory image-to-run-in-because-windows:1.0 bash