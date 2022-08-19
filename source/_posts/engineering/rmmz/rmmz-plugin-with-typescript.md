---
title: RPGツクールMZのプラグインをtypescript移行する
tags:
  - 情報技術
  - RPGツクールMZ
category:
  - ゲーム制作
date: 2022-08-18 12:25:11
---


以前挑戦して失敗した後、放置していたtypescript移行の計画を実行に移しました。
移行の方針から、実際の移行作業手順と、その過程で踏み抜いた罠、得られた副産物を記しておきます。

<!-- more -->

# 前提

[リポジトリ](https://github.com/elleonard/DarkPlasma-MZ-Plugins)は以下のような構造になっています。{% footnote yarn.lockなど、今回のtypescript移行の文脈での説明に不要なものは省いている。 %}

```
├── _dist
├── .github/workflows
├── src
│ └── codes
│   ├── プラグイン1
│   │ ├── _build
│   │ │ ├── DarkPlasma_プラグイン1_commands.js
│   │ │ ├── DarkPlasma_プラグイン1_header.js
│   │ │ ├── DarkPlasma_プラグイン1_parameters.js
│   │ │ └── DarkPlasma_プラグイン1_parametersOf.js
│   │ ├── DarkPlasma_プラグイン1.js
│   │ └── config.yml
│   ├── プラグイン2
│   └── ...
└── package.json
```

RPGツクールのプラグインは単一機能であることが望ましく、それぞれが小規模です。
1プラグインにつき1リポジトリの運用をされている方もいらっしゃいますが、筆者のプラグインはそれをやるほどの規模のものではなく、1リポジトリですべてを管理するmonorepo方式を取っています。
{% post_link engineering/rmmz/rmmz-plugin-with-rollup %}に記した通り、rollup.jsを利用して、プラグインのメインロジックと設定を分離しています。
config.ymlから、 _build 下に中間成果物を生成し、それとメインロジックを結合して、最終的な成果物を _dist に生成します。

GitHub上では成果物用のディレクトリは確認できません。
GitHub Actionsでビルドし、releaseブランチに成果物をpushしています。

今回、typescript化するのはプラグインのメインロジック。上記の図では DarkPlasma_プラグイン1.js となっているものです。

# 移行の理由

型安全に書きたい！

これに尽きます。
方々から拝借してちまちま改修しつつ使っているコアスクリプトの型定義ファイルや自前で書いたjsdocのお陰で、生jsでもそこそこ補完は効く状態でした。
{% post_link engineering/rmmz/rmmz-plugin-with-rollup rollup移行 %}によってメインロジックとボイラープレートを分離できていたのもあり、快適さもありました。
しかしそれでも、ts-checkをかけると型起因のバグが見つかるのです。

jsだと既存クラスの拡張時にimplicitなthisに頼らざるを得ず、その型を明示しようとすると毎度型チェックの分岐を書く必要があって無理でしょ感が溢れました。

例えば、こんなコードです。

```js
/**
 * アイテムの所持最大数をゲーム中に変更する
 * @param {MZ.Item | MZ.Weapon | MZ.Armor} item アイテムデータ
 * @param {number} count 変更後の最大数
 */
Game_Party.prototype.changeMaxItemCount = function (item, count) {
  if (!(this instanceof Game_Party)) {
    return;
  }
  if (!this._maxItemCount) {
    this._maxItemCount = {};
  }
  const key = this.itemMaxCountKey(item);
  if (!key) {
    return;
  }
  this._maxItemCount[key] = count;
  if (this.hasMaxItems(item)) {
    this.setItemCountToMax(item);
  }
};
```

jsdocを書いてはいますが、単に関数を代入しているだけなので `changeMaxItemCount` の型は補完されません。
関数それ自体は自分がどのクラスに属しているか知らないので、 `this` の型も推論できません。
そのためだけにinstanceofで分岐を書くのはあまりにも馬鹿らしく、やっていられません。

```ts
/**
 * アイテムの所持最大数をゲーム中に変更する
 * @param {MZ.Item | MZ.Weapon | MZ.Armor} item アイテムデータ
 * @param {number} count 変更後の最大数
 */
Game_Party.prototype.changeMaxItemCount = function (this: Game_Party, item: MZ.Item|MZ.Weapon|MZ.Armor, count: number): void {
  if (!this._maxItemCount) {
    this._maxItemCount = {};
  }
  const key = this.itemMaxCountKey(item);
  if (!key) {
    return;
  }
  this._maxItemCount[key] = count;
  if (this.hasMaxItems(item)) {
    this.setItemCountToMax(item);
  }
};
```

typescriptでは第1引数でthisの型を明示でき、余計な分岐に3行取られることもありません。
jsではふわっと書いて許されてしまっていたものが静的解析できっちり書かされるようになり、バグの混入を防いでくれます。

RPGツクールのプラグインは、人に使ってもらう目的で作って公開しているものです。
MITライセンスではありますが、技術者としては安全であることをある程度保証しておきたいと考えています。
その安全性の担保を人力でし続けるのは限界があるだろう、と常々感じていました。

ビルドを通すまでに数日かけましたが、その甲斐はあったと思っています。

# 移行の方針

まず、以下の要件を満たしているべきでした。

- これまでと書き味や運用を劇的に変えない
- メインロジックをtypescriptの強みである型安全なコードにする
- rollup構成の強みであるボイラープレートの自動生成を活かし、コードではメインロジックに集中する
- 成果物の可読性をある程度維持する

成果物のビルドの仕組みは自前のrollup構成リポジトリで持っているので、メインロジックをtypescriptで書き、トランスパイル後のjsをrollupのビルドの仕組みに放り込んで成果物を生成すれば、これまでと書き味も運用も変えずに、ある程度きれいな成果物を出せると考えました。

試作したところ、結果として驚くほど既存の成果物と差異がない{% footnote tscはAST経由でトランスパイルするため、元ファイルの空行はすべて消えてしまうが、それは許容範囲内とした。 %}ものが出来上がって、テンション爆上がりしてました。{% footnote "その後、本構成にしてGitHub Actionsのビルドを通すまで数日かかったのだが。" %}

いきなりすべてをts化するのは現実的ではないため、どれかひとつ代表のプラグインをts化し、他は既存の手段でビルドできるようにプロジェクトの構成を維持することとしました。

## 成果物の可読性？

メインで保持するのはtypescriptで書いたロジックであるため、成果物の可読性はそこまで重要ではないと思われるかもしれません。
しかし、筆者としては、RPGツクールのプラグインは利用者が読んである程度理解できるべき{% footnote 無論、ある程度jsの知識を持っている利用者が読む前提。そうでない利用者も読まずに使えるべきではある。 %}だと考えています。
利用者のゲームプロジェクト内ではビルド元のtsファイルは存在せず、成果物のみが確認できます。
利用者にとって不都合がある場合はその解決策として、拡張プラグインを作るなりしてもらえれば良いと考えているため、成果物にはある程度の可読性が必要なのです。

# 移行の手順

効果が薄く運用もやめてしまったテストコードの削除や、ベースとなるコアスクリプトの型定義を整理したりもしましたが、それらはts移行の本質とはややズレた話になるので省略します。

## typescriptのインストール

これがないと話が始まりません。

```bash
yarn add -D typescript
yarn tsc --init
```

これでプロジェクトにtypescriptをインストールし、tsconfig.jsonを生成します。
コンパイラオプションはほとんどいじりませんでした。デフォルトでstrictにチェックしてくれるので、型安全という目的はそこで達成されます。
自前でビルドの仕組みを持っているので、 module は `ESNext` にしておきました。

## npm scriptの整理

tsファイルを先にtscでトランスパイルし、その後、既存のrollupの仕組みに突っ込んで成果物をビルドする形式にするため、ビルド用のコマンドを整理する必要がありました。
ただし、トランスパイルの段階で、自動生成したプラグインパラメータなどの中間成果物の型情報がなくてエラーになるため、予めそれらの型定義ファイルも自動生成しておく必要があります。
幸い、 `tsc --declaration --allowJs --emitDeclarationOnly` で型定義を自動生成できる{% footnote 一部any型が生成されてしまっており敗北感があるものの、規模の大きいものではないため一旦許容している。 %}ため、設定のビルド時にそれらも一緒に生成してしまうこととしました。

## 既存プラグインの移行を試す

プラグインコマンド、プラグインパラメータの両方を持ち、規模が大きすぎないものとして、 [MaxItemCount](https://github.com/elleonard/DarkPlasma-MZ-Plugins/blob/release/DarkPlasma_MaxItemCount.js) を選択しました。

# 移行の罠

いろんな罠を踏んで、思っていたより時間がかかりました。

## tscはワイルドカードを解釈しない

tscのトランスパイル対象は、コマンドに引数として渡して指定することもできます。{% footnote tsconfig.jsonのincludeでの指定も可能で、そちらが主流。include設定ではワイルドカードが使用できるが、今回は要件的に直接指定が必要であった。 %}
tscで型定義ファイルを生成する際には、既存のディレクトリ構成では各プラグインディレクトリの下にある `./_build/*.js` を対象とする想定でした。
プロジェクトルートからの相対パスをglob風に書くと、 `./src/**/_build/*.js` になります。

しかし、tscにワイルドカード指定を直接渡すと `*.js is not found` と言われ、何もしてくれません。

仕方ないので、 [google/zx](https://github.com/google/zx) を利用することにしました。
npm-scriptから呼び出すことができ、ある程度複雑な処理をjsなどで書ける優れものです。
最近tsもサポートされたようですが、あまり欲張ると時間がいくらあっても足りないので、ひとまず .mjs でスクリプトを用意しました。
zxから呼び出すスクリプトで対象ファイル一覧を出し、それに対して `yarn tsc` を使って型定義ファイルを生成させる仕組みとしました。

zxはnodeのバージョンが16以上でないと動かないので、ビルド環境のアップデートも必要でした。

## 個別にtscする

単にtscのオプションをいじるだけでは、プラグインごとに個別にビルドできません。
`--rootDir` オプションで指定ディレクトリ以下だけビルドしてくれそうだなと思いましたが、そんなことはありませんでした。

多くのプラグインをひとつのリポジトリで管理するmonorepo構造なので、それぞれのプラグインを個別のプロジェクトとみなしてしまうのが一番楽そうだという結論に達しました。
ビルド時に対象ディレクトリにtsconfig.jsonをテンプレートからコピーし、 `-b` オプションでビルド対象として指定します。

せっかくなので、 origin/release のコミットコメントにある最終ビルド対象コミットIDを利用して、プロジェクト全体としての差分ビルドを実現することにしました。
rollup移行の際に、releaseブランチのコミットコメントを、ビルド元になったmasterのコミットIDにしておいたことがここで活きました。

```
git fetch origin release
git log --first-parent origin/release --pretty=oneline -n 1
```

このコマンドでorigin/releaseから最新のコミットを手に入れ、この内容からコメントを抜き出してHEADのコミットとファイル構成diffを取ります。

```
git --no-pager diff 対象コミットID HEAD --name-only
```

このあたりのコマンドの結果をプログラムで手軽に扱えるのがzxのいいとこですね！

差分ビルドを実現したことで、明示的に変更していないプラグインがビルド対象にならなくなったのは利点と言えそうです。{% footnote 共通ファイルの更新で意図せずバグった成果物をリリースしてしまうケースが過去にあった。 %}

[上記の仕組みを利用した差分ビルド用の .mjs](https://github.com/elleonard/DarkPlasma-MZ-Plugins/blob/1cb88d752fbf2041fe0e2ebd2efac984f4921ae8/scripts/buildDispatcher/buildIncremental.mjs) はちょっと雑な感じもしますが、ひとまずこんな感じです。

## GitHub Actionsが通らない

GitHub Actionsでは、一時ディレクトリの下でビルドコマンドを利用しているため、相対パスでビルド対象を決定すると残念なことになってしまいました。
横着せず、 `path.resolve(__dirname)` を駆使して絶対パス指定に変更。
すると今度はローカルでビルドを通せません。

zxが特定以外の文字を含む変数を `$` に渡すコマンド内で展開しようとすると、 `$'文字列'` のように展開してしまうのです。

つまり、以下のようなソースコードではコマンドが壊れてしまい、動きません。

```js
await $`yarn tsc --declaration --allowJs --emitDeclarationOnly ${target}`;
```

なぜかというと、筆者がWindowsを使っているからですね。絶対パスにコロンが含まれるため、zxによる展開時にエスケープされてしまうというわけです。
WSLなりdockerなりで開発環境のポータビリティを上げておかなかったツケと言えばツケですが、今それをやる余裕はないので、とりあえず[zxのコード](https://github.com/google/zx/blob/2ec0f0321fd43ceedd0287b96d07b674b2c34a6b/src/core.ts#L87)を読んでなんとかしました。

```js
await $([`yarn tsc --declaration --allowJs --emitDeclarationOnly`, ` ${target}`], '');
```

こんな感じで配列で渡してあげると結合した状態のコマンドを流してくれます。これで `C:` から始まるパスでも安心です。

# 積み残し

## releaseブランチのREADME更新

releaseブランチのコミットコメントに依存するようになってしまったので、直接releaseブランチにpushしてはいけなくなりました。
成果物を公開するブランチなので、直接pushしてはいけないという運用自体に違和感はないのですが、こうなるとビルド対象でないファイルを更新できません。

今のところreleaseブランチにはビルド対象とREADME.mdしかいないので、READMEの更新方法だけ整えてしまえば問題はなさそうです。

## 開発環境のポータビリティ

WSLにしろDockerにしろ、今回ハマった罠を考えれば、素のWindows環境よりは幾分やりやすいんだろうなとは思っています。
コミッタにその環境を整えることを強制するのはいかがなもんかとも思うし、そもそもコミッタが自分以外ほぼいない{% footnote ツクールのプラグインは人のリポジトリにPR出す文化があんまり根付いてなさそう。 %}ので、ひとまずnode入れておけば動く状態になってれば良いかなとも思っています。

お、開発環境用のdocker-composeあるやん、で気軽にコミットしてくれる人がいるなら検討しますが、多分そういう人はほとんどいないので……。

## READMEの更新

そもそもプロジェクトのREADMEが更新できてない気がするので、気力が戻ったらやっときます。

# まとめ

RPGツクールMZのプラグインリポジトリにtypescriptを導入しました。
いろいろな罠を踏み抜きましたが、型安全なコードを快適に書く環境が揃えられたので、それだけでも大きな収穫だと思っています。

zxという強力なツールに出会えたのも嬉しいですね。
npm-scriptで複雑なことをやろうとして消耗するよりずっと良さそうです。

{% footnote_list %}
