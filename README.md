# nmclean

Find every `node_modules` folder under a directory, see how much space each one takes, and delete them all at once or one by one.

A single bash script with no dependencies — no Node, no npm. Works on macOS (including the built-in bash 3.2) and Linux.

```
$ nmclean ~/projects
Searching for node_modules in /Users/me/projects ...
  1)    648M  /Users/me/projects/api/node_modules
  2)    580M  /Users/me/projects/web/frontend/node_modules
  3)     92M  /Users/me/projects/old-demo/node_modules

Found 3 folders, 1.3G total.

[a] delete all  [o] one by one  [q] quit: o
(1/3) 648M  /Users/me/projects/api/node_modules  delete? [y/n/q]: n
  Skipped.
(2/3) 580M  /Users/me/projects/web/frontend/node_modules  delete? [y/n/q]: y
  Deleted.
(3/3) 92M  /Users/me/projects/old-demo/node_modules  delete? [y/n/q]: y
  Deleted.

Freed 672M.
```

## Install

One line:

```sh
curl -fsSL https://raw.githubusercontent.com/OfirYaron/nmclean/main/install.sh | bash
```

Or from a clone:

```sh
git clone https://github.com/OfirYaron/nmclean.git
cd nmclean
./install.sh
```

Both install to `~/.local/bin/nmclean`. To install somewhere else, set `PREFIX`:

```sh
PREFIX=/usr/local/bin ./install.sh
```

If the install folder isn't on your `PATH`, the installer tells you what to add to your shell config.

## Usage

```
nmclean [options] [dir]
```

| Option | Description |
| --- | --- |
| `dir` | Folder to search. Defaults to `$NMCLEAN_ROOT`, or the current directory. |
| `-n`, `--dry-run` | List folders and sizes only; delete nothing. |
| `-y`, `--yes` | Delete everything found without asking. |
| `-h`, `--help` | Show help. |
| `-v`, `--version` | Show version. |

At the prompt:

- `a` — delete all (asks once more to confirm)
- `o` — go one by one: `y` delete, `n` skip, `q` stop
- `q` — quit without deleting

### Set a default folder

If your projects always live in one place, set it in `~/.zshrc` or `~/.bashrc`:

```sh
export NMCLEAN_ROOT="$HOME/projects"
```

## Safety

- Only folders named exactly `node_modules` are ever deleted.
- Nested `node_modules` (inside another `node_modules`) are skipped, so each project appears once.
- "Delete all" asks for confirmation unless you pass `-y`.
- Deleted folders do not go to the Trash. Run `npm install` (or your package manager) to bring them back.

## Uninstall

```sh
rm ~/.local/bin/nmclean
```

## License

MIT
