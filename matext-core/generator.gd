extends Area3D

@onready var label = $Label3D
@onready var this = $CollisionShape3D
var players_inside = []
var id = {
	'status': {'name': 'GENERATOR', 'item_produced': 'materials', 'level': 1, 'items_per_tick': 15, 'upgrade_costs': 50, },
	'menu': { 'move forward' : 'upgrade', 'move back' : 'upgrade max' }}
func terminal(command, user):
	if 'money' in user.inventory:
		if command == 'up':
			if user.inventory['money'] > id['status']['upgrade_costs']:
				upgrade(user)
				return 'back_to_status'
			else:
				return 'display: not enough'
		elif command == 'down':
			while user.inventory['money'] > id['status']['upgrade_costs']:
				upgrade(user)
				return 'back_to_status'
func upgrade(user):
	id['status']['level'] += 1
	id['status']['items_per_tick'] *= 2
	id['status']['upgrade_costs'] *= 2
	user.inventory['money'] -= id['status']['upgrade_costs']
	var text_label = str(id['status']['name']) + "\nLvl: " + str(id['status']['level'])
	label.text = text_label

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group('player'):
		this.visible = false
		players_inside.append(body)
		$Timer.start(1)
func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group('player'):
		this.visible = true
		players_inside.erase(body)
		$Timer.stop()
func _on_timer_timeout() -> void:
	for player in players_inside:
		if 'materials' in player.inventory:
			player.inventory[id['status']['item_produced']] += int(id['status']['items_per_tick'])
		else:
			player.inventory['materials'] = 0
