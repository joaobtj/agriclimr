# Modelagem do Molhamento Foliar a partir de Dados Diários

## Introdução

A Duração do Molhamento Foliar (DMF, ou *Leaf Wetness Duration* - LWD)
representa o período diário em que água livre está presente na
superfície da vegetação. Esta é uma variável agrometeorológica
fundamental para prever o risco de infecções causadas por fungos
fitopatogênicos, como o míldio e o oídio.

Embora os modelos epidemiológicos operem majoritariamente em escala
horária, registros históricos e projeções de mudanças climáticas para o
século XXI costumam disponibilizar apenas dados meteorológicos em
resolução diária. O pacote `agriclimr` implementa uma cadeia
metodológica robusta para contornar essa limitação, permitindo
reconstruir perfis horários de temperatura e umidade relativa a partir
de extremos diários para estimar a DMF diária.

A metodologia aqui descrita é baseada no trabalho de **Zito et
al. (2020)** (*Optimization of a leaf wetness duration model*,
Agricultural and Forest Meteorology).

------------------------------------------------------------------------

## Estrutura de Fluxo do Modelo

O processo de simulação é dividido em três etapas fundamentais
integradas no pacote:

1.  **Reconstrução da Temperatura Horária:** Utilização do modelo
    seno-exponencial de Wann et al. (1985).
2.  **Estimativa da Umidade Relativa Horária:** Dedução com base na
    premissa de pressão de vapor atual constante ao longo do dia.
3.  **Determinação do Molhamento Foliar Horário e Diário:** Aplicação de
    um limiar empírico de umidade relativa (Sentelhas et al., 2008).

------------------------------------------------------------------------

## Fundamentação Matemática

### Etapa 1: Modelo Seno-Exponencial de Temperatura

O ciclo diário de temperatura é reconstruído em duas fases (diurna e
noturna) utilizando as equações baseadas em parâmetros astronômicos
(fotoperíodo, nascer e pôr do sol):

**A. Fase Diurna:** Entre o momento da temperatura mínima ($`t_n`$, logo
após o nascer do sol) e o pôr do sol ($`t_s`$):

``` math
T(t) = T_{min} + (T_{max} - T_{min}) \cdot \sin\left[\frac{\pi \cdot (t - t_n)}{dl - \beta + \alpha}\right]
```

Onde:

- $`T_{min}`$ e $`T_{max}`$: Temperatura mínima e máxima do dia atual.
- $`dl`$: Duração do dia (fotoperíodo em horas), calculada a partir da
  latitude e declinação solar.
- $`\alpha`$: Defasagem entre o meio-dia solar e o horário da
  temperatura máxima (padrão: $`2.75`$ h).
- $`\beta`$: Defasagem entre o nascer do sol e o momento da temperatura
  mínima (padrão: $`1.40`$ h).

**B. Fase Noturna:** Entre o pôr do sol ($`t_s`$) e o nascer do sol do
dia seguinte ($`t_n'`$):

``` math
T(t) = T_{min\_next} + (T_{sunset} - T_{min\_next}) \cdot \exp\left[\frac{-\gamma \cdot (t - t_s)}{24 - dl + \beta}\right]
```

Onde:

- $`T_{min\_next}`$: Temperatura mínima do dia seguinte.
- $`T_{sunset}`$: Temperatura calculada para o momento do pôr do sol
  ($`t_s`$).
- $`\gamma`$: Taxa de resfriamento noturno (padrão: $`2.75`$).

### Etapa 2: Reconstrução da Umidade Relativa Horária

Assume-se que a pressão atual de vapor d’água ($`e_a`$) permanece
constante ao longo das 24 horas ($`e_{ah} = e_{ad}`$). A variação da
Umidade Relativa horária ($`UR_h`$) decorre puramente da oscilação da
pressão de saturação de vapor ($`e^o_{(T)}`$), que é função direta da
temperatura horária calculada na etapa anterior (Equação de Tetens):

``` math
e^o_{(T)} = 0.6108 \cdot \exp\left(\frac{17.27 \cdot T}{T + 237.3}\right)
```

Dessa forma, a conversão é dada por:

``` math
UR_h = 100 \cdot \frac{UR_d \cdot e^o_{(T_d)}}{e^o_{(T_h)}}
```

Onde $`UR_d`$ é a umidade relativa média diária e $`T_d`$ é a
temperatura média diária.

### Etapa 3: Estimativa do Molhamento Foliar

A Duração do Molhamento Foliar horária assume um caráter binário (0 =
seco, 1 = molhado). O molhamento é computado sempre que a $`UR_h`$
atinge ou ultrapassa um limiar crítico estruturado ($`UR_{lim}`$):

``` math
MF_h = \begin{cases} 1, & \text{se } UR_h \ge UR_{lim} \\ 0, & \text{se } UR_h < UR_{lim} \end{cases}
```

O somatório resulta no valor diário total da DMF (0 a 24 horas):

``` math
DMF_{diaria} = \sum_{h=0}^{23} MF_h
```

------------------------------------------------------------------------

## Implementação Prática com o `agriclimr`

