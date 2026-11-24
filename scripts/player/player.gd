extends CharacterBody2D
var main
var speed := 210.0
var health := 100
var hunger := 100
var thirst := 100
var energy := 100
var level := 1
var xp := 0
var inventory: Dictionary = {"Нож": 1, "Ткань": 2, "Металлолом": 3}
var attack_cooldown := 0.0
var hurt_flash := 0.0

func _physics_process(delta: float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    hurt_flash = maxf(0.0, hurt_flash - delta)
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if is_instance_valid(main): direction += main.get_touch_move()
    velocity = direction.limit_length() * (speed if energy > 0 else speed * 0.65)
    move_and_slide()
    global_position.x = clampf(global_position.x, 18.0, 1262.0)
    global_position.y = clampf(global_position.y, 18.0, 702.0)
    queue_redraw()

func _draw() -> void:
    var body := Color("#c8c1a8") if hurt_flash <= 0 else Color("#e45a42")
    draw_circle(Vector2.ZERO, 17, Color("#111715"))
    draw_circle(Vector2(0, -2), 13, body)
    draw_circle(Vector2(0, -11), 7, Color("#d7b18c"))
    draw_rect(Rect2(-11, 8, 22, 10), Color("#4a5b50"))

func try_attack() -> void:
    if attack_cooldown > 0.0 or health <= 0: return
    attack_cooldown = 0.55
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if global_position.distance_to(enemy.global_position) <= 62.0:
            enemy.take_damage(28)
            energy = maxi(0, energy - 4)
            if is_instance_valid(main): main._notify("Удар попал по заражённому.")
            return
    if is_instance_valid(main): main._notify("Удар в пустоту.")

func take_damage(amount: int) -> void:
    if health <= 0: return
    health = maxi(0, health - amount)
    hurt_flash = 0.2
    if health <= 0 and is_instance_valid(main): main._notify("Вы погибли.")

func add_item(item: String, amount: int) -> void:
    inventory[item] = int(inventory.get(item, 0)) + amount

func use_item(item: String) -> void:
    if int(inventory.get(item, 0)) <= 0: return
    if item == "Бинт": health = mini(100, health + 30)
    elif item == "Консервы": hunger = mini(100, hunger + 35)
    elif item == "Вода": thirst = mini(100, thirst + 40)
    else: return
    inventory[item] -= 1
    if inventory[item] <= 0: inventory.erase(item)
