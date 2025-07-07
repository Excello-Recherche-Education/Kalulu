import os
import re
import sys


def split_params(param_string: str):
    """Split a function parameter string on commas while ignoring brackets."""
    params = []
    current = ""
    depth = 0
    for char in param_string:
        if char == '[':
            depth += 1
        elif char == ']':
            depth = max(0, depth - 1)
        if char == ',' and depth == 0:
            params.append(current.strip())
            current = ""
            continue
        current += char
    if current:
        params.append(current.strip())
    return params

EXCLUDED_DIRS = {"addons", ".git", ".github"}

single_char_vars = []

# Patterns reused from check_gd_nomenclature.py
VAR_PATTERN = re.compile(r"(?:@\w+\s+)*var\s+([A-Za-z0-9_]+)")
FUNC_PATTERN = re.compile(r"func\s+[A-Za-z0-9_]+\s*(\([^)]*\))?")
FOR_PATTERN = re.compile(r"for\s+([A-Za-z0-9_]+)(?:\s*:\s*[^\s]+)?\s+in\b")

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
                continue
            for idx, line in enumerate(lines, 1):
                stripped = line.strip()
                if stripped.startswith('#') or not stripped:
                    continue

                match_var = VAR_PATTERN.match(stripped)
                if match_var:
                    name = match_var.group(1)
                    if len(name) == 1:
                        single_char_vars.append((path, idx, name))

                match_func = FUNC_PATTERN.match(stripped)
                if match_func:
                    params = match_func.group(1)
                    if params:
                        params = params.strip('()')
                        for param in split_params(params):
                            param_name = param.split(':')[0].split('=')[0].strip()
                            if param_name and len(param_name) == 1:
                                single_char_vars.append((path, idx, param_name))

                match_for = FOR_PATTERN.match(stripped)
                if match_for:
                    name = match_for.group(1)
                    if len(name) == 1:
                        single_char_vars.append((path, idx, name))

if single_char_vars:
    print("### \u274c Single Character Variable Check Failed\n")
    print(f"Variables and functions must not have a name of a single character, they must be more explicit.\nFound {len(single_char_vars)} single-character name{'s' if len(single_char_vars) > 1 else ''}:\n")
    for path, idx, name in single_char_vars:
        print(f"- `{path}:{idx}` variable `{name}`")
    sys.exit(1)
else:
    print("\u2705 No single-character variable names found.")
