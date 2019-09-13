---
title: 【DEPRECATED】HexoのMarkdownで複雑な表を書く
date: 2016-05-06 00:53:27
tags: [情報技術, Hexo, Markdown]
category:
 - 情報技術
---

# 動機

艦これの出撃ログを記入する際、表でセルの結合や、最上段以外にthを使いたい
しかし、htmlタグを書くのは非常にダサい上に可読性を下げるのでやりたくない


2019/09/13追記: この記事に書かれた方法は著しく保守性に欠けるため、マネしないほうが良いです
Hexoにはfilterを定義する機能があるため、それを利用してテーブルのレンダラーを自作してしまうほうが良いでしょう
{% post_link engineering/hexo-table-render %} を参照してください

<!-- more -->

# 解決策

marked.jsをいじる必要がある
理想的にはmarked.jsをcloneして新しいプロジェクトにし、hexo自体がそちらを見るようにするのが良いのだが、今回はとりあえず動かすだけなので、hexo-renderer-markedを直接いじる

修正するのは以下のjsのみ
node_modules/hexo-renderer-marked/lib/marked.js

## 手順

### 文法を決める

markdownではセルの結合や最上段以外にthを利用するための文法が規定されていない
（方言によっては、横方向のセル結合のみあるようだが）

したがって、オレオレ文法を定めてそれを用いることとする
将来的に自分が利用しないであろうアノテーション用の記号を用いた文法とする
今回は簡単なコマンドを!で囲んで実現する

* !h! th
* !r2! rowspan=2
* !c2! colspan=2

数値は任意の整数を指定できるものとし、それぞれを組み合わせることも可能とする

例えば、!hr2!ならばthで尚且つrowspan=2だ

また、パースの都合上、rowspanやcolspanで上書きされるセルの記法も考えておく
（colspanは不要なので、rowspanのみ）
wikiで用いられているような^一文字のセルは、rowspanで上書きされるセルということにする

```
|テーブル|テーブル|
|:--:|:--:|
|ヘッダ!r2!|ほげほげ|
|^|ふがふが!h!|
```

以上のように記述すると、

|テーブル|テーブル|
|:--:|:--:|
|ヘッダ!r2!|ほげほげ|
|^|ふがふが!h!|

こう出力される

## marked.jsを改修する（パーサ編）

400行目付近にtable(gfm)なる記述がある
ここで表組みのmarkdownをパースしているので、ここに先ほど決定した規則の記述を追加する

以下はとりあえず動けば良いという程度の強引なやり方

