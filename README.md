# GitHub Infisical secrets check Action

[![GitHub repo](https://img.shields.io/badge/GitHub-guibranco%2Fgithub--infisical--secrets--check--action-green.svg?style=plastic&logo=github)](https://github.com/guibranco/github-infisical-secrets-check-action "shields.io")
[![GitHub last commit](https://img.shields.io/github/last-commit/guibranco/github-infisical-secrets-check-action?color=green&logo=github&style=plastic&label=Last%20commit)](https://github.com/guibranco/github-infisical-secrets-check-action "shields.io")
[![GitHub license](https://img.shields.io/github/license/guibranco/github-infisical-secrets-check-action?color=green&logo=github&style=plastic&label=License)](https://github.com/guibranco/github-infisical-secrets-check-action "shields.io")

![CI](https://github.com/guibranco/github-infisical-secrets-check-action/actions/workflows/ci.yml/badge.svg)
[![wakatime](https://wakatime.com/badge/github/guibranco/github-infisical-secrets-check-action.svg)](https://wakatime.com/badge/github/guibranco/github-infisical-secrets-check-action)

🚨 :octocat: A GitHub action to check and report secret leaks in the repository using [Infisical CLI](https://infisical.com/docs/cli/commands/scan).

---

## Usage

The following workflow step will scan for secret leaks in your repository.

```yml
- name: Infisical Secrets Check
  id: secrets-scan
  uses: guibranco/github-infisical-secrets-check-action@v4.1.0
```

---

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `GH_TOKEN` | GitHub token to add comments in pull requests | No | `${{ github.TOKEN }}` |
| `ADD_COMMENT` | Whether to comment results in the pull request | No | `true` |

---

## Outputs

| Output | Description |
|--------|-------------|
| `secrets-leaked` | The number of secrets leaked found by the Infisical CLI tool |

---

## Examples

### Basic usage with default settings

```yml
name: Infisical secrets check

on:
  workflow_dispatch:
  pull_request:

jobs:
  secrets-check:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - name: Infisical Secrets Check
        uses: guibranco/github-infisical-secrets-check-action@v4.1.0
```

### With a custom GitHub token

```yml
name: Infisical secrets check

on:
  workflow_dispatch:
  pull_request:

jobs:
  secrets-check:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - name: Infisical Secrets Check
        uses: guibranco/github-infisical-secrets-check-action@v4.1.0
        with:
          GH_TOKEN: ${{ secrets.CUSTOM_GH_TOKEN }}
```

Remember to add the repository secret `CUSTOM_GH_TOKEN`.

### Disable PR comments

```yml
name: Infisical secrets check

on:
  workflow_dispatch:
  pull_request:

jobs:
  secrets-check:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - name: Infisical Secrets Check
        uses: guibranco/github-infisical-secrets-check-action@v4.1.0
        with:
          ADD_COMMENT: false
```

### Using outputs in subsequent steps

```yml
name: Infisical secrets check

on:
  workflow_dispatch:
  pull_request:

jobs:
  secrets-check:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - name: Infisical Secrets Check
        id: secrets-scan
        uses: guibranco/github-infisical-secrets-check-action@v4.1.0
        
      - name: Handle secrets found
        if: steps.secrets-scan.outputs.secrets-leaked > 0
        run: |
          echo "Found ${{ steps.secrets-scan.outputs.secrets-leaked }} leaked secrets!"
          # Add your custom handling logic here
```

---

## Sample outputs

### Success - ✅ No secrets leaked

![success](success.png)

### Failure - 🚨 Secrets leaked!

![failure](failure.png)

### Tool Failure - ⚠️ Unable to complete scan

When the Infisical CLI fails to run (due to network issues, API rate limiting, etc.), the action will post a clear error message:

- Explains that this is a tool failure, not a security issue
- Provides suggestions for resolution (re-run workflow, check logs)
- Includes a link to workflow logs for debugging
- Clarifies that the failure doesn't mean secrets were found

---

## Features

- 🔍 **Comprehensive Scanning**: Uses the latest Infisical CLI to scan for secrets in your repository
- 💬 **Smart PR Comments**: Automatically adds detailed comments to pull requests with scan results
- 📊 **Detailed Reports**: Provides CSV and Markdown reports of found secrets
- 🔒 **Fork-Safe**: Safely handles pull requests from forks by disabling comments
- ⚡ **Efficient Caching**: Caches CLI downloads and dependencies for faster runs
- 🛡️ **Robust Error Handling**: Distinguishes between tool failures and actual security issues
- 📝 **Actionable Guidance**: Provides clear next steps for different scenarios
- 🔧 **Configurable**: Customize token usage and comment behavior

---

## Error Handling

Version 4 introduces improved error handling that prevents confusing empty comments:

- **Tool Installation Failures**: Clear messages when CLI download or installation fails
- **API Rate Limiting**: Graceful handling of GitHub API limits
- **Network Issues**: Proper detection and reporting of connectivity problems
- **Scan Execution Errors**: Distinguishes between tool failures and secrets detection

The action will fail the workflow appropriately, providing users with meaningful feedback on what went wrong and how to resolve it.

---

## Permissions

The action requires the following permissions:

```yml
permissions:
  contents: read        # Required to checkout and scan the repository
  pull-requests: write  # Required to add comments to PRs
```

---

## Ignoring False Positives

If the scan detects false positives, you can ignore them by creating a `.infisicalignore` file in your repository root with the secret fingerprints provided in the scan results.
