param()
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
$htmlOut = Join-Path $root 'index.html'
$readmeOut = Join-Path $root 'README.adoc'

$articles = @()
$allTags = @{}

$adocFiles = Get-ChildItem -Path $root -Recurse -Filter *.adoc | Where-Object {
    $_.DirectoryName -notmatch '\\.git\\' -and $_.FullName -ne (Join-Path $root 'README.adoc')
}

foreach ($file in $adocFiles) {
    $path = $file.FullName
    $relDir = $file.DirectoryName.Substring($root.Length).TrimStart('\')
    $lines = Get-Content -Path $path -Encoding UTF8

    $title = $null
    $keywords = @()
    $description = $null
    $captureDesc = $false

    foreach ($line in $lines) {
        $trim = $line.Trim()

        if ($trim -match '^= (.+)') {
            $title = $matches[1].Trim()
            continue
        }

        if ($trim -match '^:keywords:\s*(.+)') {
            $keywords = ($matches[1] -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
            continue
        }

        if ($trim -eq 'toc::[]') {
            $captureDesc = $true
            continue
        }

        if ($captureDesc -and $trim -ne '' -and $trim -notmatch '^:' -and $trim -notmatch '^=' -and $trim -notmatch '^image::' -and $trim -notmatch '^-{4,}') {
            $description = $trim -replace '^\*+', '' -replace '\*+$', '' -replace '^NOTE: ', ''
            if ($description.Length -gt 200) { $description = $description.Substring(0, 200) + '...' }
            break
        }
    }

    if (-not $title) { continue }

    if (-not $description) {
        foreach ($line in $lines) {
            $trim = $line.Trim()
            if ($trim -ne '' -and $trim -notmatch '^:' -and $trim -notmatch '^=' -and $trim -notmatch '^image::' -and $trim -ne 'toc::[]' -and $trim -notmatch '^-{4,}') {
                $description = $trim -replace '^\*+', '' -replace '\*+$', ''
                if ($description.Length -gt 200) { $description = $description.Substring(0, 200) + '...' }
                break
            }
        }
    }
    if (-not $description) { $description = 'No description' }

    $hasPdf = Test-Path (Join-Path $file.DirectoryName ($file.BaseName + '.pdf'))
    $relPath = $file.FullName.Substring($root.Length).TrimStart('\')

    foreach ($tag in $keywords) {
        if (-not $allTags.ContainsKey($tag)) { $allTags[$tag] = 0 }
        $allTags[$tag]++
    }

    $articles += [PSCustomObject]@{
        Title       = $title
        Path        = $relPath
        Dir         = if ($relDir) { $relDir } else { '.' }
        Keywords    = $keywords
        Description = $description
        HasPdf      = $hasPdf
        PdfPath     = if ($hasPdf) { ($relPath -replace '\.adoc$', '.pdf') } else { $null }
    }
}

$articles = $articles | Sort-Object Dir, Title
$sortedTags = $allTags.Keys | Sort-Object

# --- Generate index.html ---

$sb = [System.Text.StringBuilder]::new()

$sb.AppendLine('<!DOCTYPE html>') | Out-Null
$sb.AppendLine('<html lang="ru">') | Out-Null
$sb.AppendLine('<head>') | Out-Null
$sb.AppendLine('<meta charset="UTF-8">') | Out-Null
$sb.AppendLine('<meta name="viewport" content="width=device-width, initial-scale=1">') | Out-Null
$sb.AppendLine('<title>Catalog of notes</title>') | Out-Null
$sb.AppendLine('<style>') | Out-Null

@'
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
'@ -split "`n" | ForEach-Object { $sb.AppendLine($_) | Out-Null }

$sb.AppendLine('</style>') | Out-Null
$sb.AppendLine('</head>') | Out-Null
$sb.AppendLine('<body>') | Out-Null
$sb.AppendLine('<div class="container">') | Out-Null
$sb.AppendLine('<h1>Catalog of notes</h1>') | Out-Null
$sb.AppendLine("<p class=""subtitle"">$($articles.Length) articles - click tags to filter</p>") | Out-Null
$sb.AppendLine('<div class="search-box">') | Out-Null
$sb.AppendLine('<input type="text" id="search" placeholder="Search by title, description or tag..." autocomplete="off">') | Out-Null
$sb.AppendLine('</div>') | Out-Null
$sb.AppendLine('<div class="tags-cloud" id="tagsCloud">') | Out-Null
$sb.AppendLine('<span class="reset-btn" id="resetBtn" onclick="resetFilter()">x reset</span>') | Out-Null

foreach ($tag in $sortedTags) {
    $count = $allTags[$tag]
    $tagLower = $tag.ToLower()
    $sb.AppendLine("<span class=""tag-btn"" data-tag=""$tagLower"" onclick=""toggleTag('$tagLower')"">$tag ($count)</span>") | Out-Null
}

$sb.AppendLine('</div>') | Out-Null
$sb.AppendLine('<div id="sections">') | Out-Null

$currentDir = ''
foreach ($a in $articles) {
    $dirName = if ($a.Dir -eq '.') { 'root' } else { $a.Dir }
    if ($dirName -ne $currentDir) {
        if ($currentDir -ne '') {
            $sb.AppendLine('</div>') | Out-Null
            $sb.AppendLine('</div>') | Out-Null
        }
        $currentDir = $dirName
        $displayDir = $dirName -replace '_', ' '
        $sb.AppendLine('<div class="section">') | Out-Null
        $sb.AppendLine("<div class=""section-title"">$displayDir</div>") | Out-Null
        $sb.AppendLine('<div class="cards">') | Out-Null
    }

    $tagAttrs = ($a.Keywords | ForEach-Object { "`"$($_.ToLower())`"" }) -join ','
    $titleEscaped = $a.Title -replace "'", "&#39;"
    $descEscaped = $a.Description -replace "'", "&#39;"
    $kwSearch = ($a.Keywords | ForEach-Object { $_.ToLower() }) -join ' '

    $link = if ($a.HasPdf) { $a.PdfPath } else { $a.Path }

    $sb.AppendLine("<div class=""card"" data-tags='[$tagAttrs]' data-search=""$titleEscaped $descEscaped $kwSearch"">") | Out-Null
    $sb.AppendLine("<div class=""card-title""><a href=""$link"" target=""_blank"">$titleEscaped</a></div>") | Out-Null
    $sb.AppendLine("<div class=""card-desc"">$descEscaped</div>") | Out-Null

    if ($a.Keywords.Count -gt 0) {
        $sb.AppendLine('<div class="card-tags">') | Out-Null
        foreach ($kw in $a.Keywords) {
            $kwLower = $kw.ToLower()
            $sb.AppendLine("<span class=""card-tag"" data-tag=""$kwLower"" onclick=""toggleTag('$kwLower')"">$kw</span>") | Out-Null
        }
        $sb.AppendLine('</div>') | Out-Null
    }

    $adocLink = $a.Path
    $sb.AppendLine("<div class=""card-meta""><span class=""file-badge"">adoc</span> <a href=""$adocLink"">$($a.Path)</a>") | Out-Null
    if ($a.HasPdf) {
        $sb.AppendLine(" &middot; <span class=""file-badge"">pdf</span> <a href=""$($a.PdfPath)"">open PDF</a>") | Out-Null
    }
    $sb.AppendLine('</div>') | Out-Null
    $sb.AppendLine('</div>') | Out-Null
}

if ($currentDir -ne '') {
    $sb.AppendLine('</div>') | Out-Null
    $sb.AppendLine('</div>') | Out-Null
}

$sb.AppendLine('</div>') | Out-Null
$sb.AppendLine('<div id="noResults" class="no-results" style="display:none">Nothing found. Try a different query.</div>') | Out-Null
$sb.AppendLine('<div class="footer">Generated from AsciiDoc &middot; <a href="README.adoc">README.adoc</a></div>') | Out-Null
$sb.AppendLine('</div>') | Out-Null
$sb.AppendLine('<script>') | Out-Null

@'
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
'@ -split "`n" | ForEach-Object { $sb.AppendLine($_) | Out-Null }

$sb.AppendLine('</script>') | Out-Null
$sb.AppendLine('</body>') | Out-Null
$sb.AppendLine('</html>') | Out-Null

[System.IO.File]::WriteAllText($htmlOut, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))

Write-Host "HTML: $htmlOut"

# --- Generate README.adoc ---

$rm = [System.Text.StringBuilder]::new()

function wl { param([string]$s) $rm.AppendLine($s) | Out-Null }

wl '= Каталог заметок'
wl ':doctype: article'
wl ':toc:'
wl ':toc-placement!:'
wl ':toclevels: 2'
wl ':icons: font'
wl ':keywords: catalog, index'
wl ''
wl 'Заметки по embedded Linux, ядру, драйверам и микроконтроллерам.'
wl ''
wl 'toc::[]'
wl ''
wl '== Поиск'
wl ''
wl '* В VS Code: Ctrl+Shift+F по тегу (например, `:keywords: gpio`)'
wl '* В браузере: открыть file:index.html[интерактивный каталог] — фильтрация по тегам и поиск'
wl ''
wl '== Добавление новой статьи'
wl ''
wl '. Создай `.adoc` файл в нужной папке, обязательно укажи `:keywords:` с тегами в заголовке'
wl '. (опционально) Сгенерируй PDF: Ctrl+Shift+B в VS Code (asciidoctor-pdf)'
wl '. Обнови каталог: `powershell -File scripts/generate-index.ps1` — автоматически обновятся README.adoc и index.html'
wl ''
wl '== Статьи'
wl ''

$currentDir = ''
foreach ($a in $articles) {
    $dirName = if ($a.Dir -eq '.') { 'root' } else { $a.Dir }
    if ($dirName -ne $currentDir) {
        $currentDir = $dirName
        $displayDir = $dirName -replace '_', ' '
        wl "=== $displayDir"
        wl ''
    }

    $tagsLine = $a.Keywords -join ', '
    $adocRel = $a.Path -replace '\\', '/'

    $line = "* xref:$adocRel[$($a.Title)] — $($a.Description)"
    wl $line
    if ($a.Keywords.Count -gt 0) {
        $bt = [char]96
        wl ("  *Теги:* " + $bt + $tagsLine + $bt)
    }
    wl ''
}

wl '---'
wl ''
$count = $articles.Length
wl "Сгенерировано автоматически. Всего статей: $count."

[System.IO.File]::WriteAllText($readmeOut, $rm.ToString(), [System.Text.UTF8Encoding]::new($true))

Write-Host "README: $readmeOut"
Write-Host "Articles: $($articles.Length), Tags: $($sortedTags.Count)"
