patches-own [
  chemical             ;; amount of chemical on this patch
  food                 ;; amount of food on this patch (0, 1, or 2)
  nest?                ;; true on nest patches, false elsewhere
  nest-scent           ;; number that is higher closer to the nest
  food?
  food-source-number   ;; number (1, 2, or 3) to identify the food sources
  pstate
  pval
]

breed [youths youth]
breed [elders elder]

turtles-own [
  state
  bridge-timer
]

globals [
  bridge45 ;(patch-set patch -5 -5 patch 0 0 patch 5 5)
  foodDelivered
  prev-foodDelivered
  food-rate
  nearest-patch
  ant-density
]

to setup
  clear-all
  set-default-shape turtles "bug"
  ;create-turtles 200 ;; population
  ;[ set size 2         ;; easier to see
  ;  set color red    ;; red = not carrying food
  ;  set state 1]
  ;ask turtles
  ;[ setxy -27 -32                           ;; start the ants out at the nest
  ;  set heading 0
  ;  set size 2
  ;  set state 1 ]
  spawn-ant (number-of-ants - number-of-elders)
  spawn-elder number-of-elders
  set foodDelivered 0
  set prev-foodDelivered 0
  set ant-density 0
  setup-patches


  ask patches [
    set pval max-pycor - pycor
  ]
  reset-ticks
end

to setup-patches
  ask patch -27 (-1 * GapSize / 2) [
    sprout 1 [
      ;set heading 60
      repeat GapSize / 2 [
        ask patch-here [
          ;set pcolor blue
          ask (patch-set self neighbors) [
            ask (patch-set self neighbors) [ set pcolor blue ]
          ]
        ]
        ;set chemical-to-food 50
        setxy xcor + BridgeOffset ycor + 1
      ]
      die
    ]
    sprout 1 [
      repeat 29 [
        ask patch-here [
          ;set pcolor blue
          ask (patch-set self neighbors) [
            ask (patch-set self neighbors) [ set pcolor blue ]
          ]
        ]
        setxy xcor ycor - 1
      ]
      die
    ]
  ]
  ask patch -27 (GapSize / 2) [
    sprout 1 [
      ;set heading 60
      repeat GapSize / 2 [
        ask patch-here [
          ;set pcolor blue
          ask (patch-set self neighbors) [
            ask (patch-set self neighbors) [ set pcolor blue ]
          ]
        ]
        ;set chemical-to-food 50
        setxy xcor + BridgeOffset ycor - 1
      ]
      die
    ]
    sprout 1 [
      repeat 29 [
        ask patch-here [
          ;set pcolor blue
          ask (patch-set self neighbors) [
            ask (patch-set self neighbors) [ set pcolor blue ]
          ]
        ]
        setxy xcor ycor + 1
      ]
      die
    ]
  ]
  ;ask patches [
  ;  if (pycor = GapSize / 2 or pycor = (-1 * GapSize / 2)) and (pxcor > -30 and pxcor < -26)
  ;  [ set pcolor green ]
  ;]
end

to spawn-ant [number]
  create-youths number ;; population
  [ set size 2         ;; easier to see
    set color red    ;; red = not carrying food
    set state 1
    setxy -27 -32
    set heading 0]
end

to spawn-elder [number]
  create-elders number
  [ set size 2
    set color orange
    set state 1
    setxy -27 -32
    set heading 0]
end

;;;;;;;;;;;;;;;;;;;;;
;;; Go procedures ;;;
;;;;;;;;;;;;;;;;;;;;;

