Read this in other languages: [English](README.md), [日本語](README.ja.md)

# SiTCP Sample Code for VC707 SGMII

VC707通信確認用のSiTCPサンプルソースコード（SGMII版）です。

SiTCPの利用するAT93C46のインタフェースをVC707のEEPROM(M24C08)に変換するモジュールを使用しています。

また、VC707に搭載されているI2CスイッチPCA9548Aを動作させるモジュールも使用しています。


## SiTCP とは

物理学実験での大容量データ転送を目的としてFPGA（Field Programmable Gate Array）上に実装されたシンプルなTCP/IPです。

* SiTCPについては、[SiTCPライブラリページ](https://www.bbtech.co.jp/products/sitcp-library/)を参照してください。
* その他の関連プロジェクトは、[こちら](https://github.com/BeeBeansTechnologies)を参照してください。

![SiTCP](sitcp.png)
