#!/bin/bash -l

#SBATCH -A naiss2024-5-277
#SBATCH -p core -n 20
#SBATCH -t 02-00:00:00
#SBATCH --array=1-5
#SBATCH -J fst_all
#SBATCH -e fst_all_%A_%a.err
#SBATCH -o fst_all_%A_%a.out
#SBATCH --mail-type=all
#SBATCH --mail-user=khrystyna.kurta@slu.se


#Load modules
module load bioinfo-tools
module load ANGSD/0.933


#Use files from nucleotide diversity directory
NUCL_DIR=/proj/snic2020-2-19/private/herring/users/khrystyna/Arctic_charr_ref_fSalAlp1/FST_folded
cd $NUCL_DIR


# Set the chromosome number using SLURM's array task ID
chr=$SLURM_ARRAY_TASK_ID


# Assuming FST_LIST is the filename or list containing the paths to the population .list files
POP_LIST=/proj/snic2020-2-19/private/herring/users/khrystyna/Arctic_charr_ref_fSalAlp1/FST_folded/pop.list

# Convert the list of populations into an array
populations=($(cat $POP_LIST))

# Loop over the populations, avoiding repetition
for ((i = 0; i < ${#populations[@]} - 1; i++)); do
  for ((j = i + 1; j < ${#populations[@]}; j++)); do
      pop_1_name="${populations[$i]}"
      pop_2_name="${populations[$j]}"
      
      
      echo "Comparing pairs: $pop_1_name and $pop_2_name" at chr $chr
      
      # Generate the realSFS .ml file
      realSFS "${pop_1_name}_${chr}.saf.idx" "${pop_2_name}_${chr}.saf.idx" > "${pop_1_name}.${pop_2_name}.${chr}.ml"
      
      # Generate the FST index
      realSFS fst index "${pop_1_name}_${chr}.saf.idx" "${pop_2_name}_${chr}.saf.idx" -sfs "${pop_1_name}.${pop_2_name}.${chr}.ml" -fstout "${pop_1_name}.${pop_2_name}.${chr}"
      
      # Calculate FST stats
      realSFS fst stats "${morph_1_name}.${morph_2_name}.${chr}.fst.idx"
      
      # FST statistics over windows with different sizes and steps
      realSFS fst stats2 "${pop_1_name}.${pop_2_name}.${chr}.fst.idx" -win 20000 -step 10000 > "${pop_1_name}.${pop_2_name}.${chr}_20kb_10kbstep.fst_win"
      realSFS fst stats2 "${pop_1_name}.${pop_2_name}.${chr}.fst.idx" -win 40000 -step 20000 > "${pop_1_name}.${pop_2_name}.${chr}_40kb_20kbstep.fst_win"

  done
done


