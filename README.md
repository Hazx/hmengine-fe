# HMengine-FE

HMengine-FE 是一个隐藏了 Nginx 特征的 Docker 镜像，可以平替 Nginx、用在对 Nginx 比较忌讳的环境中，`Server` 默认会显示为 `HMengine`，你也可以自行修改和打包镜像。

对应镜像及版本：

- `hazx/hmengine-fe:1.0`
- `hazx/hmengine-fe:1.0-arm`

# 目录说明

- `build`：编译打包镜像所需要用到的目录。
- `example`：运行镜像时所需要映射的目录示例，含 Nginx 的示例配置文件。

# 组件版本

- Nginx：1.24.0
- OpenSSL：1.1.1w
- PCRE：8.45
- Zlib：1.2.11

# 使用镜像

你可以直接下载使用我编译好的镜像 `docker pull hazx/hmengine-fe:1.0`（ARM64 平台使用 1.0-arm），你也可以参照 [编译与打包](#编译与打包) 部分的说明自行编译打包镜像。

## 需要做映射的内部路径

- Nginx 配置目录：`/web_server/fe/conf`（主配置文件名为 fe.conf）
- WEB 文件目录：`/web_server/fe_df_html`（非必须设定此路径，依 Nginx 配置文件而定）
- 日志文件目录：`/web_server/fe/logs`（非必须设定此路径，依配置文件而定）

> 如果你需要改变 WEB、日志或其他路径映射，你需要注意修改 Nginx 配置文件的相应路径参数。

## 需要做映射的内部端口

- 80：Nginx - HTTP（默认端口）
- 其他端口依配置文件而定


## 创建容器示例

以下命令以将文件释放在目录 `/opt/hmengine-fe` 下为例，实际操作请以实际情况为准。

```shell
chown -R 1000:1000 example/website/web
docker run -d \
    -p 80:80 \
    -v /opt/hmengine-fe/example/fe:/web_server/fe/conf \
    -v /opt/hmengine-fe/example/website/web:/home/web \
    -v /opt/hmengine-fe/example/website/web_log:/home/web_log \
    --name web_server \
    --restart unless-stopped \
    hazx/hmengine-fe:1.0
```

# 编译与打包

*需要注意，编译和打包阶段需要 Docker 环境，且依赖互联网来安装编译和运行环境。*

## 编译并打包

> 编译阶段下载安装的依赖环境不会应用到你的系统环境，且在编译完成后不保留临时编译环境镜像。

你可以按需修改 `build` 文件夹下的内容。

然后执行以下命令开始编译与打包：

```shell
bash build.sh
```

编译过程默认采用 2 线程进行，若你想提高编译线程数，可以执行如下命令，在结尾带上线程数字：

```shell
bash build.sh 8
```

## 编译参数

编译默认采用如下参数配置 Nginx ，如有特殊需求可自行修改。

```shell
./configure \
--prefix=/web_server/fe \
--with-openssl=/path/to/openssl \
--with-pcre=/path/to/pcre \
--with-zlib=/path/to/zlib \
--with-http_ssl_module \
--with-http_sub_module \
--with-http_stub_status_module \
--with-pcre-jit \
--with-pcre \
--with-http_secure_link_module \
--with-http_realip_module \
--with-http_dav_module \
--with-http_v2_module
```





