#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p "(python3.withPackages (ps: with ps; [ vdf xdg ]))"
# ^ this isn't a package dependency because the script only basically runs once per system

from os.path import expanduser, isfile, isdir, islink, join
from typing import Optional
from xdg import xdg_data_home, xdg_cache_home, xdg_config_home

import json
import os
import vdf
import sys
import shlex
import shutil

def exit(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)
    sys.exit(1)

steam_paths = [
    os.path.join(xdg_data_home(), 'Steam'),
    expanduser("~/.steam/steam"),
    expanduser("~/.var/app/com.valvesoftware.Steam/.local/share/Steam"),
]

steam_path = None
for path in steam_paths:
    if isfile(join(path, "steamapps", "libraryfolders.vdf")):
        steam_path = path
        break

if steam_path is not None:
    LIBS = vdf.load(open(join(steam_path, "steamapps", "libraryfolders.vdf"), 'rt', encoding='utf-8')).get('libraryfolders', [])
else:
    LIBS = {}

if steam_path is None:
    print("Warning: Couldn't find Steam.")

def ensure(func, x):
    if func(x):
        return x
    return None

def compatdata(lib, id):
    return join(lib, 'steamapps', 'compatdata', id)

def find_path(id, name, default_path, multi=False):
    libs = []

    for folder in LIBS.values():
        if id in folder.get('apps', {}):
            libs.append(folder['path'])

    if len(libs) == 0:
        if multi:
            return []
        else:
            return None, None

    if not multi:
        libs = [choose(libs, f'More than one Steam library contains {name}! Please choose the one you want to use.')]
    ret = []
    low_prio = []
    for lib in libs:
        try:
            manifest = vdf.load(open(join(lib, 'steamapps', f'appmanifest_{id}.acf'), 'rt', encoding='utf-8'))
            if 'AppState' not in manifest.keys() or 'installdir' not in manifest['AppState'].keys():
                raise FileNotFoundError()
            game_path = join(lib, 'steamapps', 'common', manifest['AppState']['installdir'])
            append_to = ret
        except FileNotFoundError:
            game_path = join(lib, 'steamapps', 'common', default_path)
            append_to = low_prio

        if isdir(game_path) and len(os.listdir(game_path)):
            append_to.append((game_path, lib))
    if multi:
        return list(map(lambda x: x[0], ret + low_prio))
    elif len(ret):
        return (ret + low_prio)[0]
    else:
        return None, None

def choose(items, comment, default=0):
    if len(items) == 1:
        return items[0]
    print(comment)
    for i, lib in enumerate(items):
        print(f'[{i}] {lib}')
    while True:
        num = input(f'Enter the number (default: {default}): ')
        if not num:
            return items[default]
        else:
            try:
                num = int(num)
                if num < 0:
                    raise ValueError()
                return items[num]
            except (ValueError, IndexError):
                print('Invalid number!')
dbg = find_path('9420', 'Supreme Commander: Forged Alliance', 'Supreme Commander Forged Alliance')
print(dbg)
game_path, lib_path = dbg

def find_proton(lib_path, id):
    prefix = compatdata(lib_path, id)
    if not isfile(join(prefix, 'config_info')):
        return None, None

    proton_path = None

    # Find the Proton that set this prefix up
    try:
        protons = set()
        proton_dirs = list(map(lambda x: '/files/' + x, ['share/fonts', 'lib', 'lib64', 'share/default_pfx']))
        proton_dirs = proton_dirs + list(map(lambda x: x + '/', proton_dirs))
        for line in open(join(prefix, 'config_info')):
            line = line.strip()
            for proton_dir in proton_dirs:
                if line.endswith(proton_dir):
                    protons.add(line[:-len(proton_dir)])
                    break
        protons = list(protons)
        if len(protons) != 1:
            raise ValueError()
        proton_path = protons[0]
    except (FileNotFoundError, ValueError):
        return None, None

    prefix = join(prefix, 'pfx')
    return ensure(isfile, join(proton_path, 'proton')), prefix

