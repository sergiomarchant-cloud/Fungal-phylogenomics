#Este script permite realizar la limpieza de los archivos fastq.gz del paso anterior. 
#este script usa fastp
#Utilizar este comando si fastp está instalado en un contenedor conda
#conda activate fastp
#
#
#
#!/bin/bash

# 1. Create the output directory
mkdir -p cleaned_reads

# 2. Loop through all forward read files
for r1 in *_1.fastq.gz; do
    
    # Define the corresponding reverse read
    r2="${r1/_1.fastq.gz/_2.fastq.gz}"
    
    # Extract the species name for clean output naming
    base=$(basename "$r1" _1.fastq.gz)
    
    # Define expected output files for cleaner code
    out1="cleaned_reads/${base}_cleaned_1.fastq.gz"
    out2="cleaned_reads/${base}_cleaned_2.fastq.gz"

    # Check if BOTH cleaned files already exist
    if [ -f "$out1" ] && [ -f "$out2" ]; then
        echo "-------------------------------------------------------"
        echo "Saltando: $base (Ya fue procesado)"
        echo "-------------------------------------------------------"
        continue
    fi
    
    echo "-------------------------------------------------------"
    echo "Processing Species: $base"
    echo "-------------------------------------------------------"

    # 3. Run fastp with assembly-optimized parameters
    fastp \
        --in1 "$r1" \
        --in2 "$r2" \
        --out1 "$out1" \
        --out2 "$out2" \
        --html "cleaned_reads/${base}_report.html" \
        --json "cleaned_reads/${base}_report.json" \
        --thread 16 \
        --detect_adapter_for_pe \
        --trim_poly_g \
        --cut_front \
        --cut_tail \
        --cut_window_size 4 \
        --cut_mean_quality 20 \
        --length_required 50

done
