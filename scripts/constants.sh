#!/usr/bin/env bash

balance=100000000000000000000000000
accounts=""

acc=( \
    0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501201 \
    0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501202 \
    0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501203 \
    0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501204 \
    0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501205 \
    0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501206 \
    0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501207 \
    0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501208 \
    0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501209 \
    0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501200 \
    )

# Prepare a ganache accounts parameter string like --account="0x11c..,1000" --account="0xc5d...,1000" ....
for a in ${acc[@]}; do
  accounts=$accounts" --account=${a},${balance}"
done

# Helper funcs.

# Test if ganache is running on port $1.
# Result is in $?
ganache_running() {
  nc -z localhost "$ganache_port"
}

cleanup() {
  # Kill the ganache instance that we started (if we started one and if it's still running).
  echo "cleaning up"
  if [ -n "$ganache_pid" ] && ps -p $ganache_pid > /dev/null; then
    echo "killing ganache instances"
    kill -9 $ganache_pid
  fi
}
