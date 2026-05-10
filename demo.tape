# womwiki demo recording
# Run: ~/go/bin/vhs demo.tape
# Requires: ffmpeg, ttyd, chromium

Output demo.gif
Set Width 1200
Set Height 700
Set FontSize 16
Set Padding 20
Set TypingSpeed 60ms
Set Theme "Catppuccin Mocha"
Set Shell bash

# Uses your normal Neovim config for look & feel, but points
# womwiki at a temp wiki so the demo has predictable content.
# Run demo_setup.sh before this tape (or it runs automatically below).

Hide
Type@0ms `./demo_setup.sh`
Enter
Sleep 500ms
Show

# =====================================================================
# SCENE 1: Open Neovim and the wiki menu
# =====================================================================

Type `nvim --cmd 'set noswapfile' +"lua require('womwiki').setup({path='/tmp/demo-wiki'})"`
Enter
Sleep 2s

# Open wiki menu
Type " w"
Sleep 2.5s

# =====================================================================
# SCENE 2: Open today's daily note (creates from template)
# =====================================================================

Type "t"
Sleep 2s

# Add some content to the daily note
Type "jjjjA productive"
Sleep 300ms
Escape
Sleep 200ms
Type "jA"
Sleep 200ms
Enter
Type "- [x] Record womwiki demo"
Sleep 500ms
Enter
Type "- [ ] Share on GitHub"
Sleep 500ms
Escape
Sleep 1s

# =====================================================================
# SCENE 3: Create a wikilink and follow it
# =====================================================================

# Go to the Log section, add a wikilink
Type "G"
Sleep 300ms
Type "o"
Type "Check the [[reading-list]] for next book."
Sleep 800ms
Escape
Sleep 500ms

# Follow the wikilink with Enter
Type "F["
Sleep 300ms
Enter
Sleep 1.5s

# We're now in reading-list.md — pause to show it
Sleep 2s

# =====================================================================
# SCENE 4: Graph view
# =====================================================================

Type " wg"
Sleep 3s

# Pause on the graph
Sleep 3s

# Close graph
Type "q"
Sleep 800ms

# =====================================================================
# SCENE 5: Calendar view
# =====================================================================

Type " w"
Sleep 2s
Type "c"
Sleep 2.5s

# Navigate in calendar
Type "h"
Sleep 400ms
Type "h"
Sleep 400ms
Type "h"
Sleep 400ms

# Close calendar
Type "q"
Sleep 800ms

# =====================================================================
# SCENE 6: Quick capture with location → inbox → jump back
# =====================================================================

# Use <leader>wq which captures with location link
Type " wq"
Sleep 1s

# Type the capture text
Type "Look into vhs for terminal recordings"
Enter
Sleep 1.5s

# Open inbox to see the capture
Type " wi"
Sleep 2.5s

# Jump to the source link — go to end of last line, find the link
Type "G$F["
Sleep 1s

# Follow the link back to where we captured from
Enter
Sleep 2s

# =====================================================================
# SCENE 7: Search across wiki
# =====================================================================

Type " w"
Sleep 2s
Type "s"
Sleep 1s

Type "wiki"
Sleep 2s

# Close search
Escape
Sleep 1s

# =====================================================================
# Done — hold final frame
# =====================================================================

Type " w"
Sleep 3s
Type "q"
Sleep 2s
