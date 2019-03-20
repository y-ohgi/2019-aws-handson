## 概要
ECS上でLaravelを動かしてみましょう

## ECRへpush

### 新規ECRリポジトリ作成
GUIをポチポチするのがそろそろしんどくなってきたころだと思うので、AWS CLIで操作していきます。

`nginx` と `app` の2つのリポジトリを作成します。

```
$ aws ecr create-repository --repository-name nginx
$ aws ecr create-repository --repository-name app
```

作成されたかの確認

```
$ aws ecr describe-repositories --query 'repositories[].repositoryName'
[
    "nginx",
    "handson-nginx",
    "app"
]
$
```

### Dockerのビルドとpush
ハンズオンリポジトリへチェックアウト (適宜)

```
$ cd /path/to/2019-aws-handson
```

nginxのビルドとpush
```
$ export ECR_URI_NGINX=$(aws ecr describe-repositories --repository-names nginx --query 'repositories[0].repositoryUri' --output text)
$ docker build -t ${ECR_URI_NGINX} -f docker/nginx/Dockerfile .
$ docker push ${ECR_URI_NGINX}
```

Laravelのビルドとpush
```
$ export ECR_URI_APP=$(aws ecr describe-repositories --repository-names app --query 'repositories[0].repositoryUri' --output text)
$ docker build -t ${ECR_URI_APP} .
$ docker push ${ECR_URI_APP}
```

## Laravel用の暗号化キーを生成・登録
Laravelでは起動時に暗号化キーが必要なので、その生成と登録を行います。  

docker-composeからphpコマンドを叩き、暗号化キーを生成します。
```
$ docker-compose run app php artisan key:generate --show
base64:Qg1++xxxxxxxxxxxxxxxx=
$ export LARAVEL_APP_KEY=base64:Qg1++xxxxxxxxxxxxxxxx=
```

DBの接続情報でも使用した "ParameterStore" へ暗号化キーを `handson/app/key` という命名で登録します。  

```
$ aws ssm put-parameter --name "/handson/app/key" --value ${LARAVEL_APP_KEY} --type String
{
    "Version": 1
}
```

## ECSのコンテナ定義を更新

`terraform/container_definitions.json` をLaravel用に書き換えます。  

```json
[
    {
        "name": "nginx",
        "image": "${account_id}.dkr.ecr.${region}.amazonaws.com/nginx:${tag}",
        "cpu": 0,
        "memory": 128,
        "portMappings": [
            {
                "containerPort": 80,
                "hostPort": 80,
                "protocol": "tcp"
            }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-region": "${region}",
                "awslogs-group": "/${name}/ecs",
                "awslogs-stream-prefix": "nginx"
            }
        }
    },
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
            }
        ],
        "environment": [
            {
                "name": "APP_ENV",
                "value": "${app_env}"
            },
            {
                "name": "LOG_CHANNEL",
                "value": "stderr"
            }
        ]
    }
]
```

### 環境変数の展開
`environment` で環境変数を起動したコンテナへ展開することが可能です。  
今回は `LOG_CHANNEL` と `APP_ENV` を定義してみます。  
`LOG_CHANNEL` は `stderr` でログを標準エラーへ出力することを決め打ちします。  
`APP_ENV` は変数としてTerraformの呼び出し時に動的に与えます。

```json
"environment": [
   {
     "name": "LOG_CHANNEL",
     "value": "stderr"
   }
]
```

`terraform/main.tf` で `${app_env}` で実際の値を定義します。  
ここは実際の環境ではterraform側も変数化したほうが良いですが、今回はTerraformの入門ということでTerraform側は決め打ちしてしまいます。

```diff
data "template_file" "container_definitions" {
  template = "${file("container_definitions.json")}"

  vars = {
    tag = "latest"

    account_id = "${data.aws_caller_identity.self.account_id}"
    region     = "${data.aws_region.current.name}"
    name       = "${var.name}"

+   app_env = "production"
  }
}
```

### ParameterStoreの値を環境変数へ展開
ECSではParameterStoreの値を直接呼び出すことが可能できます。  
今回はその機能を使用して、ParameterStoreに登録した暗号化キーをECSで起動したコンテナの環境変数へ展開しています。

```json
"secrets": [
    {
        "name": "APP_ENV",
        "value": "${app_env}"
    },
    {
        "name": "APP_KEY",
        "valueFrom": "/handson/app/key"
    }
],
```

## デプロイ
このハンズオンではTerraformでECSを管理しているため、terraformからデプロイを実行します。

```
$ terraform apply
```

少し時間を置いてから出力されたDNSへアクセスしてみましょう。
