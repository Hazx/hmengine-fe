#!/bin/bash

## 模块来源
## https://nginx.org/en/download.html
## https://www.openssl.org/source/
## https://www.zlib.net/


docker_path=hazx
docker_img=hmengine-fe
docker_tag=1.7
docker_base=ubuntu:jammy-20240911.1
## 编译线程数
make_threads=${1:-2}
## Server 标记
server_name='HMengine'
## 默认页面中的服务名称
server_name_page='HMengine-FE'

arch=$(uname -p)
if [[ $arch == "aarch64" ]] || [[ $arch == "arm64" ]];then
    docker_tag=${docker_tag}-arm
fi

## 清理工作目录
rm -fr build_${docker_img}
rm -f output/${docker_img}-${docker_tag}.tar

## 准备工作
mkdir -p build_${docker_img}
cp -R build build_${docker_img}/
echo "export set_server_name=\"${server_name}\"" >> build_${docker_img}/build/IDR-buildvar-sh
echo "export set_server_name_page=\"${server_name_page}\"" >> build_${docker_img}/build/IDR-buildvar-sh
echo "export set_make_threads=\"${make_threads}\"" >> build_${docker_img}/build/IDR-buildvar-sh
if [ $http_proxy ];then
    echo "export http_proxy=${http_proxy}" >> build_${docker_img}/build/IDR-buildvar-sh
fi
if [ $https_proxy ];then
    echo "export https_proxy=${https_proxy}" >> build_${docker_img}/build/IDR-buildvar-sh
fi
if [ $no_proxy ];then
    echo "export no_proxy=${no_proxy}" >> build_${docker_img}/build/IDR-buildvar-sh
fi
pwd_dir=$(cd $(dirname $0); pwd)
export BUILDKIT_STEP_LOG_MAX_SIZE=-1

## 构建编译环境镜像
echo "构建编译环境镜像..."
cat <<EOF > build_${docker_img}/build/Dockerfile
FROM ${docker_base}
COPY IDR-build-base-sh /root/hazx/build.sh
RUN chmod a+x /root/hazx/*.sh ;\
    /root/hazx/build.sh
EOF
docker build --progress=plain -t ${docker_img}:${docker_tag}-build-base build_${docker_img}/build/

## 编译Nginx
echo "准备开始编译Nginx..."
rm -f build_${docker_img}/build/Dockerfile
cat <<EOF > build_${docker_img}/build/Dockerfile
FROM ${docker_img}:${docker_tag}-build-base
COPY src /root/hazx/src
COPY conf /root/hazx/conf
COPY html /root/hazx/html
COPY IDR-build-export-sh /root/hazx/export.sh
COPY IDR-build-nginx-sh /root/hazx/build.sh
COPY IDR-buildvar-sh /root/hazx/buildvar.sh
RUN chmod a+x /root/hazx/*.sh ;\
    /root/hazx/build.sh
CMD /root/hazx/export.sh
EOF
docker build --progress=plain -t ${docker_img}:${docker_tag}-build-nginx build_${docker_img}/build/
mkdir -p build_${docker_img}/package
docker run --rm --name tmp-hmengine-build-export-nginx \
    -v ${pwd_dir}/build_${docker_img}/package:/export \
    ${docker_img}:${docker_tag}-build-nginx


## 打包最终镜像
echo "正在打包最终镜像..."
mkdir -p output
cp build/IDR-imginit-sh build_${docker_img}/package/img_init.sh
cp build/IDR-webserver-sh build_${docker_img}/package/webserver.sh
rm -f build_${docker_img}/package/Dockerfile
cat <<EOF > build_${docker_img}/package/Dockerfile
FROM ${docker_base}
LABEL maintainer="hazx632823367@gmail.com"
LABEL Version="${docker_tag}"
COPY web_server /web_server
COPY img_init.sh /
COPY webserver.sh /web_server/
RUN chmod a+x /img_init.sh ;\
    /img_init.sh ;\
    rm -f /img_init.sh
WORKDIR /web_server
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/web_server/sbin
CMD /web_server/webserver.sh
EXPOSE 80
EOF
docker build --progress=plain -t ${docker_path}/${docker_img}:${docker_tag} build_${docker_img}/package/
docker save ${docker_path}/${docker_img}:${docker_tag} | gzip -c > output/${docker_img}-${docker_tag}.tar.gz

## 清理垃圾
docker rmi ${docker_img}:${docker_tag}-build-base
docker rmi ${docker_img}:${docker_tag}-build-nginx
docker rmi ${docker_path}/${docker_img}:${docker_tag}
rm -fr build_${docker_img}

echo ""
echo "Docker镜像制作完成"
echo "镜像地址: ${docker_path}/${docker_img}:${docker_tag}"
echo "镜像文件: output/${docker_img}-${docker_tag}.tar.gz"
echo "Tips: 一些设备（例如绿联NAS）不支持.tar.gz扩展名，你需要在上传前重命名为.tar"
echo ""
