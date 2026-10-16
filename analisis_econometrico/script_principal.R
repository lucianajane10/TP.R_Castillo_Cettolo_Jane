# =====================================================================
# Análisis econométrico con datos de gapminder
# Script principal. No se definen funciones propias, por eso no hay
# archivo funciones.R en esta carpeta. Los datos están en
# data/gapminder.csv (correr con el directorio de trabajo = esta carpeta)
# =====================================================================

set.seed(123)               # reproducibilidad: SIEMPRE al principio

library(tidyverse)          # la primera vez: install.packages("tidyverse")

# Paso 1: leemos los datos (ruta relativa a esta carpeta)
datos <- read_csv("data/gapminder.csv")

# Paso 2: exploración inicial
names(datos)                          # nombres de las columnas
nrow(datos)                           # cantidad de filas
length(unique(datos$country))         # cantidad de países
min(datos$year)                       # primer y último año de la base
max(datos$year)

# =====================================================================
# PARTE 1: Ingreso por persona
# =====================================================================

# ---------------------------------------------------------------------
# Inciso 1: evolución del ingreso por persona en Argentina
# ---------------------------------------------------------------------

# Paso 1: nos quedamos con Argentina, ordenada por año
arg <- datos %>%
  filter(country == "Argentina") %>%
  select(country, year, income_per_person) %>%
  arrange(year)

# Paso 2: chequeamos que no haya NAs y los sacamos si los hubiera
sum(is.na(arg$income_per_person))
arg <- arg %>% filter(!is.na(income_per_person))
nrow(arg)

# Paso 3: gráfico de la evolución
ggplot(arg, aes(x = year, y = income_per_person)) +
  geom_line() +
  labs(title = "Ingreso por persona - Argentina",
       x = "Año", y = "Ingreso por persona") +
  theme_minimal()

# ---------------------------------------------------------------------
# Inciso 2: tres modelos de tendencia, con train y test
# ---------------------------------------------------------------------

# Paso 1: creamos el tiempo t (el primer año es t = 0)
arg <- arg %>%
  mutate(t = year - min(year))

# Paso 2: separamos los últimos 10 años para testear
anio_corte <- max(arg$year) - 10
train <- arg %>% filter(year <= anio_corte)
test  <- arg %>% filter(year >  anio_corte)
nrow(train)
nrow(test)

# Paso 3: estimamos los tres modelos SOLO con los datos de entrenamiento
# (a) lineal: ingreso = b1*t + b0
modelo_lineal <- lm(income_per_person ~ t, data = train)
summary(modelo_lineal)

# (b) grado 2: ingreso = b2*t^2 + b1*t + b0
# I(t^2) le dice a lm que use t al cuadrado como otra variable
modelo_pol2 <- lm(income_per_person ~ t + I(t^2), data = train)
summary(modelo_pol2)

# (c) grado 10: ingreso = b0 + b1*t + ... + b10*t^10
# Usamos poly(t, 10, raw = FALSE) (polinomios ortogonales): con raw = TRUE,
# t^10 da números enormes y R tiene problemas numéricos. El ajuste y las
# predicciones son los mismos, solo cambia cómo se escriben los coeficientes.
modelo_pol10 <- lm(income_per_person ~ poly(t, 10, raw = FALSE), data = train)
summary(modelo_pol10)

# Paso 4: predicciones de los tres modelos para todos los años (train + test)
arg <- arg %>%
  mutate(pred_lineal = predict(modelo_lineal, newdata = arg),
         pred_pol2   = predict(modelo_pol2,   newdata = arg),
         pred_pol10  = predict(modelo_pol10,  newdata = arg))

