#Una vez realizado el análisis con BUSCO de cada uno de los genomas, este script busca las secuencias BUSCO
#filtra las secuencias para retener solo los genes con al menos 70% de representación en todos los taxones
#Realiza el alineamiento con MAFFT, hace curación del alineamiento con TrimAl y genera arboles de maximum likelihood con Fastree
#Para finalmente construir un arbol coalescente con ASTRAL y un arbol particionado concatenado con IQTREE
#!/bin/bash

# ==============================================================================
# PIPELINE FILOGENÓMICO NATIVO (Corregido: Nombres de Especies)
# ==============================================================================

echo "1. Creando estructura de directorios..."
rm -rf analisis_filogenomico_final
mkdir -p analisis_filogenomico_final/{1_ortologos_crudos,2_filtrados,3_alineamientos,4_limpios,5_arboles_individuales}

echo "2. Extrayendo secuencias BUSCO y renombrando con la especie..."
# Busca todos los genes .faa de copia única
find entradas_filogenomica -type f -name "*.faa" | grep "single_copy" | while read filepath; do
    # SOLUCIÓN: Cortamos la ruta exactamente en la segunda carpeta (entradas_filogenomica/busco_ESPECIE/...)
    # y le quitamos el prefijo "busco_"
    carpeta_especie=$(echo "$filepath" | cut -d '/' -f 2)
    especie=$(echo "$carpeta_especie" | sed 's/busco_//')
    gen=$(basename "$filepath")
    
    # Escribe el header con la especie real y luego la secuencia de aminoácidos
    echo ">$especie" >> analisis_filogenomico_final/1_ortologos_crudos/"$gen"
    grep -v ">" "$filepath" >> analisis_filogenomico_final/1_ortologos_crudos/"$gen"
    echo "" >> analisis_filogenomico_final/1_ortologos_crudos/"$gen"
done

echo "3. Filtrando genes (mínimo 70% de presencia = 11 especies)..."
for gen in analisis_filogenomico_final/1_ortologos_crudos/*.faa; do
    num_sp=$(grep -c ">" "$gen")
    if [ "$num_sp" -ge 11 ]; then
        cp "$gen" analisis_filogenomico_final/2_filtrados/
    fi
done

echo "4. Alineando (MAFFT), Limpiando (trimAl) y Árboles (FastTree)..."
for gen in analisis_filogenomico_final/2_filtrados/*.faa; do
    nombre=$(basename "$gen" .faa)
    
    # Alinear
    mafft --auto --quiet "$gen" > analisis_filogenomico_final/3_alineamientos/"${nombre}.aln"
    
    # Limpiar ruido (gappyout)
    trimal -in analisis_filogenomico_final/3_alineamientos/"${nombre}.aln" -out analisis_filogenomico_final/4_limpios/"${nombre}.aln" -gappyout
    
    # Seguridad: Solo procesar el gen si sobrevivió a trimAl
    tamanio=$(wc -c < analisis_filogenomico_final/4_limpios/"${nombre}.aln")
    if [ "$tamanio" -gt 50 ]; then
        fasttree -quiet analisis_filogenomico_final/4_limpios/"${nombre}.aln" > analisis_filogenomico_final/5_arboles_individuales/"${nombre}.tre"
    else
        rm analisis_filogenomico_final/4_limpios/"${nombre}.aln"
    fi
done

echo "5. Construyendo el Árbol Coalescente con ASTRAL..."
cat analisis_filogenomico_final/5_arboles_individuales/*.tre > analisis_filogenomico_final/todos_los_genes.tre
astral -i analisis_filogenomico_final/todos_los_genes.tre -o analisis_filogenomico_final/ARBOL_ASTRAL_FINAL.tre

echo "6. Construyendo Árbol Particionado con IQ-TREE (Esto tardará horas)..."
iqtree -S analisis_filogenomico_final/4_limpios -m MFP -B 1000 -alrt 1000 -T AUTO --threads-max 16 --prefix analisis_filogenomico_final/ARBOL_IQTREE_FINAL

echo "=========================================================="
echo " ¡ANÁLISIS SUPERADO! Resultados listos en 'analisis_filogenomico_final'"
echo "=========================================================="
