#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
html_out="$root/index.html"
readme_out="$root/README.adoc"

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

articles_file="$temp_dir/articles.txt"
> "$articles_file"

declare -A all_tags

FS=$'\x1F'

while IFS= read -r -d '' file; do
    rel_path="${file#$root/}"
    rel_dir="$(dirname "$rel_path")"
    [ "$rel_dir" = "." ] && rel_dir="root"

    title=$(sed -n '/^= /{s/^= //;s/^[[:space:]]*//;s/[[:space:]]*$//;p;q}' "$file")
    [ -z "$title" ] && continue

    keywords_line=$(sed -n '/^:keywords:/{s/^:keywords:[[:space:]]*//;p;q}' "$file")

    IFS=',' read -ra kw_array <<< "$keywords_line"
    for kw in "${kw_array[@]}"; do
        kw="$(echo "$kw" | xargs)"
        [ -n "$kw" ] && all_tags["$kw"]=$(( ${all_tags["$kw"]-0} + 1 ))
    done

    desc=$(awk '
        /^toc::\[\]/ { found=1; next }
        found && /^[^=:*>-]/ && /^[^*\n]/ && NF {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "")
            gsub(/^\*+|\*+$/, "")
            gsub(/^NOTE: /, "")
            gsub(/^[[:space:]]+|[[:space:]]+$/, "")
            if (length > 200) $0 = substr($0, 1, 200) "..."
            print; exit
        }
    ' "$file")

    if [ -z "$desc" ]; then
        desc=$(awk '
            /^[^=:*>-]/ && /^[^*\n]/ && NF && $0 !~ /^---/ {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "")
                gsub(/^\*+|\*+$/, "")
                gsub(/^NOTE: /, "")
                gsub(/^[[:space:]]+|[[:space:]]+$/, "")
                if (length > 200) $0 = substr($0, 1, 200) "..."
                print; exit
            }
        ' "$file")
    fi
    [ -z "$desc" ] && desc="No description"

    pdf_path="${file%.adoc}.pdf"
    has_pdf="false"
    [ -f "$pdf_path" ] && has_pdf="true"

    echo "${rel_dir}${FS}${title}${FS}${rel_path}${FS}${keywords_line}${FS}${desc}${FS}${has_pdf}" >> "$articles_file"

done < <(find "$root" -name '*.adoc' -not -path '*/.git/*' -not -path "$root/README.adoc" -print0 | sort -z)

sorted_file="$temp_dir/sorted.txt"
sort -t"$FS" -k1,1 -k2,2 "$articles_file" > "$sorted_file"

declare -a dirs titles paths kw_lines descs has_pdfs

while IFS="$FS" read -r d t p kw desc pdf; do
    dirs+=("$d")
    titles+=("$t")
    paths+=("$p")
    kw_lines+=("$kw")
    descs+=("$desc")
    has_pdfs+=("$pdf")
done < "$sorted_file"

