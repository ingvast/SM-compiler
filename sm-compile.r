REBOL [
    title: "Finite state machine design tool"
    author: "Johan Ingvast"
]

do %vid-extension.r

text-size: func [ str ][ size-text make face [ text: str ] ]

state-object: make object! [
    type: 'state
    id: none
    name: "State"
    entry-code: {}
    exit-code: {}
    draw-code: [
	pen pencolor fill-pen none
	line-width 3
	translate position 
	circle 0x0 radius
	pen none fill-pen textcolor
	text vectorial text-position name
	]
    to-transitions: []
    from-transitions: []
    radius: 50
    position: 100x100
    text-position: none
    pencolor: black
    textcolor: black
    update-graphics: func [][
	    pencolor: pick [ 255.30.30 10.10.10 ] highlight
	    text-position: (text-size name ) / -2 
    ]
    highlight: off
    pos-in: func [ pos ][
	pos: pos - position
	return radius ** 2 > ( pos/x ** 2 + ( pos/y ** 2 ) )
    ]
    properties-layout: [
	origin 0x0
	across
	field bold font[ size: 20 ] name edge [ size: 0x0 ]
	    [ set-state-name self value update-graphics show canvas ]
	return
	tabs [ 75 ]
	space 2x2
	text "Entry" return
	    area entry-code 150x200 ;[ entry-code: value]
	return
	text "Exit" return
	    area exit-code 150x200 ;[ exit-code: value ]
	return
	text "Radius" tab field to-string radius [
		    radius: any [ attempt [ to-decimal do value ] 50 ]
		    update-graphics
		    update-transitions transitions
		    face/text: radius
		    show [ canvas  face ]
	]
	return
	text "Text colour" tab field to-string textcolor [
			textcolor: any [ attempt [ to-tuple do value ] black ]
			update-graphics face/text: textcolor show [ canvas face]
		    ]
	dyn-list 150x100 [ text 150 "hej"] data (
	    use [ lst ][
		lst: copy []
		? self
		foreach i from-transitions [
		    append/only lst reduce [ i/transition-clause ]
		]
		reduce [ lst ]
	    ]
	)
    ]
    
]
id?: :integer?

states: copy []

new-state-node: func [
    {Creates a node and adds to the SM}
    spec /local
	state new-id id-code
][
    new-id: round random 2 ** 30
    state: make state-object [ name: join "S" to-string new-id ]
    state: make state spec
    state: make state compose [ id: new-id ]
    set-state-name state state/name ; Will throw an error if name occupied
    repend states [ new-id state ]
]

remove-state-node: func [ state ][
    remove/part back find states state 2
    update-drawing
]


rot-90: func [ vect ][ as-pair vect/2 negate vect/1 ]
transition-object: make object! [
    type: 'transition
    label: transition-clause: ""
    from-state: none
    to-state: none

    draw-code: [
	pen arrowcolor 
	line-width 1
	fill-pen none
	arrow 1x0
	curve  from-pos knot1 knot2 to-pos
	;arrow 0x0
	;line knot1 knot2
	pen none fill-pen black
	translate knot1
	text vectorial 0x0 label
    ]
    from-pos: 0x0
    to-pos: 0x0
    knot1: knot2: 0x0
    arrowcolor: black
    highlight: off
    update-graphics: func [
	/local vector vector-length
    ][
	vector: to-state/position - from-state/position
	vector-length: square-root vector/x ** 2 + ( vector/y ** 2)
	to-pos: to-state/position - ( vector * ( 3 + to-state/radius ) / vector-length )
	from-pos: from-state/position + ( vector * from-state/radius / vector-length )

	; make it slightly bent
	vector: to-pos - from-pos
	vector-length: square-root vector/x ** 2 + ( vector/y ** 2)
	knot1: vector * 0.4 + from-pos + ( ( rot-90 vector ) * 20 / (vector-length ) )
	knot2: vector * 0.6 + from-pos + ( ( rot-90 vector ) * 20 / (vector-length ) )

	if any [ not label empty? label ] [ label: transition-clause ]
	arrowcolor: pick [ 255.30.30 10.10.10 ] highlight
    ]
    properties-layout: [
	origin 0x0
	across
	;field bold font[ size: 20 ] name edge [ size: 0x0 ]
	;    [ set-state-name self value update-graphics show canvas ]
	;return
	tabs [ 75 ]
	space 2x2
	text "From state" return
	    text from-state/name  [ properties-dialog from-state ]
	return
	text "To state" return
	    text to-state/name  [ properties-dialog to-state ]
	return
	text "Transition clause" return
	    area transition-clause 150x200 ;[ exit-code: value ]
    ]
]

