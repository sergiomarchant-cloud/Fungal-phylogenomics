# ==============================================================================
# SCRIPT DE PUBLICACIÓN: FILOGENÓMICA DE FUSARIUM (IQ-TREE & ASTRAL)
# ==============================================================================

rm(list = ls())
# Cambia esta ruta a la carpeta donde descargaste tus archivos
setwd("/Users/macbookpro/Downloads/analisis_filogenomico_final")

library(ggplot2)
library(ggtree)
library(ape)        
library(dplyr)
library(stringr)
library(RColorBrewer)

# 1. FUNCIÓN INTELIGENTE PARA CLASIFICAR EL COLOR DEL NODO (Detecta IQ-TREE vs ASTRAL)
clasificar_soporte <- function(lbl) {
  if (is.na(lbl) || lbl == "") return(NA_character_)
  
  if (str_detect(lbl, "/")) {
    # Lógica para IQ-TREE (SH-aLRT / UFboot)
    partes <- str_split(lbl, "/")[[1]]
    alrt <- suppressWarnings(as.numeric(partes[1]))
    ufb <- suppressWarnings(as.numeric(partes[2]))
    
    if (is.na(alrt) || is.na(ufb)) return(NA_character_)
    
    if (alrt >= 80 && ufb >= 95) return("Alto (SH-aLRT ≥ 80 & UFboot ≥ 95)")
    else if (alrt >= 75 || ufb >= 80) return("Medio (Soporte Moderado)")
    else return("Bajo (SH-aLRT < 75 & UFboot < 80)")
    
  } else {
    # Lógica para ASTRAL (Probabilidad Posterior Local: 0 a 1)
    lpp <- suppressWarnings(as.numeric(lbl))
    if (is.na(lpp)) return(NA_character_)
    
    if (lpp >= 0.95) return("Alto (LPP ≥ 0.95)")
    else if (lpp >= 0.85) return("Medio (Soporte Moderado)")
    else return("Bajo (LPP < 0.85)")
  }
}

# 1.1 FUNCIÓN PARA EXTRAER LOS VALORES NUMÉRICOS PARA EL TEXTO
obtener_valores_soporte <- function(lbl) {
  if (is.na(lbl) || lbl == "") return(NA_character_)
  
  if (str_detect(lbl, "/")) {
    # IQ-TREE: Solo mostrar si UFBoot es aceptable
    partes <- str_split(lbl, "/")[[1]]
    alrt <- suppressWarnings(as.numeric(partes[1]))
    ufb <- suppressWarnings(as.numeric(partes[2]))
    if (!is.na(ufb) && ufb >= 70) return(paste0(alrt, "/", ufb))
  } else {
    # ASTRAL: Redondear a dos decimales
    lpp <- suppressWarnings(as.numeric(lbl))
    if (!is.na(lpp) && lpp >= 0.70) return(as.character(round(lpp, 2)))
  }
  return(NA_character_)
}

