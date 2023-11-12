extends Node2D

class_name Reel

var reel_items : Array
var scroll_speed : int
var friction : int
var direction : Direction

enum Direction {
	UP = -1,
	DOWN = 1,
}

enum State {
	IDLE = 0,
	SCROLLING = 1,
	SLOWING_DOWN = 2,
}

var _sprites: Array[Sprite2D]
var state := State.IDLE
var velocity: float = 0.0
var tween : Tween

const SLOT_SIZE := 128
const SNAP_THRESHOLD := 10

func _init(config: Dictionary = {}):
	reel_items = config.get('items', ["a", "b", "c"])
	scroll_speed = config.get('speed', 3000)
	friction = config.get('friction', 10)
	direction = clamp(config.get('direction', Direction.DOWN), Direction.UP, Direction.DOWN)

func spin():
	state = State.SCROLLING
	
func stop():
	state = State.SLOWING_DOWN

func get_row_value(row_number: int):
	return reel_items[row_number - 1]

func _ready():
	for reel_idx in range(reel_items.size()):
		var _sprite = Sprite2D.new()
		_sprite.texture = load("res://assets/slot_icons/"+reel_items[reel_idx]+".png") as Texture2D
		_sprite.position = Vector2i(0, reel_idx * SLOT_SIZE)
		_sprites.append(_sprite)
		add_child(_sprite)

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		if state == State.SCROLLING:
			state = State.SLOWING_DOWN
		else:
			state = State.SCROLLING
	elif Input.is_action_just_pressed("line_1"):
		print(get_row_value(1))
	elif Input.is_action_just_pressed("line_2"):
		print(get_row_value(2))
	elif Input.is_action_just_pressed("line_3"):
		print(get_row_value(3))
	elif Input.is_action_just_pressed("line_4"):
		print(get_row_value(4))
	elif Input.is_action_just_pressed("line_5"):
		print(get_row_value(5))
		
	if state == State.IDLE:
		_snap_to_slot()
		return
		
	if state == State.SCROLLING:
		if tween:
			tween.kill()
			tween = null
		velocity = delta * scroll_speed * direction
		
	if state == State.SLOWING_DOWN:
		velocity -= delta * friction * direction
		if (velocity * direction) <= SNAP_THRESHOLD:
			state = State.IDLE
			return
		
	_ring_swap_items()
		
	_move_ribbon(velocity)
	
func _move_ribbon(velocity: float):
	for child in _sprites:
		child.position.y += velocity
	
func _tween_ribbon(target_y: float):
	tween = create_tween()
	var easing = Tween.EASE_IN_OUT
	if (target_y == 0 and direction == Direction.DOWN) or (target_y < 0 and direction == Direction.UP):
		easing = Tween.EASE_OUT
	for sprite_idx in range(_sprites.size()):
		tween.parallel().tween_property(_sprites[sprite_idx], "position:y", target_y + sprite_idx * SLOT_SIZE, .5).set_ease(easing).set_trans(Tween.TRANS_BACK)
		
	tween.set_parallel(false).tween_callback(_trim_outliers)
		
func _swap_front_to_back():
	var first = _sprites.back()
	if first.position.y < (_sprites.size() - 2) * SLOT_SIZE:
		var last = _sprites.pop_front()
		last.position.y = first.position.y + SLOT_SIZE
		_sprites.push_back(last)
		reel_items.push_back(reel_items.pop_front())
		
func _swap_back_to_front():
	var first = _sprites.front()
	if first.position.y > 0:
		var last = _sprites.pop_back()
		last.position.y = first.position.y - SLOT_SIZE
		_sprites.push_front(last)
		reel_items.push_front(reel_items.pop_back())
	
func _ring_swap_items():
	if direction == Direction.DOWN:
		_swap_back_to_front()
	elif direction == Direction.UP:
		_swap_front_to_back()
	
func _trim_outliers():
	var first = _sprites.front()
	if first.position.y <= -(SLOT_SIZE):
		first = _sprites.pop_front()
		first.position.y = _sprites.back().position.y + SLOT_SIZE
		_sprites.push_back(first)
		reel_items.push_back(reel_items.pop_front())
	
func _snap_to_slot():
	if tween:
		return
		
	_ring_swap_items()
		
	var first = _sprites.front()
	var target_pos := 0
	if first.position.y <= -(SLOT_SIZE / 2):
		target_pos = -SLOT_SIZE
	
	_tween_ribbon(target_pos)
