#!/bin/bash

## 内置模块来源
## http://nginx.org/en/download.html
## https://www.openssl.org/source/
## https://www.pcre.org/
## https://www.zlib.net/


docker_path=hazx
docker_img=hmengine-fe
docker_tag=1.2
## 编译线程数
make_threads=${1:-2}
## Server 标记
server_name='HMengine'
## 默认页面中的服务名称
server_name_page='HMengine-FE'


## 清理工作目录
if [ -e build_${docker_img} ];then
    rm -fr build_${docker_img}
fi
if [ -e output/${docker_img}-${docker_tag}.tar ];then
    rm -fr output/${docker_img}-${docker_tag}.tar
fi

## 构建前的准备工作
mkdir -p build_${docker_img}
cp -R build build_${docker_img}/
echo "export set_server_name=\"${server_name}\"" >> build_${docker_img}/build/IDR-buildvar-sh
echo "export set_make_threads=\"${make_threads}\"" >> build_${docker_img}/build/IDR-buildvar-sh
cat <<EOF > build_${docker_img}/build/Dockerfile
FROM centos:7.9.2009
LABEL maintainer="hazx632823367@gmail.com"
LABEL Version="${docker_tag}-build"
COPY nginx /root/hazx/fe
COPY IDR-buildex-sh /root/hazx/
COPY IDR-build-sh /root/hazx/
COPY IDR-buildvar-sh /root/hazx/
RUN mv /root/hazx/IDR-build-sh /root/hazx/build.sh ;\
    mv /root/hazx/IDR-buildex-sh /root/hazx/export.sh ;\
    mv /root/hazx/IDR-buildvar-sh /root/hazx/buildvar.sh ;\
    chmod a+x /root/hazx/*.sh ;\
    . /root/hazx/buildvar.sh ;\
    /root/hazx/build.sh
CMD /root/hazx/export.sh
EOF

## 构建资源
docker build -t ${docker_img}:${docker_tag}-build build_${docker_img}/build/
mkdir -p build_${docker_img}/package
pwd_dir=$(cd $(dirname $0); pwd)
docker run --rm --name tmp-hmengine-build-export \
    -v ${pwd_dir}/build_${docker_img}/package:/export \
    ${docker_img}:${docker_tag}-build

## 打包最终镜像
mkdir -p output
cp build/IDR-imginit-sh build_${docker_img}/package/img_init.sh
cp build/IDR-webserver-sh build_${docker_img}/package/webserver.sh
cp -R build/html build_${docker_img}/package/
sed -i "s/server_name_web/${server_name_page}/g" build_${docker_img}/package/html/index.html
cp -R build/conf build_${docker_img}/package/
cat <<EOF > build_${docker_img}/package/Dockerfile
FROM centos:7.9.2009
LABEL maintainer="hazx632823367@gmail.com"
LABEL Version="${docker_tag}"
COPY web_server /web_server
COPY img_init.sh /
COPY webserver.sh /web_server/
COPY html /web_server/html
COPY conf /web_server/conf
RUN chmod a+x /img_init.sh ;\
    /img_init.sh ;\
    rm -f /img_init.sh ;\
    rm -f /Dockerfile
WORKDIR /web_server
ENV PATH "/web_server/sbin:$PATH"
CMD /web_server/webserver.sh
EOF
docker build -t ${docker_path}/${docker_img}:${docker_tag} build_${docker_img}/package/
docker save ${docker_path}/${docker_img}:${docker_tag} | gzip -c > output/${docker_img}-${docker_tag}.tar.gz

## 清理垃圾
docker rmi ${docker_img}:${docker_tag}-build
docker rmi ${docker_path}/${docker_img}:${docker_tag}
rm -fr build_${docker_img}

echo "Docker build finished."
echo "Image name: ${docker_path}/${docker_img}:${docker_tag}"
echo "Image Path: output/${docker_img}-${docker_tag}.tar.gz"

