extends CharacterBody3D

const SPRINT = 8.0
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@onready var camera_handle = $cameraHandle
@onready var terminal_display = $cameraHandle/Camera3D/terminalDisplay
@onready var ray = $cameraHandle/RayCast3D
@onready var camera_set = $cameraHandle/Camera3D
@onready var crosshair = $screen/crosshair
@onready var miaw = $CollisionShape3D/cat/miaw
var camera_dir = Vector3.ZERO
var camera_mode_dir = Vector3.ZERO
var camera_sens = 0.2
var camera_fov = 75
var camera_fov_zoom = 10
var camera_move = true
var camera_mode = 0

var player_sprint = false
var player_zoom = false
var inventory = {'money':200}

#variable for mobile joystick and screen touch
var joystick_direction = Vector2.ZERO
var joystick_center = Vector2.ZERO
var joystick_active = false
var joystick_touch = -1
var camera_touch = -1

#variable for save status and name from object scanner
var scanner_id_get = {}
var scanner_object = ''

#wow terminal
var terminal_costum_display = ''
var terminal_open = ''
var terminal_on = false
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

func json_conv(title, data):
	var output = ['| ', title, ' >_\nv\n']
	for item in data:
		output.append('• ' + item + ' : ' + str(data[item]) + '\n')
	return ''.join(output)
func get_input_direction():
	if Input.is_action_just_pressed("ui_left"):
		return 'left'
	elif Input.is_action_just_pressed("ui_right"):
		return 'right'
	elif Input.is_action_just_pressed("ui_up"):
		return 'up'
	elif Input.is_action_just_pressed("ui_down"):
		return 'down'
func get_input_terminal():
	if Input.is_action_just_pressed("ui_up"):
		terminal_open = 'inventory'
	elif Input.is_action_just_pressed("ui_right"):
		terminal_open = 'object_scanner'
	elif Input.is_action_just_pressed("ui_down"):
		terminal_open = 'help'
	elif Input.is_action_just_pressed("click"):
		terminal_open = 'terminal_area'
func get_input_action():
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
		camera_set.fov = 10 if player_zoom else camera_fov
		camera_sens = 0.05 if player_zoom else 0.2
	elif Input.is_action_just_pressed("view_mode"):
		camera_mode += 1
		if camera_mode == 1:
			camera_set.position.z = 5
			miaw.visible = true
		elif camera_mode == 2:
			camera_set.position.z = 0
			camera_handle.rotation_degrees.y = 0
			camera_mode = 0
			miaw.visible = false

func terminal_system():
	if terminal_on:

		if terminal_open == 'inventory':
			#inventory run in _process()
			pass

		elif terminal_open == 'object_scanner':
			if ray.is_colliding():
				scanner_object = ray.get_collider()
				if ray.get_collider():
					scanner_id_get = ray.get_collider().id if 'id' in ray.get_collider() else {}
				else:
					scanner_id_get = {}
			else:
				scanner_id_get = {}
			terminal_display.text = json_conv("OBJECT SCANNER", scanner_id_get['status'] if 'status' in scanner_id_get else '') + ('\n________________________________,,,\n' + '• press the object to enter its terminal' if 'menu' in scanner_id_get else '')
			terminal_open = 'terminal_access' if 'menu' in scanner_id_get and Input.is_action_just_pressed("click") else 'object_scanner'

		elif terminal_open == 'help':
			terminal_display.text = json_conv("TERMINAL HELP", terminal_help)

		elif terminal_open == 'terminal_access':
			terminal_display.text = json_conv("TERMINAL ACCESS", scanner_id_get['menu'])
			if scanner_object.has_method('terminal'):
				var output = scanner_object.terminal(get_input_direction(), self)
				if output:
					if output == 'back_to_status':
						terminal_open = 'object_status'
					elif 'display: ' in output:
						terminal_costum_display = output.replace('display: ', '')
						terminal_open = 'display_costum'

		elif terminal_open == 'object_status':
			terminal_display.text = json_conv("OBJECT STATUS", scanner_id_get['status'] if 'status' in scanner_id_get else '')

		elif terminal_open == 'display_costum':
			terminal_display.text = terminal_costum_display
		else:
			terminal_display.text = json_conv('WELCOME TO THE TERMINAL', terminal_menu)
			get_input_terminal()
	else:
		terminal_display.text = ''
		terminal_open = 'menu'

#func for mobile movement 
func joystick_and_camera(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().size.x / 2:
				joystick_touch = event.index
				joystick_center = event.position
			else:
				camera_touch = event.index
		else:
			if event.index == joystick_touch:
				joystick_direction = Vector2.ZERO
				joystick_center = Vector2.ZERO
				joystick_touch = -1
			if event.index == camera_touch:
				camera_touch = -1
	if event is InputEventScreenDrag:
		if event.index == joystick_touch:
			joystick_direction = event.position - joystick_center
		elif event.index == camera_touch:
			camera_dir.x -= event.relative.y * camera_sens
			camera_dir.y -= event.relative.x * camera_sens
			camera_dir.x = clamp(camera_dir.x, -75, 80)

func camera_input(event):
	if camera_move and event is InputEventMouseMotion:
		camera_dir.x -= event.relative.y * camera_sens
		camera_dir.y -= event.relative.x * camera_sens
		camera_dir.x = clamp(camera_dir.x, -75, 90)
		camera_mode_dir.y -= event.relative.x * camera_sens
		if camera_dir.y > 360 or camera_dir.y < -360:
			camera_dir.y = 0
	#sprint effect
	if not player_zoom:
		camera_set.fov = camera_fov + 10 if player_sprint and Input.is_action_pressed("ui_up") else camera_fov
func camera():
	if camera_move:
		camera_handle.rotation_degrees.x = camera_dir.x
		if camera_mode == 1:
			if Input.is_action_pressed("ui_up"):
				self.rotation_degrees.y = camera_dir.y
				camera_mode_dir.y = 0
				camera_handle.rotation_degrees.y = camera_mode_dir.y
			else:
				camera_handle.rotation_degrees.y = camera_mode_dir.y
		else:
			self.rotation_degrees.y = camera_dir.y
func respawn_from_void():
	if self.global_position.y <= -15.0 and camera_dir.x <= 10 and camera_dir.x >= -10: 
		self.global_position = Vector3(0, 100, 0)
		velocity.y = -40
func cursor_visible():
	camera_move = false if Input.is_action_pressed("cursor_enable") else true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.is_action_pressed("cursor_enable") else Input.MOUSE_MODE_CAPTURED
func crosshair_is_visible():
	if Input.is_action_pressed("cursor_enable") or player_zoom:
		crosshair.visible = false
	elif player_zoom:
		crosshair.visible = false
	elif camera_mode == 1:
		crosshair.visible = false
	else:
		crosshair.visible = true

func _ready() -> void:
	add_to_group("player")
	miaw.visible = false
func _input(event: InputEvent) -> void:
	camera_input(event)
	get_input_action()
	respawn_from_void()
	crosshair_is_visible()
	cursor_visible()
	terminal_system()
func _process(delta: float) -> void:
	camera()
	if terminal_open == 'inventory':
		terminal_display.text = json_conv("INVENTORY", inventory)
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
