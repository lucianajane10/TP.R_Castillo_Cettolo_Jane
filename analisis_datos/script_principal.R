# =====================================================================
# Ejercicio de Análisis de datos: pingüinos de Palmer (palmerpenguins)
# Script principal. No se definen funciones propias, por eso no hay
# archivo funciones.R en esta carpeta.
# =====================================================================

set.seed(123)               # reproducibilidad: SIEMPRE al principio
# (este análisis no usa azar, pero lo fijamos igual)

# Paso 1: cargamos los paquetes. La primera vez hay que instalar el de
# los datos (una sola vez): install.packages("palmerpenguins")
library(tidyverse)
library(palmerpenguins)

# ---------------------------------------------------------------------
# Exploración inicial de los datos
# ---------------------------------------------------------------------

# Paso 1: tamaño de la base y categorías de las variables de texto
nrow(penguins)
unique(penguins$species)
unique(penguins$island)

# Paso 2: ¿cuántos datos faltantes (NA) hay en cada variable que usamos?
penguins %>%
  summarise(
    NA_especie = sum(is.na(species)),
    NA_isla    = sum(is.na(island)),
    NA_pico    = sum(is.na(bill_length_mm)),
    NA_peso    = sum(is.na(body_mass_g)),
    NA_sexo    = sum(is.na(sex))
  )

# Paso 3: para la pregunta 1 necesitamos largo del pico y peso, así que
# sacamos los pingüinos que no tienen alguno de los dos datos
peng <- penguins %>%
  filter(!is.na(bill_length_mm) & !is.na(body_mass_g))
nrow(peng)

# Paso 4: rangos, para chequear que no haya valores imposibles
# (negativos o absurdos)
peng %>%
  summarise(
    peso_min = min(body_mass_g), peso_max = max(body_mass_g),
    pico_min = min(bill_length_mm), pico_max = max(bill_length_mm)
  )

# Paso 5: distribuciones del peso y del largo del pico, por especie
ggplot(peng, aes(x = body_mass_g, fill = species)) +
  geom_histogram(position = "identity", alpha = 0.6, binwidth = 100) +
  labs(title = "Distribución del peso", x = "Peso (g)", y = "Frecuencia") +
  theme_minimal()

ggplot(peng, aes(x = bill_length_mm, fill = species)) +
  geom_histogram(position = "identity", alpha = 0.6, binwidth = 1) +
  labs(title = "Distribución del largo del pico", x = "Largo del pico (mm)", y = "Frecuencia") +
  theme_minimal()

# ---------------------------------------------------------------------
# Pregunta 1: ¿cómo cambia el largo del pico a medida que cambia el peso?
# ---------------------------------------------------------------------

# Paso 1: las especies tienen tamaños muy distintos, así que estimamos
# la relación con todos los pingüinos juntos y también dentro de cada
# especie. Primero, regresión con todos juntos:
# largo del pico = intercepto + pendiente * peso
modelo <- lm(bill_length_mm ~ body_mass_g, data = peng)
coef(modelo)                      # intercepto y pendiente
summary(modelo)$r.squared         # R2: qué parte de la variación explica

# Paso 2: una regresión por especie, guardando los resultados en una tabla
especies <- unique(peng$species)

resultados <- data.frame(
  species    = especies,
  intercepto = NA_real_,
  pendiente  = NA_real_,
  R2         = NA_real_
)

for (i in seq_along(especies)) {
  datos_i  <- peng %>% filter(species == especies[i])
  modelo_i <- lm(bill_length_mm ~ body_mass_g, data = datos_i)
  resultados$intercepto[i] <- coef(modelo_i)[1]
  resultados$pendiente[i]  <- coef(modelo_i)[2]
  resultados$R2[i]         <- summary(modelo_i)$r.squared
}

resultados

# Paso 3: gráfico de dispersión con una recta por especie (color) y la
# recta de todos juntos (punteada)
ggplot(peng, aes(x = body_mass_g, y = bill_length_mm, color = species)) +
  geom_point(alpha = 0.6) +
  geom_abline(data = resultados, aes(intercept = intercepto, slope = pendiente, color = species)) +
  geom_abline(intercept = coef(modelo)[1], slope = coef(modelo)[2], linetype = "dashed") +
  labs(title = "Largo del pico vs. peso",
       subtitle = "Líneas de color: recta por especie. Punteada: todos juntos",
       x = "Peso (g)", y = "Largo del pico (mm)") +
  theme_minimal()

# ---------------------------------------------------------------------
# Pregunta 2: ¿cuál es la composición por especie de cada isla?
# ---------------------------------------------------------------------

# Paso 1: usamos la base completa (penguins), porque esta pregunta no
# necesita pico ni peso. Chequeamos que no haya NAs en las variables
sum(is.na(penguins$species))
sum(is.na(penguins$island))

# Paso 2: cantidad de pingüinos de cada especie en cada isla
cantidad <- penguins %>%
  count(island, species)
cantidad

# Paso 3: composición = proporción de cada especie dentro de cada isla
composicion <- cantidad %>%
  group_by(island) %>%
  mutate(total_isla = sum(n),
         proporcion = n / total_isla) %>%
  ungroup()
composicion

# Paso 4: gráfico de la composición (cada barra suma 100%)
ggplot(composicion, aes(x = island, y = proporcion, fill = species)) +
  geom_col() +
  labs(title = "Composición por especie de cada isla",
       x = "Isla",
       y = "Proporción",
       fill = "Especie") +
  theme_minimal()

# ---------------------------------------------------------------------
# Pregunta 3: ¿cómo varía la proporción de hembras y machos entre las
# islas en la muestra?
# ---------------------------------------------------------------------

# Paso 1: cantidad y proporción de hembras y machos en cada isla
# (sacamos los pingüinos sin dato de sexo, porque esta pregunta lo usa)
isla_sexo <- peng %>%
  filter(!is.na(sex)) %>%
  group_by(island, sex) %>%
  summarise(cantidad = length(sex), .groups = "drop") %>%
  group_by(island) %>%
  mutate(proporcion = cantidad / sum(cantidad)) %>%
  ungroup()

isla_sexo

# Paso 2: gráfico de la proporción de hembras y machos en cada isla
# (cada barra suma 100%). La línea punteada marca el 50%
ggplot(isla_sexo, aes(x = island, y = proporcion, fill = sex)) +
  geom_col() +
  geom_hline(yintercept = 0.5, linetype = "dashed") +
  labs(title = "Proporción de hembras y machos por isla",
       x = "Isla", y = "Proporción", fill = "Sexo") +
  theme_minimal()