# Paso 5: gráfico con los datos observados y los tres ajustes
# (la línea punteada marca dónde empieza el test). coord_cartesian recorta
# el eje y: el grado 10 "explota" en el test y si no el gráfico es ilegible
ggplot(arg, aes(x = year)) +
  geom_point(aes(y = income_per_person)) +
  geom_line(aes(y = pred_lineal, color = "Lineal")) +
  geom_line(aes(y = pred_pol2,   color = "Grado 2")) +
  geom_line(aes(y = pred_pol10,  color = "Grado 10")) +
  geom_vline(xintercept = anio_corte + 0.5, linetype = "dashed") +
  coord_cartesian(ylim = c(min(arg$income_per_person) * 0.8,
                           max(arg$income_per_person) * 1.3)) +
  scale_color_manual(values = c("Lineal" = "red",
                                "Grado 2" = "blue",
                                "Grado 10" = "darkgreen")) +
  labs(title = "Ajustes de tendencia - Argentina",
       x = "Año", y = "Ingreso por persona", color = "Modelo") +
  theme_minimal()

# Paso 6: zoom al conjunto de testeo (últimos 10 años)
test_pred <- arg %>% filter(year > anio_corte)

ggplot(test_pred, aes(x = year)) +
  geom_point(aes(y = income_per_person)) +
  geom_line(aes(y = pred_lineal, color = "Lineal")) +
  geom_line(aes(y = pred_pol2,   color = "Grado 2")) +
  geom_line(aes(y = pred_pol10,  color = "Grado 10")) +
  coord_cartesian(ylim = c(min(test_pred$income_per_person) * 0.5,
                           max(test_pred$income_per_person) * 1.5)) +
  scale_color_manual(values = c("Lineal" = "red",
                                "Grado 2" = "blue",
                                "Grado 10" = "darkgreen")) +
  labs(title = "Conjunto de testeo - Argentina",
       x = "Año", y = "Ingreso por persona", color = "Modelo") +
  theme_minimal()

# Paso 7: error en train y en test de cada modelo (RMSE: cuánto se
# equivoca el modelo en promedio, en las unidades del ingreso)
rmse_train_lineal <- sqrt(mean((train$income_per_person - predict(modelo_lineal, newdata = train))^2))
rmse_test_lineal  <- sqrt(mean((test$income_per_person  - predict(modelo_lineal, newdata = test))^2))
rmse_train_pol2   <- sqrt(mean((train$income_per_person - predict(modelo_pol2,   newdata = train))^2))
rmse_test_pol2    <- sqrt(mean((test$income_per_person  - predict(modelo_pol2,   newdata = test))^2))
rmse_train_pol10  <- sqrt(mean((train$income_per_person - predict(modelo_pol10,  newdata = train))^2))
rmse_test_pol10   <- sqrt(mean((test$income_per_person  - predict(modelo_pol10,  newdata = test))^2))

comparacion <- data.frame(
  modelo     = c("Lineal", "Grado 2", "Grado 10"),
  rmse_train = c(rmse_train_lineal, rmse_train_pol2, rmse_train_pol10),
  rmse_test  = c(rmse_test_lineal,  rmse_test_pol2,  rmse_test_pol10)
)
comparacion

# ---------------------------------------------------------------------
# Inciso 3: correlaciones entre países sudamericanos
# ---------------------------------------------------------------------

# Paso 1: Argentina y cuatro países sudamericanos
paises_sud <- c("Argentina", "Brazil", "Chile", "Uruguay", "Paraguay")

datos_sud <- datos %>%
  filter(country %in% paises_sud) %>%
  select(country, year, income_per_person) %>%
  filter(!is.na(income_per_person)) %>%
  arrange(country, year)

length(unique(datos_sud$country))     # tienen que ser 5

# Paso 2 (3.a): matriz de correlaciones entre los niveles de ingreso.
# Pasamos la tabla a formato ancho (una columna por país)
ingresos_ancho <- datos_sud %>%
  pivot_wider(names_from = country, values_from = income_per_person) %>%
  select(-year)

matriz_corr_ingresos <- cor(ingresos_ancho, use = "complete.obs")
round(matriz_corr_ingresos, 4)

# Paso 3 (3.b): matriz de correlaciones entre los crecimientos interanuales
# (delta Y / Y = (Y_t - Y_{t-1}) / Y_{t-1}), calculados dentro de cada país
crecimiento_ancho <- datos_sud %>%
  group_by(country) %>%
  mutate(crecimiento = (income_per_person - lag(income_per_person)) / lag(income_per_person)) %>%
  ungroup() %>%
  filter(!is.na(crecimiento)) %>%
  select(country, year, crecimiento) %>%
  pivot_wider(names_from = country, values_from = crecimiento) %>%
  select(-year)

