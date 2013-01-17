#!/bin/sh

if [ $# -eq 0 ]; then

    echo "You mass pass a host name."
    exit 1;

fi

# - Send one ping (-c 1), print numeric value (-n)
# - Find the line looking like PING <hostname> (<ip>) <num1>(<num2>) bytes of data.
#     We are interested in the <ip> part
# - Cut the line into sections at white space. The (<ip>) part is the third (-f3) element.
# - Then remove the first brace "(" from the beginning.
# - Finally remove the last brace ")" from the end.
ping -c 1 -n $1 | grep ^PING | cut -d " " -f3 | cut -d "(" -f2 | cut -d ")" -f1

if [ $? -eq 0 ]; then
    exit 0;
else
    exit 1;
fi