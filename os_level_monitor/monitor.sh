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

function get_childs_pid(){
    parent=$1
    for i in "`pgrep -P $parent`"
    do
        if [[ -z "$i" ]]; then
            break
        fi
        childrens+=(`echo -n $i`)
        get_childs_pid $i
    done
}

function fill_arr(){
    local tmp_arr=($*)
    local index=0
    for (( i=0;i<${#tmp_arr[@]};i+=5 ))
    do
        index=${tmp_arr[$i]}
        for (( j=0;j<5;j++ ))
        do
            arr[$index,$j]=${tmp_arr[$((i+j))]}
        done
    done
}

function calculate(){
    arr_rows=0
    local key=0
    while [[ -n "${arr[${childrens[$arr_rows]},0]}" ]]
    do
        key=${arr[${childrens[$arr_rows]},0]}
        if [[ -n "${result_arr[$key,0]}" ]]; then
            # this process has been pushed result_arr before so update values.
            echo "merahaba"
            for (( i=1;i<5;i++ ))
            do
                if (( $(echo "${arr[$key,$i]} > ${result_arr[$key,$i]}" | bc -l) )); then
                    result_arr[$key,$i]=${arr[$key,$i]}
                fi
                result_arr[$key,$(($i+4))]=$(echo "${result_arr[$key,$(($i+4))]} + ${arr[$key,$i]}" | bc)
            done
            result_arr[$key,9]=$(( ${result_arr[$key,9]} + 1))
        else
            # new subprocess spawned.
            echo "dünya"
            pids+=("$key")
            for (( i=0;i<5;i++ ))
            do  
                result_arr[$key,$i]=${arr[$key,$i]}
                if [[ $i -eq 0 ]]; then
                    continue 
                else
                    result_arr[$key,$(($i+4))]=${arr[$key,$i]}
                fi
            done
            result_arr[$key,9]=1
        fi
        arr_rows=$((arr_rows+1))

    done
}

function test_function_measure(){
    pids=()
    declare -A result_arr
    while [[ -n "`ps -p $1 | tail -n +2`" ]]
    do
        declare -A arr
        childrens=()
        get_childs_pid $1
        info=$(ps -p "${childrens[*]}" -o pid,%mem,%cpu,rss,vsz | tail -n +2)
        fill_arr "$info"
        calculate
        unset arr
        sleep 1
    done

    deneme=0
    echo "${childrens[0]}"
    while [[ -n "${result_arr[${pids[0]},$deneme]}" ]]
    do
        echo "${result_arr[${pids[0]},$deneme]}"
        (( deneme++ ))
    done
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
	#sar_starter 1 5 "before"
    test_function_starter $*

}

main $1
