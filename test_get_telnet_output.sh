#!/bin/sh



((echo "GET / HTTP/1.0\n\n"; sleep 9) | telnet 127.0.0.1 8888 ) > telnet_output_test.tmp.txt

