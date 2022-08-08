#!/bin/bash

function sar_memory_caller(){
    sar -r $1 $2 >> "sar_memory_${3}.txt"
}

function sar_cpu_caller(){
    sar -u $1 $2 >> "sar_cpu_${3}.txt"
}

function sar_io_caller(){
    sar -b $1 $2 >> "sar_io_${3}.txt"
}

function sar_starter(){
    pids=()
	sar_memory_caller "$@"&
    pids+=("$!") 
	sar_cpu_caller "$@"&
    pids+=("$!")
	sar_io_caller "$@"&
    pids+=("$!")

    for pid in ${pids[@]}
    do
        wait $pid
    done

}

function test_function_starter(){
    coproc func { $*; }
    pid=${func_PID}
    wait $pid
    echo $pid
}

function main(){
	sar_starter 1 5 "before"
    test_function_starter $*

}

main $1