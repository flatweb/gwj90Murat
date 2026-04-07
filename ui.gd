extends PanelContainer

# Gestion du bandeau de text à afficher
var textencours : String
var textonscreen : String
var posintext : int
var cleaning : bool = false
var waiting : bool = false
const MAXLEN = 40

var textsToPrint = Array()

## affichage du texte dans la zone de défilement
func pushtext(text : String):
	textsToPrint.append(text)
	if not $TimerCleanText.is_stopped():
		if $TimerCleanText.time_left > 1.0:
			$TimerCleanText.start(1.0) # on abrège l'attente
	elif $TimerScrollText.is_stopped() :
		gotonexttext()
		
		
func gotonexttext():
	if textsToPrint.size() > 0 :
		textencours = textsToPrint.pop_at(0)
		textonscreen = ""
		posintext = 0
		cleaning = false
		$TimerScrollText.start()

func defile():
	if textonscreen.length() >= MAXLEN :
		textonscreen = textonscreen.right(-1)
	if posintext >= textencours.length():
		if $TimerCleanText.time_left > 0.0 :
			# On attend la fin de l'attente
			return
		if cleaning :
			# on est déjà en train d'effacer
			textonscreen = textonscreen.right(-1)
		else:
			# on a tout affiché, on commence à réduire
			$TimerCleanText.start(3.0)
	else:
		textonscreen = textonscreen + textencours[posintext]
		posintext += 1
	%TextMsg.text = textonscreen
	if textonscreen.length() == 0 :
		$TimerScrollText.stop()
		gotonexttext()

func startclean():
	cleaning = true
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$TimerScrollText.timeout.connect(defile.bind())
	$TimerCleanText.timeout.connect(startclean.bind())
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
