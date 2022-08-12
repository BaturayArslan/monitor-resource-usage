#!/bin/bash


function sar_memory_caller(){
    if [[ -z $3 ]]; then
        sar -r $2 >> "sar_memory_${1}.txt"
    
    else
        sar -r $2 $3 | tail -n +3 >> "sar_memory_${1}.txt"
    fi
}

function sar_cpu_caller(){
    if [[ -z $3 ]]; then
        sar -u $2 >> "sar_cpu_${1}.txt"    
    else
        sar -u $2 $3 | tail -n +3 >> "sar_cpu_${1}.txt"
    fi
}

function sar_io_caller(){
    if [[ -z $3 ]]; then
        sar -b $2 >> "sar_io_${1}.txt"
    else
        sar -b $2 $3 | tail -n +3 >> "sar_io_${1}.txt"
    fi
}

function sar_starter(){
    sar_pids=()
	sar_memory_caller "$@"&
    sar_pids+=("$!") 
	sar_cpu_caller "$@"&
    sar_pids+=("$!")
	sar_io_caller "$@"&
    sar_pids+=("$!")

    for pid in ${sar_pids[@]}
    do
        wait $pid
    done

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
    local inf=($*)
    local tmp_arr=()
    local index=0

    for (( k=0;k<5;k++ ))
    do
        tmp_arr[$k]=${inf[$k]}
    done
    tmp_arr[5]="${inf[@]:5:${#inf[@]}}"

    for (( i=0;i<${#tmp_arr[@]};i+=6 ))
    do
        index=${tmp_arr[$i]}
        for (( j=0;j<6;j++ ))
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
            result_arr[$key,10]=${arr[$key,5]}
        fi
        arr_rows=$((arr_rows+1))

    done
}

function test_function_measure(){
    pids=()
    declare -Ag result_arr
    while [[ -n "`ps -p $1 | tail -n +2`" ]]
    do
        declare -A arr
        childrens=()
        get_childs_pid $1
        info=$(ps -p "${childrens[*]}" -o pid,%mem,%cpu,rss,vsz,command | tail -n +2)
        fill_arr "$info"
        calculate
        unset arr
        sleep 1
    done

}

list_descendants ()
{
  local children=$(ps -o pid= --ppid "$1")

  for pid in $children
  do
    list_descendants "$pid"
  done

  echo "$children"
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
    sar_starter "current" 1 &
    sar_process=$!
    test_function_measure $pid
    kill -SIGINT $(list_descendants $sar_process)
    exec 3<&-
    wait $pid
 
}

function generate_report(){
    cpu_header="`cat sar_cpu_before.txt | head -n 1`"
    cpu_avg_before="`cat sar_cpu_before.txt | tail -n 1`"
    cpu_avg_current="`cat sar_cpu_current.txt | tail -n 1`"
    cpu_avg_after="`cat sar_cpu_after.txt | tail -n 1`"

    mem_header="`cat sar_memory_before.txt | head -n 1`"
    mem_avg_before="`cat sar_memory_before.txt | tail -n 1`"
    mem_avg_current="`cat sar_memory_current.txt | tail -n 1`"
    mem_avg_after="`cat sar_memory_after.txt | tail -n 1`"

    io_header="`cat sar_io_before.txt | head -n 1`"
    io_avg_before="`cat sar_io_before.txt | tail -n 1`"
    io_avg_current="`cat sar_io_current.txt | tail -n 1`"
    io_avg_after="`cat sar_io_after.txt | tail -n 1`"

    echo -e "$cpu_header\n$cpu_avg_before\n$cpu_avg_current\n$cpu_avg_after" >> report.txt
    printf "\n***************************************\n" >> report.txt
    echo -e "$mem_header\n$mem_avg_before\n$mem_avg_current\n$mem_avg_after" >> report.txt
    printf "\n***************************************\n" >> report.txt
    echo -e "$io_header\n$io_avg_before\n$io_avg_current\n$io_avg_after" >> report.txt
    printf "\n***************************************\n" >> report.txt


    printf "%-10s  %-10s  %-10s  %-10s  %-10s  %-10s  %-10s  %-10s  %-10s  %-10s %-30s\n" \
    "pid" "max_memory" "max_cpu" "max_rss" "max_vsz" "avg_memory" "avg_cpu" "avg_rss" "avg_vsz" "time" "command" >> report.txt
    row=0
    col=0
    echo "${result_arr[${pids[$row]},$col]}***"
    echo "${pids[$row]} :: pid"
    while [[ -n "${result_arr[${pids[$row]},$col]}" ]]
    do
        local tmp_arr=()
        col=0
        while [[ -n "${result_arr[${pids[$row]},$col]}" ]]
        do
            tmp_arr+=("${result_arr[${pids[$row]},$col]}")
            ((col++))
        done
        printf "%-10d  %-10.1f  %-10.1f  %-10.1f  %-10.1f  %-10.1f  %-10.1f  %-10.1f  %-10.1f  %-10d %-30s\n" ${tmp_arr[@]:0:5} \
        $( echo "${tmp_arr[5]} / ${tmp_arr[9]}" | bc ) $( echo "${tmp_arr[6]} / ${tmp_arr[9]}" | bc ) $( echo "${tmp_arr[7]} / ${tmp_arr[9]}" | bc ) \
        $( echo "${tmp_arr[8]} / ${tmp_arr[9]}" | bc ) ${tmp_arr[9]} "${tmp_arr[10]}" >> report.txt
    ((row++))
    done


}

function main(){
	sar_starter "before" 1 5
    test_function_starter $*
    sar_starter "after" 1 5
    generate_report
    trap "cat sar_cpu* > cpu_sar.txt;cat sar_mem*>memory_sar.txt;cat sar_io* > io_sar.txt; rm sar*" EXIT

}

main $1
