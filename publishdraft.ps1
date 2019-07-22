# hexoのdraftを公開する

if ($args.Length -lt 2) {
  echo "usage: publishdraft.ps1 draft path"
  exit
}

$name = $args[0]
$path = $args[1]

#$target = $path + $name

hexo publish post $name
mv ./source/_posts/$name $path
mv ./source/_posts/$name.md $path
#rm ./source/_drafts/$name.md
