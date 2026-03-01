# Function to check and install tools
install_tool() {
    if command -v $1 &> /dev/null; then
        echo "✅ $1 is already installed. Skipping..."
    else
        echo "🚀 Installing $1..."
        # Special handling for docker-desktop if it's erroring
        if [ "$1" = "docker" ]; then
            brew install --cask docker || (echo "⚠️ Fix: Repairing Docker Cask..." && brew uninstall --cask --force docker && brew install --cask docker)
        else
            brew install $2
        fi
    fi
}

# Ensure Homebrew is installed first
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Please install it from [https://brew.sh/](https://brew.sh/)"
    exit 1
fi

# Check and install the stack
install_tool "docker" "--cask docker"
install_tool "k3d" "k3d"
install_tool "kubectl" "kubectl"
install_tool "helm" "helm"
install_tool "k9s" "k9s"

