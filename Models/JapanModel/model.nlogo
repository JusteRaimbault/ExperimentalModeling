
__includes [
 
  "setup.nls"
  "main.nls" 
 
  "city.nls"
  
  "indicators.nls"
  "plot.nls"
  "display.nls"
  
  ;;;;
  ;; utils
  ;;;;
  
  "gis.nls"
  
  "utils.nls"
  
  "lib/synth-cities.nls"
  
  
]



globals [
  
  ;;
  ; setup
  ;;
  
  initial-year
  present-year
  prospective-year
  
  calibration-years
  
  ;; setup files
  gis-world-file
  gis-cities-file
  
  ; associated gis datasets
  gis-world
  gis-cities
  
  ;;
  ; cities related variables
  
  ; list of city populations - may be useful for rank-size plot e.g.
  populations
  
  ; 
  population-to-wealth-exponent
  initial-city-max-pop
  
  headless?
  realized-populations
  yearly-expected-populations
]


patches-own [
  distance-weighted-total-pop 
]



;; an agent is a city
breed [cities city]




cities-own [
  
  ; population : P(t)
  population
  delta-population
  
  ;; economic variables : E_2 and E_3 (t)
  economic-secondary
  
  economic-tertiary
  delta-economic-tertiary
  
  
  ; list of objective populations (included initial)
  expected-populations
  
  
  ;; migration flows
  ;;  as list of [to_who,flow]
  population-flows
  
]
@#$#@#$#@
GRAPHICS-WINDOW
304
10
917
563
100
-1
3.0
1
10
1
1
1
0
0
0
1
-100
100
-87
86
0
0
1
ticks
30.0

CHOOSER
6
10
98
55
setup-type
setup-type
"random" "real"
1

BUTTON
19
396
74
429
setup
set headless? false\nsetup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
143
397
206
430
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
5
84
97
117
#-cities
#-cities
0
100
80
1
1
NIL
HORIZONTAL

SLIDER
97
84
217
117
city-max-pop
city-max-pop
0
1000
514
1
1
NIL
HORIZONTAL

SLIDER
5
116
157
149
rank-size-exponent
rank-size-exponent
0
3
1.5
0.05
1
NIL
HORIZONTAL

TEXTBOX
10
68
160
86
Random setup
11
0.0
1

TEXTBOX
8
175
158
193
Runtime
11
0.0
1

SLIDER
8
224
153
257
sigma-gibrat-pop
sigma-gibrat-pop
0
0.1
0.06
0.01
1
NIL
HORIZONTAL

PLOT
953
27
1357
284
rank-size-plot
NIL
NIL
0.0
4.0
5.0
6.0
true
false
"" "update-rank-size-plot"
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
953
292
1153
442
population
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot total-population"
"pen-1" 1.0 0 -2674135 true "" "plot current-total-expected-population"

SLIDER
8
192
153
225
mean-gibrat-pop
mean-gibrat-pop
0.98
1.05
1.019
0.001
1
NIL
HORIZONTAL

PLOT
1157
292
1411
442
Economic
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"secondary" 1.0 0 -12186836 true "" "plot total-economic-secondary"
"tertiary" 1.0 0 -14333415 true "" "plot total-economic-tertiary"

BUTTON
78
396
141
429
go
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
188
498
267
543
population
total-population
17
1
11

SWITCH
6
313
145
346
with-economic?
with-economic?
1
1
-1000

SLIDER
156
192
300
225
tertiary-growth
tertiary-growth
0
0.01
0.0060
0.001
1
NIL
HORIZONTAL

PLOT
930
449
1236
644
data-fit
simulated pops
real pops
0.0
10.0
0.0
10.0
true
false
"" "update-data-fit-plot"
PENS
"default" 1.0 0 -16777216 true "" ""

SWITCH
5
348
145
381
with-migrations?
with-migrations?
1
1
-1000

SLIDER
8
258
153
291
migration-rate
migration-rate
0
1.0E-7
6.0E-8
1.0E-8
1
NIL
HORIZONTAL

MONITOR
189
546
265
591
∆E3
max [delta-economic-tertiary] of cities
17
1
11

SLIDER
156
227
300
260
city-min-pop
city-min-pop
0
20000
10000
100
1
NIL
HORIZONTAL

MONITOR
1243
453
1411
498
total fit
data-fit
17
1
11

@#$#@#$#@
# PRESENTATION

Modèle basé-agent du système de villes japonais, de 1950 à 1990, construit dans le cadre d'un exercice de modélisation participative (Université Paris Diderot, cours 54AE01GO, groupe 3).

