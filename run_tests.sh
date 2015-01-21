#!/usr/bin/env sh

run () {

    for model in $models; do
        for core in $cores; do
            for workers in $skel_workers; do
                for ops in $operators; do
                    for run in `seq 1 $run_repeat`; do
                        mkdir -p $output_root/$ops/$model/$core/w$workers

                        echo "running $model in $rtime mlsecs with $workers skel workers on $core cores with $ops operators.."
                        logfile="emas_$rtime"`date +"-%s"`".log"

                        output_file=$output_root/$ops/$model/$core/w$workers/$logfile
                        echo $output_file
                        erl +S 4:$core -pa ebin -pa deps/*/ebin \
                            -eval "emas:start($model,$rtime,[{skel_workers,$workers},{genetic_ops,$ops},{problem_size,30}])." \
                            -run init stop -noshell
                        #> $output_file
                    done
                done
            done
        done
    done
}

run_mems () {

    for eval in $eval_memetics; do
        for mut in $mut_memetics; do
            for run in `seq 1 $run_repeat`; do
                mkdir -p $output_root/$ops-$model-$cores-w$workers/ev-$eval/mt-$mut

                echo "running $model in $rtime mlsecs with $workers skel workers on $core cores with $ops operators.."
                echo "using $eval memetics for evaluation and $mut memetics for mutations"
                logfile="emas_$rtime"`date +"-%s"`".log"

                output_file=$output_root/$ops-$model-$cores-w$workers/ev-$eval/mt-$mut/$logfile
                echo $output_file
                erl -pa ebin -pa deps/*/ebin \
                    -eval "emas:start($rtime,[{model, $model}, {skel_workers,$workers},{genetic_ops,$ops}, {genetic_ops_opts, [{mem_evaluation, $eval}, {mem_mutation, $mut}]}, {problem_size,50}])." \
                    -run init stop -noshell > $output_file
            done
        done
    done
}



output_dir="output"
rtime=600000 # 10 min

eval_memetics="sdls"
mut_memetics="rhmc tabu default_mem"


cores=2
run_repeat=20
workers=2
model="mas_skel" # mas_sequential mas_concurrent mas_hybrid"
ops="labs_ops"


output_root=$output_dir

run_mems
