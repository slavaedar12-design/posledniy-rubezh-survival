extends CharacterBody2D
var enemy_name := "Обычный заражённый"
var target
var health := 55
var speed := 72.0
var attack_timer := 0.0
var attack_range := 32.0

func _ready() -> void:
    add_to_group("enemies")
    if enemy_name == "Быстрый заражённый": health = 35; speed = 118.0
    elif enemy_name == "Бронированный заражённый": health = 120; speed = 48.0

func _physics_process(delta: float) -> void:
    attack_timer = maxf(0.0, attack_timer - delta)
    if not is_instance_valid(target) or target.health <= 0:
        velocity = Vector2.ZERO
        return
    var distance := global_position.distance_to(target.global_position)
    if distance < 330.0 and distance > attack_range:
        velocity = global_position.direction_to(target.global_position) * speed
    else:
        velocity = Vector2.ZERO
        if distance <= attack_range and attack_timer <= 0.0:
            target.take_damage(8)
            attack_timer = 1.15
    move_and_slide()
    queue_redraw()

func _draw() -> void:
    var color := Color("#8b9b72") if enemy_name == "Обычный заражённый" else Color("#b18b55")
    if enemy_name == "Бронированный заражённый": color = Color("#667078")
    draw_circle(Vector2.ZERO, 16, Color("#171b19"))
    draw_circle(Vector2.ZERO, 12, color)
    draw_circle(Vector2(-4, -3), 2, Color("#d84b3f"))
    draw_circle(Vector2(4, -3), 2, Color("#d84b3f"))

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        if is_instance_valid(target):
            target.xp += 15
            if target.xp >= target.level * 50:
                target.xp -= target.level * 50
                target.level += 1
                target.health = mini(100, target.health + 20)
                if is_instance_valid(target.main): target.main._notify("Новый уровень: %d" % target.level)
        queue_free()
