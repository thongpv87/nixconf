import os

path = "modules/home/apps/wal/templates/colors-hyprland.conf"
with open(path, 'r') as f:
    content = f.read()

lines = content.split('\n')
lua_lines = []
for line in lines:
    stripped = line.strip()
    if not stripped: continue
    if stripped.startswith('$'):
        key, val = stripped.split('=', 1)
        key = key.strip()[1:] # remove $
        val = val.strip()
        lua_lines.append(f'{key} = "{val}"')
        
with open(path.replace('.conf', '.lua'), 'w') as f:
    f.write('\n'.join(lua_lines))
os.remove(path)
