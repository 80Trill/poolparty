#!/usr/bin/env bash

# Exit script as soon as a command fails.
set -o errexit

#rm -f build/contracts/*

# Constant helpers.
. scripts/constants.sh

if [ "$SOLIDITY_COVERAGE" = true ]; then
  ganache_port=8555
else
  ganache_port=8545
fi

start_ganache() {
  node_modules/.bin/ganache-cli --gasLimit 0xfffffffffff $accounts > /dev/null &

  ganache_pid=$!
}

if ganache_running; then
  echo "Using existing ganache instance"
else
  echo "Starting our own ganache instance"
  start_ganache
fi
