REBOL [
    title: "Finite state machine design tool"
    author: "Johan Ingvast"
]

text-size: func [ str ][ size-text make face [ text: str ] ]


state-object: make object! [
    type: 'state
    name: "State"
    radius: 50
    code: [
	pen black fill-pen none
	line-width 3
	translate position 
	circle 0x0 radius
	pen none fill-pen black
	text vectorial text-position name
	]
    position: 100x100
    text-position: none
    weight: 1
    update-graphics: func [][
	    text-position: (text-size name ) / -2 
    ]
    pos-in: func [ pos ][
	pos: pos - position
	return radius ** 2 > ( pos/x ** 2 + ( pos/y ** 2 ) )
    ]
]

transition-object: make object! [
    type: 'transfer
    name: "Trans"
    code: [
	pen red
	line-width 1
	arrow 1x0
	line from-pos to-pos
    ]
    from-pos: 0x0
    to-pos: 0x0
    from-state: none
    to-state: none
    update-graphics: func [
	/local vector vector-length
    ][
	vector: to-state/position - from-state/position
	vector-length: square-root vector/x ** 2 + ( vector/y ** 2)
	to-pos: to-state/position - ( vector * ( 3 + to-state/radius ) / vector-length )
	from-pos: from-state/position + ( vector * from-state/radius / vector-length )
    ]
]

    
states: reduce [
    make state-object [ position: 20x20 name: "Init" radius: 30]
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


move-env: make object! [
    current-selection: none
    ref-pos: none
    set 'move-state func [ new-pos /local ][
	if current-selection [
	    current-selection/position: (transformation/face-to-canvas new-pos) - ref-pos
	    update-transitions transitions
	]
    ]
    set 'move-state-initialize func [ down-pos /local down-in-canvas ][
	down-in-canvas: transformation/face-to-canvas down-pos
	? down-in-canvas
	foreach s states [
	    if s/pos-in down-in-canvas [
		ref-pos: down-in-canvas - s/position
		current-selection: s
		exit
	    ]
	]
	current-selection: none
    ]
]

transformation: context [
    canvas: none	; The canvas to operate on
    translate: 0x0
    scale: 2
    offset-offset: none
    translate-init-handler: func [ offset ][
	offset-offset: offset - translate
    ]
    translate-handler: func [ offset ][
	translate: offset - offset-offset 
    ]

    scale-around: func [ rel-scale around-pos ][
	; To change scale, scale around the mouse position
	; hence a position in the canvas corresponding to the mouse position should 
	; be reflected back att the mouse position after the new scale
	; canvas = ( mouse-pos - transfer-before ) / scale-before
	; mouse-pos = canvas * scale-after + tranfer-after =
	;		    (mouse-pos - transfer-before) / scale-before * scale-after + transfer-after
	; transfer-after = mouse-pos - (mouse-pos - tranfer-before) * scale-after / scale-before
	translate: probe around-pos - (around-pos - translate * rel-scale )
	scale: scale * rel-scale
    ]

    ; face = canvas * scale + transfer
    ; canvas = ( face - transfer ) / scale
    

    canvas-to-face-pos: func [ pos ][
	pos * scale + translate
    ]
    face-to-canvas: func [ pos ][
	pos - translate  / scale
    ]
]


view/new layout [
	canvas: box ivory 800x800 "Hej a ha"
		effect [ draw [
			translate transformation/translate
			scale transformation/scale transformation/scale
			push drawing
		] ]
    button "Quit" [unview]
]

over-handler: none
handle-events: func [ face action event /local mouse-pos ][
    system/view/focal-face: face
    system/view/caret: face/text
    mouse-pos: event/offset
    switch action [
	down [
	    move-state-initialize mouse-pos
	    over-handler: :move-state
	]
	over [
	    over-handler mouse-pos
	    show face
	]
	alt-down [
	    transformation/translate-init-handler mouse-pos
	    over-handler: get in transformation 'translate-handler
	]
	key [
	    print [ mold dbg: event/key event/offset ]
	    switch event/key [ 
		#"+" page-up [ transformation/scale-around 1.2 event/offset - win-offset? face show face ]
		#"-" page-down [ transformation/scale-around 1 / 1.2 event/offset - win-offset? face show face ]
	    ]
	    ? transformation
	]
    ]
]

transformation/canvas: canvas

canvas/feel: make canvas/feel [
    engage: :handle-events
]
canvas/font/valign: 'top
canvas/font/align: 'left

canvas/text: ""

show canvas
do-events


halt