article_count=${#titles[@]}

sorted_tags=$(printf '%s\n' "${!all_tags[@]}" | sort)

escape_html() {
    local s="$1"
    s="${s//&/&amp;}"
    s="${s//</&lt;}"
    s="${s//>/&gt;}"
    s="${s//\"/&quot;}"
    s="${s//\'/&#39;}"
    echo "$s"
}

{
cat << 'HTMLHEAD'
<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Catalog of notes</title>
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#f5f5f5;color:#222;line-height:1.6;padding:20px}
.container{max-width:960px;margin:0 auto}
h1{font-size:1.8rem;margin-bottom:4px}
.subtitle{color:#666;font-size:.9rem;margin-bottom:20px}
.search-box{margin-bottom:16px}
.search-box input{width:100%;padding:10px 14px;font-size:1rem;border:1px solid #ccc;border-radius:8px;outline:none;transition:border .2s}
.search-box input:focus{border-color:#2563eb;box-shadow:0 0 0 3px rgba(37,99,235,.15)}
.tags-cloud{margin-bottom:20px;display:flex;flex-wrap:wrap;gap:6px}
.tag-btn{display:inline-block;padding:4px 12px;font-size:.8rem;border-radius:20px;background:#e5e7eb;color:#444;cursor:pointer;transition:all .15s;border:1px solid transparent;user-select:none}
.tag-btn:hover{background:#d1d5db}
.tag-btn.active{background:#2563eb;color:#fff;border-color:#1d4ed8}
.reset-btn{display:inline-block;padding:4px 12px;font-size:.8rem;border-radius:20px;background:transparent;color:#999;cursor:pointer;border:1px dashed #ccc;transition:all .15s;user-select:none}
.reset-btn:hover{border-color:#999;color:#555}
.section{margin-bottom:32px}
.section-title{font-size:1.2rem;font-weight:600;color:#2563eb;margin-bottom:12px;padding-bottom:6px;border-bottom:2px solid #e5e7eb}
.cards{display:flex;flex-direction:column;gap:8px}
.card{background:#fff;border-radius:8px;padding:12px 16px;box-shadow:0 1px 3px rgba(0,0,0,.08);transition:box-shadow .15s,opacity .15s;border-left:3px solid #2563eb}
.card.hidden{display:none}
.card-title{font-size:1rem;font-weight:600;margin-bottom:4px}
.card-title a{color:#1e293b;text-decoration:none}
.card-title a:hover{color:#2563eb}
.card-desc{font-size:.85rem;color:#666;margin-bottom:6px}
.card-tags{display:flex;flex-wrap:wrap;gap:4px}
.card-tag{display:inline-block;padding:1px 8px;font-size:.7rem;border-radius:12px;background:#f0f4ff;color:#2563eb;cursor:pointer;transition:all .15s}
.card-tag:hover{background:#2563eb;color:#fff}
.card-meta{font-size:.75rem;color:#999;margin-top:4px}
.card-meta a{color:#999;text-decoration:none}
.card-meta a:hover{color:#2563eb}
.file-badge{display:inline-block;padding:0 6px;font-size:.7rem;border-radius:4px;background:#e5e7eb;color:#555}
.no-results{text-align:center;color:#999;padding:40px 0;font-size:.95rem}
.footer{text-align:center;color:#aaa;font-size:.8rem;margin-top:40px;padding:20px 0}
</style>
</head>
<body>
<div class="container">
HTMLHEAD

echo "<h1>Catalog of notes</h1>"
echo "<p class=\"subtitle\">$article_count articles - click tags to filter</p>"
echo '<div class="search-box">'
echo '<input type="text" id="search" placeholder="Search by title, description or tag..." autocomplete="off">'
echo '</div>'
echo '<div class="tags-cloud" id="tagsCloud">'
echo '<span class="reset-btn" id="resetBtn" onclick="resetFilter()">x reset</span>'

while IFS= read -r tag; do
    [ -z "$tag" ] && continue
    count=${all_tags[$tag]}
    tag_lower=$(echo "$tag" | tr '[:upper:]' '[:lower:]')
    echo "<span class=\"tag-btn\" data-tag=\"$tag_lower\" onclick=\"toggleTag('$tag_lower')\">$(escape_html "$tag") ($count)</span>"
done <<< "$sorted_tags"

echo '</div>'
echo '<div id="sections">'

current_dir=""
for ((i = 0; i < article_count; i++)); do
    dir="${dirs[$i]}"
    title="${titles[$i]}"
    path="${paths[$i]}"
    keywords="${kw_lines[$i]}"
    desc="${descs[$i]}"
    has_pdf="${has_pdfs[$i]}"

    display_dir="${dir//_/ }"

    if [ "$dir" != "$current_dir" ]; then
        [ -n "$current_dir" ] && echo '</div>' && echo '</div>'
        current_dir="$dir"
        echo '<div class="section">'
        echo "<div class=\"section-title\">$display_dir</div>"
        echo '<div class="cards">'
    fi

    IFS=',' read -ra kws <<< "$keywords"
    tag_attrs=""
    for kw in "${kws[@]}"; do
        kw_trimmed=$(echo "$kw" | xargs)
        [ -n "$kw_trimmed" ] && tag_attrs="$tag_attrs\"$(echo "$kw_trimmed" | tr '[:upper:]' '[:lower:]')\","
    done
    tag_attrs="[${tag_attrs%,}]"

    title_escaped=$(escape_html "$title")
    desc_escaped=$(escape_html "$desc")

    if [ "$has_pdf" = "true" ]; then
        link="${path%.adoc}.pdf"
    else
        link="$path"
    fi

    echo "<div class=\"card\" data-tags='$tag_attrs' data-search=\"$title_escaped $desc_escaped\">"
    echo "<div class=\"card-title\"><a href=\"$link\" target=\"_blank\">$title_escaped</a></div>"
    echo "<div class=\"card-desc\">$desc_escaped</div>"

    if [ -n "$keywords" ]; then
        echo '<div class="card-tags">'
        for kw in "${kws[@]}"; do
            kw_trimmed=$(echo "$kw" | xargs)
            [ -z "$kw_trimmed" ] && continue
            kw_lower=$(echo "$kw_trimmed" | tr '[:upper:]' '[:lower:]')
            echo "<span class=\"card-tag\" data-tag=\"$kw_lower\" onclick=\"toggleTag('$kw_lower')\">$(escape_html "$kw_trimmed")</span>"
        done
        echo '</div>'
    fi

    adoc_link="$path"
    echo "<div class=\"card-meta\"><span class=\"file-badge\">adoc</span> <a href=\"$adoc_link\">$(escape_html "$path")</a>"
    if [ "$has_pdf" = "true" ]; then
        pdf_link="${path%.adoc}.pdf"
        echo " · <span class=\"file-badge\">pdf</span> <a href=\"$pdf_link\">open PDF</a>"
    fi
    echo '</div>'
    echo '</div>'
done

if [ -n "$current_dir" ]; then
    echo '</div>'
    echo '</div>'
fi

echo '</div>'
echo '<div id="noResults" class="no-results" style="display:none">Nothing found. Try a different query.</div>'
echo '<div class="footer">Generated from AsciiDoc · <a href="README.adoc">README.adoc</a></div>'
echo '</div>'

cat << 'JSEND'
<script>
let activeTags=[];
const cards=document.querySelectorAll('.card');
const sections=document.querySelectorAll('.section');
const noResults=document.getElementById('noResults');
const searchInput=document.getElementById('search');
const resetBtn=document.getElementById('resetBtn');
function filterAll(){
  const q=searchInput.value.toLowerCase().trim();
  let anyVisible=false;
  cards.forEach(c=>{
    let m=true;
    if(activeTags.length>0){
      let t; try { t=JSON.parse(c.dataset.tags||'[]'); } catch(e) { t=[]; }
      m=activeTags.every(x=>t.includes(x));
    }
    if(m&&q){
      const s=(c.dataset.search||'').toLowerCase();
      m=s.includes(q);
    }
    c.classList.toggle('hidden',!m);
    if(m) anyVisible=true;
  });
  sections.forEach(s=>{
    const v=s.querySelectorAll('.card:not(.hidden)');
    s.style.display=v.length===0?'none':'';
  });
  noResults.style.display=anyVisible?'none':'block';
  resetBtn.style.display=(activeTags.length>0||q)?'inline-block':'none';
}
function toggleTag(tag){
  const i=activeTags.indexOf(tag);
  i>=0?activeTags.splice(i,1):activeTags.push(tag);
  document.querySelectorAll('.tag-btn').forEach(b=>{
    b.classList.toggle('active',activeTags.includes(b.dataset.tag));
  });
  filterAll();
}
function resetFilter(){
  activeTags=[];
  searchInput.value='';
  document.querySelectorAll('.tag-btn').forEach(b=>b.classList.remove('active'));
  filterAll();
}
searchInput.addEventListener('input',filterAll);
</script>
</body>
</html>
JSEND

} > "$html_out"

echo "HTML: $html_out"

{
echo '= Каталог заметок'
echo ':doctype: article'
echo ':toc:'
echo ':toc-placement!:'
echo ':toclevels: 2'
echo ':icons: font'
echo ':keywords: catalog, index'
echo ''
echo 'Заметки по embedded Linux, ядру, драйверам и микроконтроллерам.'
echo ''
echo 'toc::[]'
echo ''
echo '== Поиск'
echo ''
echo '* В VS Code: Ctrl+Shift+F по тегу (например, `:keywords: gpio`)'
echo '* В браузере: открыть file:index.html[интерактивный каталог] — фильтрация по тегам и поиск'
echo ''
echo '== Добавление новой статьи'
echo ''
echo '. Создай `.adoc` файл в нужной папке, обязательно укажи `:keywords:` с тегами в заголовке'
echo '. (опционально) Сгенерируй PDF: Ctrl+Shift+B в VS Code (asciidoctor-pdf)'
echo '. Обнови каталог: `./scripts/generate-index.sh` — автоматически обновятся README.adoc и index.html'
echo ''
echo '== Статьи'
echo ''

current_dir=""
for ((i = 0; i < article_count; i++)); do
    dir="${dirs[$i]}"
    title="${titles[$i]}"
    path="${paths[$i]}"
    keywords="${kw_lines[$i]}"
    desc="${descs[$i]}"

    display_dir="${dir//_/ }"

    if [ "$dir" != "$current_dir" ]; then
        current_dir="$dir"
        echo "=== $display_dir"
        echo ''
    fi

    adoc_path="${path//\\//}"
    echo "* xref:$adoc_path[$title] — $desc"
    if [ -n "$keywords" ]; then
        echo "  *Теги:* \`$keywords\`"
    fi
    echo ''
done

echo '---'
echo ''
echo "Сгенерировано автоматически. Всего статей: $article_count."

} > "$readme_out"

echo "README: $readme_out"
echo "Articles: $article_count, Tags: ${#all_tags[@]}"
