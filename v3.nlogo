extensions [
 csv
]

globals [
  day
  day-index
  day-list
  hours
  minutes
  seconds
  station-list
  color-list
  mileage-list
  time-list-weekday-peak
  time-list-weekday
  time-list-saturday
  time-list-sunday
  what
]

trains-own [
  idle?
  in-depot?
  in-yard?
  in-service?
  out-of-service?
  doors-open?
  at-station?
  amount-of-passengers
  miles-travelled
  next-station
  direction
  time-at-station
  last-stopped-at
  time-to-wait
  at-oak-grove?
  at-forest-hills?
]

passengers-own [
  waiting?
  on-train?
  at-destination?
  starting-station
  destination
  waiting-time
  travelling-time
  total-time
]

patches-own [
  station?
  station-id
]

breed [trains train] ;; trains
breed [passengers passenger] ;; passengers

to setup
  clear-all
  reset-ticks
  obtain-csv
  setup-clock
  setup-world
  setup-station
  setup-depots
  setup-trains
end

to go
  tick
  tick-clock ;; increments simulation clock
  train-check ;; monitors train states
end

to obtain-csv ;; gets the csv list of stations and reports them as netlogo lists
  file-open "stationlist.csv"
  set station-list csv:from-row file-read-line
  set color-list csv:from-row file-read-line
  set mileage-list csv:from-row file-read-line
  set time-list-weekday-peak csv:from-row file-read-line
  set time-list-weekday csv:from-row file-read-line
  set time-list-saturday csv:from-row file-read-line
  set time-list-sunday csv:from-row file-read-line
  file-close
end

to setup-clock ;; sets up variables relating to the time mechanic
  set hours 5
  set minutes 0
  set seconds 0
  set day-index 0
  set day-list ["Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday"]
end

to setup-world ;; sets up the world, patch data for stations and track
  ask patches [
    set pcolor white ;; set background white
    if (pycor = -1) or (pycor = 1) and (pxcor > -20) and (pxcor < 20) [
      set pcolor orange + 2 ;; makes two Orange lines at x = 1 and x = -1, to represent the tracks the Orange Line will travel on
    ]
    let x -19
    let id length station-list + 1 - length station-list
    repeat 20 [ ;; sets station ids
      if (pxcor = x) and (pycor = 0) [ ;; goes through every other x coordinate and sets the station ids
        set station-id id
        set station? true
      ]
      set x x + 2
      set id id + 1
    ]
    set plabel-color black ;; for clarity, labels are in black
  ]
end

to setup-station ;; sets up stations, using station ids of patches
  ask patches [
    let id 1
    repeat length station-list [ ;; repeat for length of station list
      if (station-id = id) [
         set plabel item (id - 1) station-list ;; sets the plabel to the station's name
         set pcolor item (id - 1) color-list ;; sets the pcolor to the station's predetermined color
      ]
      set id id + 1
    ]
  ]
end

to setup-depots ;; sets up depot and line to get to depot
  ask patches [
    if (pxcor = -15) and (pycor = 2)  [
      set pcolor orange + 2
    ]
    if (pxcor = -15) and (pycor = 3)  [
      set pcolor blue + 2
      set plabel "Wellington Carhouse"
    ]
    if (pxcor = 20) and (pycor = 0)  [
      set pcolor blue - 2
      set plabel-color white ;; just for this guy
      set plabel "Yard" ;; Forest Hills Yard
    ]
  ]
end

to tick-clock ;; increments the clock by one second and increments hours and minutes accordingly
  set seconds seconds + 1
  if (seconds > 59) [
    set seconds 0
    set minutes minutes + 1
  ]
  if (minutes > 59) [
    set minutes 0
    set hours hours + 1
  ]
  if (hours > 23) [
    set hours 0
    set day-index day-index + 1
    if (day-index > 6) [
      set day-index 0
    ]
  ]
  set day item day-index day-list
end

