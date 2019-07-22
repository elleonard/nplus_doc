---
title: Windows10がINACCESSIBLE BOOT DEVICEで起動しない（続）
tags:
  - OS
  - Windows10
category:
  - 情報技術
date: 2018-02-14 13:08:40
---


{% post_link engineering/windows10-inaccessible-boot-device %}の続き

ひとまずWindows Updateを巻き戻すことで一時的に対処できた、というところまでしか書いていなかったので追記
真っ青な画面の根本的な原因と対策について

<!-- more -->

# 原因

[Important: Windows security updates released January-February, 2018, and antivirus software](https://support.microsoft.com/en-us/help/4072699/january-3-2018-windows-security-updates-and-antivirus-software)

{% blockquote 上記記事Overviewより抜粋 %}
The compatibility issue arises when antivirus applications make unsupported calls into Windows kernel memory. These calls may cause stop errors (also known as blue screen errors) that make the device unable to boot. To help prevent these stop errors, Microsoft is currently only offering the January and February 2018 Windows security updates to devices that are running antivirus software that is from antivirus software vendors who have confirmed that their antivirus software is compatible by setting a required registry key.
{% endblockquote %}

要約すると、1月のWindows Updateでカーネルメモリへのアクセス方法を制限したが、古いアンチウイルスソフトがそれに対応できておらず、起動時にエラーが起きてブルースクリーンが発生する、ということ
そんな破壊的な変更をいきなりやるMicrosoftが悪いかというと実はそういうことではなく、アンチウイルスソフトベンダの対応状況をしっかり見てからアップデートをかけているよ、ということも書いてある
「対応済みの場合はこのレジストリキーを書き換えてね」とベンダに伝え、ベンダがアンチウイルスソフトをアップデート、そのアップデートを適用したマシンはレジストリキーが書き換えられ、該当のWindows Updateが適用される、という具合だろう

では、アンチウイルスソフトが対応したというレジストリの更新があったにも関わらず何故この問題が起きたのか

# アンチウイルスソフトは一つに絞ろう

あるアンチウイルスソフトが新しいWindows Updateに対応し、レジストリを書き換えた
しかし、別のアンチウイルスソフトもインストールされており、そちらは古いままだった

{% blockquote 雑な流れ %}
Windows Update「対応した？」
レジストリ「したよ」
Windows Update「よっしゃ通るで」
古いアンチウイルスソフト「おっ、PC起動したんやな いつもどおりカーネルメモリにアクセスして……」
Windows「あかんで（青画面）」
{% endblockquote %}

筆者のPCにも２種類のソフトがインストールされており、それで全てを察した
尚、今は１種類のみ残してアンインストールしたため、これで問題は起こらないはずである

# なぜWindowsはこんな更新を？

そもそも、Windowsがカーネルメモリへのアクセス方法を制限しなければこんな問題は起こらなかった
とMicrosoftを責めてはいけない
この更新はセキュリティ上、仕方なく必要になってしまったものなのだ

[Googleが発見した「CPUの脆弱性」とは何なのか。ゲーマーに捧ぐ「正しく恐れる」その方法まとめ - 4Gamer.net](http://www.4gamer.net/games/999/G999902/20180105085/)

わかりやすい説明が上記ページに書いてあるので細かいことは省くが、 `Meltdown` 及び `Spectre` という名前のCPU脆弱性が発表され、その対応を急がねばならなかったのである
この脆弱性はざっくり言うと、投機的実行の仕組みを悪用してカーネルメモリの内容を盗み見ることができてしまうというもの
投機的実行とは技術用語で、例えば条件分岐の結果を予測してそれよりも先にある命令に必要な計算を先んじて行ってしまい、実際の実行時にその結果を使って高速に処理できるようにしようという仕組みのこと
もちろん、分岐予測が外れた場合には先んじて実行した結果は無駄になり、捨てることになる（投機的 だからね）

この脆弱性を放置すると、カーネルメモリ領域に展開される情報が攻撃者に筒抜けになる可能性がある

[CPUの脆弱性[Spectre], [Meltdown] は具体的にどのような仕組みで攻撃する？影響範囲は？ | SEの道標](http://milestone-of-se.nesuke.com/nw-advanced/nw-security/meltdown-spectre/)

[CPUの脆弱性 MeltdownおよびSpectreの攻撃シナリオ（PDF）](http://sectanlab.sakura.ne.jp/sblo_files/sectanlab/misc/20180131/Meltdown_Spectre.pdf)

主にクラウドサービスの事業者にとっての危険が大きい脆弱性だが、個人PCでも対応を怠っていると重要な機密情報を盗み見られてしまう危険がある
特に悪意のあるJavaScriptだけで発火させられかねないのが脅威
（攻撃コードの例は既に出回っている様子 200行足らずの短いjs）

各種webブラウザでも対応の更新がされているようである

[Google、CPU脆弱性“Meltdown”“Spectre”の緩和策を「Google Chrome 64」へ導入 - 窓の杜](https://forest.watch.impress.co.jp/docs/news/1099729.html)

Windows Updateをしっかり適用し、アンチウイルスソフトもwebブラウザも正しく更新しておく、怪しげなリンクは踏まない、等の当たり前の心がけが大切である
