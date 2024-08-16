# DCAI_DIR is set to the parent directory of the folder containing this script.
# For example, if this script is in /path/to/reproduce_results/, DCAI_DIR will be /path/to/
DCAI_DIR=$(dirname "$(dirname "$(realpath "$0")")")
DCAI_DIR=$(dirname "$(dirname "$(realpath "$0")")")
DCAI_SETUP_DIR="$DCAI_DIR/setup.sh"
source "$DCAI_SETUP_DIR"

run_pipeline() {

    local CMD=$1

    echo "Running command:"
    while IFS= read -r line; do
        echo "$line"
    done <<<"$(echo "$CMD" | sed 's/ --/\n--/g')"
    echo ""

    echo "------------------------------------------------------------------------"
    echo "------------------------------------------------------------------------"
    echo "------------------------------------------------------------------------"

    # Capture start time
    START_TIME=$(date +%s%3N)

    # Run the pipeline script
    $CMD

    # Capture end time
    END_TIME=$(date +%s%3N)

    # Calculate execution time in milliseconds
    ELAPSED_TIME=$((END_TIME - START_TIME))

    # Convert milliseconds to days, hours, minutes, seconds, and milliseconds
    DAYS=$((ELAPSED_TIME / 86400000))
    ELAPSED_TIME=$((ELAPSED_TIME % 86400000))

    HOURS=$((ELAPSED_TIME / 3600000))
    ELAPSED_TIME=$((ELAPSED_TIME % 3600000))

    MINUTES=$((ELAPSED_TIME / 60000))
    ELAPSED_TIME=$((ELAPSED_TIME % 60000))

    SECONDS=$((ELAPSED_TIME / 1000))
    MILLISECONDS=$((ELAPSED_TIME % 1000))

    # Display elapsed time in the desired format
    echo "------------------------------------------------------------------------"
    echo "------------------------------------------------------------------------"
    echo "Elapsed Time for this stage (D:H:M:S:MS): $DAYS:$HOURS:$MINUTES:$SECONDS:$MILLISECONDS"
    echo "------------------------------------------------------------------------"
    echo "------------------------------------------------------------------------"
    echo "------------------------------------------------------------------------"
    echo ""
}

ENV=digitjump
DATA_DIR=digitjump
ENV_MODEL_NAME_DISC=digitjump_disc
ENV_MODEL_NAME_CONT=digitjump_cont
ENV_MODEL_DIR_DISC=saved_env_models/${ENV_MODEL_NAME_DISC}
ENV_MODEL_DIR_CONT=saved_env_models/${ENV_MODEL_NAME_CONT}
current_time=$(date +"%Y%m%d_%H%M%S%3N")
HEUR_NNET_NAME=digitjump_heur
DATA_FILE_NAME_TRAIN_VAL=s0-1k_stp20
DATA_FILE_NAME_MODEL_TEST=s5k-5.1k_stp1k
DATA_FILE_NAME_MODEL_TEST_PLOT=s5k-5.1k_stp10k
DATA_FILE_NAME_SEARCH_TEST=s2k-2.1k
QSTAR_WEIGHT=0.7
QSTAR_H_WEIGHT=1.0
QSTAR_BATCH_SIZE=1
UCS_BATCH_SIZE=50
current_time=$(date +"%Y%m%d_%H%M%S%3N")
RESULTS_DIR_QSTAR="model=${ENV_MODEL_NAME_DISC}__heur=${HEUR_NNET_NAME}_QSTAR_results/path_cost_weight=${QSTAR_WEIGHT}__h_weight=${QSTAR_H_WEIGHT}__batchsize=${QSTAR_BATCH_SIZE}_${current_time}"
RESULTS_DIR_UCS="model=${ENV_MODEL_NAME_DISC}_UCS_results/batchsize=${UCS_BATCH_SIZE}_${current_time}"
RESULTS_DIR_GBFS="model=${ENV_MODEL_NAME_DISC}__heur=${HEUR_NNET_NAME}_GBFS_results/${current_time}"
PER_EQ_TOL=100
PLOTS_SAVE_DIR=$(pwd)

CMD_TRAIN_VAL="bash scripts/pipeline.sh --stage gen_offline \
                                        --env $ENV \
                                        --data_dir $DATA_DIR \
                                        --data_file_name $DATA_FILE_NAME_TRAIN_VAL \
                                        --num_offline_steps 20 \
                                        --num_train_eps 20000 \
                                        --num_val_eps 5000 \
                                        --num_cpus $SLURM_CPUS_ON_NODE \
                                        --start_level 0 \
                                        --num_levels 1000"

