extends PanelContainer

var text : String
var textonscreen : String
var posintext : int
var cleaning : bool = false
const MAXLEN = 80

func pushtext(_text : String):
	text = _text
	textonscreen = ""
	posintext = 0
	cleaning = false
	$Defilement.start()

func defile():
	if textonscreen.length() >= MAXLEN :
		textonscreen = textonscreen.right(-1)
	if posintext >= text.length():
		if not cleaning:
			# on a tout affiché, on attend un peu et on efface
			efface()
		else:
			# on a tout affiché, on commence à réduire
			textonscreen = textonscreen.right(-1)
	else:
		textonscreen = textonscreen + text[posintext]
		posintext += 1
	if textonscreen.length() == 0 :
		$Defilement.stop()
	%TextMsg.text = textonscreen

func efface():
	$Defilement.stop()
	cleaning = true
	await get_tree().create_timer(5.0).timeout
	$Defilement.start()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Defilement.timeout.connect(defile.bind())
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
