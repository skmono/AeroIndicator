# Installing AeroIndicator from Source

## Prerequisites

- Xcode (from App Store)
- Homebrew

## Setup

```bash
# 1. First-time Xcode setup
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# 2. Clone your fork
git clone https://github.com/skmono/AeroIndicator.git
cd AeroIndicator

# 3. Build
xcodebuild -project AeroIndicator.xcodeproj -scheme AeroIndicator -configuration Release -derivedDataPath build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# 4. Zip the app
cd build/Build/Products/Release
zip -r ~/AeroIndicator.zip AeroIndicator.app
cd -

# 5. Get the sha256
shasum -a 256 ~/AeroIndicator.zip

# 6. Create local tap
mkdir -p $(brew --repository)/Library/Taps/$USER/homebrew-apps/Formula

# 7. Write the formula (replace PASTE_SHA_HERE with output from step 5)
cat > $(brew --repository)/Library/Taps/$USER/homebrew-apps/Formula/aeroindicator.rb << 'EOF'
class Aeroindicator < Formula
  desc "Workspace indicator for AeroSpace/yabai tiling window managers"
  homepage "https://github.com/skmono/AeroIndicator"
  url "file://#{ENV['HOME']}/AeroIndicator.zip"
  sha256 "PASTE_SHA_HERE"
  version "1.0.0"

  def install
    if File.exist?("AeroIndicator.app")
      prefix.install "AeroIndicator.app"
    elsif File.exist?("Contents/MacOS/AeroIndicator")
      (prefix/"AeroIndicator.app").mkpath
      (prefix/"AeroIndicator.app").install Dir["*"]
    end
    (bin/"AeroIndicator").write_env_script prefix/"AeroIndicator.app/Contents/MacOS/AeroIndicator", PATH: "#{HOMEBREW_PREFIX}/bin:${PATH}"
  end

  service do
    run [opt_bin/"AeroIndicator", "--run-app"]
    keep_alive true
    log_path var/"log/aeroindicator.log"
    error_log_path var/"log/aeroindicator.log"
  end
end
EOF

# 8. Install and start
brew install $USER/apps/aeroindicator
brew services start aeroindicator
```

## Config

Create `~/.config/aeroIndicator/config.toml`:

```toml
source = "aerospace"
position = "bottom-left"
```

### Available options

| Key | Default | Values |
|-----|---------|--------|
| `source` | `"aerospace"` | `"aerospace"`, `"yabai"` |
| `position` | `"bottom-left"` | `"bottom-left"`, `"bottom-center"`, `"bottom-right"`, `"top-left"`, `"top-center"`, `"top-right"`, `"center"` |
| `outer-padding` | `20` | any number |
| `inner-padding` | `12` | any number |
| `border-radius` | `12` | any number |
| `font-size` | system default | any number |
| `icon-size` | `16` | any number |

## AeroSpace Integration

Add to your `~/.config/aerospace/aerospace.toml`:

```toml
exec-on-workspace-change = ['/opt/homebrew/bin/AeroIndicator', 'workspace-change', '$AEROSPACE_FOCUSED_WORKSPACE']

[exec]
on-focus-changed = ['AeroIndicator focus-change']
```

## Service Management

```bash
brew services start aeroindicator
brew services stop aeroindicator
brew services restart aeroindicator
```
