extends Node2D
const PlayerScene = preload("res://scenes/Player.tscn")
const EnemyScript = preload("res://scripts/enemies/enemy.gd")
const SaveSystem = preload("res://scripts/save_system.gd")
var player
var loot: Array[Dictionary] = []
var touch_move := Vector2.ZERO
var touch_origin := Vector2.ZERO
var touch_id := -1
var inventory_open := false
var survival_tick := 0.0
var autosave_tick := 0.0
var recovery_tick := 0.0
var message := "Черноград. День 1. Найдите припасы."
var message_time := 5.0
var hud: CanvasLayer
var status_label: Label
var message_label: Label
var inventory_panel: Panel
var inventory_label: Label

func _ready() -> void:
    randomize()
    player = PlayerScene.instantiate()
    player.position = Vector2(640, 360)
    add_child(player)
    player.main = self
    _spawn_enemy(Vector2(850, 310), "Обычный заражённый")
    _spawn_enemy(Vector2(400, 520), "Быстрый заражённый")
    _spawn_enemy(Vector2(1020, 560), "Обычный заражённый")
    _spawn_loot(Vector2(540, 260), "Бинт", 1)
    _spawn_loot(Vector2(720, 490), "Консервы", 2)
    _spawn_loot(Vector2(300, 300), "Вода", 1)
    _build_hud()
    SaveSystem.load_game(player)

func _process(delta: float) -> void:
    if message_time > 0.0:
        message_time -= delta
        message_label.text = message if message_time > 0.0 else ""
    if is_instance_valid(player):
        status_label.text = "ЗДОРОВЬЕ %d   ГОЛОД %d   ЖАЖДА %d   УРОВЕНЬ %d   ОПЫТ %d" % [player.health, player.hunger, player.thirst, player.level, player.xp]
    if Input.is_action_just_pressed("inventory"): _toggle_inventory()
    if Input.is_action_just_pressed("interact"): _interact()
    if Input.is_action_just_pressed("attack"): player.try_attack()
    survival_tick += delta
    autosave_tick += delta
    recovery_tick += delta
    if recovery_tick >= 4.0:
        recovery_tick = 0.0
        player.energy = mini(100, player.energy + 2)
    if survival_tick >= 45.0:
        survival_tick = 0.0
        player.hunger = maxi(0, player.hunger - 1)
        player.thirst = maxi(0, player.thirst - 1)
        if player.hunger <= 0 or player.thirst <= 0: player.take_damage(2)
    if autosave_tick >= 30.0:
        autosave_tick = 0.0
        SaveSystem.save_game(player)

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color("#202a27"))
    draw_rect(Rect2(0, 310, 1280, 130), Color("#343a38"))
    draw_rect(Rect2(580, 0, 125, 720), Color("#343a38"))
    for x in range(0, 1280, 90): draw_line(Vector2(x, 375), Vector2(x + 45, 375), Color("#8a8062"), 3)
    _building(Rect2(65, 55, 300, 205), "ЖИЛОЙ ДОМ")
    _building(Rect2(790, 55, 390, 190), "ЗАБРОШЕННЫЙ МАГАЗИН")
    _building(Rect2(70, 500, 260, 155), "ГАРАЖ")
    _building(Rect2(850, 490, 330, 170), "СКЛАД")
    for entry in loot:
        if not entry.taken: draw_circle(entry.pos, 9, Color("#e4b45e"))

func _building(rect: Rect2, label: String) -> void:
    draw_rect(rect, Color("#414845"))
    draw_rect(rect, Color("#68716a"), false, 5)
    for x in range(int(rect.position.x + 28), int(rect.end.x - 20), 72):
        draw_rect(Rect2(x, rect.position.y + 35, 36, 42), Color("#202b2c"))
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(12, rect.size.y - 15), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#c2bca7"))

func _spawn_enemy(pos: Vector2, kind: String) -> void:
    var enemy := CharacterBody2D.new()
    enemy.set_script(EnemyScript)
    enemy.position = pos
    enemy.enemy_name = kind
    add_child(enemy)
    enemy.target = player

