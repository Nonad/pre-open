#!/bin/bash
# train a model to segment abdominal MRI (T2 fold of CHAOS challenge)
GPUID1=1
export CUDA_VISIBLE_DEVICES=$GPUID1
cd /data/fewshot/Self-supervised-Fewshot-Medical-Image-Segmentation
####### Shared configs
PROTO_GRID=8 # using 32 / 8 = 4, 4-by-4 prototype pooling window during training
CPT="myexp_sws40h_ours_rf" 
DATASET='SWS'
NWORKER=8

ALL_EV=(0) # 5-fold cross validation (0, 1, 2, 3, 4)
ALL_SCALE=( "MIDDLE") # config of pseudolabels

### Use sws as testing classes
LABEL_SETS=0
EXCLU='[]'
AUG='sws_aug'

### Use L/R kidney as testing classes
# LABEL_SETS=0 
# EXCLU='[2,3]' # setting 2: excluding kidneies in training set to test generalization capability even though they are unlabeled. Use [] for setting 1 by Roy et al.

### Use Liver and spleen as testing classes
# LABEL_SETS=1 
# EXCLU='[1,4]' 

###### Training configs ######
NSTEP=30000
DECAY=0.95

MAX_ITER=1000 # defines the size of an epoch
SNAPSHOT_INTERVAL=10000 # interval for saving snapshot
SEED='3407'

###### Validation configs ######
SUPP_ID='[-1]' #  # using the additionally loaded scan as support

echo ===================================

for EVAL_FOLD in "${ALL_EV[@]}"
do
    for SUPERPIX_SCALE in "${ALL_SCALE[@]}"
    do
    PREFIX="train_${DATASET}_lbgroup${LABEL_SETS}_scale_${SUPERPIX_SCALE}_vfold${EVAL_FOLD}"
    echo $PREFIX
    LOGDIR="exps/${CPT}_${SUPERPIX_SCALE}_${LABEL_SETS}"

    if [ ! -d $LOGDIR ]
    then
        mkdir $LOGDIR
    fi

    python3 training.py with \
    'modelname=dlfcn_res101' \
    'usealign=True' \
    'optim_type=sgd' \
    num_workers=$NWORKER \
    scan_per_load=-1 \
    label_sets=$LABEL_SETS \
    'use_wce=True' \
    exp_prefix=$PREFIX \
    'clsname=grid_proto' \
    n_steps=$NSTEP \
    exclude_cls_list=$EXCLU \
    eval_fold=$EVAL_FOLD \
    dataset=$DATASET \
    proto_grid_size=$PROTO_GRID \
    max_iters_per_load=$MAX_ITER \
    min_fg_data=100 seed=$SEED \
    save_snapshot_every=$SNAPSHOT_INTERVAL \
    superpix_scale=$SUPERPIX_SCALE \
    lr_step_gamma=$DECAY \
    path.log_dir=$LOGDIR \
    support_idx=$SUPP_ID \
    which_aug=$AUG
    done
done
