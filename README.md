# setup on WSL2
WindowsのWSL2(Ubuntu)をセットアップするためのWindows Batchファイル。

# これは何？
このリポジトリは、WindowsのWSL2上でComfyUIをセットアップするための手順を提供します。

# ATTENTION(注意事項)
- 下記をよく読み、セキュアな環境構築をしてください  
- このWindows Batchファイルは信用されるサイトからダウンロードしてください。  
  それ以外のサイトでは悪意のあるコードが混入される可能性があります。 
- WSL2は Cドライブ にインストールされます。  
  その他ドライブにインストールしたい場合は、手動で`2.Install_Linux.bat`内の
  `$DistroPath`を変更してインストールしてください。

## インストール方法

1. WSL2を有効にする  
  `1.Enable_WSL.bat` を実行する  
  管理者権限が必要となるため、UACが表示されたら「はい」を選択してください。

2. Windowsを再起動する  
  WSL2を有効にした後、Windowsを再起動してください。

3. Linux(Ubuntu24.04)をインストールする  
  `2.Install_Linux.bat` を実行する
  インストールには時間がかかります。

# LICENSE
This project is licensed under the MIT License.
