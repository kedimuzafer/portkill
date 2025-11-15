# portkill

A tiny shell helper that kills whatever process is listening on a given TCP port.

```bash
portkill 3003
```

Under the hood it uses common Unix tools (`lsof`, optionally `fuser`) to find
all PIDs bound to a port and sends them a `SIGTERM` followed by a `SIGKILL`
if they refuse to die.

---

## Features

- Simple command: `portkill <port>`
- Built‑in help: `portkill -h` / `portkill --help`
- Uninstaller: `portkill uninstall` (or `remove` / `delete`)
- Works in any POSIX shell once sourced (`bash`, `zsh`, etc.)
- Uses `lsof` and `fuser` if available
- Safe installer: adds a clearly marked block to your shell rc file and skips
  installation if it is already present

---

## Installation

You can install `portkill` in one line:

```bash
curl -fsSL https://raw.githubusercontent.com/kedimuzafer/portkill/master/portkill-install.sh | sh
```

The installer will:

- Detect a suitable rc file (preferring your current shell), e.g.:
  - `~/.zshrc`
  - `~/.bashrc`
  - `~/.bash_profile`
  - `~/.profile`
- Append a block wrapped in:
  - `# >>> portkill >>>`
  - `# <<< portkill <<<`
- Print a short banner and instructions on how to reload your config.

If `portkill` is already installed in the chosen rc file, the installer prints
an informational message and exits without changing anything.

### Custom rc file

You can force the installer to write to a specific rc file by setting
`PORTKILL_RC`:

```bash
PORTKILL_RC="$HOME/.zshrc" sh portkill-install.sh
```

---

## Usage

After installation, reload your shell configuration, for example:

```bash
. ~/.zshrc
# or
. ~/.bashrc
```

Then:

```bash
portkill 3003
portkill 8080
portkill -h
```

Behavior:

- If no process is found on the given port, it prints a message and exits
  successfully.
- If one or more PIDs are found, it prints them and issues:
  - `kill <pids>`
  - `kill -9 <pids>`

### Uninstall from the CLI

You can remove the `portkill` block from your shell rc file using:

```bash
portkill uninstall
# or
portkill remove
# or
portkill delete
```

Internally this looks for the block between the markers described below and
removes it from the detected rc file.

---

## Manual uninstall

If you prefer to remove `portkill` manually, open the rc file you installed it
into (for example `~/.zshrc` or `~/.bashrc`) and delete the block between:

```text
# >>> portkill >>>
...
# <<< portkill <<<
```

Then reload your shell config:

```bash
. ~/.zshrc    # or your file
```
