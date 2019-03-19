## About
ECS, Terraform, Datadogについてハンズオン形式で学ぶドキュメントです。

## 想定する読者層
- WebAPIのようなサーバーサイドのプログラミングをしたことがある
- AWS, Dockerを触ったことがある
- これからTerraform, Datadogを触ってみようとしている

## 構築する環境
![aws](imgs/aws.png)

## Version
- Docker
    - 18.09.3
- docker-compose
    - 1.23.2

## 必要な環境
- AWSアカウント
    - [クラウドならアマゾン ウェブ サービス 【AWS 公式】](https://aws.amazon.com/jp/)
- Datadog アカウント
    - [Datadog: Log In](https://app.datadoghq.com/account/login?next=%2Fapm%2Fhome)
- Docker for Mac/Windows
    - [Docker CE — Docker-docs-ja 17.06.Beta ドキュメント](http://docs.docker.jp/engine/installation/docker-ce.html)
    - Mac: `$ brew cask install docker`
- AWS CLI
    - [AWS Command Line Interface をインストールする - AWS Command Line Interface](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/cli-chap-install.html)
    - Mac: `$ brew install awscli`
    - Windows: `> choco install awscli`
