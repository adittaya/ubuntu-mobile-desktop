# Contributing

Contributions are welcome! Here's how to help:

## Reporting Issues

- Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) first
- Include your Android version, device model, and Termux version
- Paste the full error output

## Suggesting Features

- Open an issue with the `enhancement` label
- Describe the use case

## Submitting Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b my-feature`
3. Make your changes
4. Test on a real device
5. Commit with a clear message
6. Push and open a Pull Request

## Script Guidelines

- Keep `setup-termux-gui.sh` POSIX-compatible where possible
- Use `set -euo pipefail`
- Test on a clean Termux installation
- Don't add unnecessary dependencies

## Code Style

- 4-space indentation for shell scripts
- Meaningful variable names
- Comment non-obvious logic
