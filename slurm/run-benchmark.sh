#!/bin/bash
#SBATCH --account=nfl5182_sc
#SBATCH --job-name=run-lrcmc
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=kms8227@psu.edu
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 16
#SBATCH --mem-per-cpu=20gb
#SBATCH --time=6:00:00
#SBATCH --output=slurm/output/run-lrcmc_%j.out


DESIGN='test-5-3'
BATCH_SIZE_COV=5000000
N_PROCS=16
BATCH_SIZE_DDP=128 #32
BATCH_SIZE_DSGD=128 #32 # $((BATCH_SIZE_DDP * N_PROCS))
BASE_LR=0.005
LR_DDP=$(echo "$BASE_LR * $N_PROCS" | bc)
LR_DSGD=0.02 # $(echo "$BASE_LR * sqrt($N_PROCS)" | bc -l) #$(echo "$BASE_LR * $N_PROCS" | bc)
TOL=1e-9
MAX_EPOCHS=100
SEED=12345


echo "======================================="
echo "Start: $(date)"
echo "======================================="


echo "N_PROCS = $N_PROCS"


# Activate conda env
source ~/.bashrc
conda activate ffa-p2
cd /storage/home/kms8227/work/ffa-p2-priv

# TODO: 
#   - Create dir_out

# echo "---------- SIMULATE DATA ----------"

# python lrcmc_simulate_data.py \
#     --config roar \
#     --design $DESIGN \
#     --batch_size $BATCH_SIZE_COV \
#     --seed $SEED

echo "---------- ALLOCATE POINTS (DSGD) ----------"
    
python lrcmc_allocate_points.py \
    --config roar \
    --design $DESIGN \
    --method dsgd \
    --n_procs $N_PROCS \
    --seed $SEED
    

echo "---------- ALLOCATE POINTS (DDP) ----------"

python lrcmc_allocate_points.py \
    --config roar \
    --design $DESIGN \
    --method ddp \
    --n_procs $N_PROCS \
    --seed $SEED


echo "---------- ESTIMATE (DSGD) ----------"

python lrcmc_estimate_dsgd.py \
    --config roar \
    --design $DESIGN \
    --world_size $N_PROCS \
    --batch_size $BATCH_SIZE_DSGD \
    --lr $LR_DSGD \
    --tol $TOL \
    --patience 5 \
    --max_epochs $MAX_EPOCHS \
    --benchmark


echo "---------- ESTIMATE (DDP) ----------"

python lrcmc_estimate_ddp.py \
    --config roar \
    --design $DESIGN \
    --world_size $N_PROCS \
    --batch_size $BATCH_SIZE_DDP \
    --lr $LR_DDP \
    --tol $TOL \
    --patience 5 \
    --max_epochs $MAX_EPOCHS \
    --benchmark


# echo "---------- PLOT ----------"

# python lrcmc_plotting.py \
#     --config roar \
#     --design $DESIGN \
#     --n_procs $N_PROCS


echo "======================================="
echo "End: $(date)"
echo "======================================="