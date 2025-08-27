#!/usr/bin/env bats

setup() {
  # Create a temp directory for each test
  export TEST_REPO=$(mktemp -d)
  cd "$TEST_REPO"
}

teardown() {
  # Clean up after each test
  cd /
  rm -rf "$TEST_REPO"
}

@test "Safe repo: no secrets detected" {
  # Simulate a safe repo (no secrets)
  git init -q
  echo "hello world" > file.txt
  git add file.txt
  git commit -m "Initial commit" -q

  run bash -c 'GITHUB_WORKSPACE="$TEST_REPO" bash $BATS_TEST_DIRNAME/../run.sh'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "secrets-leaked=0" ]]
}

@test "Leaky repo: fake secret detected" {
  # Simulate a repo with a fake secret
  git init -q
  echo "FAKE_SECRET=abcd1234abcd1234abcd1234abcd1234" > .env
  git add .env
  git commit -m "Add fake secret" -q

  run bash -c 'GITHUB_WORKSPACE="$TEST_REPO" bash $BATS_TEST_DIRNAME/../run.sh'
  [ "$status" -ne 0 ]
  [[ "$output" =~ "secrets-leaked=" ]] # Should be >0
}
