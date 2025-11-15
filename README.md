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

- Simple, single function: `portkill <port>`
- Works in any POSIX shell once sourced (`bash`, `zsh`, etc.)
- Uses `lsof` and `fuser` if available
- Safe installer: adds a clearly marked block to your shell rc file and skips
  installation if it is already present

---

## Installation

Once this repository is on GitHub, you can install `portkill` in one line:

```bash
curl -fsSL https://raw.githubusercontent.com/<your-user>/portkill/main/portkill-install.sh | sh
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
```

Behavior:

- If no process is found on the given port, it prints a message and exits
  successfully.
- If one or more PIDs are found, it prints them and issues:
  - `kill <pids>`
  - `kill -9 <pids>`

---

## Uninstall

To uninstall `portkill`, open the rc file you installed it into (for example
`~/.zshrc` or `~/.bashrc`) and remove the block between:

```text
# >>> portkill >>>
...
# <<< portkill <<<
```

Then reload your shell config:

```bash
. ~/.zshrc    # or your file
```