if lib_path != None:
    proton_path, prefix_path = find_proton(lib_path, '9420')
else:
    prefix_type = None
    proton_path = None

if steam_path is not None:
    reaper_path = ensure(isfile, join(steam_path, 'ubuntu12_32', 'reaper'))
    launch_wrapper_path = ensure(isfile, join(steam_path, 'ubuntu12_32', 'steam-launch-wrapper'))
else:
    reaper_path = None
    launch_wrapper_path = None

RUNTIMES = [
    ('medic', None), # v4/debian12
    ('sniper', '16283507'), # v3/debian11
    ('soldier', '1391110'), # v2/debian10
    ('heavy', None), # v1.5/debian8
    ('scout', '1070560'), # v1/ubuntu12
]

PROTONS = [
    ('experimental', '1493710'),
    ('next', '2230260'),
    ('hotfix', '2180100'),
    ('7.0', '1887720'),
    ('6.3', '1580130'),
    ('5.13', '1420170'),
    ('5.0', '1245040'),
    ('4.11', '1113280'),
    ('4.2', '1054830'),
    ('3.16 beta', '996510'),
    ('3.16', '961940'),
    ('3.7 beta', '930400'),
    ('3.7', '858280'),
]

def find_base(name, id, human_name, path):
    ret = []

    if id != None:
        ret.extend(find_path(id, human_name, path, True))

    if not ret:
        libs = []

        for folder in LIBS.values():
            if id in folder.get('apps', {}):
                libs.append(folder['path'])

        for lib in libs:
            path = join(lib, 'steamapps', 'common', rt_path)
            if isdir(path):
                ret.append(path)

    return ret

def find_proton2(name, id):
    rt_name = 'Proton ' + name.capitalize()
    rt_path = rt_name
    if name == 'experimental':
        rt_path = 'Proton - Experimental'

    ret = find_base(name, id, rt_name, rt_path)

    return list(map(lambda x: ensure(isfile, join(x, 'proton')), ret))

def find_runtime(name, id):
    if name == 'scout':
        rt_name = 'Steam Linux Runtime'
        rt_path = 'SteamLinuxRuntime'
    else:
        rt_name = 'Steam Linux Runtime - ' + name.capitalize()
        rt_path = 'SteamLinuxRuntime_' + name

    ret = find_base(name, id, rt_name, rt_path)

    return list(filter(lambda x: isfile(join(x, '_v2-entry-point')), ret))

def ask_yn(question, default):
    default_yn = 'Y' if default else 'N'
    while True:
        ans = input(f'{question} (Y/n, default: {default_yn}): ')
        if not ans:
            return default
        if ans.lower().startswith('y'):
            return True
        elif ans.lower().startswith('n'):
            return False
        print('Invalid answer! Please write yes or no')

if game_path is not None:
    if not ask_yn(f'Detected game path:\n{game_path}.\n\nCorrect?', True):
        game_path = None

while game_path is None:
    path = ensure(isdir, input('Please enter game path: '))
    if path is None:
        print('Invalid game path!')

runtimes = []
for name, id in RUNTIMES:
    runtimes.extend(find_runtime(name, id))
protons = []
for name, id in PROTONS:
    protons.extend(find_proton2(name, id))

if len(runtimes):
    runtime_path = runtimes[0]
else:
    runtime_path = None

needs_setup = proton_path is None

if proton_path is None and protons:
    proton_path = protons[0]

if runtime_path is None:
    proton_path = None

def command(proton, runtime, wrapper, reaper, launcher, prepend):
    if launcher:
        return command(proton, runtime, wrapper, reaper, None, prepend + shlex.quote(launcher) + ' ')
    if reaper is not None:
        return command(proton, runtime, wrapper, None, None, prepend + f'{shlex.quote(reaper)} SteamLaunch AppId=9420 -- ')
    if wrapper is not None:
        return command(proton, runtime, None, None, None, prepend + f'{shlex.quote(wrapper)} -- ')
    if runtime is not None:
        return command(proton, None, None, None, None, prepend + f'{shlex.quote(join(runtime, "_v2-entry-point"))} --verb=waitforexitandrun -- ')
    if proton is not None:
        return command(None, None, None, None, None, prepend + f'{shlex.quote(proton)} waitforexitandrun ')
    return prepend + '"%s"'

