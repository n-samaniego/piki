#!/bin/bash
# Setup script for demo.tape — creates a temp wiki with sample content
set -e

rm -rf /tmp/demo-wiki
mkdir -p /tmp/demo-wiki/daily /tmp/demo-wiki/projects

cat > /tmp/demo-wiki/reading-list.md << 'EOF'
# Reading List #reference

## Currently Reading

- [ ] Designing Data-Intensive Applications
- [x] The Pragmatic Programmer

## Want to Read

- [ ] Structure and Interpretation of Computer Programs
EOF

cat > /tmp/demo-wiki/projects/ideas.md << 'EOF'
---
tags: [project, brainstorm]
---
# Ideas

- [ ] Build a CLI tool for time tracking
- [x] Set up personal wiki — see [[getting-started]]
EOF

cat > /tmp/demo-wiki/getting-started.md << 'EOF'
# Getting Started #guide

Use [[daily notes]] to journal every day.
Organize thoughts in [[projects/ideas]].
Tag pages with #project or #reference for filtering.
EOF

YESTERDAY=$(date -d 'yesterday' +%Y-%m-%d)
cat > "/tmp/demo-wiki/daily/${YESTERDAY}.md" << EOF
<!-- [[« Prev]] · [[Next »]] -->
# ${YESTERDAY}
## Standup
* Vibe: focused
* ToDone: Organized wiki structure
* ToDo:
- [ ] Review [[reading-list]]
## Log
Productive day.
EOF
