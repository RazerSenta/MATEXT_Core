extends Area3D

@onready var this = $CollisionShape3D/MeshInstance3D
var status = {
	'name' : 'SELL',
	'sell_materials': 15}

func sell(player):
	while player.inventory['materials'] > status['sell_materials']:
		player.inventory['materials'] -= status['sell_materials']
		player.inventory['money'] += 1
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		this.visible = false
		if 'materials' in body.inventory:
			if 'money' in body.inventory:
				sell(body)
			else:
				body.inventory['money'] = 0
				sell(body)
func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		this.visible = true