old_setup = not ask_yn('Use the new setup wizard for Steam+Proton? Answer no if you plan to use Wine.', True)

if not old_setup:
    input("1. Set Supreme Commander: Forged Alliance's launch options in Steam to `PROTON_NO_ESYNC=1 PROTON_DUMP_DEBUG_COMMANDS=1 %command%` and press enter. ")
    input("2. Run Supreme Commander: Forged Alliance at least once and press enter. ")
    source_path = f'/tmp/proton_{os.environ.get("USER", "")}/run'
    while not os.path.exists(source_path):
        if ask_yn(f'Failed to locate {source_path}. Switch to legacy wizard instead? If not, run Supreme Commander again and answer no to try again.', True):
            old_setup = True
            break

if not old_setup:
    os.makedirs(expanduser('~/.local/share/faforever'), exist_ok=True)
    target_path = expanduser('~/.local/share/faforever/run.sh')
    shutil.copy2(source_path, target_path)
    print(f'Launch command will be set to `steam-run {target_path} "%s"`. You may modify the `run.sh` script as necessary.')
    cmd: Optional[str] = f'steam-run {target_path} "%s"'
else:
    launcher: Optional[str] = 'steam-run'
    env = {'PROTON_NO_ESYNC':'1'} if proton_path else {}
    def cur_cmd():
        env_s = ''
        for k, v in env.items():
            env_s += f'{shlex.quote(k)}={shlex.quote(v)} '
        if env_s:
            env_s = 'env ' + env_s
        return command(proton_path, runtime_path, launch_wrapper_path, reaper_path, launcher, env_s)

    cmd = cur_cmd()

    print('\nAutodetected launch command:')
    print(cmd)
    if not ask_yn('\nCorrect?', True):
        cmd = None

    def ask_cmd():
        val = cur_cmd()
        print('Launch command:', val)
        if ask_yn('\nCorrect?', True):
            return val

    if cmd is None:
        env_s = ''
        for k, v in env.items():
            env_s += f'{shlex.quote(k)}={shlex.quote(v)} '
        print('Env vars:', env_s if env_s else 'none')
        if not ask_yn('\nCorrect?', True):
            while True:
                vars = shlex.split(input('Enter your own env vars: '))
                env = {}
                try:
                    for var in vars:
                        k, v = var.split('=')
                        env[k] = v
                    break
                except IndexError:
                    print('Invalid environment variable list!')
            cmd = ask_cmd()

    if cmd is None and (runtime_path is None or not ask_yn('Use Steam runtime?', True)):
        runtime_path = None
        launch_wrapper_path = None
        reaper_path = None
        if steam_path and ask_yn('Use Proton?', True):
            env['STEAM_COMPAT_CLIENT_INSTALL_PATH'] = steam_path
            if prefix_path is not None and os.path.split(prefix_path)[-1] == 'pfx':
                pfx = os.path.split(prefix_path)[0]
                pfx1 = expanduser(input(f'Enter prefix path (Default: {prefix_path}): '))
                if pfx1:
                    pfx = pfx1
            else:
                pfx = expanduser(input('Enter prefix path: '))
            needs_setup = True
            env['STEAM_COMPAT_DATA_PATH'] = pfx
            prefix_path = join(pfx, 'pfx')
            if proton_path is not None:
                cmd = ask_cmd()
            if cmd is None:
                proton_path = expanduser(input('Enter path to proton binary: '))
        elif ask_yn('Use Wine?', True):
            if 'PROTON_NO_ESYNC' in env.keys():
                del env['PROTON_NO_ESYNC']
            if 'PROTON_NO_FSYNC' in env.keys():
                del env['PROTON_NO_FSYNC']
            proton_path = None
            if ask_yn('Use 32-bit WINEARCH?', True):
                env['WINEARCH'] = 'win32'
            prefix_path = expanduser(input('Enter prefix path (default: ~/.wine): '))
            if prefix_path:
                env['WINEPREFIX'] = prefix_path
            else:
                prefix_path = expanduser('~/.wine')
            needs_setup = True
            launcher = 'wine'
            cmd = ask_cmd()
            if cmd is None:
                launcher = expanduser(input('Enter custom path to wine binary: '))
                cmd = ask_cmd()
        else:
            launcher = None
            prefix_path = None
            if 'PROTON_NO_ESYNC' in env.keys():
                del env['PROTON_NO_ESYNC']
            if 'PROTON_NO_FSYNC' in env.keys():
                del env['PROTON_NO_FSYNC']
            proton_path = None
    elif cmd is None:
        # use steam runtime, implying proton
        if not ask_yn('Is the correct Proton version being used?', True):
            opts = ['Custom']
            opts.extend(protons)
            proton_path = choose(opts, 'Choose the Proton version.', 1)
            if proton_path == 'Custom':
                proton_path = expanduser(input('Enter custom path to proton binary: '))
            cmd = ask_cmd()
        if cmd is None and not ask_yn('Is the correct Steam Runtime being used?', True):
            opts = ['Custom']
            opts.extend(runtimes)
            runtime_path = choose(opts, 'Choose the Steam Runtime', 1)
            if runtime_path == 'Custom':
                runtime_path = expanduser(input('Enter custom Steam runtime path (must have a _v2-entry-point binary inside): '))
            cmd = ask_cmd()
        if cmd is None and not ask_yn('Use steam-launch-wrapper?', True):
            launch_wrapper_path = None
            cmd = ask_cmd()
        if cmd is None and not ask_yn('Use reaper?', True):
            reaper_path = None
            cmd = ask_cmd()
        if cmd is None and (launch_wrapper_path is not None or reaper_path is not None) and not ask_yn('Use 32-bit steam-launch-wrapper/reaper?', True):
            if reaper_path is not None and steam_path is not None:
                reaper_path = ensure(isfile, join(steam_path, 'ubuntu12_64', 'reaper'))
            if launch_wrapper_path is not None and steam_path is not None:
                launch_wrapper_path = ensure(isfile, join(steam_path, 'ubuntu12_64', 'steam-launch-wrapper'))
            cmd = ask_cmd()

    if cmd is None:
        needs_setup = True
        print("Couldn't automatically guess the launch command.")
        cmd = input('Enter custom launch command (don\'t forget to use "%s" instead of exe path): ')

