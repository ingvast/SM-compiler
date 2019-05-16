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
    active-color: green
    textcolor: black
    update-graphics: func [][
            pencolor: case [
                active [ active-color ]
                highlight [ 255.30.30 ]
                true [ 10.10.10 ] 
            ]
            text-position: (text-size name ) / -2 
    ]
    highlight: off
    active: off
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
        return
        text "Reach transitions here" return
        dyn-list 150x100 [ across space 0x0 
                text 80 "from state" edge[ color: black size: 0x1]
                    [   properties-dialog face/parent-face/pane/3/text
                        select-object face/parent-face/pane/3/text
                        show [ canvas properties ]
                    ]
                text 60 "clause" edge[color: black size: 0x1]
                    [   properties-dialog face/parent-face/pane/3/text
                        select-object face/parent-face/pane/3/text
                        show [ canvas properties ]
                    ]
                text 0x0 "object"  with [ show?: off ]
            ] data (
            use [ lst ][
                lst: copy []
                foreach i to-transitions [
                    append/only lst reduce [ any [ i/from-state/name i/from-state/id ] i/transition-clause i ]
                ]
                reduce [ lst ]
            ]
        )
        return
        text "Leave transition" return
        dyn-list 150x100 [ across space 0x0 
                text 80 "To state" edge[ color: black size: 0x1]
                    [   properties-dialog face/parent-face/pane/3/text
                        select-object face/parent-face/pane/3/text
                        show [ canvas properties ]
                    ]
                text 60 "clause" edge[color: black size: 0x1]
                    [   properties-dialog face/parent-face/pane/3/text
                        select-object face/parent-face/pane/3/text
                        show [ canvas properties ]
                    ]
                text 0x0 "object"  with [ show?: off ]
            ] data (
            use [ lst ][
                lst: copy []
                foreach i from-transitions [
                    append/only lst reduce [ any [ i/to-state/name i/to-state/id ] i/transition-clause i ]
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
    state: make state-object [ name: join "S" to-string id: new-id ]
    state: make state spec
    ;state: make state compose [ id: new-id ]
    set-state-name state state/name ; Will throw an error if name occupied
    repend states [ state/id state ]
    state
]

remove-state-node: func [ state ][
    foreach tr state/to-transitions [ remove find transitions tr ]
    foreach tr state/from-transitions [ remove find transitions tr ]
    remove/part back find states state 2
    update-canvas
]


rot-90: func [ vect ][ as-pair vect/2 negate vect/1 ]
transition-object: make object! [
    type: 'transition
    id: none
    label: transition-clause: ""
    from-state: none
    to-state: none

    draw-code: [
        pen arrow-color 
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
    arrow-color: black
    active-color: green
    highlight: off
    active: off
    update-graphics: func [
        /local vector vector-length
    ][
        vector: to-state/position - from-state/position
        vector-length: square-root vector/x ** 2 + ( vector/y ** 2)
        if to-state/radius + from-state/radius + 1 < vector-length [
            to-pos: to-state/position - ( vector * ( 3 + to-state/radius ) / vector-length )
            from-pos: from-state/position + ( vector * from-state/radius / vector-length )

            ; make it slightly bent
            vector: to-pos - from-pos
            vector-length: square-root vector/x ** 2 + ( vector/y ** 2)
            knot1: vector * 0.4 + from-pos + ( ( rot-90 vector ) * 20 / (vector-length ) )
            knot2: vector * 0.6 + from-pos + ( ( rot-90 vector ) * 20 / (vector-length ) )
        ]

        if any [ not label empty? label ] [ label: transition-clause ]
        arrow-color: case [
            active [ active-color ]
            highlight [ 255.30.30 ]
            true [ 10.10.10 ] 
        ]
    ]
    properties-layout: [
        origin 0x0
        across
        ;field bold font[ size: 20 ] name edge [ size: 0x0 ]
        ;    [ set-state-name self value update-graphics show canvas ]
        ;return
        tabs [ 75 ]
        space 2x2
        text bold from-state/name  [
            select-object from-state
            properties-dialog from-state
            show [ canvas properties ]
        ]
        return
        box 100x15 effect[draw[ pen black arrow 1x0 line 10x0 10x15 ]]
        return
        text bold to-state/name  [
            select-object to-state
            properties-dialog to-state
            show [ canvas properties ]
        ]
        return
        text "Transition clause" return
            area transition-clause 150x200 [ show canvas ]
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
    tran
]

properties-dialog: func [ object ][
    properties/pane: layout compose object/properties-layout
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
    
load-sm: func [
    [catch]
    file [string! file! ] {File to read from}
    /local
][
    unless file? file [ file: to-file file ]
    either 'file = get in info? file 'type [
        content: load file

        clear transitions
        clear states
        
        unless parse content [
            'SM-COMPILER 
            'Format 0.1
            opt [ 'Save-date set file-date date! ]

            'States
            any [
                set state block! (
                    new-state-node state
                )
            ]
            'Transitions
            any [
                set tran block! (
                    new-transition tran
                )
            ]
        ] [
            inform layout [ h1 "Something wrong in data" ] 
        ]
        select-object none
    ][
        throw make error! "Not a valid file" 
    ]
]

save-sm: func [
    file [string! file! ] {File to read from}
    /local
;       content
][
    unless file? file [ file: to-file file ]

    content: trim copy {SM-COMPILER
    format 0.1
    }

    repend content [ "Save-date " now newline newline ]
    repend content {States^/}
    foreach [ id state ] states [
        append content {[^/}
        foreach field-name [ name id position entry-code exit-code radius ][
            value: get in state field-name
            if object? value [ value: value/id ]
            repend content [ tab field-name ":" tab mold value newline]
        ]
        append content {]^/}
    ]
    repend content {Transitions^/}
    foreach tran transitions [
        append content {[^/}
        foreach field-name [ transition-clause label from-state to-state ][
            value: get in tran field-name
            if object? value [ value: value/id ]
            repend content [ tab field-name ":" tab mold value newline]
        ]
        append content {]^/}
    ]

    write file content
]
        

update-canvas: does [ 
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
        if all [ current-selection current-selection/type = 'state ] [
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
    canvas: none        ; The canvas to operate on
    offset: 0x0
    scale: 2
    offset-offset: none
    translate-init-handler: func [ new-offset ][
        offset-offset: new-offset - offset
    ]
    translate-handler: func [ new-offset ][
        offset: new-offset - offset-offset 
    ]

    scale-around: func [ rel-scale around-pos ][
        ; To change scale, scale around the mouse position
        ; hence a position in the canvas corresponding to the mouse position should 
        ; be reflected back att the mouse position after the new scale
        ; canvas = ( mouse-pos - transfer-before ) / scale-before
        ; mouse-pos = canvas * scale-after + tranfer-after =
        ;                   (mouse-pos - transfer-before) / scale-before * scale-after + transfer-after
        ; transfer-after = mouse-pos - (mouse-pos - tranfer-before) * scale-after / scale-before
        offset: around-pos - (around-pos - offset * rel-scale )
        scale: scale * rel-scale
    ]

    ; face = canvas * scale + transfer
    ; canvas = ( face -transfer ) / scale
    

    canvas-to-face-pos: func [ pos ][
        pos * scale + offset
    ]
    face-to-canvas: func [ pos ][
        pos - offset  / scale
    ]
]

languages: copy []
repend languages [
    'rebol context [
        typical-code: func [
                current-state {The state should be passed in and is returned}
                /local t
            ][
                unless current-state [
                    current-state: context [ state: 'S0  time-enter: now/precise ]
                ]
                t: now/time/precise - current-state/time-enter/time
                transit-to: none
                transit-to: switch current-state/state compose [  ; 
                    (none) [ 'init ]
                    init [
                        case [
                            true [ 'bright ]
                        ]
                    ]
                    bright [
                        case [
                             t > 0:0:1 [ 'wait ]
                        ]
                    ]
                    wait [
                        case [
                             t > 0:0:1 [ 'bright ]
                        ]
                    ]
                ]
                if transit-to [
                    switch current-state/state [  ; 
                        S0 []
                        init [ setup-led ]
                        bright [led-off ]
                        wait [ ]
                    ]

                    switch transit-to [  ; Entry code
                        init [ ]
                        bright [led-on ]
                        wait [ ]
                    ]
                    current-state/time-enter: now/precise
                ]
                if transit-to [ current-state/state: transit-to ]
                current-state
            ]
                    
        body: trim/auto copy {
            func [ 
                current-state
                /local t
            ][
                unless current-state [
                    current-state: context [ state: 0  time-enter: now/precise ]
                ]
                t: now/time/precise - current-state/time-enter/time
                transit-to: none
                transit-to: switch current-state/state 
                    <transition-insert-point>
                
                if transit-to [
                    switch current-state/state  [
                        <exit-insert-point>
                    ]
                    switch transit-to [ ; Entry code
                        <entry-insert-point>
                    ]
                    current-state/time-enter: now/precise
                ]
                if transit-to [ current-state/state: transit-to ]
                current-state
            ]
        }    

        create-sm-fun: func [
            {Creates a function that runs the state-machine, returns a function}
            /local
            result
            transition-switch
            entry-switch
            exit-switch
            state
            state-tran
            indent
        ][
            transition-switch: reduce [
                0 reduce [ states/1 ] ;; change later when we have set up the starter
            ]
            exit-switch: copy ""
            entry-switch: copy ""
            foreach [ id state ]  states  [
                ; transitions
                state-tran: copy reduce [
                    state/id reduce [ 
                        'case copy []
                ] ]
                foreach tr state/from-transitions [
                    repend state-tran/2/case [
                        make paren! to-block tr/transition-clause
                        reduce [ tr/to-state/id ]
                    ]
                ]
                append transition-switch state-tran
                new-line find transition-switch state-tran on
                
                indent: "                "
                ; exit
                repend exit-switch [ newline
                    indent id "^-[ " state/exit-code " ]"
                ]
                repend entry-switch [ newline
                    indent id "^-[ " state/entry-code " ]"
                ]
            ]

            result: copy body
            replace result {<transition-insert-point>} mold transition-switch
            replace result {<exit-insert-point>} exit-switch
            replace result {<entry-insert-point>} entry-switch
            do result
        ]
    ]
]

export: func [ 
    [catch]
    lang {What language to export to}
    file {The name of the file to save to. If none file request pops up.}
    /local
        header
        data
][
    either find languages lang [
        unless file [
            file: request-file/title/keep/only/save/filter {Name of file to save state machine to} {OK} {*.r}
            unless file [ exit ]
        ]
    ][
        throw make error! {Cannot find the language}
    ]
    header: context [
        title: {Exported}
        author: get-env {username}
        date: now
        doc: {
            > f: do %<file>.r 
            > state: f none ; Create the starting state
            > forever [ state: f state ]
        } 
    ]
    data: languages/:lang/create-sm-fun
    save/header file data header
]
    

states: copy [
]


update-canvas

simulate-sm: func [ 
    /local
][
    sys: languages/rebol/create-sm-fun
    state: none

    simulation-view: view/title/new layout [
        across
        btn "Run/Restart" [ state: none act/rate: do interval-field/text show act]
        btn "Pause/cont" [ act/rate: if not act/rate [ do interval-field/text ] show act]

        return
        state-text: area 600x300 
            mold state
        return
        text "Interval" interval-field: field "10" 100 [ if act/rate [ act/rate: do value show act]]
        step-btn: btn "Step" [ act/action none none ]
        act: box 0x0 on green [
            old-state-id:  all [ state state/state  ]
            state: sys state
            if old-state-id <> state/state [
                state-object: select states old-state-id
                if state-object [
                    state-object/active: off
                    state-object/update-graphics
                ]

                state-object: select states state/state
                state-object/active: on
                state-object/update-graphics

                show canvas
            ]

            state-text/text: mold state
            
            show state-text
            ]
            feel [
                engage: func [ f a e ][
                    if a = 'time [
                        f/action none none
                    ]
                ]
            ]
        btn "Close" [ unview/only simulation-view ]

    ] "Simulation"
]


view/new layout [
    across 
    canvas: box ivory 800x800 "" top left
            edge  [ size: 1x1 colour: black ]
            effect [ draw [ translate transformation/offset
                    scale transformation/scale transformation/scale
                    push drawing-transitions
                    push drawing-states
            ] ]
    properties: panel 150x800 [] edge [ size: 1x1 colour: black ]
    return
    button "Open" #"^o" [
        filename: request-file/title/filter/keep/only "Open state machine" "OK" "*.sm" 
        if filename [
            load-sm filename
            transformation/offset: 0x0 transformation/scale: 1
            update-canvas
            show [ canvas properties ]
        ]
    ]
    button "Save" #"^s" [
        filename: request-file/title/filter/keep/only/save "Save state machine" "OK" "*.sm" 
        if filename [
            unless find filename "." [ append filename ".sm" ]
            save-sm filename
        ]
    ]
    button "Quit" #"^q" [unview]
    
    button "Export model" [ export 'rebol none ]
    Button "Run"  [ simulate-sm ]
]

selected: none
select-object: func [ object ][
    if selected [
        selected/highlight: off
        selected/update-graphics
    ]
    selected: object
    if object [
        selected/highlight: on
        selected/update-graphics
    ]
]

handle-events: func [ face action event
                        /local mouse-pos transition state
][
    local: [ over-handler none state-from none state-to none ]  ; Static variables
    system/view/focal-face: face
    system/view/caret: face/text
    mouse-pos: event/offset
    switch action [
        down [
            move-state-initialize mouse-pos
            local/over-handler: :move-state

            either state: find-mouse-hit states transformation/face-to-canvas mouse-pos [
                select-object state
                properties-dialog selected
                show [ canvas properties]
            ] [
                transformation/translate-init-handler mouse-pos
                local/over-handler: get in transformation 'translate-handler
            ]
            
        ]
        over [
            local/over-handler mouse-pos
            show face
        ]
        alt-down [
            local/state-from: find-mouse-hit states transformation/face-to-canvas mouse-pos
            local/over-handler: none
        ]
        alt-up [
            local/state-to: find-mouse-hit states transformation/face-to-canvas mouse-pos
            if local/state-to [
                transition: new-transition [ from-state: local/state-from to-state: local/state-to ]
                update-canvas
                select-object transition
                properties-dialog transition
                show [ canvas properties ]
            ]
        ]
        key [
            mouse-pos: event/offset - win-offset? face
            switch event/key [ 
                #"+" page-up [ transformation/scale-around 1.2 mouse-pos show face ]
                #"-" page-down [ transformation/scale-around 1 / 1.2 mouse-pos show face ]
                #"0" [ transformation/scale-around 1 / transformation/scale mouse-pos show face ]
                #"s" [  select-object new-state-node [
                            position: transformation/face-to-canvas mouse-pos
                        ]
                        update-canvas
                        properties-dialog selected
                        show [ canvas properties ]
                    ]
                #"t" [
                    if all [ selected selected/type = 'state ] [
                        local/state-to: find-mouse-hit states transformation/face-to-canvas mouse-pos
                        if local/state-to [
                            transition: new-transition [ from-state: selected to-state: local/state-to ]
                            update-canvas
                            select-object transition
                            properties-dialog transition
                            show [ canvas properties ]
                        ]
                    ]
                ]
                        
                #"^~" [  ; Delete node
                        if all [ selected selected/type = 'state ] [
                            remove-state-node selected
                            show canvas
                            properties/pane: none
                            show properties
                            select-object none
                        ]
                    ]
                #"^[" [ select-object none properties/pane: none show [ canvas properties ] ]
            ]
        ]
    ]
]

transformation/canvas: canvas

canvas/feel: make canvas/feel [
    engage: :handle-events
]

canvas/text: ""

load-sm %blinky-2.sm
update-canvas
show [ canvas properties ]


if all [ error? e: try [ do-events ] ] [
    e: disarm e 
    ? e
]
halt



; vim: expandtab 
