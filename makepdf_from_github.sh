#!/bin/bash

# 元ファイルのパス
SRC="../KanbanGuides-ja/site/content/open-guide-to-kanban/2025.7/index.ja.md"
DST="./index.ja.md"

  rm "$DST"
  wget "https://raw.githubusercontent.com/tomoharunagasawa/KanbanGuides-ja/refs/heads/translation/add-ja-language/site/content/open-guide-to-kanban/2025.7/index.ja.md"    


# 置換と削除
# macOS の sed は -i に空文字引数が必要
# 1) 斜体→明朝体
# 2) チェックボックス → ハイフン
# 3) [!FOOTNOTE] → [注釈:]
# 4) 太字と斜体の混合文を置換
# 5) URLからURL記法を削除
# 6) <!-- ... --> コメント削除（複数行対応）

# 1〜5の置換
sed -E -i '' \
  -e 's/斜体/明朝体/g' \
  -e 's/- \[ \]/- /g' \
  -e 's/\[!FOOTNOTE\]/注釈:/g' \
  -e 's/\*カンバンシステムメンバーがどこから始めればよいかわからない場合、本ガイドは次のように提案する\*\。/カンバンシステムメンバーがどこから始めればよいかわからない場合、本ガイドは次のように提案する。/g' \
  "$DST"

# perl split_italic_urls.pl "$DST" > "$DST.tmp" && mv -f "$DST.tmp" "$DST"

perl -pe '
  # _…_ の中の [URL](URL) を外に出す（URL直後の空白を条件付きで詰める；\ も対象）
  s{
    _([^_]*?)                                   # 前
    (                                           # リンク全体
      \[https?://[^\]\s]+\]
      \(
        https?://(?:[^()\s]+|\([^()\s]*\))*
      \)
    )
    ([^_]*?)_                                   # 後
  }{
    my ($pre,$link,$post)=($1,$2,$3);
    my $post2 = $post;
    my $sp = " ";
    # 直後が「空白＋（バックスラッシュ or ( or [ or 句読点）」ならスペース不要＋空白除去
    if ($post2 eq "" || $post2 =~ /^\s*(?:\\|\(|\[|[.,;:!?])/) {
      $sp = "";
      $post2 =~ s/^\s+//;  # 例: " \[Accessed...]" → "\[Accessed...]"
    }
    "_" . $pre . "_ " . $link . $sp . "_" . $post2 . "_"
  }egx;

  # *…* の中の [URL](URL) を外に出す（同様に \ も対象）
  s{
    \*([^*]*?)                                  # 前
    (                                           # リンク全体
      \[https?://[^\]\s]+\]
      \(
        https?://(?:[^()\s]+|\([^()\s]*\))*
      \)
    )
    ([^*]*?)\*                                  # 後
  }{
    my ($pre,$link,$post)=($1,$2,$3);
    my $post2 = $post;
    my $sp = " ";
    if ($post2 eq "" || $post2 =~ /^\s*(?:\\|\(|\[|[.,;:!?])/) {
      $sp = "";
      $post2 =~ s/^\s+//;
    }
    "*" . $pre . "* " . $link . $sp . "*" . $post2 . "*"
  }egx;
' "$DST" > "$DST.tmp" && mv -f "$DST.tmp" "$DST"

# 解決しなかった「)__」を処理する
# -E で拡張正規表現、リテラルの ) は \) でエスケープ
sed -E -i '' 's/\)_{2,}/)/g' "$DST"

# 6) コメント削除（<!-- ... --> を全て消す）
# GNU grep互換のPerlを利用して安全に複数行対応
perl -0777 -pe 's/<!--.*?-->//gs' "$DST" > "${DST}.tmp" && mv "${DST}.tmp" "$DST"

echo "更新完了: $DST"

# PDFの作成
rake pdf  || { echo "PDFビルド失敗"; exit 1; }