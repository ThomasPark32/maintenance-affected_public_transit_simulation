extensions [csv]

globals [
  time
  time-in-depot
  time-at-station
  waiting-time
  time-at-destination
  person-num
  get-off-train?
]
turtles-own [
  in-depot?
  exiting-depot?
  normal-operation?
  left?
  right?
  at-station?
  what-station
  destination
  randall
  passenger-waiting?
  passenger-onboard?
  at-destination?
  miles-traveled
  go-to-depot?
  entering-depot?
  time-waiting
  time-travelling
  time-final
  when-waiting
  when-travelling
  stop-count1?
  stop-count2?
]

breed [trains train]
breed [persons person]

to setup
  clear-all
  setup-patches
  summon-trains
  summon-persons
  setup-variables
  reset-ticks
end

to setup-patches
  ask patches [set pcolor gray ] ;; background color
  ask patches [
    if (pycor = -1) or (pycor = 1) [ ;; orange lines
      set pcolor orange
    ]
    if ((pxcor = -12) or (pxcor = 12)) and (pycor = 0) [ ;; orange line connectors
      set pcolor orange
    ]
    if (pxcor = 10) and ((pycor = 2) or (pycor = 3)) [ ;; line to depot
      set pcolor orange
    ]
    if (pxcor = -6) or (pxcor = 6) and ((pycor = 1) or (pycor = -1)) [ ;; stations
      set pcolor green
      if (pxcor = -6) and (pycor = 1) [ ;; setting labels for stations
        set plabel "station 1"
      ]
      if (pxcor = -6) and (pycor = -1) [
        set plabel "station 2"
      ]
      if (pxcor = 6) and (pycor = -1) [
        set plabel "station 3"
      ]
      if (pxcor = 6) and (pycor = 1) [
        set plabel "station 4"
      ]
    ]
    if (pxcor = 10) and (pycor = 4)[ ;; color depot blue
      set pcolor blue
      set plabel "depot"
    ]
  ]
end

to setup-variables
  set waiting-time 50
end

to summon-trains
  create-trains 1 [
    set shape "train passenger car"
    set color orange
    set label "train"
    setxy 10 4
    set in-depot? true ;; the train is in the depot when it starts
    set go-to-depot? false ;; train is not in the process of going to the depot
    set entering-depot? false ;; the train is exiting
  ]
end

to summon-persons
  set person-num 0
  repeat passenger-amount [ ;; creates the people in this simulation and assigns them a number to display
    create-persons 1 [
      set person-num person-num + 1
      set shape "person"
      set label (word "passenger" " " person-num)
      set randall random 4 random-destination
      set at-destination? false
      set passenger-waiting? true
      set time-waiting 0
      set time-travelling 0
      set time-final 0
      set stop-count1? false
      set stop-count2? false
    ]
  ]
  ask persons [
    if (color = gray) [ ;; sets color of gray passengers to black for easier visibility
      set color black
    ]
    if (randall = 0) [
      set what-station 1 ;; this passenger will go to station 1
      setxy -6 2
    ]
    if (randall = 1) [
      set what-station 2 ;; this passenger will go to station 2
      setxy -6 -2
    ]
    if (randall = 2) [
      set what-station 3 ;; this passenger will go to station 3
      setxy 6 -2
    ]
    if (randall = 3) [
      set what-station 4 ;; this passenger will go to station 4
      setxy 6 2
    ]
  ]
end

to summon-persons-2
  repeat passenger-amount [ ;; creates a second batch of people in this simulation and assigns them a number to display
    create-persons 1 [
     set person-num person-num + 1
      set shape "person"
      set label (word "passenger" " " person-num)
      set randall random 4 random-destination
      set at-destination? false
      set passenger-waiting? true
      set time-waiting 0
      set time-travelling 0
      set time-final 0
      set stop-count1? false
      set stop-count2? false
    ]
  ]
  ask persons [
    if (at-destination? = false) [
      if (color = gray) [ ;; sets color of gray passengers to black for easier visibility
        set color black
      ]
      if (randall = 0) [
        set what-station 1 ;; this passenger will go to station 1
        setxy -6 2
      ]
      if (randall = 1) [
        set what-station 2 ;; this passenger will go to station 2
        setxy -6 -2
      ]
      if (randall = 2) [
        set what-station 3 ;; this passenger will go to station 3
        setxy 6 -2
      ]
      if (randall = 3) [
        set what-station 4 ;; this passenger will go to station 4
        setxy 6 2
      ]
    ]
  ]
