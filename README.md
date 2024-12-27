# GitHub Infisical secrets check Action

[![GitHub repo](https://img.shields.io/badge/GitHub-guibranco%2Fgithub--infisical--secrets--check--action-green.svg?style=plastic&logo=github)](https://github.com/guibranco/github-infisical-secrets-check-action "shields.io")
[![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/guibranco/github-infisical-secrets-check-action?color=green&label=Code%20size&style=plastic&logo=github)](https://github.com/guibranco/github-infisical-secrets-check-action "shields.io")
[![GitHub last commit](https://img.shields.io/github/last-commit/guibranco/github-infisical-secrets-check-action?color=green&logo=github&style=plastic&label=Last%20commit)](https://github.com/guibranco/github-infisical-secrets-check-action "shields.io")
[![GitHub license](https://img.shields.io/github/license/guibranco/github-infisical-secrets-check-action?color=green&logo=github&style=plastic&label=License)](https://github.com/guibranco/github-infisical-secrets-check-action "shields.io")

![CI](https://github.com/guibranco/github-infisical-secrets-check-action/actions/workflows/ci.yml/badge.svg)
[![wakatime](https://wakatime.com/badge/github/guibranco/github-infisical-secrets-check-action.svg)](https://wakatime.com/badge/github/guibranco/github-infisical-secrets-check-action)

🚨 :octocat: A GitHub action to check and report secret leaks in the repository using [Infisical CLI](https://infisical.com/docs/cli/commands/scan).

---

## Usage

The following workflow step will scan for secret leaks in your repository.

```yml

  - name: Run the action
    uses: guibranco/github-infisical-secrets-check-action@latest
    id: secrets-scan
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
name: 'Infisical secrets check'

on:
  pull_request:

  jobs:
    check-secrets:
      runs-on: ubuntu-latest
      permissions:
        contents: read
        pull-requests: write

      steps:
        - uses: actions/checkout@v4
          
        - name: Run the action
          uses: guibranco/github-infisical-secrets-check-action@latest
```

### With a custom GitHub token

```yml
name: 'Infisical secrets check'

on:
  pull_request:

  jobs:
    check-secrets:
      runs-on: ubuntu-latest
      permissions:
        contents: read
        pull-requests: write

      steps:
        - uses: actions/checkout@v4
          
        - name: Run the action
          uses: guibranco/github-infisical-secrets-check-action@latest
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