matriz_corr_crecimiento <- cor(crecimiento_ancho, use = "complete.obs")
round(matriz_corr_crecimiento, 4)

# =====================================================================
# PARTE 2: Esperanza de vida y género (un solo año: 2007)
# =====================================================================

# Paso 1: filtramos el año. life_expectancy_female puede venir como texto
# (donde falta el dato hay un "-"): as.numeric() lo pasa a número y los "-"
# quedan como NA (R avisa con un warning, es esperable). Después los sacamos
df_2007 <- datos %>%
  filter(year == 2007) %>%
  mutate(life_expectancy_female = as.numeric(life_expectancy_female)) %>%
  filter(!is.na(life_expectancy) & !is.na(life_expectancy_female))

# Paso 2: chequeos (NAs, cantidad de países y rango de valores)
sum(is.na(df_2007$life_expectancy))
sum(is.na(df_2007$life_expectancy_female))
nrow(df_2007)
min(df_2007$life_expectancy_female)
max(df_2007$life_expectancy_female)

# ---------------------------------------------------------------------
# Inciso 5: life_expectancy vs. life_expectancy_female
# ---------------------------------------------------------------------
# La línea punteada es la de 45 grados (ambas variables iguales)
ggplot(df_2007, aes(x = life_expectancy_female, y = life_expectancy)) +
  geom_point(color = "steelblue", alpha = 0.7, size = 2) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray50") +
  labs(title = "Esperanza de vida total vs. femenina (2007)",
       x = "Esperanza de vida femenina (años)",
       y = "Esperanza de vida total (años)") +
  theme_minimal()


# ---------------------------------------------------------------------
# Inciso 6: regresión simple de life_expectancy sobre life_expectancy_female
# ---------------------------------------------------------------------
modelo_simple <- lm(life_expectancy ~ life_expectancy_female, data = df_2007)
summary(modelo_simple)

coef(modelo_simple)
r2_simple <- summary(modelo_simple)$r.squared
r2_simple

# Gráfico: datos y recta estimada
ggplot(df_2007, aes(x = life_expectancy_female, y = life_expectancy)) +
  geom_point(color = "steelblue", alpha = 0.7, size = 2) +
  geom_abline(intercept = coef(modelo_simple)[1], slope = coef(modelo_simple)[2],
              color = "darkred") +
  labs(title = "Regresión simple: esperanza de vida total vs. femenina (2007)",
       x = "Esperanza de vida femenina (años)",
       y = "Esperanza de vida total (años)") +
  theme_minimal()
# ---------------------------------------------------------------------
# Inciso 7: contraste de hipótesis
# H0: life_expectancy_female = life_expectancy
# H1: life_expectancy_female > life_expectancy   (alternativa de UNA cola)
# ---------------------------------------------------------------------

# Paso 1: diferencia país por país (femenina - total)
df_2007 <- df_2007 %>%
  mutate(diferencia = life_expectancy_female - life_expectancy)

# Paso 2: diferencia promedio y en cuántos países la diferencia es positiva
mean(df_2007$diferencia)
sum(df_2007$diferencia > 0)
nrow(df_2007)

# Paso 3: regresión de la diferencia sobre una constante. El intercepto es
# la diferencia promedio; summary() muestra su estadístico t y su p-valor
modelo_dif <- lm(diferencia ~ 1, data = df_2007)
summary(modelo_dif)

# Paso 4: summary() da el p-valor de DOS colas (H1: diferencia distinta de
# 0). Como nuestra alternativa es de una cola (diferencia > 0) y el
# estimador es positivo, el p-valor de una cola es la mitad
p_dos_colas <- summary(modelo_dif)$coefficients[1, 4]
p_una_cola  <- p_dos_colas / 2
p_una_cola

# ---------------------------------------------------------------------
# Inciso 8: regresión múltiple con income_per_person
# ---------------------------------------------------------------------

