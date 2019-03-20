## IaCについて
Infrastructure as Code は既に聞き慣れた単語かも知れません。  
インフラの構成をコード化しようというアプローチで、AnsibleやChefなども同じくIaCのアプローチです。  
構成を宣言的に記述することによってコードベースでインフラの管理を行え、属人化を防ぐことができます。  

## Terraform

![terraform](imgs/terraform-logo.png)

TerraformはHashiCorp社製のOSS IaC ツールです。  
AWSにもCloudFormationという素晴らしいマネージドサービスがありますが、Terraformは複数のベンダー(AWS, GCP, Azure, Datadog, etc...)へ対応しています。  
OSSということで"自前でパッチを当てて使う"ということも可能です。  

また、Terraformの特徴的な機能として **再利用性** を担保するModuleという機能があります。  
単純にコピペするだけでもIaCは機能するのですが、よりスマートに配布する仕組みを実現し、GitHubやS3上のコードを参照することが可能になりました。  
例えば社内のGitHub Enterprise で管理されているTerraformをもとに、よくある環境をサクッと作ってしまうようなことができます。
