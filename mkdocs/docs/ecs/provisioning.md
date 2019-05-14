## 作成する環境

![aws](../imgs/aws.png)

(AZ・RouteTable・SecurityGroupなどは省略していますが、) 上記の環境を目標に構築していきます。

## ハンズオン環境の構築

![aws](imgs/aws.png)

Terraformで環境構築を行いますが、ParameterStoreとECRだけ手動で構築します。  

## ParameterStore
ParameterStoreはAWSのサービスの1つで、シークレット情報や設定情報を管理するためのサービスです。  

このハンズオンではAurora(AWSのマネージドDB)の初回起動時に作成される **"DBのユーザー名"** と **"DBのパスワード"** をParameterStoreへ登録します。  
早速パラメータを登録してみましょう。  
[AWS Systems Manager - Parameter Store](https://ap-northeast-1.console.aws.amazon.com/systems-manager/parameters?region=ap-northeast-1)
![top](imgs/ssm-top.png)

### DBユーザー名の登録
まずはユーザー名を登録します。  
名前を `/handson/db/username` で登録し、値は任意の文字列を入力してください  (1 ~ 16文字の英数字を使用する必要があります)。  
ここでは `myusername` とします。

![username](imgs/ssm-username.png)

![create](imgs/ssm-create.png)

### DBパスワードの登録

続いてパスワードを登録します。  
名前を `/handson/db/password` で登録し、値は任意の文字列を入力してください (8文字以上の英数字を使用する必要があります)。  
ここでは `mypassword` とします。

![password](imgs/ssm-password.png)

## 登録情報の確認

`/handson/db/username` と `/handson/db/password` が登録していることを確認できたら完了です。  

![confirm](imgs/ssm-confirm.png)


## GitHubからサンプルコードのpull
このハンズオンではLaravelをECSで動かします。  
今回はDocker対応させたLaravelのサンプルコードを用意しているので、ローカルへpullして使用してください。

```
$ cd /path/to/your/directory/
$ git clone https://github.com/y-ohgi/2019-aws-handson.git
$ cd 2019-aws-handson/laravel
```

docker-composeでLaravelの動作確認をしてみましょう。
```
$ docker-compose up
```

[http://localhost:8001](http://localhost:8001) へアクセスし、Laravelが起動できていることを確認しましょう。  

```console
$ curl -I localhost:8001
HTTP/1.1 200 OK
Server: nginx/1.15.12
Content-Type: text/html; charset=UTF-8
Connection: keep-alive
Cache-Control: no-cache, private
Date: Tue, 14 May 2019 10:21:48 GMT
Set-Cookie: XSRF-TOKEN=eyJpdiI6Im5CSHRJNEVrXC9aU1VLZ3lzcTl3ZnhRPT0iLCJ2YWx1ZSI6IjQ2bTZPOElYQ3JTbTgrMVhDdGJuK3I1dG43UkRtbEVoeG84WUE3XC80M3V3YnM0UkRTRFdrSXdLb21NaXBQXC9xNSIsIm1hYyI6ImEwYmJlYjEyZTgzYzMyNTFhM2Y1NDQ4ZTBmYzhiODE1MmY3YjQwNTBlNjdlNWE5YzRiZDY2ZTBkNWZkN2Q0ZjkifQ%3D%3D; expires=Tue, 14-May-2019 12:21:48 GMT; Max-Age=7200; path=/
Set-Cookie: handson_session=eyJpdiI6ImlJbTk0cTdNWFYxMysydFZGaVwvK2N3PT0iLCJ2YWx1ZSI6IkVzaElLNGMwVVFnS25xeXNUdmlOY0E0SCtQSHNsVzJ1OUd5Z0ZTaXQ2XC9IYnBuWnpKeUUybTA4ZktxSVJJb3htIiwibWFjIjoiZGMzYTk3ZmE0YmY4M2I5ODMxMWMyZDI4ZTQ0MjFiNzA4NGMxZmY5YTc3MzM4ZjhiNjc3YWI2OGYzMzFiNDljYiJ9; expires=Tue, 14-May-2019 12:21:48 GMT; Max-Age=7200; path=/; httponly
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
X-Content-Type-Options: nosniff
```

アクセスできていることが確認できたらdocker-composeを停止させてしまいましょう。

## ECR

### Registryの作成
まずはECRへアクセスし、「Get Started」からDockerレジストリの作成を開始します。

[Amazon ECR](https://ap-northeast-1.console.aws.amazon.com/ecr/get-started?region=ap-northeast-1)
![top](imgs/ecr-top.png)

レジストリ名を「 `handson-nginx` 」と入力します。  

![create](imgs/ecr-create.png)

これでレジストリの作成は完了です。

また、以下に表示されているURIはDocker Image をpushするときに必要なので控えておきましょう。

![confirm](imgs/ecr-confirm.png)


### Build & Push
DockerのBuildを実行します。  
その際タグ名にECRのURIを設定する点に注意してください。

```console
$ ECR_URI_HANDSON_NGINX=<YOUR ECR REGISTRY URI> # 先程控えたECRのレジストリURIを変数として展開
$ docker build \
    -t ${ECR_URI_HANDSON_NGINX} \
    -f docker/handson-nginx/Dockerfile \
    docker/handson-nginx
```

ビルドしたdockerを立ち上げてnginxが立ち上がるか確認してみましょう
```
$ docker run -p 8080:80 ${ECR_URI_HANDSON_NGINX}
```

[http://localhost:8080](http://localhost:8080)
![8080](imgs/handson-docker-8080.png)


### ECRへDockerをpush
AWSへログインし、ECRのアクセス情報を取得します。  

アクセスキーは先ほど作成したterraformのものを流用しましょう。

```
$ aws configure
AWS Access Key ID [None]: <YOUR ACCESS KEY>
AWS Secret Access Key [None]:  <YOUR SECRET KEY>
Default region name [None]: ap-northeast-1
Default output format [None]: json
```

ログイン後、dockerの認証情報を取得します。
WARNINGと表示されますが、無視して問題ありません。  
```
$ $(aws ecr get-login --no-include-email --region ap-northeast-1)
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
Login Succeeded
```

最後に、作成したDocker Image をpushしてECRにアップロードされたことを確認します。
```
$ docker push ${ECR_URI_HANDSON_NGINX}
```

[https://ap-northeast-1.console.aws.amazon.com/ecr/repositories/handson-nginx/?region=ap-northeast-1](https://ap-northeast-1.console.aws.amazon.com/ecr/repositories/handson-nginx/?region=ap-northeast-1)
![ecr-handson-nginx.png](imgs/ecr-handson-nginx.png)


!!! warning "エラー: no basic auth credentials"
    `docker push` 後に"no basic auth credentials"とエラーが表示される場合、aws cliでログインしているアカウントが異なっています。  
    現在のaws cliの profile がどのアカウントのものになっているか確認を行ってください。  
    e.g. 現在のAWSアカウントIDを確認する。 `$ aws sts get-caller-identity --query Account --output text`

## Terraformでプロビジョニング

![aws](imgs/aws.png)

実際に図のAWSの環境を構築していきます。

### Terraformの初期化
Terraform用ディレクトリにチェックアウトし、初期化を行います。
```
$ cd terraform
$ ls
main.tf
```

Dockerからterraformを立ち上げます。
```
$ docker run \
    -e AWS_ACCESS_KEY_ID=<AWS ACCESS KEY> \
    -e AWS_SECRET_ACCESS_KEY=<AWS SECRET ACCESS KEY> \
    -v $(pwd):/templates \
    -w /templates \
    -it \
    --entrypoint=ash \
    hashicorp/terraform:0.11.12
$ terraform init
```

### プロビジョニング
どんなリソースが作成されるのか `plan` で確認し、 `apply` でプロビジョニングを実行します。
```
$ terraform plan
$ terraform apply
```

RDSのプロビジョニングに時間がかかるため、15分ほど待ちます。  

#### 作成されるサービス・リソースのコンソールへのリンク

![aws](../imgs/aws.png)

以下が今回使用するAWSサービスのWebコンソールへのリンクです。  
プロビジョニングがどのように実行されているのか、ターミナルを確認しつつWebコンソールを追うと良いでしょう。  

- VPC
    - ネットワークを司るサービスです
    - [https://ap-northeast-1.console.aws.amazon.com/vpc/home?region=ap-northeast-1](https://ap-northeast-1.console.aws.amazon.com/vpc/home?region=ap-northeast-1)
- ECS
    - [https://ap-northeast-1.console.aws.amazon.com/ecs/home?region=ap-northeast-1#/clusters](https://ap-northeast-1.console.aws.amazon.com/ecs/home?region=ap-northeast-1#/clusters)
- RDS
    - [https://ap-northeast-1.console.aws.amazon.com/rds/home?region=ap-northeast-1#](https://ap-northeast-1.console.aws.amazon.com/rds/home?region=ap-northeast-1#)
- Parameter Store
    - [https://ap-northeast-1.console.aws.amazon.com/systems-manager/parameters?region=ap-northeast-1](https://ap-northeast-1.console.aws.amazon.com/systems-manager/parameters?region=ap-northeast-1)

### 環境の確認
Terraformのプロビジョニングが完了すると、以下のようにDNSが表示されるのでアクセスして動作確認をしましょう。  

![outputs](imgs/terraform-output-dns.png)  
