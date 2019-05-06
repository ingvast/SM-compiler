REBOL []

style: stylize/master [
    dyn-list: list 
]

style/dyn-list: make style/dyn-list [
    row-offset: 0
    init: [
	if image? image [
	    if none? size [ size: image/size ]
	    if size/y < 0 [ size/y: size/x * image/size/y / image/size/x effect: insert copy effect 'fit ]
	    if color [ effect: join effect [ 'colorize color ] ]
	]
	if none? size [size: 100x100]
	subface: layout/parent/origin/styles second :action blank-face 0x0 copy self/styles
	pane: func [face id /local count spane] [
	    if pair? id [return 1 + second id / subface/size]
	    subface/offset: subface/old-offset: id - 1 * subface/size * 0x1
	    if subface/offset/y + subface/size/y > size/y [return none]
	    count: 0
	    foreach item subface/pane [
		if object? item [
		    subfunc item id + row-offset count: count + 1
		]
	    ]
	    subface
	]
    ]
]
