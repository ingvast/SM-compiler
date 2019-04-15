REBOL [
]

base: make object! [
    code: [
	pen black
	line-width 3
	translate position 
	circle 0x0 50
    ]
    position: 100x100
    weight: 1
]

objects: reduce [
    make base [ position: 20x20 ]
    make base [ position: 120x200 ]
    make base [ position: 120x30 ]
]

drawing: copy []
foreach o objects [ append drawing reduce [ 'push o/code ] ]

view/new layout [
    canvas: box ivory 250x250
		effect [ draw drawing ]
    button "Quit" [unview]
]

equalize: func [
    objects size
    /local
	pos mass
	min-x max-x 
	min-y max-y 
][
    pos: 0x0
    mass: 0
    min-x: 1e6 max-x: -1e6
    min-y: 1e6 max-y: -1e6
    foreach o objects [
	pos: o/position * o/weight + pos
	mass: o/weight + mass
	min-x: minimum min-x o/position/x
	max-x: maximum max-x o/position/x
	min-y: minimum min-y o/position/y
	max-y: maximum max-y o/position/y
    ]
    pos: pos / mass
    diff-x: max-x - min-x
    diff-y: max-y - min-y

    foreach o objects [
	o/position: o/position - pos + (size / 2)
    ]

]

equalize objects canvas/size
show canvas


