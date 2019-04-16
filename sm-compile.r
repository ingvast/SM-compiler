REBOL [
]

text-size: func [ str ][ size-text make face [ text: str ] ]


state-object: make object! [
    type: 'state
    name: "State"
    code: [
	pen black
	line-width 3
	translate position 
	circle 0x0 50
	text text-position name
    ]
    position: 100x100
    text-position: none
    weight: 1
    update-graphics: func [][
	text-position: (text-size name ) / -2 + position
    ]
]

transition-object: make object! [
    type: 'transfer
    name: "Trans"
    code: [
	pen black
	line-width 1
	arrow 0x1
	line from-pos to-pos
    ]
    from-pos: 0x0
    to-pos: 0x0
    from-state: none
    to-state: none
    update-graphics: func [
	/local
    ][
	to-pos: to-state/position
	from-pos: from-state/position
    ]
]

    
states: reduce [
    make state-object [ position: 20x20 name: "Init" ]
    make state-object [ position: 120x200 name: "Collect" ]
    make state-object [ position: 120x30 name: "Discharge" ]
]

transitions: reduce [
    make transition-object [ from-state: states/1 to-state: states/2  update-graphics ]
    make transition-object [ from-state: states/2 to-state: states/3  update-graphics ]
]
update-transitions: func [ transitions ][
    foreach t transitions [ t/update-graphics ]
]
update-states: func [ states ][
    foreach s states [ s/update-graphics ]
]
    

drawing: copy []
foreach s states [ append drawing reduce [ 'push s/code ] ]
foreach t transitions [ append drawing reduce[ 'push t/code ]]

update-states states

view/new layout [
    canvas: box ivory 250x250
		effect [ draw drawing ]
    button "Quit" [unview]
]

equalize: func [
    states size
    /local
	pos mass
	min-x max-x 
	min-y max-y 
][
    pos: 0x0
    mass: 0
    min-x: 1e6 max-x: -1e6
    min-y: 1e6 max-y: -1e6
    foreach s states [
	pos: s/position * s/weight + pos
	mass: s/weight + mass
	min-x: minimum min-x s/position/x
	max-x: maximum max-x s/position/x
	min-y: minimum min-y s/position/y
	max-y: maximum max-y s/position/y
    ]
    pos: as-pair max-x + min-x / 2 max-y + min-y / 2
    diff-x: max-x - min-x
    diff-y: max-y - min-y

    scale-x: size/x / diff-x
    scale-y: size/y / diff-y

    foreach o states [
	o/position: o/position - pos 
	o/position/x: o/position/x * scale-x + ( size/x / 2)
	o/position/y: o/position/y * scale-y + ( size/y / 2)
    ]
    update-states states
    update-transitions transitions

]

equalize objects canvas/size
show canvas


halt
