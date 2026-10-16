# Análisis de datos: pingüinos de Palmer

Este ejercicio analiza, en R, la base `penguins` del paquete `palmerpenguins` (344 pingüinos de tres especies, observados en tres islas del archipiélago Palmer). Responde tres preguntas sobre la relación entre el largo del pico y el peso, la composición por especie de cada isla y la proporción de hembras y machos por isla.

## Contenido de la carpeta

    analisis_datos/
    |-- README.md
    `-- script_principal.R

- **`script_principal.R`**: contiene todo el análisis (exploración de los datos y las tres preguntas), paso a paso y comentado. Es el único archivo que hay que correr.

No hay `funciones.R` porque en este ejercicio no se definen funciones propias. Tampoco hay carpeta `data/`: los datos vienen incluidos en el paquete `palmerpenguins`.

## Cómo reproducir los resultados

1. Abrir R o RStudio.
2. Instalar los paquetes, una sola vez:

        install.packages("tidyverse")
        install.packages("palmerpenguins")

3. Fijar como directorio de trabajo esta carpeta. En RStudio: abrir `script_principal.R` y usar *Session → Set Working Directory → To Source File Location*.
4. Correr `script_principal.R` completo (botón *Source*).

El script empieza con `set.seed(123)`. Este análisis no usa números aleatorios, así que los resultados son siempre los mismos.

## Datos

| Variable | Descripción |
|---|---|
| `species` | Especie: Adelie, Chinstrap o Gentoo |
| `island` | Isla: Biscoe, Dream o Torgersen |
| `bill_length_mm` | Largo del pico (mm) |
| `body_mass_g` | Peso (g) |
| `sex` | Sexo: female o male |

La base tiene 344 filas. Hay 2 pingüinos sin largo del pico ni peso y 11 sin sexo. Las variables de especie e isla no tienen datos faltantes.

## Decisiones de diseño

- **Cada pregunta usa los datos que necesita.** La pregunta 1 usa los 342 pingüinos con largo del pico y peso (objeto `peng`). La pregunta 2 usa los 344 de la base completa, porque solo necesita especie e isla. La pregunta 3 usa los 333 pingüinos de `peng` que además tienen sexo.
- **Regresión general y por especie.** Como las especies tienen tamaños muy distintos, la pregunta 1 estima la recta con todos los pingüinos juntos y también una recta por cada especie.
- **Proporciones, no cantidades.** Las preguntas 2 y 3 comparan islas con distinta cantidad de pingüinos, por eso se grafican proporciones dentro de cada isla (cada barra suma 1).

## Resumen de resultados

- **Datos:** 344 pingüinos en total y 342 con largo del pico y peso. Los rangos son razonables (peso entre 2.700 y 6.300 g, pico entre 32,1 y 59,6 mm).
- **Pregunta 1:** el largo del pico aumenta con el peso. Con todos juntos, largo del pico = 26,90 + 0,00405 × peso (R² = 0,354). Por especie la pendiente es positiva en las tres: Adelie 0,0032 (R² 0,30), Gentoo 0,0041 (R² 0,45) y Chinstrap 0,0045 (R² 0,26). A igual peso, Chinstrap tiene el pico más largo.
- **Pregunta 2:** Biscoe es 26% Adelie y 74% Gentoo; Dream es 45% Adelie y 55% Chinstrap; Torgersen es 100% Adelie.
- **Pregunta 3:** la proporción de hembras es de 49% a 51% en las tres islas, así que no hay diferencias apreciables.

La interpretación completa de cada pregunta está en `informe.pdf`.
