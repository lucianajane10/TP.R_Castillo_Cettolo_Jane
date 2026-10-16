# ---------------------------------------------------------------------
# Inciso 1: generación de ingresos
# ---------------------------------------------------------------------
# Y ~ chi-cuadrado con k grados de libertad.
# Propiedades (para documentar cómo elegir k):
#   E[Y] = k ;  Var(Y) = 2k ;  coef. de variación = sd/media = sqrt(2/k)
# => a mayor k sube el ingreso medio y sube la dispersión en términos
#    absolutos (sd = sqrt(2k)), pero BAJA la dispersión relativa y la
#    distribución se vuelve más simétrica.
simular_ingreso <- function(n, k) {
  # chequeos de robustez (stop() genera un error informativo)
  if (n < 1) stop("n debe ser al menos 1")
  if (k <= 0) stop("k (grados de libertad) debe ser positivo")
  Y <- rchisq(n, df = k)
  return(Y)
}

# ---------------------------------------------------------------------
# Inciso 2: demanda óptima Cobb-Douglas
# ---------------------------------------------------------------------
# Recibe Y, p1, p2, alpha1, alpha2 (pueden ser escalares o vectores del
# mismo largo que Y, por eso sirve para el caso homogéneo y para el
# heterogéneo) y devuelve una lista con x1*, x2* y U*.
demanda_cd <- function(Y, p1, p2, alpha1, alpha2) {
  # chequeos: precios e ingreso positivos, alphas en (0,1) y suma 1
  if (any(Y <= 0)) stop("El ingreso Y debe ser positivo")
  if (any(p1 <= 0) || any(p2 <= 0)) stop("Los precios deben ser positivos")
  if (any(alpha1 <= 0) || any(alpha1 >= 1)) stop("alpha1 debe estar en (0,1)")
  if (any(abs(alpha1 + alpha2 - 1) > 1e-8)) stop("alpha1 + alpha2 debe ser 1")
  
  x1 <- alpha1 * Y / p1                 # demanda óptima del bien 1
  x2 <- alpha2 * Y / p2                 # demanda óptima del bien 2
  U  <- x1^alpha1 * x2^alpha2           # utilidad indirecta U*
  
  return(list(x1 = x1, x2 = x2, U = U))
}

# ---------------------------------------------------------------------
# Auxiliar: media y cuartiles de un vector (incisos 3, 5 y 7)
# ---------------------------------------------------------------------
# quantile() con probs = c(0.25, 0.5, 0.75) devuelve Q1, mediana y Q3.
resumir <- function(x) {
  q <- quantile(x, probs = c(0.25, 0.5, 0.75))
  return(c(Media = mean(x), Q1 = q[[1]], Mediana = q[[2]], Q3 = q[[3]]))
}
# ---------------------------------------------------------------------
# Inciso 4: probabilidad de bajo consumo en un bien
# ---------------------------------------------------------------------
# sim: lista devuelta por demanda_cd; c: umbral (> 0); j: bien (1 o 2).
# Estima P(x_j* < c) como la proporción de hogares simulados por debajo
# de c (Monte Carlo).
prob_bajo_consumo <- function(sim, c, j) {
  if (c <= 0) stop("El umbral c debe ser positivo")
  if (j == 1) {
    x <- sim$x1
  } else if (j == 2) {
    x <- sim$x2
  } else {
    stop("j debe ser 1 o 2")
  }
  return(mean(x < c))
}

# ---------------------------------------------------------------------
# Auxiliar: dos histogramas superpuestos (incisos 6 y 7)
# ---------------------------------------------------------------------
# Se usan los MISMOS cortes (breaks) en ambos para que sean comparables.
# El segundo se agrega con add = TRUE y colores con transparencia rgb().
graficar_superpuesto <- function(x_pre, x_post, titulo, xlab, etiquetas) {
  maximo <- max(c(x_pre, x_post))
  cortes <- seq(0, maximo, length.out = 40)
  
  # alto máximo de ambos histogramas, para que el eje y alcance a los dos
  # (hist con plot = FALSE solo calcula, no dibuja)
  alto <- max(hist(x_pre,  breaks = cortes, plot = FALSE)$density,
              hist(x_post, breaks = cortes, plot = FALSE)$density)
  
  hist(x_pre, breaks = cortes, freq = FALSE, ylim = c(0, 1.05 * alto),
       col = rgb(0, 0.5, 1, 0.5), main = titulo, xlab = xlab)
  hist(x_post, breaks = cortes, freq = FALSE,
       col = rgb(1, 0.5, 0, 0.5), add = TRUE)
  legend("topright", legend = etiquetas,
         fill = c(rgb(0, 0.5, 1, 0.5), rgb(1, 0.5, 0, 0.5)))
}
# ---------------------------------------------------------------------
# Inciso 7: simulación con heterogeneidad en preferencias
# ---------------------------------------------------------------------
# Para cada hogar, alpha1 ~ Beta(a, b) y alpha2 = 1 - alpha1.
# Devuelve las demandas antes (pre) y después (post) del shock de
# precios, usando los MISMOS ingresos Y, y las alphas sorteadas.
correr_heterogeneo <- function(Y, p1, p1_nuevo, p2, a, b) {
  alpha1_h <- rbeta(length(Y), a, b)    # una alpha1 por hogar
  alpha2_h <- 1 - alpha1_h
  pre_h  <- demanda_cd(Y, p1,       p2, alpha1_h, alpha2_h)
  post_h <- demanda_cd(Y, p1_nuevo, p2, alpha1_h, alpha2_h)
  return(list(pre = pre_h, post = post_h, alpha1 = alpha1_h))
}