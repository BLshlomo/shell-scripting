#!/bin/sh

# My test script example - made for Alpine linux (Busybox)

# Proccess command line args
ret=8
addr=$1; shift
port=$1; shift
data=$1
out=''

# set default test data in case of no command line arguments
[ -z $data ] && \
data="username=script&msg=test
username=scriptdb&msg=test1
username=etc&msg=test2
username=more&msg=test3
username=even_more&msg=test4"

# Wait for connection
until curl --retry-delay 6 --connect-timeout 5 --max-time 5 --retry 5 \
--silent --fail ${addr}:${port} 1>/dev/null || [ $ret -eq 0 ]; do
    echo "retries left = $ret"
    sleep 5 
    ret=$((ret-1))
done

# Exit if the number of retries left is none (No connection)
[ $ret -eq 0 ] && printf '%s \n' 'Failed to connect' && exit 1 || printf '%s \n' 'Connection established'

# Initiate testing table
curl --silent ${addr}:${port}/api/chat/testing -X POST -d "username=script&msg=init"

# Reads post request data file line by line and saves the response to file
echo "$data" | while IFS= read -r line || [ -n "$line" ]; do
  printf %s\n "`curl --silent ${addr}:${port}/api/chat/testing -X POST -d $line`" > out.txt
done

# Count the amount of lines to compare
lines=`printf '%s\n' $data | wc -l`

# Set the comarators
received=`cut -d' ' -f3,4 out.txt | tr -d : | sed -n "1,${lines}p"`
sent=`echo "$data" | tr '&' = | cut -d'=' -f2,4 | sed 's/=/ /' | tac`

# Compare response with expected outcome
if [ "$sent" = "$received" ]; then
    printf "E2E tests are done\n"
else
    printf "E2E tests failed\n"
    exit 1
fi

echo "? = $?"
exit 0