TerraformでVPCを記述する

- provider
- resources

## 概要
AWSのネットワークをTerraformで定義してみましょう。  
具体的に言うと、 `VPC` , `Subnet` , `Route Table` , `Internet Gateway` をTerraformで定義して作成していきます。

## 目標とする環境
![network](imgs/network.png)

一般的に用いられるであろうネットワークです。  
パブリックとプライベートのサブネットを作成して、アベイラビリティゾーン(以下AZ) 3つにサービスを配置できるようサブネットを3つずつ作成します。  
また、NAT Gatewayは1AZに1つしか配置できないため、ディザスタリカバリの観点から単一障害点にならないようにAZの数だけ用意しましょう。


## Terraformで空のVPCを作成する

![terraform vpc](imgs/terraform-vpc.png)

まずは空のVPCをTerraformで作成してみましょう。

前の章で作成したディレクトリ内で `main.tf` というファイルを作成し、以下の通り記述します。

```ruby
# Providerの設定。
#XXX: AWS Providerを使用してAWSのAPIを有効化し、ap-norheast-1(東京)リージョンへプロビジョニングを実行する
provider "aws" {
  region = "ap-northeast-1"
}

# 変数の宣言
#XXX: 複数回使用する値や、ステージング・本番のように環境によって値が変わるものを変数で宣言する
variable "name" {
  description = "各種リソースの命名"
  default     = "aws-handson"
}

#########################
# VPC
#########################
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.name}"
  }
}
```

### terraformの初期化
まずは `init` コマンドでTerraformの初期化を行います。  
`init` で依存するプラインなどをローカルへダウンロードします。今回はAWSのAPIを叩くために `AWS Provider` を使用しています。

```
$ terraform init
```

![terraform init](imgs/terraform-init.png)

### プロビジョニング
Terraformは非常順でdry-run機能を備えています。  
極めて厳密というわけではありませんが、コードと現在の環境を比較してプロビジョニング結果を予測してくれます。  
プロビジョニングの前に使用すると良いでしょう。  

```
$ terraform plan
```

`plan` が正常終了したら実際にAWSへTerraformでプロビジョニングしてみましょう。  

```
$ terraform apply
```

![terraform apply](imgs/terraform-apply.png)

!!! warning "エラーが起きる場合"
    - `terraform` コマンドを実行するディレクトリはあっていますか？
    - コードはあっていますか？
    - IAMのアクセスキー・権限は正しいですか？
    - AWSのリソース上限に達していませんか？

### Webコンソールで確認
実際にAWSのWebコンソールへアクセスし、 `aws-handson` とい名前のVPCが作成されたか確認してみましょう。

[https://ap-northeast-1.console.aws.amazon.com/vpc/home?region=ap-northeast-1](https://ap-northeast-1.console.aws.amazon.com/vpc/home?region=ap-northeast-1)

![vpc list](imgs/vpc-list.png)

## パブリックサブネットを作成

![vpc subnet](imgs/vpc-publicsubnet.png)

AWSのSLAは「リージョン使用不可」の状態になった時間を定義しています。  
そのため、AZはSLAを享受するためにリージョン内のAZ全てに配置する必要ができます。  
気になる方は [AWSの公式](https://aws.amazon.com/jp/legal/service-level-agreements/) で確認してみてください。

東京(ap-norheast-1)リージョンの場合は現在(2019/03)3つのAZが存在するため、各サービスが3AZにまたがって配置できるように **サブネットを3つ** 作成します。  
そのあと、インターネットと接続できるよう **"Internet Gateway"** を作成し、そのInternet Gateway を各サブネットが使用できるよう **"Route Table"** でルーティングを設定します。  
このようにInternet Gatewayとつながっているサブネットのことを **パブリックサブネット** と呼びます。逆にInternet Gateway とつながっていないサブネットのことはプライベートサブネットと呼びます。

### `main.tf` へ追記
以下のコードを `main.tf` へ追記します。

```ruby
#########################
# Public Subnet
#########################
# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = "${aws_vpc.main.id}" # 上記の `resource "aws_vpc" "main"` が作成したVPCのIDを取得

  tags = {
    Name = "${var.name}"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "${var.name}_public"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.this.id}"
}

# Public Subnet
resource "aws_subnet" "public_1a" {
  vpc_id = "${aws_vpc.main.id}"

  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "${var.name}_public_1a"
  }
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = "${aws_subnet.public_1a.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_subnet" "public_1c" {
  vpc_id = "${aws_vpc.main.id}"

  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "${var.name}_public_1c"
  }
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = "${aws_subnet.public_1c.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_subnet" "public_1d" {
  vpc_id = "${aws_vpc.main.id}"

  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1d"

  tags = {
    Name = "${var.name}_public_1d"
  }
}

resource "aws_route_table_association" "public_1d" {
  subnet_id      = "${aws_subnet.public_1d.id}"
  route_table_id = "${aws_route_table.public.id}"
}
```

!!! note "Don't Repeat Yourself"
    繰り返し処理が多いですね。  
    Terraformではプログラミング言語でいう `for` のようなループして実行するための機能があります。  
    今回のPublic Subnet はまさに繰り返し処理が生きる箇所なので、余裕のある方はリファクタしてみると良いでしょう。
    
    [Interpolation Syntax - 0.11 Configuration Language - Terraform by HashiCorp](https://www.terraform.io/docs/configuration-0-11/interpolation.html#using-templates-with-count)
    


### プロビジョニングの実行と確認

`plan` コマンドでコードに問題がないこを確認します。  
このときにTerraformはAWSの環境との差分を比較し、どのリソースを作成するか表示してくれます。  
VPCは作成されず、Internet Gateway, Route Table , Public Subnet x3 , Route x4 、の計 **9つのリソース** が新しく追加されることを確認してください。

```
$ terraform plan
```

![terraform plan publicsubnet](imgs/terraform-plan-publicsubnet.png)


問題がないことを確認できたらプロビジョニングを実行します

```
$ terraform apply
```

パブリックサブネットが作成されたかをWebコンソールで確認します。  
サイドメニューの「VPCでフィルタリング」でVPCを選択すると、選択したVPC内のリソースだけ表示されるようになります。

1. 3つSubnetが作成できているか
    - `aws-handson_public_1a` , `aws-handson_public_1c` , `aws-handson_public_1d`
2. SubnetとInternet Gateway が紐付いているか
    - "サブネットを選択" > "ルートテーブル" > 送信先が0.0.0.0、ターゲットがIGW (Internet GateWay)

![VPC list subnet](imgs/vpc-listsubnet.png)

## プライベートサブネットとNAT Gatewayの作成

![network](imgs/network.png)

最後にプライベートサブネットとNAT Gatewayを作成しましょう。

### `main.tf` へ追記

### プロビジョニングの実行と確認


## まとめ
- `main.tf` に必要なリソースを記述する
- `terraform plan` でdry-run
- `terraform apply` でプロビジョニング