to setup-trains
  create-trains 25 ;; initializations
  [
    set shape "orange line train"
    setxy -14 3
    set label-color black
    set label (word "Train " who)
    set miles-travelled random maintenance-cycle + 1
    set idle? false
    set in-depot? false
    set in-yard? true
    set in-service? false
    set at-station? false
    set doors-open? false
    set out-of-service? false
    set last-stopped-at 0
    set direction 0 ;; 0 is directionless, 1 is right, 2 is left, 3 is up, 4 is down
  ]
  repeat 4 [
    ask train random 25 [
      setxy 20 0
    ]
  ]
  ask train 24 [ ;; tests all train actions with one train
    setxy -19 -1
    set in-service? false
    set out-of-service? false
    set at-station? true
    set direction 1
  ]
end

to train-check ;; directs proper actions via train states
  ask train 24 [
    if (in-service? = true) [
      train-movement
    ]
    if (out-of-service? = true) [
      train-movement
    ]
    if (at-station? = true) [
      station
    ]
  ]
end

to train-movement ;; responsible for movement of trains
  ask train 24 [
    if (out-of-service? = false) [ ;; only checks for stations if going to stop at them
      let id next-station
      if (xcor > (first [pxcor] of patches with [station-id = id]) - 0.1) and (xcor < (first [pxcor] of patches with [station-id = id]) + 0.1)  [
        station-check
      ]
    ]
    change-direction
    facing
    forward-amount
    set what what + 1
    show what
  ]
end

to station-check ;; checks if there is a directly station below or above the train
  if (direction = 1) [
    if ([station?] of patch-at 0 1 = true) [
      if ([station-id] of patch-at 0 1 != last-stopped-at) [ ;; makes sure train isn't stopping at same station
        set in-service? false
        set at-station? true
      ]
    ]
  ]
  if (direction = 2) [
    if ([station?] of patch-at 0 -1 = true) [
      if ([station-id] of patch-at 0 -1 != last-stopped-at) [ ;; makes sure train isn't stopping at same station
        set in-service? false
        set at-station? true
      ]
    ]
  ]
end

to forward-amount ;; dictates how far the train moves every second
  if (next-station = 0) [
    upcoming-station
  ]
  let miles 0
  let time 0
  if (hours >= 6) and (hours < 9) and ((day-index <= 0) and (day-index >= 4))  [ ;; peak hour times

  ]
  if (day-index >= 0) and (day-index <= 4) [
    set miles item (next-station - 2) mileage-list
    set time item (next-station - 2) time-list-weekday
  ]
  if (day-index = 5) [

  ]
  if (day-index = 6) [

  ]
  let speed (miles / time)
  fd speed
end

to change-direction ;; changes direction variable at certain points in the line
  ask patch-at 0 1 [ ;; going up before Forest Hills
    if (station-id = 20) [
      ask train 24 [
        set direction 3
      ]
    ]
  ]
  ask patch-at 0 -1 [ ;; going left after Forest Hills
    if (station-id = 20) [
      ask train 24 [
        set direction 2
      ]
    ]
  ]
  ask patch-at 0 -1 [ ;; going down before Oak Grove
    if (station-id = 1) [
      ask train 24 [
        set direction 4
      ]
    ]
  ]
  ask patch-at 0 1 [ ;; going right after Oak Grove
    if (station-id = 1) [
      ask train 24 [
        set direction 1
      ]
    ]
  ]
end

to facing ;; points train in certain direction using facexy command
  if (direction = 1) [
    facexy 20 -1
  ]
  if (direction = 2) [
    facexy -20 1
  ]
  if (direction = 3) [
    facexy 19 3
  ]
  if (direction = 4) [
    facexy -19 -3
  ]
end

