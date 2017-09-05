cc -fno-stack-protector -o nossp test-ssp.c
cc -fstack-protector    -o ssp   test-ssp.c

#echo "Testing binary which is compiled without stack protector"
#./nossp `perl -e 'print "x"x1234'`

#echo "Testing binary which is compiled with stack protector"
#./ssp `perl -e 'print "x"x1234'`