to go ;; forever button
  if ticks > 5
  [ ask one-of turtles with [state != 0 and ycor > -30 ]
    [ set ant-density count turtles with [state != 0] in-radius 1 ]]
  ;[ set ant-density count turtles-here ]
  ask turtles
  [ if who >= ticks [ stop ] ;; delay initial departure
    if should-fall? [ die ]
    ifelse state = 0
    [ if should-break?
      [ break-bridge ]
      ifelse bridge-timer > bridge-cooldown and should-leave-bridge?
      [ leave-bridge ]
      [ set bridge-timer bridge-timer + 1 ] ]
    [ if is-youth? self and should-join-bridge?
      [ join-bridge ]
      if state = 1
      [ stage-one ]
      if state = 2
      [ stage-two ]
      if state = 3
      [ stage-three ]
      if state != 0 [
        if wiggle? [ wiggle ]
        if [pcolor] of patch-ahead 1 = black
        [ ifelse ycor > 0
          [ if heading < 180 [ lt 90 ] ]
          [ rt 90]]
        if [pcolor] of patch-ahead 1 != black
        [ fd 0.5 ]
    ]]
    if ycor > 30
    [ die ]
  ]
  if count elders < number-of-elders ;and count turtles-on (patch-set patch -27 -32 patch -27 -32 neighbors) < 1
  [ spawn-elder 1 ]
  if count youths < (number-of-ants - number-of-elders)
  [ spawn-ant 1 ]
  set food-rate (foodDelivered - prev-foodDelivered)
  set prev-foodDelivered foodDelivered
  tick
end

;;; ANT STAGES and MOVEMENT ;;;

to stage-one
  ifelse ycor > (-1 * GapSize / 2 - 2) and ycor < (GapSize / 2)
  [ set state 2 ]
    ;set color orange ]
  [ set heading 0 ]
end

to stage-two
  ifelse ycor >= 0 and not ([pcolor] of patch-at 0 0 = gray)
  [ set state 3 ]
    ;set color yellow ]
  [ ifelse [pcolor] of patch-at 0 3 = black
    [ facexy (-27 + (GapSize / 2 * BridgeOffset)) 0 ]
    [ set heading 0 ] ]
end

to stage-three
  ifelse ycor > GapSize / 2 + 1
  [ set state 1
    ;set color red
    set foodDelivered foodDelivered + 1]
  [ facexy -27 (1 + GapSize / 2) ]
end

to wiggle ;;
  rt random 30
  lt random 30
  if not can-move? 1 [ rt 180 ]
end

;;; ANT BRIDGING ;;;

to join-bridge ;[ ax ay ]
  set nearest-patch min-one-of patches with [pcolor = black] [distance myself]
  if distance nearest-patch < 1 [
    move-to nearest-patch
    set state 0
    set color gray
    set bridge-timer 0
    ask patch-here
    [ set pcolor gray]]
end

to leave-bridge
  let new-patch one-of (patch-set patch-at -1 1 patch-at 0 1 patch-at 1 1) with [pcolor != black]
  if new-patch != nobody
  [ ask patch-here [ set pcolor black ]
    move-to new-patch
    update-state ]
end

to break-bridge
  ask patch-here [ set pcolor black ]
  die
end

to update-state
  if ycor > (-1 * GapSize / 2 - 2) and ycor <= 0
  [ set state 2
    set color red ]

  if ycor > 0 and ycor < GapSize
  [ set state 3
    set color red ]

  if ycor > GapSize / 2
  [ set state 1
    set color red ]
end

;;; REPORTERS ;;;

to-report should-join-bridge?
  report ycor > (-1 * GapSize / 2) and count-neighbor-agents > ant-cost
end

to-report should-leave-bridge?
  report no-bridge-behind? and count-neighbor-agents < ant-cost-free and count-side-bridges = 1 and count-forward-neighbors > 0
end

to-report count-neighbor-agents
  report count turtles with [color != gray] in-radius ant-radius
end

to-report count-forward-neighbors
  report count (patch-set patch-at -1 1 patch-at 0 1 patch-at 1 1) with [pcolor != black]
end

to-report count-side-bridges
  report count (patch-set patch-at 1 0 patch-at -1 0) with [pcolor = gray]
end

to-report count-solid-neighbors
  report count patches with [pcolor != black] in-radius 1
end

to-report count-bridge-neighbors
  report count patches with [pcolor = gray] in-radius 1
end

to-report no-bridge-behind?
  report [pcolor = black] of patch-at 0 -1 or [pcolor = blue] of patch-at 0 -1
end

to-report gray-to-left?
  report [pcolor = gray] of patch-at -1 0
end

to-report gray-to-right?
  report [pcolor = gray] of patch-at 1 0
end

to-report should-fall?
  ifelse [pcolor = black] of patch-here
  [ report 0 = 0 ]
  [ let c count (patch-set patch-here neighbors) with [pcolor != black]
    report c = 0 ]
