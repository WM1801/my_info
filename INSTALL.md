# Установка

## Linux (Ubuntu/Debian)

### 1. Docker (для сборки PDF)

Что это: контейнер с asciidoctor-pdf, не нужно ставить Ruby вручную.

```bash
sudo apt update
sudo apt install -y docker.io
```

Добавить пользователя в группу docker (чтобы не вводить sudo):

```bash
sudo usermod -aG docker $USER
```

> После этой команды выйди из системы и зайди заново (или перезагрузи компьютер). Иначе Docker попросит пароль.

Проверка:

```bash
docker --version
```

### 2. Генерация каталога

Ничего устанавливать не нужно. Скрипт `scripts/generate-index.sh` написан на bash и работает на любой системе.

Запуск:

```bash
./scripts/generate-index.sh
```

### 3. VS Code (опционально)

Для редактирования с подсветкой синтаксиса и горячими клавишами.

Установка:

```bash
sudo snap install code
```

Открой VS Code → вкладка Extensions (Ctrl+Shift+X) → найди **AsciiDoc** от AsciiDoc → Install.

Горячие клавиши:

- **Ctrl+Shift+B** — собрать PDF для текущего открытого `.adoc`-файла и перегенерировать каталог.

### 4. Любой текстовый редактор

Если не хочешь ставить VS Code — файлы `.adoc` это обычный текст. Открывай любым редактором:

- **nano** — простой, уже установлен: `nano файл.adoc`
- **vim** — мощный: `vim файл.adoc`
- **gedit** — графический: `gedit файл.adoc`

---

## Windows

### 1. Ruby + Asciidoctor PDF (для сборки PDF)

Для генерации PDF из `.adoc` файлов нужен Ruby с гемом asciidoctor-pdf.

1. Скачай и установи [RubyInstaller](https://rubyinstaller.org) (версия с Devkit, по умолчанию).
2. При установке обязательно поставь галочку **«Add Ruby to PATH»**.
3. После установки открой **командную строку (cmd)** и выполни:

```cmd
gem install asciidoctor-pdf
```

Установка займёт 1-2 минуты.

Проверка:

```cmd
asciidoctor-pdf --version
```

### 2. PowerShell

Уже предустановлен в Windows. Используется для генерации каталога.

Запуск:

```powershell
powershell -File scripts\generate-index.ps1
```

### 3. VS Code (опционально)

1. Скачай и установи [VS Code](https://code.visualstudio.com).
2. Открой VS Code → вкладка Extensions (Ctrl+Shift+X) → найди **AsciiDoc** от AsciiDoc → Install.

Горячие клавиши:

- **Ctrl+Shift+B** — собрать PDF для текущего открытого `.adoc`-файла и перегенерировать каталог.

### 4. Любой текстовый редактор

Если не хочешь ставить VS Code — `.adoc` это обычный текст. Открывай любым редактором:

- **Notepad++** — удобный бесплатный редактор с подсветкой
- **Блокнот (Notepad)** — встроен в Windows, всегда под рукой

---

## После установки (что со всем этим делать)

- Открой корневую папку репозитория в VS Code
- Открой любой `.adoc` файл (например, `licheerv_nano/gpio_output.adoc`)
- Нажми **Ctrl+Shift+B** → появится PDF и обновится каталог
- **Файл `index.html`** открой в браузере — там поиск и фильтрация по тегам
- **`README.adoc`** — автоматически сгенерированное оглавление всех заметок

Если нужно только почитать заметки — достаточно открыть `index.html` в браузере. Ничего устанавливать не обязательно.
