#!/bin/bash

# Colima の状態を確認
STATUS=$(colima status | grep -i "status" | awk '{print $2}')

# 状態が "running" でない場合に Colima を起動
if [ "$STATUS" != "running" ]; then
    echo "Colima is not running. Starting Colima..."
    colima start
fi

docker-compose up -d
docker exec -it cpp-study-ubuntu-env-1 /bin/bash