end

to-report should-break?
  report [pcolor = black] of patch-at 0 -1 and [pcolor = black] of patch-at 1 0 and [pcolor = black] of patch-at -1 0
end

;;; NOT USED ;;;

to update-bridge
  set nearest-patch min-one-of patches with [pcolor != black] [distance myself]
  ask patch-here [ set pcolor black ]
  move-to nearest-patch
  update-state
end

to searchForFood ;;
  ifelse food?
  [ set color orange
    rt 180
    stop ]
  [ set chemical chemical + 60
    uphill-chemical ]
end

;; sniff left and right, and go where the strongest smell is
to uphill-chemical  ;; turtle procedure
  let scent-ahead chemical-scent-at-angle   0
  let scent-right chemical-scent-at-angle  45
  let scent-left  chemical-scent-at-angle -45
  if (scent-right > scent-ahead) or (scent-left > scent-ahead)
  [ ifelse scent-right > scent-left
    [ rt 45 ]
    [ lt 45 ] ]
end

to-report chemical-scent-at-angle [angle]
  let p patch-right-and-ahead angle 1
  if p = nobody [ report 0 ]
  report [chemical] of p
end


;;
@#$#@#$#@
GRAPHICS-WINDOW
210
10
623
424
-1
-1
5.0
1
10
1
1
1
0
0
1
1
-40
40
-40
40
0
0
1
ticks
30.0

BUTTON
115
142
181
175
NIL
setup
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
44
185
107
218
NIL
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

BUTTON
116
184
179
217
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

CHOOSER
40
23
178
68
BridgeOffset
BridgeOffset
0 1 2 3 4 5 6
2

CHOOSER
40
86
178
131
GapSize
GapSize
5 10 15 20 25 30 35
4

SLIDER
1150
295
1322
328
diffusion-rate
diffusion-rate
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
1150
336
1322
369
evaporation-rate
evaporation-rate
0
100
10.0
1
1
NIL
HORIZONTAL

PLOT
1127
33
1327
183
Food vs. Time
tick
food
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot foodDelivered"

MONITOR
636
379
693
424
ticks
ticks
17
1
11

INPUTBOX
37
232
186
292
bridge-cooldown
20.0
1
0
Number

SLIDER
27
303
199
336
ant-radius
ant-radius
0
4
2.0
1
1
NIL
HORIZONTAL

SLIDER
26
350
198
383
ant-cost
ant-cost
0
20
13.0
1
1
NIL
HORIZONTAL

MONITOR
1154
210
1213
255
Orange
count elders
17
1
11

SLIDER
24
440
196
473
number-of-ants
number-of-ants
0
500
300.0
10
1
NIL
HORIZONTAL

SLIDER
24
486
196
519
number-of-elders
number-of-elders
0
200
0.0
5
1
NIL
HORIZONTAL

PLOT
1130
374
1330
524
Red and Orange over Time
ticks
ants
0.0
10.0
50.0
100.0
true
true
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count youths"
"pen-1" 1.0 0 -7500403 true "" "plot count elders"

SWITCH
259
448
362
481
wiggle?
wiggle?
0
1
-1000

SLIDER
26
393
198
426
ant-cost-free
ant-cost-free
0
20
1.0
1
1
NIL
HORIZONTAL

MONITOR
1239
211
1296
256
Red
count youths
17
1
11

MONITOR
635
177
712
222
Ants Total
count turtles
17
1
11

MONITOR
721
177
806
222
Bridge Ants
count turtles with [state = 0]
17
1
11

PLOT
635
10
835
160
Rate of Food Collection
ticks
food rate
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot food-rate"

MONITOR
844
10
918
55
Food Rate
food-rate
17
1
11

MONITOR
635
230
800
275
Percent of Ants in Bridge
((count turtles with [state = 0]) / (count youths)) * 100
1
1
11

MONITOR
635
288
721
333
ants per cm
ant-density
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

long_rectangle
true
0
Rectangle -13345367 true false 120 0 180 300

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

rectangle
true
0
Rectangle -7500403 true true 90 30 210 270

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
NetLogo 6.3.0
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
