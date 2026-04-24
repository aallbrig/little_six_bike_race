# Little Six Scripts

This directory contains shell scripts for all development and deployment tasks.

## Script Categories

### Development
- `start-website.sh` - Start the marketing website server
- `run-godot-game.sh` - Run the Little Six game
- `open-godot-editor.sh` - Open Godot editor
- `start-localstack.sh` - Start LocalStack for AWS testing
- `run-matchmaking-service.sh` - Run matchmaking service

### Build & Export
- `build-site.sh` - Build the static website
- `export-web.sh` - Export Godot game for web

### AWS/SAM
- `sam-build.sh` - Build SAM application
- `sam-local-api.sh` - Start SAM API locally
- `sam-deploy.sh` - Deploy to AWS

### Deployment
- `deploy.sh` - Full deployment pipeline

## Usage

Use `make <command>` from the project root instead of calling these scripts directly. The Makefile provides a consistent interface and handles dependencies.

Example:
```bash
make website    # Calls ./scripts/start-website.sh
make deploy     # Calls ./scripts/deploy.sh
```

## Script Standards

All scripts follow these conventions:
- Use `#!/bin/bash` and `set -e` for error handling
- Include usage comments and help text
- Check for required dependencies and files
- Use absolute paths where possible
- Exit with appropriate error codes
- Provide clear success/failure messages