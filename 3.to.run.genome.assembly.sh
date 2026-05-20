#Este script ensambla los genomas descritos en el archvio MPGAP_samplesheet.yml
#utilizando nextflow:mpgap. Se seleccionó los ensambladores spades y megahit porque son más adecuados para genomas de hongos.
#Utilizar este comando si nextflow está instalado en un entorno conda
#conda activate nextflow
nextflow run fmalmeida/mpgap \
    -profile docker \
    --output ./genome_assembly_4_fungi_cleaned \
    --tracedir ./genome_assembly_4_fungi_cleaned/pipeline_info_4_fungi \
    --input MPGAP_samplesheet.yml \
    --organism 'fungus' \
    --max_cpus 48 \
    --assemblers 'spades,megahit' \
    -resume
