#!/bin/bash

# 当前脚本会在容器启动时执行 
# 脚本位置：/usr/local/bin/boot.sh


# 初始化：还原面板数据
if [ -f /www_backup.tar.gz ]; then
  # www目录为空 并且/www.tar.gz存在
  # 还原数据
  echo "初始化：还原面板数据"
  tar xzf /www_backup.tar.gz -C /
  rm -rf /www_backup.tar.gz
fi


# 启动面板
/usr/bin/bt stop
/usr/bin/bt start


# 扫描并启动服务
for script in /etc/init.d/*; do
    if [[ "$script" =~ ^/etc/init.d/(bt|mysqld|nginx|httpd|php-fpm-74|php-fpm-82)$ ]]; then
        echo -e "启动 ${script##*/}"
        ${script} start
    else if [[ "$script" =~ ^/etc/init.d/(redis)$ ]]; then
        if ps -p 1 | grep -q "systemd"; then
            echo -e "当前容器在特权模式下，执行正常启动redis"
            /etc/init.d/redis restart
        else
            echo -e "当前容器为非特权模式，适配宝塔面板中redis无法启动的问题"
            rm -rf /www/server/redis/redis.pid
            /etc/init.d/redis stop > /dev/null
            /www/server/redis/src/redis-server /www/server/redis/redis.conf
        fi
      fi
    fi
done


# 运行防火墙规则
# 检查 /lib/systemd/systemd 是否在运行
if ps -p 1 | grep -q "systemd"; then
    echo "运行systemd"
    chmod +x /usr/local/bin/iptables-rules.sh
    /usr/local/bin/iptables-rules.sh
else
   echo "未运行systemd"
fi


tail -f /dev/null