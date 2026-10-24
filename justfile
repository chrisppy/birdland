set dotenv-load := false

# List available recipes
default:
    @just --list

# Build the Birdland suite package
build:
    nix build .#birdland

# Run the Bullpen status bar
run-bullpen:
    nix run .#bullpen

# Run the Dugout app launcher
run-dugout:
    nix run .#dugout

# Check flake outputs and evaluation
check:
    nix flake check

# Format Nix and other configured files
fmt:
    nix fmt

# Check formatting without modifying files
fmt-check:
    nix fmt -- --check

# Update all flake inputs
update:
    nix flake update

# Update a specific flake input
update-input input:
    nix flake update {{ input }}

# Enter the development shell
dev:
    nix develop

# Build and check
verify: fmt-check check build

# Remove local Nix build artifacts
clean:
    rm -f result result-*
