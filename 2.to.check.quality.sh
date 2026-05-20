#Para evaluar la calidad de las lecturas luego de revisadas por calidad utilizando multiqc
#Activar este comando si multiqc está instalado en un contenedor conda
#conda activate multiqc
multiqc . --filename reporte_final_fusarium --title "Análisis de Calidad Fusarium Data"