if needs_setup:
    print("Don't forget to set the prefix up for SupCom!")

save_path = ''
save_base = ''
if prefix_path:
    users = join(prefix_path, 'drive_c', 'users')
    if proton_path:
        user = join(users, 'steamuser')
    else:
        user = join(users, os.getlogin())
    save_base = join(user, 'AppData', 'Local', 'Gas Powered Games', 'Supreme Commander Forged Alliance')
    save_path = join(save_base, 'Game.prefs')

if save_path:
    print('\nAutomatically inferred Game.prefs save path:')
    print(save_path)
    if not isfile(save_path):
        print('\n!!! Warning: file does not exist!', end='')

save_is_default = True
if not save_path or not ask_yn('\nCorrect?', True):
    save_is_default = False
    save_path = expanduser(input('Enter Game.prefs save path (will be inside the Wine prefix): '))
    save_base = os.path.split(save_path)[0]

config = {'forgedAlliance':{'installationPath': game_path, 'preferencesFile': save_path, 'executableDecorator': cmd}}

if ask_yn('Enable IPv6 support?', True):
    config['forgedAlliance']['allowIpv6'] = True

changed_dirs = False
if ask_yn('Change FAF config to use XDG_DATA_HOME (~/.local/share)?', True):
    changed_dirs = True
    data = xdg_data_home()
    cache = xdg_cache_home()
    faf_home = join(data, 'faforever')
    sup_home = join(data, 'Gas Powered Games', 'Supreme Commander Forged Alliance')
    sup_config = join(xdg_config_home(), 'Gas Powered Games', 'Supreme Commander Forged Alliance')
    sup_cache = join(cache, 'Gas Powered Games', 'Supreme Commander Forged Alliance')

    if save_is_default and not islink(save_path):
        os.makedirs(sup_config, exist_ok=True)
        old_save_path = save_path
        save_path = join(sup_config, 'Game.prefs')
        config['forgedAlliance']['preferencesFile'] = save_path
        if isfile(old_save_path):
            if isfile(save_path):
                os.remove(old_save_path)
            else:
                shutil.move(old_save_path, save_path)
        os.symlink(save_path, old_save_path)

    old_sup_cache = join(save_base, 'cache') if save_is_default else None
    if save_is_default and old_sup_cache and not islink(old_sup_cache):
        os.makedirs(join(cache, 'Gas Powered Games'), exist_ok=True)
        if isdir(old_sup_cache):
            shutil.move(old_sup_cache, sup_cache)
        os.symlink(sup_cache, old_sup_cache)

    config['forgedAlliance']['vaultBaseDirectory'] = sup_home
    config['forgedAlliance']['modsDirectory'] = join(sup_home, 'mods')
    config['forgedAlliance']['mapsDirectory'] = join(sup_home, 'maps')

    # Sadly, this mostly doesn't work. Instead, everything will be overwritten
    # with baseDataDirectory-derived path on launch. Symlinks don't work either,
    # as faf doesn't handle them well. We can only change baseDataDirectory
    config['data'] = {
        # XDG_STATE_HOME candidates
        "baseDataDirectory": faf_home,
        "binDirectory": join(faf_home, 'bin'),
        "mapGeneratorDirectory": join(faf_home, 'map_generator'),
        # logs don't respect config and always stay in ~/.faforever
        # join(expanduser(faf_home, 'logs'))

        # XDG_CACHE_HOME candidates
        "cacheDirectory": faf_home,
        "cacheStylesheetsDirectory": join(faf_home, 'stylesheets'),
        "featuredModCacheDirectory": join(faf_home, 'featured_mod'),

        # These files will properly be located in XDG_DATA_HOME as they should
        "languagesDirectory": join(faf_home, 'languages'),
        "themesDirectory": join(faf_home, 'themes'),
        "replaysDirectory": join(faf_home, 'replays'),
        "corruptedReplaysDirectory": join(faf_home, 'corrupt'),
    }