# Paso 1: chequeo de NAs del ingreso. Para que la comparación de R2 con la
# simple sea justa, usamos la misma muestra en ambos modelos
sum(is.na(df_2007$income_per_person))
df_8 <- df_2007 %>% filter(!is.na(income_per_person))
nrow(df_8)

# Paso 2: simple (misma muestra) y múltiple
modelo_simple_8 <- lm(life_expectancy ~ life_expectancy_female, data = df_8)
modelo_multiple <- lm(life_expectancy ~ life_expectancy_female + income_per_person,
                      data = df_8)
summary(modelo_multiple)
coef(modelo_multiple)

# Paso 3: R2 de ambos modelos
r2_simple_8 <- summary(modelo_simple_8)$r.squared
r2_multiple <- summary(modelo_multiple)$r.squared
c(R2_simple = r2_simple_8, R2_multiple = r2_multiple)

# ---------------------------------------------------------------------
# Inciso 9: modelo lineal de máximo 3 covariables para life_expectancy
# ---------------------------------------------------------------------

# Paso 1: variables que excluimos
# - life_expectancy_female y life_expectancy_male: forman parte de la
#   esperanza de vida total por construcción (la explicarían "mecánicamente").
# - country: es un identificador. year: es constante (filtramos 2007).
# - Variables de texto (world_region, income_groups, main_religion, is_oecd):
#   las dejamos afuera.

# Paso 2: nuevas columnas. Usamos el logaritmo del ingreso y de la población:
# son variables muy asimétricas (pocos países con valores enormes) y el
# logaritmo las hace más comparables
df_2007 <- df_2007 %>%
  mutate(log_income     = log(income_per_person),
         log_population = log(population))

# Paso 3: chequeo de NAs de las candidatas y nos quedamos con los países
# que tienen todas (si no, lm los descarta y predict da NA en el test)
sum(is.na(df_2007$log_income))
sum(is.na(df_2007$child_mortality))
sum(is.na(df_2007$children_per_woman))
sum(is.na(df_2007$log_population))

candidatas <- c("log_income", "child_mortality", "children_per_woman", "log_population")

df_9 <- df_2007 %>%
  filter(!is.na(life_expectancy) & !is.na(log_income) & !is.na(child_mortality) &
           !is.na(children_per_woman) & !is.na(log_population))
datos9 <- df_9[, c("life_expectancy", candidatas)]
nrow(datos9)

# Paso 4: separamos train (70%) y test (30%). Volvemos a fijar la semilla
# acá para que la partición sea la misma aunque se corra solo este bloque
set.seed(123)
filas_train <- sample(seq_len(nrow(datos9)), size = floor(0.7 * nrow(datos9)))
train9 <- datos9[filas_train, ]
test9  <- datos9[-filas_train, ]

# Paso 5: todas las combinaciones de 1, 2 y 3 variables
combinaciones <- list()
for (k in 1:3) {
  combinaciones <- c(combinaciones, combn(candidatas, k, simplify = FALSE))
}

resultados9 <- data.frame(
  regresores = sapply(combinaciones, paste, collapse = " + "),
  k          = sapply(combinaciones, length),
  R2_train   = NA_real_,
  ECM_test   = NA_real_
)

# Paso 6: para cada combinación, estimamos en train y medimos el error
# cuadrático medio (ECM) en test
for (i in seq_along(combinaciones)) {
  formula_i <- reformulate(combinaciones[[i]], response = "life_expectancy")
  modelo_i  <- lm(formula_i, data = train9)
  resultados9$R2_train[i] <- summary(modelo_i)$r.squared
  resultados9$ECM_test[i] <- mean((test9$life_expectancy - predict(modelo_i, newdata = test9))^2)
}

# Paso 7: elegimos el modelo con menor error en test
resultados9[order(resultados9$ECM_test), ]
mejor <- which.min(resultados9$ECM_test)
resultados9[mejor, ]

# Paso 8: estimamos el modelo elegido con todos los datos
formula_final <- reformulate(combinaciones[[mejor]], response = "life_expectancy")
modelo_propuesto <- lm(formula_final, data = datos9)
summary(modelo_propuesto)
summary(modelo_propuesto)$r.squared