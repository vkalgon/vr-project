extends Node

var inv := {}  # {"cao": 0, "mu": 0, "huo": 0, ...}

func add_item(id: String, n:=1):
	inv[id] = inv.get(id, 0) + n

func can_pay(cost: Dictionary) -> bool:
	for k in cost.keys():
		if inv.get(k, 0) < cost[k]:
			return false
	return true

func pay(cost: Dictionary) -> bool:
	if not can_pay(cost): return false
	for k in cost.keys():
		inv[k] -= cost[k]
	return true
