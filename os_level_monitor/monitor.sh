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

function check_values(){
    local mem="`echo $1 | cut -d " " -f 1`"
    local cpu="`echo $1 | cut -d " " -f 2`"
    local rss="`echo $1 | cut -d " " -f 3`"
    local vsz="`echo $1 | cut -d " " -f 4`"

    if (( $(echo "$cpu > $max_cpu" |bc -l) )); then
        max_cpu=$cpu
    fi
    if (( $(echo "$mem > $max_memory" |bc -l) )); then
        max_memory=$mem
    fi
    if (( $(echo "$rss > $max_rss" |bc -l) )); then
        max_rss=$rss
    fi
    if (( $(echo "$vsz > $max_vsz" |bc -l) )); then
        max_vsz=$vsz
    fi
    avg_cpu=`echo "$avg_cpu + $cpu" | bc -l`
    avg_memory=`echo "$avg_memory + $mem" | bc -l`
    avg_rss=`echo "$avg_rss + $rss" | bc -l`
    avg_vsz=`echo "$avg_vsz + $vsz" | bc -l`

}

function test_function_measure(){
    read -r max_cpu max_rss max_vsz max_memory avg_cpu avg_rss avg_vsz avg_memory <<< $(echo "0 0 0 0 0 0 0 0")
    counter=0
    while [[ -n "`ps -p $1 | tail -n +2`" ]]
    do
        info="`ps -p $1 -o %mem,%cpu,rss,vsz | tail -n +2`"
        check_values "$info"
        (( counter += 1 ))
        sleep 1
    done
    echo "$max_cpu $max_memory, $max_rss, $max_vsz"
    avg_cpu=`echo "$avg_cpu / $counter" | bc -l`
    avg_memory=`echo "$avg_memory / $counter" | bc -l`
    avg_rss=`echo "$avg_rss / $counter" | bc -l`
    avg_vsz=`echo "$avg_vsz / $counter" | bc -l`
    echo "$avg_cpu, $avg_memory, $avg_rss, $avg_vsz"
}

function test_function_starter(){
    coproc func { $*; }
    pid=${func_PID}
    exec 3>&${func[0]}
    (
        while read -u 3 -r line
        do
            echo $line
        done
    )&
    test_function_measure $pid
    wait $pid
 
}

function main(){
	sar_starter 1 5 "before"
    test_function_starter $*

}

main $1
