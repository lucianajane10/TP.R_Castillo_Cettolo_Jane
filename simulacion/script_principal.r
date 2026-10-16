set.seed(2026)              # reproducibilidad: SIEMPRE al principio
source("funciones.R")       # carga simular_ingreso, demanda_cd, etc.

# ---------------------------------------------------------------------
# Inciso 1: generación de ingresos (Y ~ chi-cuadrado con k g.l.)
# ---------------------------------------------------------------------

# Paso 1: ¿cómo cambia la dispersión de Y al variar k?
# Teoría: E[Y] = k, Var(Y) = 2k, coef. de variación = sqrt(2/k).
valores_k <- c(2, 5, 10, 30)
tabla_k <- data.frame(
  k           = valores_k,
  media       = sapply(valores_k, function(k) mean(simular_ingreso(10000, k))),
  desvio      = sapply(valores_k, function(k) sd(simular_ingreso(10000, k))),
  cv_teorico  = sqrt(2 / valores_k)
)
tabla_k$cv_empirico <- tabla_k$desvio / tabla_k$media
round(tabla_k, 3)

# Paso 2: gráfico de las densidades para distintos k
par(mfrow = c(2, 2))
for (k in valores_k) {
  hist(simular_ingreso(10000, k), freq = FALSE, col = "lightblue",
       main = paste("Ingreso ~ chi2, k =", k), xlab = "Y")
}
par(mfrow = c(1, 1))

# Paso 3: elegimos k = 10 (media 10, ingreso asimétrico a derecha pero
# sin una cola excesiva). Las unidades de Y son arbitrarias.


# ---------------------------------------------------------------------
# Inciso 2: demanda óptima Cobb-Douglas
# ---------------------------------------------------------------------

# Paso 1: probamos la función con un solo hogar:
# Y = 10, p1 = 2, p2 = 4, alpha1 = 0.4, alpha2 = 0.6
# A mano: x1* = 0.4*10/2 = 2 ; x2* = 0.6*10/4 = 1.5
prueba <- demanda_cd(Y = 10, p1 = 2, p2 = 4, alpha1 = 0.4, alpha2 = 0.6)
prueba

# Paso 2: chequeo de la restricción presupuestaria.
# El hogar tiene que gastar todo su ingreso: p1*x1* + p2*x2* = Y
2 * prueba$x1 + 4 * prueba$x2

# ---------------------------------------------------------------------
# Inciso 3: simulación base (caso homogéneo)
# ---------------------------------------------------------------------

# Paso 1: parámetros fijados por nosotras
n      <- 10000   # cantidad de hogares
k      <- 10      # grados de libertad del ingreso
p1     <- 2       # precio del bien 1
p2     <- 4       # precio del bien 2
alpha1 <- 0.4     # preferencia por el bien 1
alpha2 <- 0.6     # alpha1 + alpha2 = 1

# Paso 2: generamos los ingresos UNA vez y los reutilizamos en todos los
# escenarios (así las comparaciones pre/post shock se hacen sobre los
# mismos hogares y la diferencia no es ruido muestral).
Y <- simular_ingreso(n, k)

# ---------------------------------------------------------------------
# Inciso 4: probabilidad de bajo consumo
# ---------------------------------------------------------------------

# Paso 1: umbral c = 1 (la media de x1* es alpha1*k/p1 = 2)
c_umbral <- 1
p_bajo_pre <- prob_bajo_consumo(base, c_umbral, j = 1)
p_bajo_pre

# Paso 2: chequeo teórico. P(x1* < c) = P(Y < c*p1/alpha1) = pchisq(...)
pchisq(c_umbral * p1 / alpha1, df = k)

# Paso 3: demandas óptimas y utilidad de los 10.000 hogares
base <- demanda_cd(Y, p1, p2, alpha1, alpha2)

# Paso 4: distribuciones empíricas de x1*, x2* y U*
par(mfrow = c(1, 3))
hist(base$x1, freq = FALSE, col = "lightblue",  main = "x1*", xlab = "x1*")
hist(base$x2, freq = FALSE, col = "lightgreen", main = "x2*", xlab = "x2*")
hist(base$U,  freq = FALSE, col = "lightpink",  main = "U*",  xlab = "U*")
par(mfrow = c(1, 1))

# Paso 5: media y cuartiles
round(resumir(base$x1), 3)
round(resumir(base$x2), 3)
round(resumir(base$U), 3)

# Paso 6: chequeo contra la teoría. Como x1* = (alpha1/p1) * Y, los
# cuartiles de x1* son (alpha1/p1) por los cuantiles de una chi2(k).
(alpha1 / p1) * qchisq(c(0.25, 0.5, 0.75), df = k)

