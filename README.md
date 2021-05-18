# ProvisioningShell

# 使い方

## 準備

- virtualbox と vagrant をインストール後、centos の box を追加して下さい
  - [vagrant をダウンロードページ](https://www.vagrantup.com/downloads)
  - [virtualbox をダウンロードページ](https://www.virtualbox.org/wiki/Downloads)

## box を追加する

- 今回は `bento/centos-8.3` を使用しています。
- [bento/centos バージョン情報](https://app.vagrantup.com/bento/boxes/centos-8.3)

```sh
# 任意のディレクトリを作成して以下のコマンドを実行してください

vagrant init bento/centos-8.3
# Vagrant ファイルが生成されます
```

## Vagrant ファイルを編集する

- シェルスクリプトを Vagrant ファイルと同じ位置に配置します
- visual studio code などで Vagrant ファイルを開きます

```ini

### 中略 ###

  # Enable provisioning with a shell script. Additional provisioners such as
  # Ansible, Chef, Docker, Puppet and Salt are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL

  # provision コマンドを実行したらシェルスクリプトが起動するように指定
  config.vm.provision "shell" , path: "bootstrap.sh"

  #   apt-get update
  #   apt-get install -y apache2
  # SHELL
end

```

### その他の設定

- その他、任意で固定 IP アドレスに修正して下さい
- [ネットワーク関連の設定](https://www.vagrantup.com/docs/networking/private_network#static-ip)

```ini
# config.vm.network "private_network", ip: "192.168.33.10"
config.vm.network "private_network", ip: "192.168.33.20"
```

- [メモリーや CPU 等のリソース割当の設定](https://www.vagrantup.com/docs/providers/virtualbox/configuration#vboxmanage-customizations)

## Vagrant を起動する

```sh
vagrant up
```

## シェルスクリプトを実行する

```sh
vagrant provision
```
