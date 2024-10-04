#!/usr/bin/env bash
#SBATCH --time=00:10:00
#SBATCH --partition=students
#SBATCH --gpus=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=5G
#SBATCH --output=./slurm.out

# This activates the environment (given .envrc is in the current directory)
# This activates the environment (given .envrc is in the current directory)
# If you do not want to have the .envrc in your current directory, use this snippet
# pushd $(pwd)
# cd path/to/devshell
# direnv allow . && eval "$(direnv export bash)"
# popd
direnv allow . && eval "$(direnv export bash)"

python -c "import torch; print(torch.__version__)"