```
    // table (gfm)
    if (top && (cap = this.rules.table.exec(src))) {
      src = src.substring(cap[0].length);

      item = {
        type: 'table',
        header: cap[1].replace(/^ *| *\| *$/g, '').split(/ *\| */),
        align: cap[2].replace(/^ *|\| *$/g, '').split(/ *\| */),
        cells: cap[3].replace(/(?: *\| *)?\n$/, '').split('\n'),
        header_colspan: new Array(),
        header_rowspan: new Array(),
        header_combined: new Array(),
        cell_header: new Array(),
        cell_colspan: new Array(),
        cell_rowspan: new Array(),
        cell_combined: new Array()
      };
      
      // header colspan rowspan
      for (i = 0; i< item.header.length; i++) {
        if (header_flag = /.*!(.+)!$/.exec(item.header[i])) {
          if (rows = /^.*r([0-9]+).*$/.exec(header_flag[1])) {
            item.header_rowspan[i] = rows[1]; 
          }
          if (cols = /^.*c([0-9]+).*$/.exec(header_flag[1])) {
            item.header_colspan[i] = cols[1];
            for(j = 1; j < cols[1]; j++) {
              item.header_combined[i+j] = true;
            }
          }
          item.header[i] = item.header[i].replace(/!(.+)!/, '');
        } else {
          item.header_rowspan[i] = 1;
          item.header_colspan[i] = 1;
        }
      }

      for (i = 0; i < item.align.length; i++) {
        if (/^ *-+: *$/.test(item.align[i])) {
          item.align[i] = 'right';
        } else if (/^ *:-+: *$/.test(item.align[i])) {
          item.align[i] = 'center';
        } else if (/^ *:-+ *$/.test(item.align[i])) {
          item.align[i] = 'left';
        } else {
          item.align[i] = null;
        }
      }

      for (i = 0; i < item.cells.length; i++) {
        if (!item.cells[i].match(/\|$/)) {
          item.cells[i] = item.cells[i] + "\|";
        }
        item.cells[i] = item.cells[i]
          .replace(/^ *\| *| *\| *$/g, '')
          .split(/ *\| */);

        // cell rowspan colspan header
        item.cell_header[i] = new Array();
        item.cell_colspan[i] = new Array();
        item.cell_rowspan[i] = new Array();
        if(item.cell_combined[i] == null) {
          item.cell_combined[i] = new Array();
        }
        for(j = 0; j < item.cells[i].length; j++) {
          if (cell_flag = /.*!(.+)!$/.exec(item.cells[i][j])) {
            if (rows = /^.*r([0-9]+).*$/.exec(cell_flag[1])) {
              item.cell_rowspan[i][j] = rows[1];
              for(k = 1; k < rows[1]; k++) {
                if(item.cell_combined[i+k] == null){
                  item.cell_combined[i+k] = new Array();
                }
                for(l = 0; l < j; l++){
                  if(item.cell_combined[i+k][l] == null) {
                    item.cell_combined[i+k][l] = false;
                  }
                }
                item.cell_combined[i+k][j] = true;
              }
            }
            if (cols = /^.*c([0-9]+).*$/.exec(cell_flag[1])) {
              item.cell_colspan[i][j] = cols[1];
              for(k = 1; k < cols[1]; k++) {
                item.cell_combined[i][j+k] = true;
              }
            }
            if (header = /^.*h.*$/.exec(cell_flag[1])) {
              item.cell_header[i][j] = true;
            }
            item.cells[i][j] = item.cells[i][j].replace(/!(.+)!/, '');
          } else {
            item.cell_rowspan[i][j] = 1;
            item.cell_colspan[i][j] = 1;
          }
        }
      }
      

      this.tokens.push(item);

      continue;
    }
```

尚、別の箇所にふち無しテーブルに関するパースもほぼ同等の記述で書かれているため、そこも変更する必要がある

（2016/05/06修正） ^のみのセルは無視するように、としましたが、それではalignがズレてしまうので、素直にcell_combinedフラグを使うようにしました

## marked.jsを改修する（レンダラー編）

tablecell関数で表のセルを出力しているので、その呼出時に、先ほどのパーサで追加した変数を引数として渡してやる

```
      // header
      cell = '';
      for (i = 0; i < this.token.header.length; i++) {
        flags = { header: true, align: this.token.align[i] };
        cell += this.renderer.tablecell(
          this.inline.output(this.token.header[i]),
          { header: true, align: this.token.align[i] },
          this.token.header_colspan[i],
          this.token.header_rowspan[i],
          this.token.header_combined[i]
        );
      }
      header += this.renderer.tablerow(cell);

      for (i = 0; i < this.token.cells.length; i++) {
        row = this.token.cells[i];

        cell = '';
        for (j = 0; j < row.length; j++) {
          cell += this.renderer.tablecell(
            this.inline.output(row[j]),
            { header: this.token.cell_header[i][j], align: this.token.align[j] },
            this.token.cell_colspan[i][j],
            this.token.cell_rowspan[i][j],
            this.token.cell_combined[i][j]
          );
        }

        body += this.renderer.tablerow(cell);
      }
      return this.renderer.table(header, body);
 ```
 
勿論、関数そのものの中身を変更することもお忘れなく

```
Renderer.prototype.tablecell = function(content, flags, colspan, rowspan, combined) {
  if(combined === true){ return ""; }
  var cols = colspan || 1;
  var rows = rowspan || 1;
  var type = flags.header ? 'th' : 'td';
  var tag = flags.align
    ? '<' + type + ' style="text-align:' + flags.align + '" colspan="' + cols + '" rowspan="' + rows + '">'
    : '<' + type + '>';
  return tag + content + '</' + type + '>\n';
};
```




