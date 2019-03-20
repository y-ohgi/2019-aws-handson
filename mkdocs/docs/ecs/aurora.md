## 概要
LaravelとAurora(MySQL)を連携を行います。

## タスク定義へDB接続情報の追加
`terraform/container_definitions.json` へDBの接続情報を追記します。  
今回データベース名だけ決め打ちしていますが、接続情報は基本的にParameter Store から取得します。

```diff
{
    "name": "app",
    "image": "${account_id}.dkr.ecr.${region}.amazonaws.com/app:${tag}",
    "cpu": 0,
    "memory": 128,
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-region": "${region}",
            "awslogs-group": "/${name}/ecs",
            "awslogs-stream-prefix": "app"
        }
    },
    "secrets": [
        {
            "name": "APP_KEY",
            "valueFrom": "/handson/app/key"
-       }
+       },
+       {
+           "name": "DB_HOST",
+           "valueFrom": "/handson/db/endpoint"
+       },
+       {
+           "name": "DB_USERNAME",
+           "valueFrom": "/handson/db/username"
+       },
+       {
+           "name": "DB_PASSWORD",
+           "valueFrom": "/handson/db/password"
+       }
    ],
    "environment": [
        {
            "name": "APP_ENV",
            "value": "${app_env}"
        },
        {
            "name": "LOG_CHANNEL",
            "value": "stderr"
-       }
+       },
+       {
+           "name": "DB_DATABASE",
+           "value": "handson"
+       },
+       {
+           "name": "DB_DATABASE",
+           "value": "handson"
+       }
    ]
}
```

## Auroraへmigrationの実行

