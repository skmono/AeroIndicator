# AeroIndicator

## Install

```sh
brew tap skmono/apps
brew install --cask aeroindicator
```

## Usage

### Aerospace

Add to your `.aerospace.toml`

```toml
# Apple Silicon
after-startup-command = ["exec-and-forget /opt/homebrew/bin/aeroIndicator --restart-service"]
exec-on-workspace-change = ['/bin/bash', '-c', '/opt/homebrew/bin/aeroIndicator workspace-change $AEROSPACE_FOCUSED_WORKSPACE']
on-focus-changed = ['exec-and-forget /opt/homebrew/bin/aeroIndicator focus-change']

# Intel
after-startup-command = ["exec-and-forget /usr/local/bin/aeroIndicator --restart-service"]
exec-on-workspace-change = ['/bin/bash', '-c', '/usr/local/bin/aeroIndicator workspace-change $AEROSPACE_FOCUSED_WORKSPACE']
on-focus-changed = ['exec-and-forget /usr/local/bin/aeroIndicator focus-change']
```

### Yabai

Add to your `.yabairc`

```shell
yabai -m signal --add event=window_focused action='aeroIndicator focus-change'
yabai -m signal --add event=window_destroyed action='aeroIndicator focus-change'
yabai -m signal --add event=space_changed action='aeroIndicator workspace-change $YABAI_SPACE_INDEX'
yabai -m signal --add event=space_created action='aeroIndicator workspace-created-or-destroyed'
yabai -m signal --add event=space_destroyed action='aeroIndicator workspace-created-or-destroyed'
```

## Commands

- `--start-service`: Start the AeroIndicator service
- `--stop-service`: Stop the AeroIndicator service
- `--restart-service`: Restart the AeroIndicator service
- `--help, -h`: Show this help message
- `workspace-change WORKSPACE`: Change to specified workspace
- `focus-change`: Refresh application list
- `workspace-created-or-destroyed`: Get all workspace

Use `rm /tmp/AeroIndicator` when there are no running instances of the app, but when executing `--start-service` it shows that the program is already running.

## Config

add `config.toml` in `~/.config/aeroIndicator`.

### Default Config

```toml
# ~/.config/aeroIndicator/config.toml
source = "aerospace" # available value: aerospace, yabai
position = "bottom-left" # available value: bottom-left, bottom-center, bottom-right, top-left, top-center, top-right, center
outer-padding = 20
inner-padding = 12
border-padius = 12
# font-size = 14 # emit this field to use system default size
icon-size = 16
```
