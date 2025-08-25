import os
import re
import sys

EXCLUDED_DIRS = {"addons", ".git", ".github"}

issues = []

ANNOTATION_RE = re.compile(r"@(?:tool|icon|static_unload)\b")

def add_issue(path: str, line: int, message: str) -> None:
    issues.append((path, line, message))

for root, dirs, files in os.walk('.', topdown=True):
    rel_root = os.path.relpath(root, '.')
    if any(rel_root == ex or rel_root.startswith(f"{ex}{os.sep}") for ex in EXCLUDED_DIRS):
        dirs[:] = []
        continue
    for fname in files:
        if not fname.endswith('.gd'):
            continue
        path = os.path.join(root, fname)
        try:
            with open(path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
        except Exception as e:
            add_issue(path, 0, f'Could not read file: {e}')
            continue
        if not lines:
            continue
        i = 0
        n = len(lines)
        stripped0 = lines[0].strip()
        if not (
            ANNOTATION_RE.match(stripped0)
            or stripped0.startswith('class_name')
            or stripped0.startswith('extends')
        ):
            add_issue(path, 1, 'File must start with @tool/@icon/@static_unload, class_name, or extends')
        # annotations
        while i < n and ANNOTATION_RE.match(lines[i].strip()):
            i += 1
        # optional class_name
        if i < n and lines[i].strip().startswith('class_name'):
            i += 1
            if i >= n or lines[i].strip() != '':
                add_issue(path, i + 1, 'Missing blank line after class_name')
            else:
                i += 1
        else:
            if i < n and lines[i].strip() == '':
                add_issue(path, i + 1, 'Unexpected blank line before extends')
                while i < n and lines[i].strip() == '':
                    i += 1
        if i >= n or not lines[i].strip().startswith('extends'):
            add_issue(path, i + 1 if i < n else n, 'Missing extends declaration')
            continue
        i += 1
        # two blank lines after extends
        for _ in range(2):
            if i >= n or lines[i].strip() != '':
                add_issue(path, i + 1, 'Expected two blank lines after extends')
                break
            i += 1
        if i < n and lines[i].strip() == '':
            add_issue(path, i + 1, 'Too many blank lines after extends')
            while i < n and lines[i].strip() == '':
                i += 1
        # optional doc comment
        if i < n and lines[i].lstrip().startswith('##'):
            while i < n and lines[i].lstrip().startswith('##'):
                i += 1
            if i >= n or lines[i].strip() != '':
                add_issue(path, i + 1, 'Missing blank line after doc comment')
            else:
                i += 1
                if i < n and lines[i].strip() == '':
                    add_issue(path, i + 1, 'Too many blank lines after doc comment')
                    while i < n and lines[i].strip() == '':
                        i += 1
        # check order: signals -> enums -> consts
        order = ['signal', 'enum', 'const']
        stage = 0
        other_seen = False
        for idx in range(i, n):
            stripped = lines[idx].strip()
            if not stripped or stripped.startswith('#'):
                continue
            if ANNOTATION_RE.match(stripped) or stripped.startswith('class_name') or stripped.startswith('extends'):
                add_issue(path, idx + 1, 'Annotations and declarations must be at the top of the file')
                continue
            if stripped.startswith('signal '):
                if stage > 0 or other_seen:
                    add_issue(path, idx + 1, 'Signals must be declared before enums, consts and other code')
                else:
                    stage = 1
            elif stripped.startswith('enum '):
                if stage > 1 or other_seen:
                    add_issue(path, idx + 1, 'Enums must be declared after signals and before consts')
                else:
                    stage = max(stage, 2)
            elif stripped.startswith('const '):
                if other_seen:
                    add_issue(path, idx + 1, 'Consts must be declared before other code')
                else:
                    stage = 3
            else:
                other_seen = True

if issues:
    print('### ❌ GDScript Structure Check Failed\n')
    print(f'Total issues: {len(issues)}\n')
    for path, line, msg in issues:
        print(f'- `{path}:{line}` {msg}')
    sys.exit(1)
else:
    print('✅ All GDScript files follow the structure guidelines.')
