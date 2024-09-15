# GitHub Infisical secrets check Action

[![GitHub repo](https://img.shields.io/badge/GitHub-guibranco%2Fgithub--infisical--secrets--check--action-green.svg?style=plastic&logo=github)](https://github.com/guibranco/github-infisical-secrets-check-action)
[![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/guibranco/github-infisical-secrets-check-action?color=green&label=Code%20size&style=plastic&logo=github)](https://github.com/guibranco/github-infisical-secrets-check-action)
[![GitHub last commit](https://img.shields.io/github/last-commit/guibranco/github-infisical-secrets-check-action?color=green&logo=github&style=plastic&label=Last%20commit)](https://github.com/guibranco/github-infisical-secrets-check-action)
[![GitHub license](https://img.shields.io/github/license/guibranco/github-infisical-secrets-check-action?color=green&logo=github&style=plastic&label=License)](https://github.com/guibranco/github-infisical-secrets-check-action)

![CI](https://github.com/guibranco/github-infisical-secrets-check-action/actions/workflows/ci.yml/badge.svg)

🚨 :octocat: A GitHub action to check and report secret leaks in the repository using [Infisical CLI](https://infisical.com/docs/cli/commands/scan).

---

## Usage

None.

## Outputs

None.

---

## Example

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
---

## Sample output

### Success - no secrets leaked

[!success](success.png)

### Failure - secrets leaked

[!failure](failure.png)
