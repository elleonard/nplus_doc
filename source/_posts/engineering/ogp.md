---
title: OGPとその設定
date: 2016-11-26 08:15:01
tags: [情報技術, OGP, hexo, WIX]
category:
  - 情報技術
---

つい最近、OGPの設定が変えられなくて困っている友人を見たので、その仕組について

<!-- more -->

# OGPって何？

ググるのが最も早くて正確な答えが得られるはず
とだけ書いておくのも不親切なので、簡単に説明しておくと

* Open Graph protocolの略
* SNS等でページ情報をリッチに表示するためのwebページに行うメタ情報設定
  * twitterとかにURLを貼った時、いい感じに表示してくれるための設定

# どうやって設定するの？

htmlのmetaタグを使って設定する
下記に一例を記す

{% codeblock OGP設定例 lang:html %}
<head>
  <meta property="og:title">タイトル</meta>
  <meta property="og:site_name">サイト名</meta>
  <meta property="og:image">OGP画像のパス</meta>
</head>
{% endcodeblock %}

# どういう仕組で表示されるの？

たとえばtwitter等のSNSは、URLがpostされた時、そのURLにアクセスしてhtmlをパースする
そして、上記metaタグの中身を拾ってきて表示させている

重要なのは、htmlをパースするだけであってそこに書かれたjavascriptは一切実行されないという点だ
つまり、javascriptで動的にmetaタグを書き換えるコードを仕込んでおいても、twitterに表示される情報に何ら影響はないのである

# つまり、どういうことだってばよ

これがどう問題になるかというと、ページ遷移をjsによるdom書き換えで実現している[WIX](http://ja.wix.com/)のようなウェブページ作成ツールで引っかかる
ページごとに別々のHTMLになっている場合はmetaタグをそれぞれ別々の表記にすれば良いが、それができない環境ではページごとにOGP設定を変えることができない

WIXは手軽でスタイリッシュに見えるものの、HTMLページ自体は一つしかなくjavascriptで複数のページを行き来しているように見せているだけだ
これは、ウェブブラウザのデバッグツール（ChromeならF12を押すと開く）を開いて、htmlコードを見ながらWIX製のページを行き来してみればすぐにわかる

# なんとかならんか

ならん
現実的になんとかなるとすれば、WIX側がHTMLページを複数置けるようなシステムに根っこから置き換わるくらいか

twitter側にjsを実行させる、というのはあまりにハードルが高いように思う
（悪意あるjsを仕込んでtwitterに実行させる、なんていう脆弱性を生みかねない）

# ちなみにhexoでは

hexoではOGP設定は各ページごとに標準で設定できる
titleとかcoverとかをページごとに設定もできるし、configに書いておけばサイト全体での設定も容易だ
twitterカードについても、configやページごとに設定項目を書き、それを読んで生成するようejsに追記するだけである

{% codeblock twitterカードの設定 lang:html %}
  <!-- twitter -->
  <% if (theme.share.twitter) { %>
    <meta property="twitter:card" content="summary" />
    <% if (theme.bottom_link.twitter) { %>
      <meta property="twitter:site" content="@<%= theme.bottom_link.twitter %>" />
    <% } %>
    <% if (page.title) { %>
      <meta property="twitter:title" content="<%= page.title %>" />
    <% } else { %>
      <meta property="twitter:title" content="<%= config.title %>" />
    <% } %>
    <% if (page.description) { %>
      <meta property="twitter:description" content="<%= page.description %>" />
    <% } else if (config.description) { %>
      <meta property="twitter:description" content="<%= config.description %>" />
    <% } else if (page.excerpt) { %>
      <meta property="twitter:description" content="<%= page.excerpt %>" />
    <% } %>
    <% if (page.cover) { %>
      <meta property="twitter:image" content="<%= config.url %>/<%= page.path %><%= page.cover %>" />
    <% } else { %>
      <meta property="twitter:image" content="<%= config.url %><%= config.cover %>"/>
    <% } %>
  <% } %>
{% endcodeblock %}

## 実はhexo 2.7以降からはhelpersが使える

twitterで心優しい方からご指摘がありました
[公式ドキュメント](https://hexo.io/docs/helpers.html#open-graph)読んでないのまるわかりで恥ずかしい！
下記の記述でも設定可能になるはず

でも、twitter:imageとかはサポートされてないのかなあ

{% codeblock helerの使い方 lang:html %}
  <!-- ogp -->
  <% if (page.cover) { %>
    <% if (theme.bottom_link.twitter) { %>
      <%- open_graph({image: url_for(page.path) + page.cover, twitter_id: theme.bottom_link.twitter}) %>
    <% } else { %>
      <%- open_graph({image: url_for(page.path) + page.cover}) %>
    <% } %>
    <meta name="twitter:image" content="<% url_for(page.path) + page.cover %>" />
  <% } else { %>
    <% if (theme.bottom_link.twitter) { %>
      <%- open_graph({twitter_id: theme.bottom_link.twitter}) %>
    <% } %>
    <meta name="twitter:image" content="<%= config.url %><%= config.cover %>"/>
  <% } %>
{% endcodeblock %}


# 参考URL

* [The Open Graph protocol](http://ogp.me/)
* [Twitterカード - Twitter Developers](https://dev.twitter.com/ja/cards/overview)