func _spawn_loot(pos: Vector2, item: String, amount: int) -> void:
    loot.append({"pos": pos, "item": item, "amount": amount, "taken": false})
    queue_redraw()

func _build_hud() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    var top := Panel.new()
    top.position = Vector2(14, 12)
    top.size = Vector2(620, 48)
    hud.add_child(top)
    status_label = Label.new()
    status_label.position = Vector2(12, 8)
    status_label.size = Vector2(600, 32)
    status_label.add_theme_font_size_override("font_size", 16)
    top.add_child(status_label)
    message_label = Label.new()
    message_label.position = Vector2(14, 70)
    message_label.size = Vector2(800, 32)
    message_label.add_theme_font_size_override("font_size", 18)
    hud.add_child(message_label)
    _add_button("УДАР", Vector2(1090, 570), Vector2(150, 62), func(): player.try_attack())
    _add_button("ОБЫСКАТЬ [E]", Vector2(900, 645), Vector2(210, 48), _interact)
    _add_button("РЮКЗАК [I]", Vector2(1110, 645), Vector2(150, 48), _toggle_inventory)
    _add_button("СОХРАНИТЬ", Vector2(14, 650), Vector2(150, 42), _save_game)
    inventory_panel = Panel.new()
    inventory_panel.position = Vector2(380, 145)
    inventory_panel.size = Vector2(520, 420)
    inventory_panel.visible = false
    hud.add_child(inventory_panel)
    inventory_label = Label.new()
    inventory_label.position = Vector2(24, 22)
    inventory_label.size = Vector2(470, 300)
    inventory_panel.add_child(inventory_label)
    _add_button("БИНТ", Vector2(398, 505), Vector2(105, 42), func(): _use_inventory_item("Бинт"))
    _add_button("ЕДА", Vector2(510, 505), Vector2(105, 42), func(): _use_inventory_item("Консервы"))
    _add_button("ВОДА", Vector2(622, 505), Vector2(105, 42), func(): _use_inventory_item("Вода"))

func _add_button(caption: String, pos: Vector2, size: Vector2, action: Callable) -> void:
    var b := Button.new()
    b.text = caption
    b.position = pos
    b.size = size
    b.pressed.connect(action)
    hud.add_child(b)

func _toggle_inventory() -> void:
    inventory_open = not inventory_open
    inventory_panel.visible = inventory_open
    if inventory_open:
        var lines := "РЮКЗАК ВЫЖИВШЕГО\n\n"
        for item in player.inventory.keys(): lines += "• %s — %d\n" % [item, player.inventory[item]]
        lines += "\nВместимость: %d / 20" % player.inventory.size()
        inventory_label.text = lines

func _use_inventory_item(item_name: String) -> void:
    var before: int = int(player.inventory.get(item_name, 0))
    if before <= 0:
        _notify("В рюкзаке нет: %s" % item_name)
        return
    player.use_item(item_name)
    _notify("Использовано: %s" % item_name)
    if inventory_open:
        _toggle_inventory()
        _toggle_inventory()

func _interact() -> void:
    var index := -1
    var nearest := 72.0
    for i in range(loot.size()):
        if loot[i].taken: continue
        var d: float = player.global_position.distance_to(loot[i].pos)
        if d < nearest: nearest = d; index = i
    if index >= 0:
        var item: Dictionary = loot[index]
        loot[index].taken = true
        player.add_item(item.item, int(item.amount))
        _notify("Найдено: %s ×%d" % [item.item, item.amount])
        queue_redraw()
    else: _notify("Рядом нет припасов.")

func _notify(value: String) -> void:
    message = value
    message_time = 3.0

func _save_game() -> void:
    SaveSystem.save_game(player)
    _notify("Прогресс сохранён.")

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and event.position.x < get_viewport_rect().size.x * 0.48:
            touch_id = event.index
            touch_origin = event.position
            touch_move = Vector2.ZERO
        elif not event.pressed and event.index == touch_id:
            touch_id = -1
            touch_move = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == touch_id:
        touch_move = ((event.position - touch_origin) / 55.0).limit_length(1.0)

func get_touch_move() -> Vector2:
    return touch_move

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST: _save_game()
