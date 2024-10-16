#!/bin/bash
set -e
export LANG=en_US.UTF-8
# 安装文件
if [ -f .env ]; then
    rm .env
fi

if [ -f Dockerfile ]; then
    rm Dockerfile
fi
# 检测docker
if ! command -v docker &> /dev/null; then
    echo " 需要安装 docker, 参考：https://github.com/DeepInsight-AI/DeepBI/blob/main/Docker_install_CN.md "
    exit 1
fi

# 检测 docker-compose 支持
if ! command -v docker-compose &> /dev/null; then
    echo "需要安装 docker-compose, 参考：https://github.com/DeepInsight-AI/DeepBI/blob/main/Docker_install_CN.md"
    exit 1
fi
# get local ip
ip_addresses=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -vE '^inet 127(\.[0-9]{1,3}){3}')
# 使用固定的IP地址
ip="172.21.34.154"
echo "使用固定的IP地址: $ip"
# shellcheck disable=SC2162

# get web port
# shellcheck disable=SC2162
web_port=8338
# get socket port
# shellcheck disable=SC2162
socket_port=8339
ai_web_port=8340

# replace front file ip
echo "Rename files "
rm -rf ./client/dist
cp -R ./client/dist_source ./client/dist
echo "Replace ip port"
os_name=$(uname)
if [[ "$os_name" == "Darwin" ]]; then
    sed -i '' "s|192.168.5.165:8339|$ip:$socket_port|g" ./client/dist/vendors~app.js
    sed -i '' "s|192.168.5.165:8339|$ip:$socket_port|g" ./client/dist/app.js
else
    sed -i "s|192.168.5.165:8339|$ip:$socket_port|g" ./client/dist/vendors~app.js
    sed -i "s|192.168.5.165:8339|$ip:$socket_port|g" ./client/dist/app.js
fi
# 复制 .env file基础内容
env_content=$(cat .env.template)
# replace language
env_content=$(echo "$env_content" | sed "s/LANGTYPE/CN/g")
# replace web port
# shellcheck disable=SC2001
env_content=$(echo "$env_content" | sed "s/AI_WEB_PORT/$ai_web_port/g")
env_content=$(echo "$env_content" | sed "s/WEB_PORT/$web_port/g")
# shellcheck disable=SC2001
env_content=$(echo "$env_content" | sed "s/SOCKET_PORT/$socket_port/g")
# replace ip，替换IP
env_content=$(echo "$env_content" | sed "s/IP/$ip/g")
# replace sec_key， 替换码
sec_key=$(openssl rand -hex 16)
env_content=$(echo "$env_content" | sed "s/SEC_KEY/$sec_key/g")
# save .env file，保存文件
echo "$env_content" > .env
echo "DATA_SOURCE_FILE_DIR=/app/user_upload_files" >> .env
# 修改配置 pip 为国内清华源
sed 's/#CN#//g' Dockerfile.template > Dockerfile
# 输出说明：
echo "所有配置如下:"
echo "--------------------------------"
echo "$env_content"
echo "--------------------------------"
# begin run docker compose

docker-compose build
echo "--------------------------------"
echo "镜像拉取创建完毕，开始初始化镜像中数据库"
docker-compose run --rm server create_db
echo "数据库初始化完毕"

echo "现在，创建并启动容器......"
docker-compose up -d
echo "--------------------------------"
echo "启动成功，你可以访问 http://$ip:$web_port"
echo "--------------------------------"


