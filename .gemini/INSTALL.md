# DevOps Marketplace for Gemini CLI

Complete guide for installing and using the DevOps Marketplace with the [Gemini CLI](https://github.com/google/gemini-cli).

## Installation

To install the DevOps Marketplace extension for the Gemini CLI, use the following command:

```bash
gemini extensions install https://github.com/logic3579/devops-marketplace
```

## Updating

To update the extension later, run:

```bash
gemini extensions update devops-marketplace
```

## Usage

The DevOps Marketplace provides a suite of tools and skills optimized for DevOps workflows, including CI/CD automation and marketplace management tools.

### Activating Skills

You can activate specialized skills from this marketplace using the `activate_skill` tool:

```bash
# Example: Activate the skill-creator to build new skills
gemini activate_skill skill-creator
```

### Available Plugins

- **cicd-automation**: Automated pipeline generation and review.
- **marketplace-tools**: Tools for managing and extending the marketplace.
- **share-mcp**: Integration for Model Context Protocol.

## Troubleshooting

If you encounter any issues:

1. Verify that you are using a recent version of the Gemini CLI.
2. Check your connection to GitHub.
3. Report issues at: [https://github.com/logic3579/devops-marketplace/issues](https://github.com/logic3579/devops-marketplace/issues)