# ---------------------------------------------------------------------
# Inciso 5: shock de precios (p1 sube 20%; p2 e Y constantes)
# ---------------------------------------------------------------------

# Paso 1: nuevo precio y nueva simulación con los MISMOS ingresos Y.
# Así la diferencia entre antes y después se debe solo al precio.
p1_nuevo <- 1.2 * p1
post <- demanda_cd(Y, p1_nuevo, p2, alpha1, alpha2)

# Paso 2: comparamos media y cuartiles de x1* antes y después del shock
round(resumir(base$x1), 3)    # antes
round(resumir(post$x1), 3)    # después

# Paso 3: probabilidad de bajo consumo del bien 1 después del shock
p_bajo_post <- prob_bajo_consumo(post, c_umbral, j = 1)
c(pre = p_bajo_pre, post = p_bajo_post)

# Paso 4: chequeo teórico. Con el shock, x1* nueva = x1* vieja / 1.2
# en cada hogar, así que la media post / media pre debe ser 1/1.2
mean(post$x1) / mean(base$x1)
1 / 1.2

# ---------------------------------------------------------------------
# Inciso 6: visualización comparada
# ---------------------------------------------------------------------

# Paso 1: histogramas superpuestos de x1* pre y post shock
# La línea punteada marca el umbral de bajo consumo (c = 1).
graficar_superpuesto(base$x1, post$x1,
                     titulo = "x1*: pre y post shock (homogéneo)",
                     xlab = "x1*", etiquetas = c("Pre shock", "Post shock"))
abline(v = c_umbral, lty = 2)

# Paso 2: efecto sobre la utilidad indirecta promedio
c(U_pre = mean(base$U), U_post = mean(post$U),
  variacion = mean(post$U) / mean(base$U) - 1)

# Paso 3: chequeo teórico. Con alphas homogéneos, U* post / U* pre es
# exactamente 1.2^(-alpha1) en cada hogar.
1.2^(-alpha1) - 1

# ---------------------------------------------------------------------
# Inciso 7: heterogeneidad en preferencias (alpha1 ~ Beta(a, b))
# ---------------------------------------------------------------------

# Paso 1: dos casos con la MISMA media de alpha1 (a/(a+b) = 0.4, igual
# que en el caso homogéneo) pero distinta dispersión:
#   Var(alpha1) = a*b / ((a+b)^2 * (a+b+1))
a_baja <- 40; b_baja <- 60     # dispersión baja  (sd ~ 0.05)
a_alta <- 2;  b_alta <- 3      # dispersión alta  (sd ~ 0.20)

# Paso 2: simulamos los dos casos con los mismos ingresos Y
het_baja <- correr_heterogeneo(Y, p1, p1_nuevo, p2, a_baja, b_baja)
het_alta <- correr_heterogeneo(Y, p1, p1_nuevo, p2, a_alta, b_alta)

# Paso 3: chequeo de las alphas sorteadas (media y desvío)
c(media_baja = mean(het_baja$alpha1), sd_baja = sd(het_baja$alpha1))
c(media_alta = mean(het_alta$alpha1), sd_alta = sd(het_alta$alpha1))

# Paso 4: distribuciones de x1*, x2* y U* antes del shock
# (fila de arriba: dispersión baja; fila de abajo: dispersión alta)
par(mfrow = c(2, 3))
hist(het_baja$pre$x1, freq = FALSE, col = "lightblue",  main = "x1* (disp. baja)", xlab = "x1*")
hist(het_baja$pre$x2, freq = FALSE, col = "lightgreen", main = "x2* (disp. baja)", xlab = "x2*")
hist(het_baja$pre$U,  freq = FALSE, col = "lightpink",  main = "U* (disp. baja)",  xlab = "U*")
hist(het_alta$pre$x1, freq = FALSE, col = "lightblue",  main = "x1* (disp. alta)", xlab = "x1*")
hist(het_alta$pre$x2, freq = FALSE, col = "lightgreen", main = "x2* (disp. alta)", xlab = "x2*")
hist(het_alta$pre$U,  freq = FALSE, col = "lightpink",  main = "U* (disp. alta)",  xlab = "U*")
par(mfrow = c(1, 1))

# Paso 5: media y cuartiles, dispersión baja
round(resumir(het_baja$pre$x1), 3)
round(resumir(het_baja$pre$x2), 3)
round(resumir(het_baja$pre$U), 3)

# Paso 6: media y cuartiles, dispersión alta
round(resumir(het_alta$pre$x1), 3)
round(resumir(het_alta$pre$x2), 3)
round(resumir(het_alta$pre$U), 3)

# ---------------------------------------------------------------------
# Inciso 7 (equivalente al inciso 4): probabilidad de bajo consumo
# ---------------------------------------------------------------------