end

to random-destination ;; makes sure the destinations of all the passengers are not the same as their origin
  ask persons [
    set destination random 4
    while [destination-same] [set destination random 4]
  ]
end

to-report destination-same
  ifelse (destination = randall) ;; report if destination is equal to current station
  [
    report true
  ]
  [
    report false
  ]
end

to-report maintenance-time-check
  ifelse (time-in-depot != maintenance-time) ;; report if time in depot is not equal to maintenance time
  [
    report false
  ]
  [
    report true
  ]
end

to-report station-finish
  ifelse (time-at-station != waiting-time) ;; report if time at station is not equal to waiting time
  [
    report false
  ]
  [
    report true
  ]
end

to-report passenger-at-destination
  ifelse ([passenger-onboard?] of persons = false) and ([at-destination?] of persons = true)
  [
    report true
  ]
  [
    report false
  ]
end

to go
  tick
  set time time + 1 ;; increment time by one]
  train-check ;; train code
  passenger-check ;; passenger code
  maintenance-check ;; maintenance code
  time-checks ;; code that increments variables (waiting time, travelling time, etc.)
  if (time = 500) [ ;; at 500 minutes, spawn more passengers
    ask persons [
      if (at-destination? = true) [
        set color red
        set label "completed journey"
        setxy 0 0
      ]
    ]
    summon-persons-2 ;; second round of passengers
  ]
  if (time = 1000) [ ;; after 1000 minutes, stop the simulation
    csv ;; code that puts the time variables in lists for the csv file
    stop
  ]
end

to train-check
  ask trains [
    if (in-depot? = true) [
      depot ;; process of staying in depot
    ]
    if exiting-depot? = true [
      exit-depot ;; process of leaving depot
    ]
    if (normal-operation? = true) and not (exiting-depot? = true) and not (entering-depot? = true) and not (in-depot? = true) [
      train-movement ;; normal movement
    ]
    if (at-station? = true) [ ;; stopped at a station
      station
    ]
    if (at-destination? = true) [ ;; stopped at a station
      station
    ]
    if (go-to-depot? = true) [
      train-movement
    ]
    if (entering-depot? = true) [
      enter-depot
    ]
  ]
end