O pacote oferece funções modulares e funções de alto nível para
processamento direto de tabelas de dados (`data.frame` ou `tibble`).

### Exemplo Base: Execução Vetorial Única

Para compreender o funcionamento interno, podemos testar as funções
básicas de estimativa horária para um único dia:

``` r


library(agriclimr)

# Definindo as variáveis meteorológicas de um dia hipotético
t_min <- 12.0
t_max <- 25.0
t_min_next <- 13.0
lat <- -27.3
doy <- 150 # Dia do ano (Junho)

# 1. Reconstruir as 24 horas de temperatura
temperaturas_h <- estimate_hourly_temp(
  t_min = t_min,
  t_max = t_max,
  t_min_next = t_min_next,
  lat = lat,
  doy = doy
)
temperaturas_h
#>  [1] 15.48827 14.90347 14.41671 14.01155 13.67432 13.39362 13.15999 12.96552
#>  [9] 12.80365 13.39782 15.10608 16.75904 18.32727 19.78285 21.09987 22.25487
#> [17] 23.22730 23.99984 22.62528 21.01162 19.66849 18.55053 17.61999 16.84546

# 2. Reconstruir a Umidade Relativa horária (com média diária de UR = 80%)
ur_h <- estimate_hourly_rh(
  rh_daily = 80,
  t_daily = (t_min + t_max) / 2,
  t_hourly = temperaturas_h
)
ur_h
#>  [1]  96.82462 100.00000 100.00000 100.00000 100.00000 100.00000 100.00000
#>  [8] 100.00000 100.00000 100.00000  99.23086  89.28305  80.87074  73.85334
#> [15]  68.09016  63.45034  59.81901  57.10071  62.03861  68.46008  74.37916
#> [22]  79.74727  84.54910  88.79467

# 3. Determinar o vetor binário de molhamento foliar (Limiar de 85%)
molhamento_h <- estimate_lwd_rh(ur_h, threshold = 85)
molhamento_h
#>  [1] 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 1

# Soma do molhamento foliar diário
sum(molhamento_h)
#> [1] 13
```

### Processamento de Séries Temporais Diárias

Na rotina operacional, você utilizará a função principal
[`daily_to_hourly_lwd()`](https://joaobtj.github.io/agriclimr/reference/daily_to_hourly_lwd.md),
que realiza toda a esteira de desagregação interna e retorna um conjunto
estruturado.

``` r


library(agriclimr)

# Criando uma série de dados diários de exemplo (5 dias contínuos)
dados_diarios <- tibble::tibble(
  data    = as.Date("2026-06-01") + 0:4,
  lat     = rep(-27.3, 5),
  tmin    = c(12.0, 13.5, 11.0, 10.5, 14.0),
  tmax    = c(22.0, 24.5, 21.0, 19.5, 23.0),
  ur_media = c(80, 75, 85, 90, 70)
)

# Aplicando a função automatizada do pacote
resultado_horario <- daily_to_hourly_lwd(
  data = dados_diarios,
  date_col = data,
  t_min_col = tmin,
  t_max_col = tmax,
  rh_daily_col = ur_media,
  lat_col = lat,
  rh_threshold = 85 
)

# Visualizando os primeiros registros estruturados
head(resultado_horario, 12)
#> # A tibble: 12 × 5
#>    datetime            temperature_hourly rh_hourly leaf_wetness_hourly
#>    <dttm>                           <dbl>     <dbl>               <dbl>
#>  1 2026-06-01 00:00:00               14.7      92.8                   1
#>  2 2026-06-01 01:00:00               14.2      95.5                   1
#>  3 2026-06-01 02:00:00               13.9      97.9                   1
#>  4 2026-06-01 03:00:00               13.5      99.9                   1
#>  5 2026-06-01 04:00:00               13.3     100                     1
#>  6 2026-06-01 05:00:00               13.1     100                     1
#>  7 2026-06-01 06:00:00               12.9     100                     1
#>  8 2026-06-01 07:00:00               12.7     100                     1
#>  9 2026-06-01 08:00:00               12.6     100                     1
#> 10 2026-06-01 09:00:00               13.1     100                     1
#> 11 2026-06-01 10:00:00               14.4      94.6                   1
#> 12 2026-06-01 11:00:00               15.7      87.2                   1
#> # ℹ 1 more variable: lwd_daily_sum <dbl>
```

## Referências Bibliográficas

- **Zito, S., Castel, T., Richard, Y., Rega, M., & Bois, B. (2020).**
  Optimization of a leaf wetness duration model. *Agricultural and
  Forest Meteorology*, 291, 108087.
- **Wann, M., Yen, D., & Gold, H. J. (1985).** Evaluation and
  calibration of three models for daily cycle of air temperature.
  *Agricultural and Forest Meteorology*, 34(2), 121-128.
- **Sentelhas, P. C., Dalla Marta, A., Orlandini, S., Santos, E. A.,
  Gillespie, T. J., & Gleason, M. L. (2008).** Suitability of relative
  humidity as an estimator of leaf wetness duration. *Agricultural and
  Forest Meteorology*, 148(3), 392-400.
