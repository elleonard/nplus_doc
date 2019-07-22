# hexoのdraftを作成する

# 引数チェック
if ($args.Length -lt 2) {
  echo "usage: makedraft.ps1 template target"
  exit
}

$template = $args[0]
$target = $args[1]

cp ./scaffolds/$template.md ./scaffolds/draft.md
hexo new draft $target
