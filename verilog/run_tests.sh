runtest() {
	echo $1 "pipeline";
	vvp pipeline_sim +bin=../target_code/$1;
	echo
	echo $1 "CPU";
	vvp cpu_sim +bin=../target_code/$1;
	echo
}

runtest "bubble-sort.hex"
runtest "dcache.hex"
runtest "div.hex"
runtest "fib.hex"
runtest "reverse.hex"
runtest "pipeline-tests.hex"

echo "Tests complete"
