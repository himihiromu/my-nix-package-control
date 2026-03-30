#!/bin/bash

set -e

echo "======================================"
echo "Home Manager Application Script"
echo "======================================"

# Ensure git is configured properly
git config --global --add safe.directory /workspace 2>/dev/null || true

USER_NAME="himihiromu"

echo -e "\n1. Building Home Manager configuration..."
nix build .#homeConfigurations.${USER_NAME}.activationPackage

echo -e "\n2. Activating Home Manager configuration..."
echo "Note: This will set up vim, python, and shell configuration for user ${USER_NAME}"

# Create user home directory if needed
sudo mkdir -p /home/${USER_NAME}
sudo chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME} 2>/dev/null || true

# Apply the configuration
./result/activate

echo -e "\n3. Verifying installation..."
echo "Checking vim configuration:"
vim --version | head -3

echo -e "\nChecking python installation:"
python3 --version

echo -e "\nChecking installed packages:"
which vim && echo "✓ vim installed"
which python3 && echo "✓ python3 installed"
which git && echo "✓ git installed"
which tree && echo "✓ tree installed"
which ripgrep && echo "✓ ripgrep installed"
which bat && echo "✓ bat installed"

echo -e "\n======================================"
echo "Home Manager setup complete!"
echo "======================================"
echo ""
echo "The following have been configured:"
echo "  • Vim with plugins (gruvbox theme, fugitive, airline)"
echo "  • Python 3 with pip, virtualenv, ipython"
echo "  • Git with user configuration"
echo "  • Bash with custom aliases"
echo "  • FZF for fuzzy finding"
echo "  • Various CLI tools (tree, ripgrep, bat, etc.)"
echo ""
echo "You can now use 'vim' with the configured plugins and settings!"