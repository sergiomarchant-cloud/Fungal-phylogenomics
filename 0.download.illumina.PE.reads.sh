#Este script utiliza sra-tools intalado en conda y permite descargar lecturas de illumina a partir del ID_SRR. 
#Incluir en la lista aquellos ID de relevancia para el proyecto
#
#
#
#Ejectuar este comando si usas sra-tools en entorno conda
#conda activate sra-tools
# Lista de pares ID_SRR:Nombre_Especie (PE Confirmados)
samples=(
    "SRR35993446:F_oxysporum_albedinis"
    "SRR35660540:F_oxysporum_fragariae"
    "SRR32606958:F_oxysporum_lycopersici"
    "SRR25037564:F_oxysporum_cubense"
    "SRR11523115:F_oxysporum_Fo47_REF"       
    "SRR35777317:F_verticillioides"
    "SRR34933776:F_proliferatum"
    "SRR35384911:F_solani"
    "SRR5194938:F_equiseti"
    "SRR34016940:Trichoderma_reesei_OUT"    
    "SRR35017290:Aspergillus_flavus"
    "ERR15975942:Aspergillus_fumigatus"
)

mkdir -p reads
# Creamos el encabezado del CSV solo si el archivo NO existe
if [ ! -f muestras_fusarium.csv ]; then
    echo "sample_id,fastq_1,fastq_2" > muestras_fusarium.csv
fi

echo "Iniciando verificación de archivos..."

for sample in "${samples[@]}"; do
    srr_id="${sample%%:*}"
    species_name="${sample##*:}"
    
    # 1. VERIFICACIÓN: ¿Ya existe el archivo final?
    if [ -f "reads/${species_name}_1.fastq.gz" ] && [ -f "reads/${species_name}_2.fastq.gz" ]; then
        echo ">>> Saltando $species_name: Ya se encuentra en la carpeta."
        
        # Opcional: Asegurar que esté en el CSV si no estaba
        if ! grep -q "$species_name" muestras_fusarium.csv; then
            echo "${species_name},reads/${species_name}_1.fastq.gz,reads/${species_name}_2.fastq.gz" >> muestras_fusarium.csv
        fi
        continue
    fi

    # 2. DESCARGA: Solo si no pasó la verificación anterior
    echo "----------------------------------------------------"
    echo "Descargando faltante: $species_name [$srr_id]"
    
    fasterq-dump --split-3 --outdir reads --progress "$srr_id"
    
    if [ -f "reads/${srr_id}_1.fastq" ] && [ -f "reads/${srr_id}_2.fastq" ]; then
        mv "reads/${srr_id}_1.fastq" "reads/${species_name}_1.fastq"
        mv "reads/${srr_id}_2.fastq" "reads/${species_name}_2.fastq"
        
        gzip "reads/${species_name}_1.fastq"
        gzip "reads/${species_name}_2.fastq"
        
        echo "${species_name},reads/${species_name}_1.fastq.gz,reads/${species_name}_2.fastq.gz" >> muestras_fusarium.csv
        echo "ÉXITO: $species_name descargado y procesado."
    else
        echo "ERROR: No se pudo obtener $species_name en formato PE."
    fi
done

echo "----------------------------------------------------"
echo "Verificación finalizada. Tu set de datos está completo."
