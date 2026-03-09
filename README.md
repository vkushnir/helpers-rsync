# rsync sync scripts

Набор из трёх скриптов для синхронизации рабочей копии проекта между двумя директориями
(например, git-репозиторий ↔ cowork-сессия).

## Файлы

| Файл | Назначение |
|------|-----------|
| `sync.zsh` | Базовый rsync-wrapper. Принимает `<src>` и `<dst>` явно. |
| `pull.zsh` | Тянет изменения **из dst в src** (cowork → git). |
| `push.zsh` | Пушит изменения **из src в dst** (git → cowork). |
| `.rsync-filter` | Правила исключений для rsync + конфиг путей. |

## Использование

```zsh
./pull.zsh          # синхронизировать dst → src
./push.zsh          # синхронизировать src → dst
./sync.zsh <src> <dst>   # произвольное направление
```

## Конфигурация путей — `.rsync-filter`

Пути проекта задаются прямо в файле `.rsync-filter` в виде комментариев-маркеров.
`pull.zsh` и `push.zsh` читают их автоматически.

```
# @src: /path/to/git/repo/myproject
# @dst: /path/to/cowork/myproject
```

**Правила:**

- `@src:` — «источник истины», как правило git-репозиторий.
- `@dst:` — рабочая копия на другом конце (cowork, удалённая машина и т.д.).
- Оба параметра **опциональны**. Если параметр не указан:
  - `pull.zsh` использует директорию, где находится `.rsync-filter`, как `@dst:`
  - `push.zsh` использует директорию, где находится `.rsync-filter`, как `@src:`
- Обязателен хотя бы **противоположный** конец (`@src:` для pull, `@dst:` для push).

## Пример `.rsync-filter`

```
# rsync exclude rules — used by sync.zsh via --exclude-from
# For git-only excludes see .gitignore.

# Project paths — read by pull.zsh and push.zsh
# @src: /home/user/projects/myproject
# @dst: /home/user/cowork/myproject

# Git internals
.git/

# IDE
.idea/
.vscode/

# Build artifacts
dist/
build/
.build/

# Dependency / cache directories
node_modules/
.cache/
__pycache__/

# Vim swap files
*.swp
*.swo

# macOS
.DS_Store
._*
```

## Поиск `.rsync-filter`

Скрипты ищут файл в следующем порядке:

1. Директория, из которой запущен скрипт (или директория симлинка).
2. Директория реального файла скрипта (если запущен через симлинк из другого места).

Это позволяет хранить `pull.zsh` / `push.zsh` как общие скрипты в одном месте
и симлинкать их в каждый проект, у каждого из которых свой `.rsync-filter`.

```
~/bin/pull.zsh          ← реальный файл
~/bin/push.zsh
~/bin/sync.zsh

~/projects/foo/pull.zsh → ~/bin/pull.zsh   ← симлинк
~/projects/foo/.rsync-filter               ← свой конфиг для foo

~/projects/bar/pull.zsh → ~/bin/pull.zsh   ← симлинк
~/projects/bar/.rsync-filter               ← свой конфиг для bar
```

## Поведение rsync

`sync.zsh` запускает rsync со следующими флагами:

| Флаг | Эффект |
|------|--------|
| `-a` | archive: рекурсия, права, время изменения, симлинки |
| `-v` | verbose: список переданных файлов |
| `--delete` | удалять файлы в dst, которых нет в src |
| `--progress` | прогресс передачи каждого файла |
| `--exclude-from` | правила исключений из `.rsync-filter` |

> **Внимание:** `--delete` работает только для файлов, не попавших под exclude-правила.
> Исключённые файлы в dst никогда не удаляются.
