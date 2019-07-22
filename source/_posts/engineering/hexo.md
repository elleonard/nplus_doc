---
title: Hexo導入メモ
date: 2016-02-21 01:06:16
tags: [情報技術,Hexo]
category:
  - 情報技術
---
というわけで、Hexo導入にあたってのメモを書きます。

# 引っかかったこと

## 同名カテゴリが複数現れる

* Hexoのカテゴリは階層構造を持つ
* つまり、「ゲーム」カテゴリ内の「艦これ」カテゴリと、「艦これ」カテゴリ内の「ゲーム」カテゴリが明確に区別される
* 面倒だが、カテゴリを複数設定する場合は順番を揃えて設定する
* また、一度間違った階層でgenerateしてしまったものは、 hexo clean で抹殺する

# 参考リンク

## [所要時間3分!? Github PagesとHEXOで爆速ブログ構築してみよう！](http://liginc.co.jp/web/programming/server/104594)
* 2014年8月の記事のため、やや古い（の割に、Hexoでググるとトップに来てしまう）
* Hexo3.0以降、当時とはdeployの方法が少し変わっている

## [Themes](https://github.com/hexojs/hexo/wiki/Themes)
* テーマリンク集
* ただし、こちらも古く、Deprecatedの表記
* 多くのテーマが消滅したり、保守されていない状態になっている
* ただし、[新しい方](https://hexo.io/themes/)は種類が少ない
* 古いほうの保守されていないテーマも、軽く手を加えれば十分使えたりする

## [\[techaday:0013\] Hexoで気軽に静的ブログ作成 (2)設定とページの生成](http://blog.tokor.org/2015/12/11/Hexo%E3%81%A7%E6%B0%97%E8%BB%BD%E3%81%AB%E9%9D%99%E7%9A%84%E3%83%96%E3%83%AD%E3%82%B0%E4%BD%9C%E6%88%90-2-%E8%A8%AD%E5%AE%9A%E3%81%A8%E3%83%9A%E3%83%BC%E3%82%B8%E3%81%AE%E7%94%9F%E6%88%90/)
* timezoneの設定を参考にした
* 最近の記事なので信頼できるのでは

## [Hexo でハロー](http://www.ty07.net/2015/04/28/hello-world/)

## [静的ページジェネレータHexoで作成したブログをGitHub Pagesで公開する](http://raimon49.github.io/2015/04/25/create-blog-with-hexo.html)
* rootの設定を参考にした
* この設定にしておかないと、css等への相対パスが狂って表示が死ぬ
