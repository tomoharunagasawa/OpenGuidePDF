# ファイル名: split_italic_urls.pl
#!/usr/bin/env perl
use strict;
use warnings;

# 1行ずつ処理（巨大ファイルでも固まらない）
while (my $line = <STDIN>) {
  my $prev;
  # 変換後にさらに対象が残っていたら最大10回まで反復
  for (my $i=0; $i<10; $i++) {
    $prev = $line;

    # _..._ の中の [URL](URL) だけ外に出す（URL内の入れ子()対応）
    $line =~ s{
      _([^_]*?)                        # 斜体前半（最短）
      \[ (https?://[^\]\s]+) \]        # [] 内URL
      \( (                              # () 内URL（入れ子対応）
          https?://
          (?: [^()\s]+ | \([^()\s]*\) )*
        ) \)
      ([^_]*?)_                        # 斜体後半（最短）
    }{
      my ($pre,$u1,$u2,$post)=($1,$2,$3,$4);
      my $sp = ($post eq '' || $post =~ /^[\[\(\.,;:!?]/) ? '' : ' ';
      "_${pre}_ [$u1]($u2)$sp_${post}_"
    }gex;

    # *...* の中の [URL](URL) だけ外に出す（同様）
    $line =~ s{
      \*([^*]*?)                       # 斜体前半（最短）
      \[ (https?://[^\]\s]+) \]
      \( (
          https?://
          (?: [^()\s]+ | \([^()\s]*\) )*
        ) \)
      ([^*]*?)\*                       # 斜体後半（最短）
    }{
      my ($pre,$u1,$u2,$post)=($1,$2,$3,$4);
      my $sp = ($post eq '' || $post =~ /^[\[\(\.,;:!?]/) ? '' : ' ';
      "*${pre}* [$u1]($u2)$sp*${post}*"
    }gex;

    last if $line eq $prev;
  }

  print $line;
}