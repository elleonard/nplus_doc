---
title: 【新】HexoのMarkdownで複雑な表を書く
tags:
  - 情報技術
  - Hexo
  - Markdown
  - JavaScript
category:
  - 情報技術
date: 2019-09-13 19:40:04
---


# 動機

たまたま{% post_link engineering/hexo-markdown-table 前回の記事 %}を見てみたら、とんでもなく保守性の悪いことをしていたので、もうちょいマシな方法を記しておきます。

node_modulesの中身を直接書き換えるなんてことしちゃあダメだぞ。

<!-- more -->

# 方針

前回の記事で定義したオレオレ記法はひとまず引き継ぐこととします。
昔の記事が壊れちゃうのもなんだかかっこ悪いし、後方互換性君を意識した開発は基本ですので。

Hexoには[記事データにフィルタをかける機能](https://hexo.io/api/filter.html)があります。
今回はそれを使って、デフォルトレンダラーに表を作られる前に自前のレンダラーで思い通りの表を作る、ということをします。

# フィルタ定義の方法

表をレンダリングされる前にこちらでHTMLタグに変換してしまうので、 `before_post_render` のタイミングでフィルタをかけます。
使っているテーマディレクトリの下に `scripts` ディレクトリを作成し、その下に任意の名前で.jsファイルを置きます。

今回は `table.js` としましょう。

# 完成したコード

```javascript
const rTable = / *\|(.+)\n *\|( *[-:]+[-| :]*)\n((?: *\|.*(?:\n|$))*)\n*/g;

hexo.extend.filter.register('before_post_render', function(data) {
  data.content = data.content.replace(rTable, (content, header, align, body) => {

    var headerContents = header.split('|').map(content => {
      return {
        isNoContent: content === '',
        isHeader: true,
        rowspan: content.match(/!.*(r[1-9]).*!/) != null ? Number(content.match(/!.*(r[1-9]).*!/)[1].substring(1)) || 1 : 1,
        colspan: content.match(/!.*(c[1-9]).*!/) != null ? Number(content.match(/!.*(c[1-9]).*!/)[1].substring(1)) || 1 : 1,
        content: content.replace(/!.*!/, ''),
        isCombined: content === '^' || content === '<'
      };
    });
    headerContents.pop(); // 末尾に邪魔な要素がいる
  
    const lines = body.split('\n');
    var cellContents = lines.map((line) => {
      var cells = line.split('|').map(cell => {
        return {
          isNoContent: cell === '',
          isHeader: cell.match(/!.*h.*!/) != null,
          // row, colともに1桁のみ対応。2桁以上は必要になり次第実装する
          rowspan: cell.match(/!.*(r[1-9]).*!/) != null ? Number(cell.match(/!.*(r[1-9]).*!/)[1].substring(1)) || 1 : 1,
          colspan: cell.match(/!.*(c[1-9]).*!/) != null ? Number(cell.match(/!.*(c[1-9]).*!/)[1].substring(1)) || 1 : 1,
          content: cell.replace(/!.*!/, ''),
          isCombined: cell === '^' || cell === '<'
        }
      });
      cells.shift();
      cells.pop();
      return cells;
    });
  
    // text align
    var textAlign = align.split('|').map(align => {
      if (align.match(/^:-*:$/)) {
        return "center";
      } else if (align.match(/^-*:$/)) {
        return "right";
      }
      return "left";
    });
  
    var thead = `<thead><tr>${headerContents.map((cell) => {
        if (cell.isCombined) {
          return "";
        }
        return `<th style="text-align:center" rowspan=${cell.rowspan} colspan=${cell.colspan}>${cell.content}</th>`;
      }).join('')}</tr></thead>`;
  
    var tbody = `<tbody>${cellContents.map((line) => {
        return `<tr>${line.map((cell, cellIndex) => {
          if (cell.isCombined) {
            return "";
          }
          const tag = cell.isHeader ? `th` : `td`;
          return `<${tag} style="text-align:${cell.isHeader ? "center" : textAlign[cellIndex]}" rowspan=${cell.rowspan} colspan=${cell.colspan}>${cell.content}</${tag}>`
        }).join('')}</tr>`;
      }).join('')}</tbody>`;
  
    return `<table>${thead}${tbody}</table>\n\n`;
  });
  return data;
});

```

すべての記事データの中から、正規表現でテーブル部分を抜き出して自前で組み立てています。
とりあえず自分で使いそうなスタイルのみ対応しているので、左右の枠なしテーブルとかには対応してません。

# 前の方法と比べてどこが良い？

まず、node_modulesの中身を直接触らなくて良いというのが一番大きいです。
テーマディレクトリの下に `scripts` を置かないといけないというのは少し面倒ですが、日本語向けのテーマはなかなかないので、基本的にいい感じのやつをforkして自分でメンテしていくことになるでしょう。

# 追記/編集履歴

## 2020/03/22

テーブルの直後のマークダウン要素がHTMLの一部と解釈されてしまうバグがあったため、スクリプトを簡単に修正しました。
