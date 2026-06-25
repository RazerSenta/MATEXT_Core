extends CharacterBody3D

const SPRINT = 8.0
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@onready var camera_handle = $cameraHandle
@onready var terminal_display = $cameraHandle/terminalDisplay
@onready var ray = $cameraHandle/RayCast3D
@onready var camera_set = $cameraHandle/Camera3D
@onready var crosshair = $CanvasLayer/crosshair
@onready var miaw = $CollisionShape3D/MeshInstance3D/miaw
var camera_dir = Vector3.ZERO
var camera_sens = 0.2
var camera_fov = 75
var camera_fov_zoom = 10
var camera_move = true
var player_sprint = false
var player_zoom = false
var inventory = {'money':200}

var ray_id_get = {}
var ray_object = ''

var terminal_open = ''
var terminal_on = false
var terminal_costum_display = ''
var terminal_menu = {
	'move forward' : 'open inventory',
	'move right' : 'open object scanner',
	'move back' : 'open terminal help'}
var terminal_help = {
	'use player movement' : 'interact with the terminal',
	'press [e]' : 'terminal',
	'press [r]' : 'respawn',
	'press [c]' : 'zoom',
	'press [Alt+q]' : 'exit the game',
	'hold [x]' : 'enable cursor'}

#main terminal system
func terminal():
	if terminal_on:

		if terminal_open == 'inventory':
			#inventory run in _process()
			pass

		elif terminal_open == 'object_scanner':
			ray_scanner()
			terminal_display.text = json_conv("OBJECT SCANNER", ray_id_get['status'] if 'status' in ray_id_get else '') + ('\n________________________________,,,\n' + '• press the object to enter its terminal' if 'menu' and 'status' in ray_id_get else '')
			terminal_open = 'terminal_access' if 'menu' in ray_id_get and Input.is_action_just_pressed("click") else 'object_scanner'

		elif terminal_open == 'help':
			terminal_display.text = json_conv("TERMINAL HELP", terminal_help)

		elif terminal_open == 'terminal_access':
			terminal_display.text = json_conv("TERMINAL ACCESS", ray_id_get['menu'])
			if ray_object.has_method('terminal'):
				var output = ray_object.terminal(get_input_direction(), self)
				if output:
					if output == 'back_to_status':
						terminal_open = 'object_status'
					elif 'display: ' in output:
						terminal_costum_display = output.replace('display: ', '')
						terminal_open = 'display_costum'

		elif terminal_open == 'object_status':
			terminal_display.text = json_conv("OBJECT STATUS", ray_id_get['status'] if 'status' in ray_id_get else '')

		elif terminal_open == 'display_costum':
			terminal_display.text = terminal_costum_display
		else:
			terminal_display.text = json_conv('WELCOME TO THE TERMINAL', terminal_menu)
			terminal_input()
	else:
		terminal_display.text = ''
		terminal_open = 'menu'


func terminal_inventory():
	if terminal_open == 'inventory':
		terminal_display.text = json_conv("INVENTORY", inventory)
func terminal_input():
	if Input.is_action_just_pressed("ui_up"):
		terminal_open = 'inventory'
	elif Input.is_action_just_pressed("ui_right"):
		terminal_open = 'object_scanner'
	elif Input.is_action_just_pressed("ui_down"):
		terminal_open = 'help'
	elif Input.is_action_just_pressed("click"):
		terminal_open = 'terminal_area'

func ray_scanner(): 
	if ray.is_colliding():
		ray_object = ray.get_collider()
		if ray.get_collider():
			ray_id_get = ray.get_collider().id if 'id' in ray.get_collider() else {}
		else:
			ray_id_get = {}
	else:
		ray_id_get = {}
func json_conv(title, data):
	var output = ['| ', title, ' >_\nv\n']
	for item in data:
		output.append('• ' + item + ' : ' + str(data[item]) + '\n')
	return ''.join(output)
func player_press_button():
	if Input.is_action_just_pressed("sprint"):
		player_sprint = !player_sprint
	elif Input.is_action_just_pressed("open_terminal"):
		terminal_on = !terminal_on
	elif Input.is_action_just_pressed("respawn"):
		self.global_position = Vector3.ZERO
	elif Input.is_action_just_pressed("exit"):
		get_tree().quit()
	elif Input.is_action_just_pressed("zoom"):
		player_zoom = !player_zoom
		crosshair.visible = false if player_zoom else true
		camera_set.fov = 10 if player_zoom else camera_fov
		camera_sens = 0.05 if player_zoom else 0.2

func get_input_direction():
	if Input.is_action_just_pressed("ui_left"):
		return 'left'
	elif Input.is_action_just_pressed("ui_right"):
		return 'right'
	elif Input.is_action_just_pressed("ui_up"):
		return 'up'
	elif Input.is_action_just_pressed("ui_down"):
		return 'down'
func camera(event):
	if camera_move and event is InputEventMouseMotion:
		camera_dir.x -= event.relative.y * camera_sens
		camera_dir.y -= event.relative.x * camera_sens
		camera_dir.x = clamp(camera_dir.x, -75, 90)
	#sprint effect
	if not player_zoom:
		camera_set.fov = camera_fov + 10 if player_sprint and Input.is_action_pressed("ui_up") else camera_fov

func respawn_from_void():
	if self.global_position.y <= -15.0 and camera_dir.x <= 10 and camera_dir.x >= -10: 
		self.global_position = Vector3(0, 100, 0)
		velocity.y = -40
func mouse():
	camera_move = false if Input.is_action_pressed("cursor_enable") else true
	crosshair.visible = false if Input.is_action_pressed("cursor_enable") or player_zoom else true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.is_action_pressed("cursor_enable") else Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
	add_to_group("player")
	miaw.visible = false
func _input(event: InputEvent) -> void:
	camera(event)
	player_press_button()
	respawn_from_void()
	mouse()
	terminal()
func _process(delta: float) -> void:
	if camera_move:
		camera_handle.rotation_degrees.x = camera_dir.x
		self.rotation_degrees.y = camera_dir.y
	terminal_inventory()
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") 
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * (SPRINT if player_sprint and Input.is_action_pressed("ui_up") else SPEED)
		velocity.z = direction.z * (SPRINT if player_sprint and Input.is_action_pressed("ui_up") else SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()