to passenger-check
  ask persons [ ;; makes passengers move along with train
      if (passenger-onboard? = true) [
        move-to train 0
    ]
  ]
  ask trains [
    if (go-to-depot? = true) [
      ask persons-here [ ;; puts passengers back at their originating stop, this will be improved on later (people don't teleport from the train when it goes out of service)
        set passenger-onboard? false
        return-to-origin
      ]
    ]
  ]
end

to return-to-origin
  ask persons [
    if (at-destination? = false) [
      if (what-station = 1) [
         setxy -6 2
      ]
      if (what-station = 2) [
         setxy -6 -2
      ]
      if (what-station = 3) [
         setxy 6 -2
      ]
      if (what-station = 4) [
         setxy 6 2
      ]
      set passenger-waiting? true
    ]
  ]
end

to maintenance-check
  ask trains [
    if (miles-traveled > maintenance-cycle) and (normal-operation? = true) [ ;; checks if maintenance cycle is surpassed by miles traveled
      set go-to-depot? true ;; depot flag is true
      set normal-operation? false
    ]
  ]
end

to time-checks
  ask persons [
    ifelse (passenger-waiting? = true) [
      set time-waiting time-waiting + 1
    ]
    [
      if (stop-count1? = true) [
        set when-waiting time
        set time-waiting time-waiting
        set stop-count1? false
      ]
    ]
    ifelse (passenger-onboard? = true) [
      set time-travelling time-travelling + 1
    ]
    [
      if (stop-count2? = true) [
        set when-travelling time
        set time-travelling time-travelling
        set stop-count2? false
      ]
    ]
    if (at-destination? = true) [
       set time-final time-waiting + time-travelling
    ]
  ]
end

to enter-depot
  fd 1
  set miles-traveled miles-traveled + 1
  ask trains [
    if (xcor = 10) and (ycor = 4) [
      set entering-depot? false ;; set entering flag false
      set in-depot? true ;; set depot operation flag true
    ]
  ]
end

to depot
  set miles-traveled 0
   ifelse (maintenance-time-check = false) [
        set time-in-depot time-in-depot + 1 ;; increment timer by 1
        setxy 10 4 ;; stay at depot
      ]
      [
        set time-in-depot 0
        set in-depot? false ;; set depot flag to false
        set exiting-depot? true ;; set depot exit flag true
      ]
end

to exit-depot
  facexy 10 1 ;; face towards train line
  fd 1
  set miles-traveled miles-traveled + 1
  if (xcor = 10) and (ycor = 1) [
    set left? true ;; set left flag true
    set exiting-depot? false ;; set exiting flag false
    set normal-operation? true ;; set normal operation flag true
    set time-at-station 0
  ]
end

to train-movement
  facing
  fd 1
  set miles-traveled miles-traveled + 1 ;; increment miles traveled
  if (go-to-depot? = true) [
    if (xcor = 10) and (ycor = 1) [
      facexy 10 4 ;; face towards the depot
      set entering-depot? true
      set go-to-depot? false
    ]
  ]
  check-station
end

to facing ;; faces train in a direction

  if (left? = true) [
    facexy -12 ycor ;; face left
  ]
  if (xcor = -12) and (ycor = 1) [ ;; if at left most position
    facexy xcor -1
  ]
  if (xcor = -12) and (ycor = -1) [ ;; switch left to right
    set right? true
    set left? false
  ]
  if (right? = true) [
    facexy 12 ycor ;; face right
  ]
  if (xcor = 12) and (ycor = -1) [ ;; if at right most position
    facexy xcor 1
  ]
  if (xcor = 12) and (ycor = 0) [ ;; switch right to left
    set right? false
    set left? true
  ]
end

to check-station
  if (pcolor = green) [ ;; if there is a station, stop, except if you are going to the depot
    set at-station? true
    set normal-operation? false
  ]
end

to station
  passenger-boarding
  passenger-alighting
  ifelse (station-finish = false) [
        set time-at-station time-at-station + 1 ;; increment timer by 1
        setxy xcor ycor  ;; stay at station
      ]
      [
        set at-station? false ;; set station flag to false
        set normal-operation? true ;; set normal operation flag true
        set time-at-station 0
      ]
end

to passenger-boarding
  ask trains [
    if (at-station? = true) [ ;; asks train if it is at the station and if it is accepting more passengers
      ask persons [
        if (what-station = 1) or (what-station = 4) [ ;; different directions for stations
          if any? [trains-at 0 -1] of self [ ;; detects if train is in their station
            set passenger-onboard? true
            set passenger-waiting? false
            set stop-count1? true
          ]
        ]
        if (what-station = 2) or (what-station = 3) [
          if any? [trains-at 0 1] of self [
            set passenger-onboard? true
            set passenger-waiting? false
            set stop-count1? true
         ]
        ]
      ]
    ]
  ]
end

to passenger-alighting
  ask persons [
    if (destination = 0) and (plabel = "station 1") [
      setxy -6 6
      set passenger-onboard? false
      set stop-count2? true
      set at-destination? true
    ]
    if (destination = 1) and (plabel = "station 2") [
      setxy -6 -6
      set passenger-onboard? false
      set stop-count2? true
      set at-destination? true
    ]
    if (destination = 2) and (plabel = "station 3") [
      setxy 6 -6
      set passenger-onboard? false
      set stop-count2? true
      set at-destination? true
    ]
    if (destination = 3) and (plabel = "station 4") [
      setxy 6 6
      set passenger-onboard? false
      set stop-count2? true
      set at-destination? true
    ]
  ]
end

to csv ;; thank you to this thread on Google Groups for help in this output code https://groups.google.com/g/netlogo-users/c/Bq4MF0xg89c

  let directory "/Users/thomaspark/Documents/NetLogo/Maintenance Affected Simulation/version2/" ;; local path directory

  let averaging-list []
  ask persons [
    set averaging-list lput time-final averaging-list ;; makes a list of all passenger travel times
  ]

  let average 0 ;; average variable
   ask persons [
    set average mean averaging-list ;; takes average of all passenger travel times and sets it to the variable average
  ]

  let waiting-list [] ;; waiting times
  set waiting-list lput ["Waiting times of Passengers"] waiting-list
  set waiting-list lput (list "Passenger" "Waiting Time" "Time Occurred") waiting-list
  foreach sort [who] of persons  [
    number -> ask person number [
      set waiting-list lput (list who time-waiting when-waiting) waiting-list ;; appends what each passenger's waiting time is to the master list
    ]
  ]
  csv:to-file (word directory "waitingexport" maintenance-cycle "ticks.csv") waiting-list

  let travel-list [] ;; travel times
  set travel-list lput ["Travel times of Passengers"] travel-list
  set travel-list lput (list "Passenger" "Traveling Time" "Time Occurred") travel-list
  foreach sort [who] of persons  [
    number -> ask person number [
      set travel-list lput (list who time-travelling when-travelling) travel-list ;; appends what each passenger's travel time is to the master list
    ]
  ]
  csv:to-file (word directory "travelexport" maintenance-cycle "ticks.csv") travel-list

  let totals-list [] ;; total times
  set totals-list lput ["Passenger" "Total trip times of Passengers"] totals-list
  set totals-list lput (list "Passenger" "Total Trip Time") totals-list
  foreach sort [who] of persons  [ ;; repeats through all passengers
    number -> ask person number [
      set totals-list lput (list who time-final) totals-list ;; appends what each passenger's total time is to the master list
    ]
  ]
  set totals-list lput (list "Average" average) totals-list ;; appends what the average passenger travel time is to the master list
  csv:to-file (word directory "totalsexport" maintenance-cycle "ticks.csv") totals-list

end
@#$#@#$#@
GRAPHICS-WINDOW
239
10
997
769
-1
-1
30.0
1
10
1
1
1
0
0
0
1
-12
12
-12
12
1
1
1
ticks
30.0

BUTTON
15
42
81
75
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
106
43
169
76
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
21
138
126
183
Time (minutes)
time
17
1
11

SLIDER
16
196
234
229
maintenance-time
maintenance-time
0
100
30.0
1
1
minutes
HORIZONTAL

MONITOR
19
270
120
315
NIL
time-in-depot
17
1
11

MONITOR
21
336
192
381
NIL
[miles-traveled] of train 0
17
1
11

SLIDER
1009
20
1256
53
passenger-amount
passenger-amount
1
20
4.0
1
1
passengers
HORIZONTAL

MONITOR
1007
66
1164
111
Number of passengers:
count persons
17
1
11

MONITOR
1008
124
1323
169
Person 1's Destination
[destination] of person 1
17
1
11

SLIDER
19
98
224
131
maintenance-cycle
maintenance-cycle
1
100
100.0
1
1
miles
HORIZONTAL

BUTTON
1195
71
1323
104
Summon a train
summon-trains\n
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
1012
182
1186
227
Person 1's Time Waiting
[time-waiting] of person 1
17
1
11

MONITOR
1015
245
1190
290
Person 1's Time Travelling
[time-travelling] of person 1
17
1
11

MONITOR
1015
310
1211
355
Person 1's Total Journey Time
[time-final] of person 1
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

train passenger car
false
0
Polygon -7500403 true true 15 206 15 150 15 135 30 120 270 120 285 135 285 150 285 206 270 210 30 210
Circle -16777216 true false 240 195 30
Circle -16777216 true false 210 195 30
Circle -16777216 true false 60 195 30
Circle -16777216 true false 30 195 30
Rectangle -16777216 true false 30 140 268 165
Line -7500403 true 60 135 60 165
Line -7500403 true 60 135 60 165
Line -7500403 true 90 135 90 165
Line -7500403 true 120 135 120 165
Line -7500403 true 150 135 150 165
Line -7500403 true 180 135 180 165
Line -7500403 true 210 135 210 165
Line -7500403 true 240 135 240 165
Rectangle -16777216 true false 5 195 19 207
Rectangle -16777216 true false 281 195 295 207
Rectangle -13345367 true false 15 165 285 173
Rectangle -2674135 true false 15 180 285 188

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