to station ;; station process
  how-long-to-wait
  passenger-on-off
  ifelse (station-finish = false) [
    set time-at-station time-at-station + 1
    setxy xcor ycor
  ]
  [
    upcoming-station
    if (direction = 1) [
      set last-stopped-at [station-id] of patch-at 0 1
    ]
    if (direction = 2) [
      set last-stopped-at [station-id] of patch-at 0 -1
    ]
    set at-station? false ;; set station flag to false
    set in-service? true ;; set normal operation flag true
    let id last-stopped-at
    set xcor first [pxcor] of patches with [station-id = id]
    set time-at-station 0
    set what 0
  ]
end

to-report station-finish
  ifelse (time-at-station != time-to-wait) ;; report if time at station is not equal to waiting time
  [
    report false
  ]
  [
    report true
  ]
end

to how-long-to-wait ;; checks if there is any passengers at the station the train is at
  ifelse (any? passengers-at 0 1) [

  ]
  [
    set time-to-wait 30 ;; if no passengers, wait for at least 30 seconds
  ]
end

to passenger-on-off ;; dictates how the passengers get on and off train

end

to upcoming-station ;; sets next-station so that distances can be accounted for
  let number 0
  if (direction = 1) [
    ask patch-at 2 1 [
      if (station? = true) [
        set number station-id
      ]
    ]
  ]
  if (direction = 2) [
    ask patch-at -2 -1 [
      if (station? = true) [
        set number station-id
      ]
    ]
  ]
  set next-station number
end
@#$#@#$#@
GRAPHICS-WINDOW
53
65
1496
529
-1
-1
35.0
1
9
1
1
1
0
0
0
1
-20
20
-6
6
1
1
1
seconds
30.0

BUTTON
53
540
119
573
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

MONITOR
130
11
180
56
NIL
hours
17
1
11

MONITOR
183
11
244
56
NIL
minutes
17
1
11

MONITOR
247
11
312
56
NIL
seconds
17
1
11

BUTTON
126
540
189
573
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

MONITOR
52
11
113
56
NIL
day
17
1
11

SLIDER
208
544
429
577
maintenance-cycle
maintenance-cycle
100
50000
24300.0
100
1
miles
HORIZONTAL

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

orange line train
false
5
Polygon -10899396 true true 15 206 15 150 15 135 30 120 270 120 285 135 285 150 285 206 270 210 30 210
Rectangle -1 true false 15 135 285 165
Circle -16777216 true false 240 195 30
Circle -16777216 true false 210 195 30
Circle -16777216 true false 60 195 30
Circle -16777216 true false 30 195 30
Rectangle -16777216 true false 30 140 270 180
Line -7500403 false 60 135 60 165
Line -1 false 60 135 60 165
Line -1 false 90 135 90 165
Line -1 false 120 135 120 165
Line -1 false 150 135 150 165
Line -1 false 180 135 180 165
Line -1 false 210 135 210 165
Line -1 false 240 135 240 165
Rectangle -16777216 true false 5 195 19 207
Rectangle -16777216 true false 281 195 295 207
Rectangle -955883 true false 15 165 285 195
Polygon -955883 true false 30 120 15 135 285 135 270 120 30 120 15 135 285 135 270 120 30 120
Polygon -7500403 true false 15 135 285 135 270 120 30 120 15 135

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

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

person construction
false
0
Rectangle -7500403 true true 123 76 176 95
Polygon -1 true false 105 90 60 195 90 210 115 162 184 163 210 210 240 195 195 90
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Circle -7500403 true true 110 5 80
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -955883 true false 180 90 195 90 195 165 195 195 150 195 150 120 180 90
Polygon -955883 true false 120 90 105 90 105 165 105 195 150 195 150 120 120 90
Rectangle -16777216 true false 135 114 150 120
Rectangle -16777216 true false 135 144 150 150
Rectangle -16777216 true false 135 174 150 180
Polygon -955883 true false 105 42 111 16 128 2 149 0 178 6 190 18 192 28 220 29 216 34 201 39 167 35
Polygon -6459832 true false 54 253 54 238 219 73 227 78
Polygon -16777216 true false 15 285 15 255 30 225 45 225 75 255 75 270 45 285

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
