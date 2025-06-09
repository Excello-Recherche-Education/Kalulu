import os
import re
import sys

EXCLUDED_DIRS = {"addons", ".git", ".github"}

PASCAL_CASE = re.compile(r"^[A-Z][A-Za-z0-9]*$")
SNAKE_CASE = re.compile(r"^_?[a-z][a-z0-9_]*$")

# Allow constants in regular snake_case as well
LOWER_SNAKE_CASE = SNAKE_CASE
UPPER_SNAKE_CASE = re.compile(r"^[A-Z][A-Z0-9_]*$")

issues = []
MESSAGES = {
    'class': 'is a class name and should be in PascalCase',
    'function': 'is a function name and should be in snake_case',
    'variable': 'is a variable name and should be in snake_case',
    'constant': 'is a constant name and should be in UPPER_SNAKE_CASE',
    'signal': 'is a signal name and should be in snake_case',
}

for root, dirs, files in os.walk('.', topdown=True):
    rel_root = os.path.relpath(root, '.')
    if any(rel_root == ex or rel_root.startswith(f"{ex}{os.sep}") for ex in EXCLUDED_DIRS):
        dirs[:] = []
        continue
    for fname in files:
        if fname.endswith('.gd'):
            path = os.path.join(root, fname)
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
            except Exception as e:
                issues.append((path, 0, 'error', f'Could not read file: {e}'))
                continue
            for idx, line in enumerate(lines, 1):
                stripped = line.strip()
                if stripped.startswith('#') or not stripped:
                    continue
                m = re.match(r"class_name\s+([A-Za-z0-9_]+)", stripped)
                if m:
                    name = m.group(1)
                    if not PASCAL_CASE.match(name):
                        issues.append((path, idx, 'class', name))
                m = re.match(r"func\s+([A-Za-z0-9_]+)\s*(\([^)]*\))?", stripped)
                if m:
                    name = m.group(1)
                    if not SNAKE_CASE.match(name):
                        issues.append((path, idx, 'function', name))
                    params = m.group(2)
                    if params:
                        params = params.strip('()')
                # Constants can optionally start with an underscore. They may be in
                # upper snake case or regular snake case.
                    if not UPPER_SNAKE_CASE.match(name) and not LOWER_SNAKE_CASE.match(name):
                            if not param_name:
                                continue
                            param_name = param_name.split(':')[0].split('=')[0].strip()
                            if param_name and not SNAKE_CASE.match(param_name):
                                issues.append((path, idx, 'variable', param_name))
                m = re.match(r"(?:@export\s+)?var\s+([A-Za-z0-9_]+)", stripped)
                if m:
                    name = m.group(1)
                    if not SNAKE_CASE.match(name):
                        issues.append((path, idx, 'variable', name))
                m = re.match(r"const\s+([A-Za-z0-9_]+)", stripped)
                if m:
                    name = m.group(1)
                    if not UPPER_SNAKE_CASE.match(name):
                        issues.append((path, idx, 'constant', name))
                m = re.match(r"signal\s+([A-Za-z0-9_]+)", stripped)
                if m:
                    name = m.group(1)
                    if not SNAKE_CASE.match(name):
                        issues.append((path, idx, 'signal', name))
                m = re.match(r"for\s+([A-Za-z0-9_]+)(?:\s*:\s*[^\s]+)?\s+in\b", stripped)
                if m:
                    name = m.group(1)
                    if not SNAKE_CASE.match(name):
                        issues.append((path, idx, 'variable', name))

if issues:
    print(f"Total issues: {len(issues)}")
    print('GDScript naming issues found:')
    for path, idx, kind, name in issues:
        if kind == 'error':
            message = name
        else:
            message = f"'{name}' {MESSAGES[kind]}"
        print(f"{path}:{idx}: {message}")
    sys.exit(1)
else:
    print('All GDScript files follow the naming conventions.')
