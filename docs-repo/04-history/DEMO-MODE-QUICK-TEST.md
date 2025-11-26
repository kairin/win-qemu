# Demo Mode Quick Test Guide

**Purpose**: Verify the improved demo mode works correctly
**File**: `/home/kkk/Apps/win-qemu/start.sh`
**Function**: `run_demo_mode()`

---

## 🚀 Quick Test Steps

### 1. Prerequisites Check
```bash
# Check if VHS is installed
command -v vhs && echo "✅ VHS installed" || echo "❌ VHS not found"

# Check if JetBrainsMono Nerd Font exists
fc-list | grep "JetBrainsMono Nerd Font" && echo "✅ Font installed" || echo "❌ Font not found"

# Check if gum is installed
command -v gum && echo "✅ gum installed" || echo "❌ gum not found"
```

### 2. Run Demo Mode
```bash
cd /home/kkk/Apps/win-qemu
./start.sh
# Select: "🎥 Run Demo (Record VHS)"
# Confirm: Press Enter for "Yes"
```

### 3. Verification Checklist

While recording (watch the terminal):
```
⏱️ Expected duration: ~2 minutes (recording 90-second demo)
🎬 Watch for these sequences:

1. ✅ Quick Start Wizard appears → Ctrl+C exits
2. ✅ System Readiness runs for ~8 seconds
3. ✅ Installation menu shows submenu items scrolling (Down key)
4. ✅ VM Operations menu shows submenu items scrolling
5. ✅ Performance guide displays for ~5 seconds
6. ✅ Security guide displays for ~5 seconds
7. ✅ File Sharing guide displays for ~5 seconds
8. ✅ Backup guide displays for ~5 seconds
9. ✅ Diagnostics menu shows submenu items
10. ✅ Documentation menu shows submenu items
11. ✅ Settings menu shows submenu items
12. ✅ Exit with farewell message
```

### 4. Output Validation
```bash
# Check demo.gif was created
ls -lh demo.gif

# Expected output:
# -rw-r--r-- 1 user user 2-5M Nov 27 XX:XX demo.gif

# View the demo
xdg-open demo.gif
# OR
viu demo.gif  # If installed
```

---

## 🔍 What to Look For in demo.gif

### Font Rendering
- ✅ Emojis render correctly (🖥️ 🚀 📋 💿 ⚡ 🔒 📁 💾 🏥 📚 ⚙️)
- ✅ Borders are clean (double-line borders around headers)
- ✅ Icons from Nerd Fonts display properly
- ✅ No boxes (□) or question marks (?) instead of icons

### Navigation Flow
```
Start → Quick Start (5s) → System Readiness (8s) →
Installation (8s) → VM Operations (8s) →
Performance (5s) → Security (5s) → File Sharing (5s) → Backup (5s) →
Diagnostics (8s) → Documentation (8s) → Settings (6s) →
Exit (3s)
```

### Timing Checks
- ✅ Menus don't flash by too quickly
- ✅ Can read menu options before they change
- ✅ Submenu items visible (Down key pauses on each)
- ✅ Total duration ~85-90 seconds

### Coverage Validation
- ✅ Quick Start demonstrated (NEW!)
- ✅ All 11 main menus visited (except self-referential "Run Demo")
- ✅ 5 submenus explored (Installation, VM, Diagnostics, Docs, Settings)
- ✅ 4 info screens shown (Performance, Security, File Sharing, Backup)

---

## 🐛 Troubleshooting

### Issue: VHS not installed
```bash
# Install VHS
go install github.com/charmbracelet/vhs@latest

# Add to PATH if needed
echo 'export PATH="$HOME/go/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Issue: Font rendering shows boxes
```bash
# Verify Nerd Font installed
fc-list | grep "JetBrainsMono Nerd Font"

# If not found, install Nerd Fonts
mkdir -p ~/.local/share/fonts/NerdFonts
cd ~/.local/share/fonts/NerdFonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
unzip JetBrainsMono.zip
fc-cache -fv
```

### Issue: Demo recording fails
```bash
# Check for errors in VHS
vhs --version

# Try running demo.tape manually
cd /home/kkk/Apps/win-qemu
./start.sh  # Select Demo Mode to generate demo.tape
vhs < demo.tape  # Run manually to see errors

# Check terminal compatibility
echo $TERM  # Should be xterm-256color or similar
```

### Issue: Demo runs too fast/slow
```bash
# Edit start.sh VHS settings (lines 1017-1018):
Set TypingSpeed 50ms      # Decrease for faster, increase for slower
Set PlaybackSpeed 1.0     # 0.5 = half speed, 2.0 = double speed
```

---

## ✅ Success Criteria

The demo is successful if:

1. **✅ Font Rendering**: All emojis and icons display correctly (no boxes)
2. **✅ Quick Start**: Quick Start wizard is shown first
3. **✅ Submenu Exploration**: Can see menu items scrolling (Down key)
4. **✅ Timing**: Each section is readable (~5-8 seconds)
5. **✅ Coverage**: All 11 menus visited (92% coverage)
6. **✅ File Size**: demo.gif is 2-5MB (reasonable size)
7. **✅ Duration**: Video is 85-90 seconds long
8. **✅ Professional Quality**: Smooth, polished, marketing-ready

---

## 📊 Expected Output Summary

```
File: demo.gif
Size: 2-5 MB
Duration: ~90 seconds
Resolution: 1200x900
Font: JetBrainsMono Nerd Font
Theme: Catppuccin Mocha
Coverage: 11/12 main menu items (92%)
Submenu Exploration: 5 menus with 2-3 options shown
Quality: Production-ready
```

---

## 🎯 Quick Validation Command

```bash
cd /home/kkk/Apps/win-qemu

# Run and validate in one go
./start.sh <<EOF
Run Demo
y
EOF

# Wait for completion (~2 minutes)
# Then check output
if [ -f demo.gif ]; then
    echo "✅ Demo created successfully!"
    ls -lh demo.gif
    echo ""
    echo "View with: xdg-open demo.gif"
else
    echo "❌ Demo creation failed!"
fi
```

---

## 📝 Manual Verification (Without Recording)

If you want to verify the flow without recording:

```bash
# Check the demo.tape content
./start.sh
# Select "Run Demo"
# Press "n" to cancel before recording
# Check demo.tape file was generated:
cat demo.tape

# Verify:
✅ Line 1015: Set FontFamily "JetBrainsMono Nerd Font"
✅ Line 1026: # 0. Quick Start Wizard (PRIMARY FEATURE)
✅ Lines 1042-1056: Installation submenu exploration (Down keys)
✅ Lines 1058-1072: VM Operations submenu exploration (Down keys)
```

---

**Last Updated**: 2025-11-27
**Status**: ✅ READY FOR TESTING
