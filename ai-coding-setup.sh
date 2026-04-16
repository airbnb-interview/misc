#!/bin/sh
# Interview environment setup script.
# Usage: sh ai-coding-setup.sh [WORKDIR]
# WORKDIR defaults to the current directory if not provided.

WORKDIR="${1:-$(pwd)}"

echo "Setting up environment..."

# Clean up stray files left by the environment
rm -f "$WORKDIR/main.sh"

# Language selection
echo ""
echo "Select your language:"
echo "  1) Python"
echo "  2) Java"
echo "  3) JavaScript"
echo "  4) TypeScript"
echo "  5) Golang"
echo "  6) C++"
echo ""

LANG_CHOICE=""
while true; do
  printf "Enter choice [1-6]: "
  read LANG_CHOICE
  case "$LANG_CHOICE" in
    1|2|3|4|5|6) break ;;
    *) echo "Invalid choice. Please enter a number from 1 to 6." ;;
  esac
done

case "$LANG_CHOICE" in
  1) LANG_NAME="Python" ;;
  2) LANG_NAME="Java" ;;
  3) LANG_NAME="JavaScript" ;;
  4) LANG_NAME="TypeScript" ;;
  5) LANG_NAME="Golang" ;;
  6) LANG_NAME="C++" ;;
esac

echo "Language: $LANG_NAME"

# Diagnostics
echo "User: $(whoami)"
echo "Git: $(git --version)"

cd "$WORKDIR"

git config --global user.email "candidate@airbnb.interview.com"
git config --global user.name "candidate"
git config --global init.defaultBranch main

case "$LANG_CHOICE" in
  1) echo "Python: $(python3 --version 2>&1)" ;;
  2) echo "Java: $(java -version 2>&1 | head -1)" ;;
  3) echo "Node: $(node --version 2>&1)" ;;
  4) echo "Node: $(node --version 2>&1)" ; echo "TypeScript: $(tsc --version 2>&1)" ;;
  5) echo "Go: $(go version 2>&1)" ;;
  6) echo "C++: $(g++ --version 2>&1 | head -1)" ;;
esac

# Project setup
if [ "$LANG_CHOICE" = "2" ]; then
  git clone https://github.com/airbnb-interview/java-starter.git project
else
  mkdir -p project
  cd project
  git init
  echo "# $LANG_NAME" > README.md
  cd ..
fi

cd project

# Setup Claude if it is not already
if ! command -v claude &> /dev/null; then
  npm install -g @anthropic-ai/claude-code --silent

  CONFIRM_CODE=`echo $ANTHROPIC_API_KEY | sed 's/.*\(.\{20\}\)$/\1/'`
cat >~/.claude.json <<EOL
{
  "customApiKeyResponses": {
    "approved": [
      "$CONFIRM_CODE"
    ],
    "rejected": []
  },
  "projects": {
    "$WORKDIR": {
      "allowedTools": [],
      "hasTrustDialogAccepted": true,
      "projectOnboardingSeenCount": 1
    }
  },
  "hasCompletedOnboarding": true
}
EOL
fi

cat > agents.md << 'EOF'
- You are running in a containerized environment without a display; terminal access only
- Neither you nor the user has root access — don't rely on anything that requires root access
- You can install anything a regular user can install
- Port 3000 is special. It is mapped externally as port 80.  So if you build any application with a server or dev server, make sure it is running on port 3000 so the user can access it. You can run a backend on another port, but if you want to expose it, you will need to proxy it through port 3000 as /api or something appropriate for the need.
- Do not suggest or prompt to install any plugins, LSP servers, or extensions
EOF

# Summary
if [ "$LANG_CHOICE" = "2" ]; then
  PROJECT_NOTE="empty Gradle project cloned"
else
  PROJECT_NOTE="empty git project initialized"
fi

echo ""
echo "┌─────────────────────────────────────────────────┐"
echo "│              Environment ready                  │"
echo "├─────────────────────────────────────────────────┤"
printf "│  Language:  %-36s│\n" "$LANG_NAME"
printf "│  Project:   %-36s│\n" "$WORKDIR/project"
printf "│  Setup:     %-36s│\n" "$PROJECT_NOTE"
echo "└─────────────────────────────────────────────────┘"
echo ""

# Run Claude in project directory
claude
