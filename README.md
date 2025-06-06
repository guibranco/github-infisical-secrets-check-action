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
    uses: guibranco/github-infisical-secrets-check-action@v3.0.0
```

---

## Inputs

- `gh_token`: The GitHub token to add the comment in the PR using the [mshick/add-pr-comment@v2](https://github.com/mshick/add-pr-comment) GitHub Action.

---

## Outputs

- `secrets-leaked`: The number of secrets leaked found by the Infisical CLI tool.

---

## Example

### With default (inherited) GitHub token

```yml
name: Infisical secrets check

on:
  workflow_dispatch:
  pull_request:

jobs:
  secrets-check:
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write
    steps:
      - name: Infisical Secrets Check
        uses: guibranco/github-infisical-secrets-check-action@v3.0.0
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
      pull-requests: write
    steps:
      - name: Infisical Secrets Check
        uses: guibranco/github-infisical-secrets-check-action@v3.0.0
        with:
          gh_token: ${{ secrets.GH_TOKEN }}
```

Remember to add the repository secret `GH_TOKEN`.

---

## Sample output

### Success - ✅ No secrets leaked

![success](success.png)

### Failure - 🚨 Secrets leaked!

![failure](failure.png)
