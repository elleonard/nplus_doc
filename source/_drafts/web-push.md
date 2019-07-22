---
title: Web Pushってなんだ？
date: 2019-01-16 08:59:28
tags:
  - WebPush
category:
  - 情報技術
---

先日、[ニコ生アラートが廃止されました。](https://blog.nicovideo.jp/niconews/96390.html)
フォローしているコミュニティやチャンネルのニコ生の開始を教えてくれるものだったようです。

# ブラウザを閉じていても通知は来る

Service Workerの魔法でブラウザを閉じてても通知は来る

# Web Pushはニコ生アラートより遅い？

筆者の小さめのコミュニティで25秒程度かかった
サーバサイドの構造を想像するに、人数の多いコミュニティだともう少しかかるかもしれない

# ニコ生アラートより機能は落ちている

<blockquote class="twitter-tweet" data-lang="ja"><p lang="ja" dir="ltr">自分は特定のコミュに参加することはほぼ無く、キーワードをユーザーさん作成のアラートに入れていろんな放送を楽しんできました。<br>本日使えなくなっており本当にがっかりです。<br>自分の利用方法ではアラートソフトあってこそのニコ生でした。</p>&mdash; CHA-DA (@mogu_7_001) <a href="https://twitter.com/mogu_7_001/status/1085166108594757632?ref_src=twsrc%5Etfw">2019年1月15日</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

現状、キーワード指定で通知を受け取ることはできなさそうです。

# 音量や表示時間の設定はOS側にある

Windows10の例
https://urashita.com/archives/25034
https://win10labo.info/win10-notice/

# ニコニコの意図は？

完全に想像だけど、ニコ生アラートはシステムが古くなりすぎて一度捨てるという方針だったのでは。
有志が作ったツールを利用してニコ生を待つくらいリテラシーのあるユーザの割合、実はそこまで多くないという判断かもしれません。

有志がツール作って遊べる環境は楽しいだろうし、（もちろん、無茶な使われ方しない範囲で）今後サポートされるようになると良いなあとは思います。

# 他サービスの生放送開始通知

## youtube

Web Pushがある

## twitch