# Paso 1: P(x1* < c) antes del shock, con el mismo umbral c = 1
p_bajo_pre_baja <- prob_bajo_consumo(het_baja$pre, c_umbral, j = 1)
p_bajo_pre_alta <- prob_bajo_consumo(het_alta$pre, c_umbral, j = 1)
c(homogeneo = p_bajo_pre, disp_baja = p_bajo_pre_baja, disp_alta = p_bajo_pre_alta)

# Paso 2: chequeo teórico. Dado alpha1 de cada hogar, P(x1* < c) es
# P(Y < c*p1/alpha1) = pchisq(c*p1/alpha1, k). Promediamos esa
# probabilidad sobre los alpha1 sorteados.
mean(pchisq(c_umbral * p1 / het_baja$alpha1, df = k))
mean(pchisq(c_umbral * p1 / het_alta$alpha1, df = k))

# ---------------------------------------------------------------------
# Inciso 7 (equivalente al inciso 5): shock de precios con heterogeneidad
# ---------------------------------------------------------------------

# Paso 1: media y cuartiles de x1* antes y después del shock
# Dispersión baja
round(resumir(het_baja$pre$x1), 3)    # antes
round(resumir(het_baja$post$x1), 3)   # después
# Dispersión alta
round(resumir(het_alta$pre$x1), 3)    # antes
round(resumir(het_alta$post$x1), 3)   # después

# Paso 2: probabilidad de bajo consumo del bien 1 después del shock
p_bajo_post_baja <- prob_bajo_consumo(het_baja$post, c_umbral, j = 1)
p_bajo_post_alta <- prob_bajo_consumo(het_alta$post, c_umbral, j = 1)

# Paso 3: comparación pre vs. post para los tres escenarios
c(homogeneo_pre = p_bajo_pre,       homogeneo_post = p_bajo_post)
c(disp_baja_pre = p_bajo_pre_baja,  disp_baja_post = p_bajo_post_baja)
c(disp_alta_pre = p_bajo_pre_alta,  disp_alta_post = p_bajo_post_alta)

# Paso 4: aumento de la probabilidad, en puntos porcentuales
100 * c(homogeneo = p_bajo_post - p_bajo_pre,
        disp_baja = p_bajo_post_baja - p_bajo_pre_baja,
        disp_alta = p_bajo_post_alta - p_bajo_pre_alta)

# Paso 5: chequeo teórico. Como x1* = alpha1*Y/p1, el shock divide la
# demanda de CADA hogar por 1.2, sin importar su alpha1. Entonces el
# cociente de medias post/pre debe ser 1/1.2 en los dos casos.
c(disp_baja = mean(het_baja$post$x1) / mean(het_baja$pre$x1),
  disp_alta = mean(het_alta$post$x1) / mean(het_alta$pre$x1),
  teorico   = 1 / 1.2)

# ---------------------------------------------------------------------
# Inciso 7 (equivalente al inciso 6): visualización comparada
# ---------------------------------------------------------------------

# Paso 1: histogramas superpuestos de x1* pre y post shock
# (izquierda: dispersión baja; derecha: dispersión alta).
# La línea punteada marca el umbral de bajo consumo (c = 1).
par(mfrow = c(1, 2))
graficar_superpuesto(het_baja$pre$x1, het_baja$post$x1,
                     titulo = "x1*: pre y post shock (disp. baja)",
                     xlab = "x1*", etiquetas = c("Pre shock", "Post shock"))
abline(v = c_umbral, lty = 2)
graficar_superpuesto(het_alta$pre$x1, het_alta$post$x1,
                     titulo = "x1*: pre y post shock (disp. alta)",
                     xlab = "x1*", etiquetas = c("Pre shock", "Post shock"))
abline(v = c_umbral, lty = 2)
par(mfrow = c(1, 1))

# Paso 2: utilidad indirecta promedio pre y post shock
c(U_pre = mean(het_baja$pre$U), U_post = mean(het_baja$post$U),
  variacion_pct = 100 * (mean(het_baja$post$U) / mean(het_baja$pre$U) - 1))
c(U_pre = mean(het_alta$pre$U), U_post = mean(het_alta$post$U),
  variacion_pct = 100 * (mean(het_alta$post$U) / mean(het_alta$pre$U) - 1))

# Paso 3: chequeo teórico. Para CADA hogar, U* post / U* pre es
# exactamente 1.2^(-alpha1) (con su propia alpha1). La diferencia máxima
# entre lo simulado y la fórmula tiene que ser prácticamente cero.
max(abs(het_alta$post$U / het_alta$pre$U - 1.2^(-het_alta$alpha1)))

# Paso 4: variación porcentual teórica de la utilidad media, si todos los
# hogares tuvieran el mismo ingreso (promedio del factor de cada hogar)
100 * (mean(1.2^(-het_alta$alpha1)) - 1)