# 2. FUNCIÓN PRINCIPAL DE GRAFICADO (MEJORADA)
generar_filograma <- function(archivo, nombre_pdf, titulo) {
  
  message("Procesando: ", archivo)
  tree_raw <- read.tree(archivo)
  
  # Enraizar con Trichoderma reesei
  outgroup <- tree_raw$tip.label[str_detect(tree_raw$tip.label, "Trichoderma")]
  if (length(outgroup) > 0) {
    tree_rooted <- root(tree_raw, outgroup = outgroup, resolve.root = TRUE)
  } else {
    tree_rooted <- phangorn::midpoint(tree_raw)
  }
  
  tree_data <- ggtree(tree_rooted)$data
  
  df_meta <- tree_data %>%
    mutate(
      Complejo = case_when(
        !isTip ~ NA_character_,
        str_detect(label, "Trichoderma") ~ "Outgroup",
        str_detect(label, "oxysporum|FG14|FG15|Fo47") ~ "FOSC (F. oxysporum)",
        str_detect(label, "equiseti|FG16") ~ "FIESC (F. incarnatum-equiseti)",
        str_detect(label, "solani|FG17") ~ "FSSC (F. solani)",
        str_detect(label, "proliferatum|verticillioides") ~ "FFSC (F. fujikuroi)",
        TRUE ~ "Otros"
      ),
      
      # Limpieza profunda y formato correcto de "F. especie"
      Label_Clean = case_when(
        !isTip ~ NA_character_,
        TRUE ~ label %>% 
          str_replace_all("_shovill_spades_final|_megahit_assembly|_shovill_skesa_final|_unicycler_assembly|_shovill_megahit_final|_REF_megahit_assembly", "") %>% 
          str_replace_all("_", " ") %>%
          str_replace("^F([a-z])", "F. \\1") %>% # Convierte "Foxysporum" a "F. oxysporum"
          str_replace("^F\\s", "F. ") %>%       # Convierte "F oxysporum" a "F. oxysporum"
          str_trim()
      ),
      
      Soporte_Color = ifelse(isTip == FALSE, sapply(label, clasificar_soporte), NA_character_),
      Soporte_Texto = ifelse(isTip == FALSE, sapply(label, obtener_valores_soporte), NA_character_)
    )
  
  paleta_complejos <- c(
    "FOSC (F. oxysporum)" = "#E31A1C", 
    "FIESC (F. incarnatum-equiseti)" = "#1F78B4", 
    "FSSC (F. solani)" = "#33A02C", 
    "FFSC (F. fujikuroi)" = "#FF7F00",
    "Outgroup" = "#000000",
    "Otros" = "#999999"
  )
  
  colores_nodos <- c(
    "Alto (SH-aLRT ≥ 80 & UFboot ≥ 95)" = "#33A02C",  
    "Alto (LPP ≥ 0.95)" = "#33A02C",
    "Medio (Soporte Moderado)" = "#E6AB02", 
    "Bajo (SH-aLRT < 75 & UFboot < 80)" = "#E31A1C",
    "Bajo (LPP < 0.85)" = "#E31A1C"
  )
  
  # Aumentar el margen dinámicamente para evitar que se corten los nombres
  x_max <- max(tree_data$x, na.rm = TRUE)
  
  p <- ggtree(tree_rooted, layout = "rectangular", ladderize = TRUE, right = FALSE, linewidth = 0.6) %<+% 
    df_meta +
    
    # Ajustar el offset de las etiquetas y su tamaño
    geom_tiplab(aes(label = Label_Clean, color = Complejo), 
                size = 3.8, offset = x_max * 0.03, fontface = "bold.italic", 
                align = TRUE, linetype = "dotted", linesize = 0.3, show.legend = FALSE) +
    
    scale_color_manual(values = paleta_complejos, name = "Complejo de Especies:") +
    
    geom_point(aes(color = Complejo), size = 0, alpha = 0, 
               data = function(d) filter(d, isTip == TRUE)) +
    guides(color = guide_legend(override.aes = list(size = 4, alpha = 1, shape = 15), order = 1)) +
    
    geom_nodepoint(aes(fill = Soporte_Color), 
                   data = function(d) filter(d, !is.na(Soporte_Color) & isTip == FALSE),
                   shape = 21, size = 3, color = "black", stroke = 0.5) +
    scale_fill_manual(values = colores_nodos, na.translate = FALSE, name = "Soporte Nodal:") +
    guides(fill = guide_legend(override.aes = list(size = 4), order = 2)) +
    
    # Usar geom_label con fondo blanco semitransparente para evitar solapamiento
    geom_label(aes(label = Soporte_Texto), 
               data = function(d) filter(d, !is.na(Soporte_Texto) & isTip == FALSE),
               size = 2.5, fontface = "bold", color = "black", 
               fill = alpha("white", 0.7), label.size = 0, label.padding = unit(0.1, "lines"),
               nudge_y = 0.4, nudge_x = - (x_max * 0.01)) + 
    
    # Posicionar bien la escala
    geom_treescale(fontsize = 3, linesize = 1, y = -1, offset = 0.01) +
    
    theme_void() +
    ggtitle(titulo) +
    theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 20)),
      legend.position = "right",
      legend.title = element_text(size = 12, face = "bold"),
      legend.text = element_text(size = 10),
      plot.margin = margin(10, 120, 10, 10) # Mayor margen derecho (120) para los nombres
    ) +
    xlim(0, x_max * 1.6) # Expandir más el canvas para que quepa la alineación
  
  # Usar una proporción ligeramente más alta para dar respiro a las ramas
  pdf(nombre_pdf, width = 14, height = 9, useDingbats = FALSE)
  print(p)
  dev.off()
  
  message("PDF generado: ", nombre_pdf)
}

# 3. EJECUCIÓN PARA AMBOS ÁRBOLES
archivos_filogenomicos <- list(
  "ARBOL_IQTREE_FINAL.treefile" = "Árbol de Máxima Verosimilitud (Supermatriz IQ-TREE)",
  "ARBOL_ASTRAL_FINAL.tre"      = "Árbol de Especies (Modelo Coalescente ASTRAL)"
)

for (archivo in names(archivos_filogenomicos)) {
  if (file.exists(archivo)) {
    nombre_salida <- paste0("Fig_Fusarium_", gsub("\\.(treefile|tre)$", ".pdf", archivo))
    generar_filograma(archivo, nombre_salida, archivos_filogenomicos[[archivo]])
  } else {
    message("Advertencia: No se encontró el archivo ", archivo)
  }
}
