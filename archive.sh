#!/bin/bash
cd "$(dirname "$0")"

if ! command -v yt-dlp >/dev/null; then
    echo "yt-dlp가 필요합니다. 설치: brew install yt-dlp"
    exit 1
fi

python3 -B archive.py "$@"
status=$?

# archive.py는 볼트의 타임스탬프 노트를 쓰기만 하고 커밋하지 않는다.
# 그대로 두면 노트가 커밋되지 않은 채 남아, 다음 git pull이 "로컬 변경을
# 덮어쓰게 된다"며 거부한다. 여기서 바로 커밋해 작업트리를 깨끗하게 둔다.
# 푸시는 옵시디언 Git 플러그인이 알아서 하므로 건드리지 않는다.
if [ $status -eq 0 ]; then
    # 볼트 경로는 chat.py와 같은 규칙으로 구한다 (config.json이 우선).
    vault=$(python3 -c "
import json, os
try:
    cfg = json.load(open('config.json', encoding='utf-8'))
except Exception:
    cfg = {}
print(os.path.expanduser(cfg.get('obsidian_vault') or '~/Documents/Obsidian Vault'))
" 2>/dev/null)

    note="치지직/타임스탬프.md"
    if [ -n "$vault" ] && [ -d "$vault/.git" ] && [ -f "$vault/$note" ]; then
        # 경로를 지정해 커밋하므로 볼트의 다른 변경은 함께 딸려가지 않는다.
        if ! git -C "$vault" diff --quiet -- "$note" 2>/dev/null; then
            if git -C "$vault" commit -q -m "치지직 타임스탬프 기록" -- "$note"; then
                echo "볼트에 타임스탬프 노트를 커밋했습니다."
            else
                echo "타임스탬프 노트 커밋에 실패했습니다. 볼트에서 직접 확인하세요."
            fi
        fi
    fi
fi

exit $status
