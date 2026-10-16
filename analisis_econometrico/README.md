# Análisis econométrico con datos de gapminder

Este ejercicio usa la base `gapminder` para practicar regresión, análisis de correlaciones y visualización en R. La parte 1 estudia el ingreso por persona de Argentina y de otros países sudamericanos a lo largo del tiempo. La parte 2 estudia, para el año 2007, la relación entre la esperanza de vida total y la esperanza de vida femenina.

## Contenido de la carpeta

    analisis_econometrico/
    |-- README.md
    |-- script_principal.R
    `-- data/
        `-- gapminder.csv

- **`script_principal.R`**: resuelve la parte 1 (incisos 1 a 3) y la parte 2 (incisos 5 a 9) paso a paso, con gráficos y tablas. Es el único archivo que hay que correr. La numeración sigue la de la consigna, que no tiene inciso 4.
- **`data/gapminder.csv`**: base de datos original, tal como se descargó del campus.

No hay `funciones.R` porque en este ejercicio no se definen funciones propias.

## Cómo reproducir los resultados

1. Abrir R o RStudio.
2. Instalar el paquete, una sola vez:

        install.packages("tidyverse")

3. Fijar como directorio de trabajo esta carpeta. En RStudio: abrir `script_principal.R` y usar *Session → Set Working Directory → To Source File Location*. El script lee los datos con la ruta relativa `data/gapminder.csv`, así que `data/` tiene que estar dentro de la carpeta de trabajo.
4. Correr `script_principal.R` completo (botón *Source*).

El script empieza con `set.seed(123)`. El único paso con azar es la partición entre entrenamiento y testeo del inciso 9, y la semilla se vuelve a fijar justo antes de ese paso, así que los resultados son reproducibles. Al convertir `life_expectancy_female` a número, R muestra un aviso ("NAs introducidos por coerción"): es esperable, corresponde a los países que tienen "-" en lugar de un dato.

## Datos

La base tiene 9.843 observaciones de 193 países entre 1960 y 2010. Las variables que se usan son:

| Variable | Descripción |
|---|---|
| `country`, `year` | País y año |
| `income_per_person` | Ingreso por persona |
| `life_expectancy` | Esperanza de vida total (años) |
| `life_expectancy_female` | Esperanza de vida femenina (años). Viene como texto, con "-" donde falta el dato |
| `child_mortality` | Mortalidad infantil |
| `children_per_woman` | Hijos por mujer |
| `population` | Población |

## Decisiones de diseño

- **Train y test en la serie de Argentina (inciso 2).** Los últimos 10 años (2001 a 2010) se reservan para testear y los modelos se estiman solo con 1960 a 2000. La comparación entre modelos se hace con el RMSE (error cuadrático medio, en las unidades del ingreso) en ambos conjuntos.
- **Polinomio de grado 10.** Se usa `poly(t, 10, raw = FALSE)` (polinomios ortogonales), porque con potencias crudas de t el ajuste tiene problemas numéricos. El ajuste y las predicciones son equivalentes. En los gráficos se recorta el eje y, porque el grado 10 explota fuera de la muestra.
- **Correlaciones (inciso 3).** Se usan Argentina, Brasil, Chile, Uruguay y Paraguay. Las matrices se calculan en niveles y en crecimiento interanual (ΔY/Y), con el crecimiento calculado dentro de cada país.
- **Contraste de hipótesis (inciso 7).** Se regresa la diferencia (femenina − total) sobre una constante. Como la alternativa de la consigna es de una cola, el p-valor reportado es la mitad del que muestra `summary()`.
- **Misma muestra en la simple y la múltiple (inciso 8).** Ambos modelos se estiman con los mismos países, para que la comparación de R² sea justa.
- **Modelo de máximo tres variables (inciso 9).** Se excluyen la esperanza de vida femenina y masculina (por construcción forman parte de la total), el identificador del país, el año y las variables de texto. Las candidatas son `log_income`, `child_mortality`, `children_per_woman` y `log_population`. Se estiman los 14 modelos con 1, 2 o 3 variables en un 70% de los países y se elige el de menor error cuadrático medio en el 30% restante.

## Resumen de resultados

- **Inciso 1:** el ingreso por persona de Argentina pasa de 9.765 en 1960 a 18.912 en 2010, con ciclos marcados (caídas hacia 1990 y 2002).
- **Inciso 2:** el grado 10 ajusta mejor en entrenamiento (R² de 0,94) pero es el peor en test (RMSE de 138.837, contra 2.012 del lineal y 3.114 del grado 2): sobreajusta y no sirve para extrapolar.
- **Inciso 3:** las correlaciones en niveles van de 0,67 a 0,95 y en crecimiento de 0,01 a 0,51. Uruguay es el más parecido a Argentina en ambos casos.
- **Incisos 5 y 6 (2007, 184 países):** relación positiva y casi lineal entre ambas esperanzas de vida; la recta estimada tiene pendiente 0,881 y R² de 0,937.
- **Inciso 7:** la esperanza de vida femenina es en promedio 1,51 años mayor que la total (mayor en 140 de 184 países); se rechaza H0 con un p-valor de una cola de 9,1 × 10⁻¹⁴.
- **Inciso 8:** al agregar el ingreso, el coeficiente de la esperanza de vida femenina baja de 0,88 a 0,86 y el R² sube apenas, de 0,9370 a 0,9388.
- **Inciso 9:** el modelo elegido es `log_income + child_mortality + log_population`, con R² = 0,804.

La interpretación completa de cada inciso está en `informe.pdf`.
