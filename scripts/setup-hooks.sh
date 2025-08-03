#!/bin/sh
# Setup script for Git hooks

echo "🔧 Setting up Git hooks for Orbit Jump..."

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Copy pre-commit hook
if [ -f "scripts/hooks/pre-commit" ]; then
    cp scripts/hooks/pre-commit .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    echo "✅ Pre-commit hook installed"
else
    echo "⚠️  Pre-commit hook template not found in scripts/hooks/"
fi

# Optional: Install luacheck if not present
if ! command -v luacheck &> /dev/null; then
    echo ""
    echo "📦 luacheck is not installed. To enable linting, install it with:"
    echo "   luarocks install luacheck"
    echo ""
fi

echo "✅ Git hooks setup complete!"
echo ""
echo "The following checks will run before each commit:"
echo "  - Lua linting (if luacheck is installed)"
echo "  - File size checks"
echo "  - Deprecated file usage detection"
echo "  - Common issue detection"
echo ""
echo "To skip hooks temporarily, use: git commit --no-verify"