Le but est de simuler la croissance urbaine du Japon de 1950 à 1990, avec une attention particluière à la structure économique pour tenter de reproduire le fait stylisé de l'impact de la transition secondaire-tertiaire sur la structure du système de ville décrit dans [Fujita & Tabuchi, 1997]. [choc externe de la transition pas encore implémenté]

# FONCTIONNEMENT DU MODELE

## Agents et interactions

Les agents du système sont les villes (~30 plus grandes villes japonaises sur cette période), qualifiée par leur population P(t) et leur économie, décrite par deux variables E2(t) (resp. E3(t)) équivalentes respectivement à la valeur du secondaire (resp. du tertaire) produit dans la ville. On dispose des populations réelles sur cette période, qu'on cherche à reproduire (données issues de [Eaton & Eckstein, 1997]).

L'évolution entre deux pas de temps (un an) est régie par les règles d'évolution et d'interaction suivantes :
  - croissance endogène : suivant un modèle de Gibrat, chaque ville croit de manière intrinsèque (intégrant solde de naissances et migrations depuis l'extérieur du pays), selon un taux de croissance aléatoire dont la moyenne et la variabilité sont fixés.
  - migration (désactivable) : les villes échangent des populations selon la dynamique de leur économie tertiaire, c'est à dire que les gens sont plus attirés par une ville en forte croissance sur le plan tertiaire.
  - croissance économique (désactivable) : l'économie secondaire dépend de la population (= les usines utilisent la main-d'oeuvre présente) ; l'économie tertiaire croit selon la dynamique de la population (donc croissance population -> croissance tertiaire) ET selon une croissance propre : phénomène d'attachement préférentiel.

##  Paramètres

### Paramètres d'initialisation

  - `setup-type` : `random` pour aléatoire, `real` pour la configuration réelle 
  - dans le cas d'une initialisation aléatoire : `#-cities` nombre de villes, `city-max-pop` population de la plus grande ville, `rank-size-exponent` degré de hierarchie entre la taille des villes


### Paramètres d'évolution

  - `mean-gibrat-pop` : moyenne du taux de croissance endogène. 
  - `sigma-gibrat-pop` : variabilité (écart-type) du taux de croissance endogène
  - `migration-rate` : importance des migrations
  - `tertiary-growth` : taux de croissance propre de l'économie tertiaire
  - `city-min-pop` : population minimale
  - `with-economic?` : interactions économie-population prises en compte
  - `with-migration?` : migrations prises en compte

##  Graphes

  - `rank-size-plot` : hiérarchie du système au cours du temps
  - `population` : population totale réalisée (noir) et attendue (rouge)
  - `economic` : économie totale
  - `data-fit` : proximité aux données, plus la courbe est proche de la diagonale, meilleur est le modèle


# EXPLORATION

 -> Objectif : être proche des données réelles, i.e. courbe noire = courbe rouge dans le graphe `population`, ou être proche de la diagonale pour l'ensemble des courbes dans `data-fit`, ou avoir la valeur finale de `total fit` la plus faible possible (! notation scientifique).

 -> étudier l'influence de chaque paramètre les autres restant fixé.

 -> en particulier, rechercher si l'ajout de l'économie et des migrations semble changer la performance du modèle (sur plusieurs run en moyenne, le modèle étant aléatoire).

 -> dans un premier temps, chercher à approcher les données réelles par une variation manuelle des paramètres.

 -> réfléchir aux hypothèses sur les interactions qui sont questionables, réfléchir à d'autres hypothèses ou d'autres méchanismes.

# EXTENSIONS POSSIBLES

  - Calibration, exploration et validations automatiques en cours;

  - ajout de modules et test d'hypothèses (ex. accessibilité, autres relations population <-> économie, ...)



# MODELES SIMILAIRES

 - series des Modèles Simpop [Pumain, 2012]
 - Modèle Marius [Cottineau, 2014]

# CREDITS AND REFERENCES

## LICENCE

Code © J. Raimbault, sous licence libre creative commons CC-BY-NC 4.0

## REFERENCES

 -  [Fujita & Tabuchi, 1997] : Fujita, M., & Tabuchi, T. (1997). Regional growth in postwar Japan. Regional Science and Urban Economics, 27(6), 643-670.

 - [Eaton & Eckstein, 1997] : Eaton, J., & Eckstein, Z. (1997). Cities and growth: Theory and evidence from France and Japan. Regional science and urban Economics, 27(4), 443-474.


 - [Pumain, 2012] : Pumain, D. (2012). Multi-agent system modelling for urban systems: The series of SIMPOP models. In Agent-based models of geographical systems (pp. 721-738). Springer Netherlands.

 - [Cottineau, 2014] : Cottineau, C. (2014). L'évolution des villes dans l'espace post-soviétique. Observation et modélisations (Doctoral dissertation, Université Paris 1 Panthéon-Sorbonne).
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
