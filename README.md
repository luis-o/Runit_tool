# runit

```
 ____   _   _  _   _  ___  _____
|  _ \ | | | || \ | ||_ _||_   _|
| |_) || | | ||  \| | | |   | |
|  _ < | |_| || |\  | | |   | |
|_| \_\ \___/ |_| \_||___|  |_|
```

`runit` reads a project's `README.md`, figures out how the tool it describes is
meant to be launched, and runs it. When a README documents more than one
plausible launch command, `runit` asks which one you want instead of guessing.

It ranks the fenced code blocks in a README by:

- **section heading** — commands under *Usage*, *Quick start*, *Running*, etc.
  score higher, and
- **command shape** — lines that look like launchers (`./app`, `python …`,
  `npm start`, `docker run …`, `flask run`, `cargo run`, …) score higher than
  ordinary text.

Setup lines (`pip install`, `npm install`, `git clone`, `cargo build`, …) are
recognised and skipped, so they're never mistaken for the launch command.

## Install

Put `runit` on your `PATH` with the bundled installer:

```bash
./install.sh
```

By default it symlinks `runit` into the first writable bin directory on your
`PATH` (`~/.local/bin`, `~/bin`, or `/usr/local/bin`) and marks it executable.
If that directory isn't on your `PATH`, the installer prints the `export` line
to add to your shell profile.

Options:

```bash
./install.sh --dir ~/bin    # install into a specific directory
./install.sh --copy         # copy the file instead of symlinking
./install.sh --uninstall    # remove a previously installed runit
```

## Usage

Run it against the current directory, another directory, or a specific
markdown file:

```bash
runit                    # use README.md in the current directory
runit path/to/dir        # use README.md in that directory
runit path/to/FILE.md    # use that specific markdown file
```

Preview what it found without running anything, or skip the confirmation when
there's a single obvious command:

```bash
runit --list             # show ranked launch candidates, run nothing
runit --yes              # run the single obvious candidate without confirming
runit --setup            # run setup steps (pip install, …) first, then launch
runit --fg               # launch in the foreground and hand over the terminal
runit --help             # show help
```

With `--setup`, the setup commands the README documents (`pip install`,
`npm install`, …) are run in order first; if any of them fails, `runit` stops
and does not launch.

**By default the launched process runs in the background** (handy for servers
and other long-running processes): it starts in its own session and `runit`
watches your keyboard — press **`q`** (or `Ctrl-C`) to stop it. The process's
output still streams to the terminal, but its stdin is disconnected. For
interactive processes that need the terminal (REPLs, TUIs), use **`--fg`** to
launch in the foreground instead.

On stop, `runit` tears down **everything the command spawned**, not just the
top-level process: it snapshots the descendant tree, then sends `SIGTERM` to
the whole process group *and* to each descendant (so subprocesses that moved
into their own process group are still stopped), escalating to `SIGKILL` for
anything that doesn't exit promptly. The one thing it can't reach is a process
that fully daemonizes and reparents itself away (e.g. containers owned by the
Docker daemon) — those sever the link back to the launched command.

## How it works

1. Locate the README (`find_readme`) — a directory resolves to its `README.md`.
2. Parse fenced code blocks, remembering the heading and fence language each
   lives under (`parse_blocks`). Blocks tagged with a non-shell language
   (```` ```json ````, ```` ```python ````, …) are ignored so their contents
   can't be mistaken for commands.
3. Clean each line — strip `$`/`>` prompts and trailing comments
   (`clean_command`).
4. Drop setup lines, keep launch-looking ones, de-duplicate, and rank them by
   score (`collect_candidates`). A chained command like `cd app && npm start`
   is judged by its last step, so it isn't mistaken for setup.
5. If one candidate clearly wins, confirm and run it; if several tie, list them
   and ask.

## Requirements

- Python 3 (uses only the standard library — no dependencies).