transitions: copy []

new-transition: func [
    spec
    /local tran
][
    tran: make transition-object spec
    if id? tran/from-state [ tran/from-state: select states tran/from-state ]
    if id? tran/to-state [ tran/to-state: select states tran/to-state ]
    append tran/from-state/from-transitions tran
    append tran/to-state/to-transitions     tran

    tran/update-graphics
    append transitions tran

]

properties-dialog: func [ object ][
    properties/pane: layout probe compose dbg: object/properties-layout
    properties/pane/offset: 0x0
]
       
set-state-name: func [
    [ catch ]
    state {State or id}
    name {New name}
    /local s 
][
    unless object? state [ state: select states state ]
    foreach [id s] states [
	unless  s = state  [
	    if s/name = name  [
		throw make error! rejoin [ 
			{Name already occupied by:} mold s
		]
	    ]
	]
    ] 
    state/name: name
]

update-transitions: func [ transitions ][
    foreach t transitions [ t/update-graphics ]
]

update-states: func [ states ][
    foreach [id s ] states [ s/update-graphics ]
]
    

update-drawing: does [ 
    drawing-states: copy []
    drawing-transitions: copy []
    foreach [id s ] states [ append drawing-states reduce [ 'push s/draw-code ] ]
    foreach t transitions [ append drawing-states reduce[ 'push t/draw-code ]]
    update-states states
    update-transitions transitions
]

find-mouse-hit: func [ objects pos ][
    foreach [id s ] states [
	if s/pos-in pos [
	    return s
	]
    ]
    none
]

make object! [
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
	current-selection: find-mouse-hit states down-in-canvas
	if current-selection [
	    ref-pos: down-in-canvas - current-selection/position
	]
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
	translate: around-pos - (around-pos - translate * rel-scale )
	scale: scale * rel-scale
    ]

    ; face = canvas * scale + transfer
    ; canvas = ( face -transfer ) / scale
    

    canvas-to-face-pos: func [ pos ][
	pos * scale + translate
    ]
    face-to-canvas: func [ pos ][
	pos - translate  / scale
    ]
]

states: copy [
]

new-state-node [ position: 20x20 name: "Init" radius: 30]
new-state-node [ position: 120x200 name: "Collect" ]
new-state-node [ position: 120x30 name: "Discharge" ]


new-transition  [from-state: states/1 to-state: states/3  transition-clause: "true" ]
new-transition  [from-state: states/4 to-state: states/6  transition-clause: "true" ]

update-drawing


view/new layout [
    across 
    canvas: box ivory 800x800 "" top left
	    edge  [ size: 1x1 colour: black ]
	    effect [ draw [
		    translate transformation/translate
		    scale transformation/scale transformation/scale
		    push drawing-transitions
		    push drawing-states
	    ] ]
    properties: panel pink 150x800 [] edge [ size: 1x1 colour: black ]
    return
    button "Save" #"^s" [ save ]
    button "Quit" #"^q" [unview]
]

selected: none
over-handler: none
handle-events: func [ face action event /local mouse-pos ][
    system/view/focal-face: face
    system/view/caret: face/text
    mouse-pos: event/offset
    switch action [
	down [
	    move-state-initialize mouse-pos
	    over-handler: :move-state

	    if state: find-mouse-hit states transformation/face-to-canvas mouse-pos [

		if selected [ selected/highlight: off selected/update-graphics ]
		selected: state 
		selected/highlight: on
		selected/update-graphics

		properties-dialog selected
		show [ canvas properties]
	    ]
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
	    mouse-pos: event/offset - win-offset? face
	    switch event/key [ 
		#"+" page-up [ transformation/scale-around 1.2 mouse-pos show face ]
		#"-" page-down [ transformation/scale-around 1 / 1.2 mouse-pos show face ]
		#"0" [ transformation/scale-around 1 / transformation/scale mouse-pos show face ]
		#"s" [  new-state-node [
			    position: transformation/face-to-canvas mouse-pos
			]
			update-drawing show face
		    ]
		#"t" [ new-transition transformation/face-to-canvas mouse-pos update-drawing show face]
		#"^~" [ dbg: selected if all [ selected selected/type = 'state ] [
			    remove-state-node selected
			    show canvas
			    properties/pane: none show properties
			    selected: none] ]
	    ]
	]
    ]
]

transformation/canvas: canvas

canvas/feel: make canvas/feel [
    engage: :handle-events
]

canvas/text: ""

show canvas
do-events


halt