def deep_update(x, update):
    for k, v in update.items(): 
        if k not in x.keys() or not isinstance(v, dict):
            x[k] = v
        elif isinstance(v, dict):
            deep_update(x[k], v)

print('Final config:')
print(json.dumps(config, indent=2))
if changed_dirs:
    print('# FAF data will be in `~/.local/share/faforever`.')
    print('Everything in that directory will be redownloaded if needed, except for folders `replays`, `corrupt`, `languages`, `themes`.')
    print("It is safe to delete that directory, unless you have some replays that aren't saved online or use a custom theme/localization.")
    print("`~/.faforever` will still have `client.prefs` (required) and logs")
    print('# Supreme Commander config will be in `~/.config/Gas Powered Games/Supreme Commander Forged Alliance`')
    print('# Supreme Commander maps and mods will be in `~/.local/share/Gas Powered Games/Supreme Commander Forged Alliance`')

if ask_yn('Commit (Other settings will be preserved if already set)?', True):
    os.makedirs(expanduser('~/.faforever'), exist_ok=True)
    config_path = expanduser('~/.faforever/client.prefs')
    if isfile(config_path):
        shutil.copy2(config_path, expanduser('~/.faforever/client.prefs.bak'))
        print('Wrote a backup of the old `~/.faforever/client.prefs` to `~/.faforever/client.prefs.bak`')
        config2 = config
        config = json.loads(open(config_path, 'rt', encoding='utf-8').read())
        deep_update(config, config2)
    open(config_path, 'wt', encoding='utf-8').write(json.dumps(config, indent=2))