CMD_ENV_MODEL_TEST="bash scripts/pipeline.sh --stage gen_env_test \
                                             --env $ENV \
                                             --data_dir $DATA_DIR \
                                             --data_file_name $DATA_FILE_NAME_MODEL_TEST \
                                             --num_offline_steps 1000 \
                                             --num_test_eps 100 \
                                             --num_cpus $SLURM_CPUS_ON_NODE \
                                             --start_level 5000 \
                                             --num_levels 100"

CMD_SEARCH_TEST="bash scripts/pipeline.sh --stage gen_search_test \
                                          --env $ENV \
                                          --data_dir $DATA_DIR \
                                          --data_file_name $DATA_FILE_NAME_SEARCH_TEST \
                                          --num_test_eps 100 \
                                          --num_cpus $SLURM_CPUS_ON_NODE \
                                          --start_level 2000"

CMD_TRAIN_ENV_DISC="bash scripts/pipeline.sh --stage train_model \
                                             --env $ENV \
                                             --data_dir $DATA_DIR \
                                             --data_file_name $DATA_FILE_NAME_TRAIN_VAL \
                                             --env_batch_size 100 \
                                             --env_model_name $ENV_MODEL_NAME_DISC"

CMD_TEST_ENV_DISC="bash scripts/pipeline.sh --stage test_model \
                                            --env $ENV \
                                            --data_dir $DATA_DIR \
                                            --data_file_name $DATA_FILE_NAME_MODEL_TEST \
                                            --env_model_name $ENV_MODEL_NAME_DISC \
                                            --print_interval 50"

CMD_TRAIN_ENV_CONT="bash scripts/pipeline.sh --stage train_model_cont \
                                             --env $ENV \
                                             --data_dir $DATA_DIR \
                                             --data_file_name $DATA_FILE_NAME_TRAIN_VAL \
                                             --env_batch_size 100 \
                                             --env_model_name $ENV_MODEL_NAME_CONT"

CMD_TEST_ENV_CONT="bash scripts/pipeline.sh --stage test_model_cont \
                                             --env $ENV \
                                             --data_dir $DATA_DIR \
                                             --data_file_name $DATA_FILE_NAME_MODEL_TEST \
                                             --env_model_name $ENV_MODEL_NAME_CONT \
                                             --print_interval 50"

CMD_ENCODE_OFFLINE="bash scripts/pipeline.sh --stage encode_offline \
                                             --env $ENV \
                                             --data_dir $DATA_DIR \
                                             --data_file_name $DATA_FILE_NAME_TRAIN_VAL \
                                             --env_model_name $ENV_MODEL_NAME_DISC"

CMD_TRAIN_HEUR="bash scripts/pipeline.sh --stage train_heur \
                                         --env $ENV \
                                         --data_dir $DATA_DIR \
                                         --data_file_name $DATA_FILE_NAME_TRAIN_VAL \
                                         --env_model_name $ENV_MODEL_NAME_DISC \
                                         --heur_nnet_name $HEUR_NNET_NAME \
                                         --per_eq_tol $PER_EQ_TOL \
                                         --heur_batch_size 10_000 \
                                         --states_per_update 50_000_000 \
                                         --start_steps 20 \
                                         --goal_steps 20 \
                                         --max_solve_steps 20 \
                                         --num_test 1000"

CMD_TRAIN_HEUR_DIST="bash scripts/pipeline.sh --stage train_heur \
                                              --env $ENV \
                                              --data_dir $DATA_DIR \
                                              --data_file_name $DATA_FILE_NAME_TRAIN_VAL \
                                              --env_model_name $ENV_MODEL_NAME_DISC \
                                              --heur_nnet_name $HEUR_NNET_NAME \
                                              --per_eq_tol $PER_EQ_TOL \
                                              --heur_batch_size 10_000 \
                                              --states_per_update 50_000_000 \
                                              --start_steps 20 \
                                              --goal_steps 20 \
                                              --max_solve_steps 20 \
                                              --num_test 1000 \
                                              --use_dist"

