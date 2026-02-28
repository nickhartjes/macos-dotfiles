#!/bin/sh
# macOS defaults — idempotent, safe to re-run
# Run: sh defaults.sh
set -e

echo "Applying macOS defaults..."

# ─── Finder ──────────────────────────────────────────────
# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# ─── Dock ────────────────────────────────────────────────
# Enable autohide
defaults write com.apple.dock autohide -bool true

# Remove autohide delay
defaults write com.apple.dock autohide-delay -float 0

# Instant hide animation (effectively no dock)
defaults write com.apple.dock autohide-time-modifier -float 0

# Minimize with scale effect
defaults write com.apple.dock mineffect -string "scale"

# ─── Keyboard ────────────────────────────────────────────
# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable smart quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Enable key repeat (disable press-and-hold)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Faster key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2

# Shorter initial key repeat delay
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# ─── Scrolling ───────────────────────────────────────────
# Disable natural scroll direction (uncomment if desired)
# defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# ─── Clock ──────────────────────────────────────────────
# Use 24-hour clock
defaults write com.apple.menuextra.clock DateFormat -string "EEE HH:mm"

# ─── Screenshots ─────────────────────────────────────────
# Save screenshots to ~/Screenshots
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"

# Save as PNG
defaults write com.apple.screencapture type -string "png"

# ─── Battery ─────────────────────────────────────────────
# Show battery percentage
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

# ─── Apply changes ───────────────────────────────────────
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

echo "macOS defaults applied. Some changes may require a logout/restart."
