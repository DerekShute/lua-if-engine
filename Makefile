
# TODO: strip requires from lua files and compile those

all: unittest.luac sample.luac tombofkepshai.luac coverage diagrams

all_tests := $(addsuffix .test, $(basename $(wildcard *.test-in)))
all_dots := sample.dot
all_diagrams := sample.svg

# https://stackoverflow.com/questions/4927676/implementing-make-check-or-make-test

# Regenerate a test file as necessary
#
#       (I'm not sure how to make a test_regenerate target here
#	without causing the .test-cmp files to be rebuilt
#
#       lua unittest.luac <unittest.test-in >unittest.test-cmp 2>&1
#       lua sample.luac <sample.test-in >sample.test-cmp 2>&1

coverage: $(all_tests)
# TODO coverage invoked as
#	lua -lluacov <test>.luac <input
#         must have luacov rock installed and LUA_PATH set up correctly, not
#	  sure how to manhandle that
#	luacov (to convert stats to report

%.test : %.test-in %.test-cmp unittest.luac sample.luac
	@lua $*.luac < $< 2>&1 | diff $(word 2, $?) - || \
	(echo "Test $@ failed" && exit 1)

diagrams: $(all_dots) $(all_diagrams)

%.dot : %.lua
	echo "digraph {" > $@
	cat $< | grep "DOT" | cut --complement -c 1,2,3,4,5,6 | sort -u >> $@
	echo "}" >> $@

%.svg : %.dot
	dot -Tsvg $< -o $@

unittest.luac: if-engine.lua unittest.lua
	luac -o $@ $^

sample.luac: if-engine.lua sample.lua
	luac -o $@ $^

tombofkepshai.luac: if-engine.lua tombofkepshai.lua
	luac -o $@ $^

.PHONY: clean all %.test
clean:
	rm -f *.luac *~ *.dot *.svg
