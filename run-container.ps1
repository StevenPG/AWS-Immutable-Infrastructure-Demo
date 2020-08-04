docker build -t image-to-run-in-because-windows:1.0 ./docker
docker run -it -v C:\Git\AWS-Immutable-Infrastructure-Demo:/working-directory image-to-run-in-because-windows:1.0 bash