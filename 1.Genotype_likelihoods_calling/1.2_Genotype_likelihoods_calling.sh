#!/bin/bash -l

#SBATCH -A naiss2024-5-277
#SBATCH -p core
#SBATCH -n 20
#SBATCH -t 04-00:00:00
#SBATCH --array=1-40
#SBATCH -J GL
#SBATCH -e GL_%A_%a.err
#SBATCH -o GL_%A_%a.out
#SBATCH --mail-type=all
#SBATCH --mail-user=khrystyna.kurta@slu.se

#Load modules
module load bioinfo-tools
module load samtools/1.12
module load bamtools/2.5.1
module load ANGSD/0.933


######################################################################################
# CONDUCT GENOTYPE LIKELIHOOD ESTIMATION USING ANGSD v.0.930
# Will output the following files per chromosome:
# 1. VCF (with PL field included)
# 2. Beagle (genotype likelihood format)
# 3. MAFs (allele frequencies)

# A. Khrystyna Kurta, November 2022
######################################################################################

#Path to the directory where you have the bam-files
BASEDIR=/proj/snic2020-2-19/private/herring/users/khrystyna/Arctic_charr_ref_fSalAlp1/Run_1_2
cd $BASEDIR

#STEP 1: Define paths to Refference genome
REFGENOME=/proj/snic2020-2-19/private/arctic_charr/assemblies/fSalAlp1.1/Data_Package_fSalAlp1_assembly_20231024/fSalAlp1.1.hap1.cur.20231016.fasta
REF_INDEXED=/proj/snic2020-2-19/private/arctic_charr/assemblies/fSalAlp1.1/Data_Package_fSalAlp1_assembly_20231024/fSalAlp1.1.hap1.cur.20231016.fasta.fai


##STEP 2: Determine chromosome/ or Get all the contig (or scaffold) names from the reference genome fasta file
CHUNK_DIR=/proj/snic2020-2-19/private/herring/users/khrystyna/Arctic_charr_ref_fSalAlp1/CHUNK_LIST
CHUNK_NAMES=/proj/snic2020-2-19/private/herring/users/khrystyna/Arctic_charr_ref_fSalAlp1/CHUNK_LIST/only_chr.list

CHUNK_NAMES_target=$(cat $CHUNK_NAMES | sed -n ${SLURM_ARRAY_TASK_ID}p)
CHUNK_NAMES_target_name=${CHUNK_NAMES_target/.txt/}

#STEP 3: Create bam file list
#Text file containing sample bam paths
ls /proj/snic2020-2-19/private/herring/users/khrystyna/Arctic_charr_ref_fSalAlp1/Run_1_2/*.bam > all_bam_path.list
BAM_LIST=all_bam_path.list


#STEP 4: Specify PATH to out dir
OUT_DIR=/proj/snic2020-2-19/private/herring/users/khrystyna/Arctic_charr_ref_fSalAlp1/GL_MAF_GENO_INV


#STEP 5: Run ANGSD
echo "Run angsd for $CHUNK_DIR/$CHUNK_NAMES_target"

angsd -b $BAM_LIST \
-ref $REFGENOME -fai $REF_INDEXED \
-rf $CHUNK_DIR/$CHUNK_NAMES_target.txt \
-uniqueOnly 1 -remove_bads 1 -only_proper_pairs 1 -minMapQ 30 -minQ 20 \
-gl 2 -trim 0 -doMajorMinor 4 -domaf 1 -doPost 2 -doGlf 2 -docounts 1 -dogeno 2 \
-out $OUT_DIR/Charr_RefUK_MAF0.05_chunk_${CHUNK_NAMES_target_name} \
-nThreads 10 \
-minmaf 0.05 #\ run only ones to generate a list of $SITES fot the downstream analysis
