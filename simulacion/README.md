# Simulación 1: Demanda con preferencias Cobb–Douglas

Este ejercicio estudia, mediante simulaciones en R, la demanda de dos bienes de consumo por parte de los hogares con preferencias Cobb–Douglas, y cómo reaccionan ante un shock de precios.

## Contenido de la carpeta

    simulacion/
    |-- README.md
    |-- script_principal.R
    `-- funciones.R

- **`script_principal.R`**: resuelve los incisos 1 a 7 paso a paso (parámetros, simulaciones, gráficos y tablas). Es el único archivo que hay que correr.
- **`funciones.R`**: contiene solo las definiciones de las funciones. El script principal las carga con `source("funciones.R")`.

No se usan datos externos: todos los datos se generan por simulación, así que no hay carpeta `data/`.

## Cómo reproducir los resultados

1. Abrir R o RStudio.
2. Fijar como directorio de trabajo esta carpeta (`simulacion/`). En RStudio: abrir `script_principal.R` y usar *Session → Set Working Directory → To Source File Location*.
3. Correr `script_principal.R` completo (botón *Source*).

No hace falta instalar ningún paquete. El script empieza con `set.seed(2026)`, así que los resultados son reproducibles.

## Modelo

Cada hogar tiene ingreso Y > 0, enfrenta precios p₁ > 0 y p₂ > 0 y elige (x₁, x₂) para maximizar

    U(x1, x2) = x1^alpha1 * x2^alpha2,   con alpha1 + alpha2 = 1

sujeto a p₁·x₁ + p₂·x₂ ≤ Y. La solución es:

    x1* = alpha1 * Y / p1
    x2* = alpha2 * Y / p2
    U*  = (x1*)^alpha1 * (x2*)^alpha2

## Funciones (`funciones.R`)

| Función | Qué hace |
|---|---|
| `simular_ingreso(n, k)` | Genera `n` ingresos con distribución χ² con `k` grados de libertad (inciso 1). |
| `demanda_cd(Y, p1, p2, alpha1, alpha2)` | Devuelve una lista con las demandas óptimas `x1`, `x2` y la utilidad indirecta `U` (inciso 2). Acepta escalares o vectores, y verifica que ingresos y precios sean positivos y que alpha1 + alpha2 = 1. |
| `prob_bajo_consumo(sim, c, j)` | Estima P(x_j\* < c) como la proporción de hogares simulados por debajo del umbral `c`, para el bien `j` (1 o 2) (inciso 4). |
| `resumir(x)` | Devuelve la media y los cuartiles (Q1, mediana, Q3) de un vector. |
| `graficar_superpuesto(x_pre, x_post, ...)` | Dibuja dos histogramas superpuestos con los mismos cortes, para comparar antes y después del shock (incisos 6 y 7). |
| `correr_heterogeneo(Y, p1, p1_nuevo, p2, a, b)` | Sortea alpha1 ~ Beta(a, b) para cada hogar y calcula las demandas antes y después del shock (inciso 7). |

## Parámetros elegidos

| Parámetro | Valor |
|---|---|
| Cantidad de hogares (n) | 10.000 |
| Grados de libertad del ingreso (k) | 10 |
| Precio del bien 1 (p₁) | 2 |
| Precio del bien 2 (p₂) | 4 |
| Preferencias (α₁, α₂) | 0,4 y 0,6 |
| Umbral de bajo consumo (c) | 1 |
| Shock | p₁ sube 20% (p₁′ = 2,4) |
| Heterogeneidad, dispersión baja | α₁ ~ Beta(40, 60), desvío ≈ 0,05 |
| Heterogeneidad, dispersión alta | α₁ ~ Beta(2, 3), desvío ≈ 0,20 |

Las unidades del ingreso son arbitrarias. Con k = 10 el ingreso medio es 10.

## Decisiones de diseño

- **Mismos ingresos en todos los escenarios.** Los ingresos se generan una sola vez y se reutilizan antes y después del shock y en los casos homogéneo y heterogéneo. Así las diferencias entre escenarios se deben solo al cambio de precios o de preferencias, y no al ruido muestral.
- **Misma media de α₁ en los casos heterogéneos.** Ambos casos tienen α₁ de media 0,4, igual que el caso homogéneo. Solo cambia la dispersión, lo que permite aislar su efecto.
- **Validación con la teoría.** Cuando existe una fórmula cerrada, el script la compara con la simulación. Por ejemplo: los cuartiles de x₁\* con `qchisq`, la probabilidad de bajo consumo con `pchisq`, el cociente post/pre de x₁\* (que debe ser 1/1,2) y la variación de la utilidad (1,2^(−α₁)).

## Resumen de resultados

- **Ingreso (inciso 1):** el coeficiente de variación es √(2/k). Al subir k, la dispersión relativa baja y la distribución se vuelve más simétrica. Se eligió k = 10.
- **Simulación base (inciso 3):** x₁\*, x₂\* y U\* son múltiplos del ingreso, así que heredan su asimetría hacia la derecha. Las medias son 1,99, 1,49 y 1,67 respectivamente.
- **Bajo consumo (inciso 4):** P(x₁\* < 1) = 0,1076 (simulada) frente a 0,1088 (teórica).
- **Shock de precios (incisos 5 y 6):** el consumo de x₁\* cae 16,7% (exactamente 1/1,2) en todos los hogares. La probabilidad de bajo consumo sube de 0,1076 a 0,1841 y la utilidad media cae 7,03%.
- **Heterogeneidad (inciso 7):** la caída relativa del consumo del bien 1 es la misma (−16,7%) cualquiera sea la dispersión de α₁. Lo que cambia con la dispersión es el nivel de bajo consumo antes del shock (11% en el caso homogéneo, 26% con dispersión alta) y la dispersión de las demandas. La utilidad media cae entre 7,0% y 7,2% en todos los escenarios.

La interpretación completa de cada inciso está en `informe.pdf`.
