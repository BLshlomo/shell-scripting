#!/bin/sh
set -x

addr=tox_lb
port=8080
t=5

# Split test file to smaller ones
mkdir -p src/test/split
cd src/test/split
split -l 10 ../e2e
cd ..

# Check if the app container is running
while [ $t -gt 0 ]; do
nc -z "$addr" $port && break || sleep 3
t=$((t-1))
done
[ $t -eq 0 ] && echo "App is not up, quitting" && exit 1

# Run test files simultaneously in the background
rm -f log.log
for b in split/*; do
    python e2e_test.py $addr:$port $b 0 2>>log.log &
done

# Waiting for all tests to end
wait

# Checking for error
grep -q Traceback log.log && exit 2 || exit 0

# For longer tests, would use a loop similar to the next code
# For alpine linux (busybox) the syntax would be different, as you dont have regular arrays in busybox
###
for p in "${pid[@]}"; do
    wait "$p"
    exit=$?
    [ $exit -ne 0 -a $exit -ne 127 ] && exit $exit || echo "pid $p is over"
    # Checking for error
    grep -q error log && exit 2
done
###