CMD_QSTAR="bash scripts/pipeline.sh --stage qstar \
                                    --env $ENV \
                                    --data_dir $DATA_DIR \
                                    --data_file_name $DATA_FILE_NAME_SEARCH_TEST \
                                    --env_model_name $ENV_MODEL_NAME_DISC \
                                    --heur_nnet_name $HEUR_NNET_NAME \
                                    --qstar_batch_size $QSTAR_BATCH_SIZE \
                                    --qstar_weight $QSTAR_WEIGHT \
                                    --qstar_h_weight $QSTAR_H_WEIGHT \
                                    --per_eq_tol $PER_EQ_TOL \
                                    --qstar_results_dir $RESULTS_DIR_QSTAR \
                                    --save_imgs true"

CMD_UCS="bash scripts/pipeline.sh --stage ucs \
                                  --env $ENV \
                                  --data_dir $DATA_DIR \
                                  --data_file_name $DATA_FILE_NAME_SEARCH_TEST \
                                  --env_model_name $ENV_MODEL_NAME_DISC \
                                  --ucs_batch_size $UCS_BATCH_SIZE \
                                  --per_eq_tol $PER_EQ_TOL \
                                  --ucs_results_dir $RESULTS_DIR_UCS \
                                  --save_imgs true"

CMD_GBFS="bash scripts/pipeline.sh --stage gbfs \
                                   --env $ENV \
                                   --data_dir $DATA_DIR \
                                   --data_file_name $DATA_FILE_NAME_SEARCH_TEST \
                                   --env_model_name $ENV_MODEL_NAME_DISC \
                                   --heur_nnet_name $HEUR_NNET_NAME \
                                   --per_eq_tol $PER_EQ_TOL \
                                   --gbfs_results_dir $RESULTS_DIR_GBFS \
                                   --search_itrs 100"

CMD_VIZ_DATA="bash scripts/pipeline.sh --stage visualize_data \
                                       --env $ENV \
                                       --data_dir $DATA_DIR \
                                       --data_file_name $DATA_FILE_NAME_TRAIN_VAL \
                                       --num_train_trajs_viz 8 \
                                       --num_train_steps_viz 2 \
                                       --num_val_trajs_viz 8 \
                                       --num_val_steps_viz 2"

CMD_ENV_MODEL_TEST_PLOT="bash scripts/pipeline.sh --stage gen_env_test \
                                                  --env $ENV \
                                                  --data_dir $DATA_DIR \
                                                  --data_file_name $DATA_FILE_NAME_MODEL_TEST_PLOT \
                                                  --num_offline_steps 10_000 \
                                                  --num_test_eps 100 \
                                                  --num_cpus $SLURM_CPUS_ON_NODE \
                                                  --start_level 5000 \
                                                  --num_levels 100"

CMD_DISC_VS_CONT="bash scripts/pipeline.sh --stage disc_vs_cont \
                                           --env $ENV \
                                           --data_dir $DATA_DIR \
                                           --data_file_name $DATA_FILE_NAME_MODEL_TEST_PLOT \
                                           --env_model_dir_disc $ENV_MODEL_DIR_DISC \
                                           --env_model_dir_cont $ENV_MODEL_DIR_CONT \
                                           --save_dir $PLOTS_SAVE_DIR \
                                           --num_steps 1000 \
                                           --num_episodes 100 \
                                           --print_interval 1"

# gen_offline
run_pipeline "$CMD_TRAIN_VAL"

# visualize_data
run_pipeline "$CMD_VIZ_DATA"

# gen_offline_test
run_pipeline "$CMD_ENV_MODEL_TEST"

# gen_offline_test (10K steps for plotting)
run_pipeline "$CMD_ENV_MODEL_TEST_PLOT"

# gen_search_test
run_pipeline "$CMD_SEARCH_TEST"

# train_model
run_pipeline "$CMD_TRAIN_ENV_DISC"

# test_model
run_pipeline "$CMD_TEST_ENV_DISC"

# train_model_cont
run_pipeline "$CMD_TRAIN_ENV_CONT"

# test_model_cont
run_pipeline "$CMD_TEST_ENV_CONT"

# disc_vs_cont
run_pipeline "$CMD_DISC_VS_CONT"

# encode_offline
run_pipeline "$CMD_ENCODE_OFFLINE"

# train_heur
run_pipeline "$CMD_TRAIN_HEUR"

# # train_heur (Distributed Training)
# run_pipeline "$CMD_TRAIN_HEUR_DIST"

# qstar
run_pipeline "$CMD_QSTAR"

# ucs
run_pipeline "$CMD_UCS"

# gbfs
run_pipeline "$CMD_GBFS"
