extends Node3D

const PLAYER = preload("res://scenes/Player.tscn")
const ZONE_COLORS = [Color("#8bd65c"), Color("#63c9d9"), Color("#b58bff"), Color("#ff9b55")]
const EGG_COLORS = [Color("#f5e7c6"), Color("#66d9e8"), Color("#b98cff"), Color("#ffbf55")]
const EGG_NAMES = ["Лесное яйцо", "Ледяное яйцо", "Кристальное яйцо", "Солнечное яйцо"]
const EGG_COSTS = [0, 250, 900, 2500]
const PET_INCOME = [4, 12, 35, 90]

var player: CharacterBody3D
var world_ui: CanvasLayer
var stats_label: Label
var hint_label: Label
var toast_label: Label
var action_button: Button
var upgrade_button: Button
var eggs: Array[Node3D] = []
var pets: Array[Node3D] = []
var coins := 100
var speed_level := 1
var carried_egg: Node3D
var carried_type := -1
var incubating := false
var hatch_time := 0.0
var income_timer := 0.0
var toast_timer := 0.0
var guard: Node3D
var guard_active := false
var base_center := Vector3(0, 0, 18)
var camera_drag := false
var touch_origin := Vector2.ZERO

func _ready() -> void:
    randomize()
    _make_environment()
    _make_island()
    _make_base()
    _make_zones()
    _make_road()
    _make_eggs()
    _make_guard()
    player = PLAYER.instantiate()
    add_child(player)
    player.global_position = Vector3(0, 0.15, 23)
    player.main = self
    _make_ui()
    _update_ui()
    say("Добро пожаловать! Укради яйцо и принеси его на свою базу 🥚")

func _make_environment() -> void:
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color("#4a9ce0")
    sky_mat.sky_horizon_color = Color("#c6edff")
    sky_mat.ground_bottom_color = Color("#5b8d58")
    sky_mat.ground_horizon_color = Color("#b5d8a0")
    env.sky.sky_material = sky_mat
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#d5eaff")
    env.ambient_light_energy = 0.85
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.glow_enabled = true
    env.glow_intensity = 0.35
    var we := WorldEnvironment.new()
    we.environment = env
    add_child(we)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -25, 0)
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    add_child(sun)

func _mat(color: Color, rough := 0.8, metal := 0.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = rough
    m.metallic = metal
    return m

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, collision := false, rough := 0.8) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    var shape := BoxMesh.new()
    shape.size = size
    mesh.mesh = shape
    mesh.material_override = _mat(color, rough)
    mesh.position = pos
    parent.add_child(mesh)
    if collision:
        var body := StaticBody3D.new()
        body.position = pos
        parent.add_child(body)
        var visual := MeshInstance3D.new()
        visual.mesh = shape
        visual.visible = false
        body.add_child(visual)
        var col := CollisionShape3D.new()
        var cs := BoxShape3D.new()
        cs.size = size
        col.shape = cs
        body.add_child(col)
    return mesh

func _make_island() -> void:
    var ground := StaticBody3D.new()
    add_child(ground)
    var disc := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 58
    cylinder.bottom_radius = 52
    cylinder.height = 2.5
    disc.mesh = cylinder
    disc.material_override = _mat(Color("#78c957"))
    disc.position.y = -1.25
    ground.add_child(disc)
    var col := CollisionShape3D.new()
    var cs := CylinderShape3D.new()
    cs.radius = 58
    cs.height = 2.5
    col.shape = cs
    col.position.y = -1.25
    ground.add_child(col)
    var water := MeshInstance3D.new()
    var ocean := PlaneMesh.new()
    ocean.size = Vector2(300, 300)
    water.mesh = ocean
    water.material_override = _mat(Color("#38b9df"), 0.25, 0.12)
    water.position.y = -2.7
    add_child(water)
    for i in range(90):
        var a := randf() * TAU
        var r := randf_range(31, 55)
        var p := Vector3(cos(a) * r, 0, sin(a) * r)
        _tree(p, randf_range(0.7, 1.3))

func _tree(p: Vector3, scale_factor: float) -> void:
    var root := Node3D.new()
    root.position = p
    add_child(root)
    var trunk := MeshInstance3D.new()
    var cyl := CylinderMesh.new()
    cyl.top_radius = 0.22 * scale_factor
    cyl.bottom_radius = 0.34 * scale_factor
    cyl.height = 2.0 * scale_factor
    trunk.mesh = cyl
    trunk.material_override = _mat(Color("#9b653e"))
    trunk.position.y = scale_factor
    root.add_child(trunk)
    for j in range(3):
        var crown := MeshInstance3D.new()
        var cone := SphereMesh.new()
        cone.radius = (1.0 - j * 0.13) * scale_factor
        cone.height = 1.45 * scale_factor
        crown.mesh = cone
        crown.material_override = _mat([Color("#3d9b50"), Color("#55b85b"), Color("#78cc62")][j])
        crown.position = Vector3(0, (2.0 + j * 0.65) * scale_factor, 0)
        root.add_child(crown)

func _make_base() -> void:
    var base := Node3D.new()
    base.position = base_center
    add_child(base)
    _box(base, Vector3(0, 0.08, 0), Vector3(15, 0.3, 13), Color("#f1d58a"))
    _box(base, Vector3(0, 0.27, 0), Vector3(13.5, 0.16, 11.5), Color("#fff0bd"))
    for x in [-6.0, 6.0]:
        for z in [-5.0, 5.0]:
            var post := MeshInstance3D.new()
            var cylinder := CylinderMesh.new()
            cylinder.top_radius = 0.22
            cylinder.bottom_radius = 0.28
            cylinder.height = 2.3
            post.mesh = cylinder
            post.material_override = _mat(Color("#a86d40"))
            post.position = Vector3(x, 1.3, z)
            base.add_child(post)
    _box(base, Vector3(0, 1.0, -5.2), Vector3(12.5, 1.6, 0.35), Color("#f3b957"))
    _box(base, Vector3(-6.2, 1.0, 0), Vector3(0.35, 1.6, 10.5), Color("#f3b957"))
    _box(base, Vector3(6.2, 1.0, 0), Vector3(0.35, 1.6, 10.5), Color("#f3b957"))
    _box(base, Vector3(0, 0.5, -5.0), Vector3(3.0, 0.8, 0.18), Color("#fff7dc"))
    _make_sign(base, Vector3(0, 3.1, -5.4), "ТВОЯ БАЗА", Color("#ffcf55"))
    _make_nest(base, Vector3(0, 0.45, 0))
    _make_treadmill(base, Vector3(4.0, 0.35, 2.0))

func _make_sign(parent: Node3D, pos: Vector3, title: String, color: Color) -> void:
    var sign := MeshInstance3D.new()
    var b := BoxMesh.new()
    b.size = Vector3(4.8, 0.9, 0.18)
    sign.mesh = b
    sign.material_override = _mat(color)
    sign.position = pos
    parent.add_child(sign)
    var label := Label3D.new()
    label.text = title
    label.font_size = 48
    label.pixel_size = 0.008
    label.modulate = Color("#53351e")
    label.position = pos + Vector3(0, -0.13, 0.12)
    parent.add_child(label)

func _make_nest(parent: Node3D, pos: Vector3) -> void:
    var nest := MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 0.7
    torus.outer_radius = 1.0
    nest.mesh = torus
    nest.material_override = _mat(Color("#b77a39"))
    nest.position = pos
    nest.rotation_degrees.x = 90
    parent.add_child(nest)
    var label := Label3D.new()
    label.text = "ГНЕЗДО • ВЫЛУПЛЕНИЕ"
    label.font_size = 26
    label.pixel_size = 0.009
    label.modulate = Color("#67421f")
    label.position = pos + Vector3(0, 1.25, 0)
    parent.add_child(label)

func _make_treadmill(parent: Node3D, pos: Vector3) -> void:
    var belt := MeshInstance3D.new()
    var b := BoxMesh.new()
    b.size = Vector3(2.3, 0.3, 3.3)
    belt.mesh = b
    belt.material_override = _mat(Color("#36a9d6"), 0.45, 0.15)
    belt.position = pos
    parent.add_child(belt)
    for z in [-1.0, 0.0, 1.0]:
        var stripe := MeshInstance3D.new()
        var s := BoxMesh.new()
        s.size = Vector3(1.7, 0.04, 0.08)
        stripe.mesh = s
        stripe.material_override = _mat(Color("#d5f5ff"))
        stripe.position = pos + Vector3(0, 0.18, z)
        parent.add_child(stripe)
    _make_sign(parent, pos + Vector3(0, 1.0, 1.8), "ТРЕНИРОВКА СКОРОСТИ", Color("#69d5ee"))

func _make_zones() -> void:
    var centers := [Vector3(0, 0, -16), Vector3(-19, 0, -22), Vector3(20, 0, -25), Vector3(0, 0, -43)]
    var names := ["ЛЕСНОЙ МИР", "ЛЕДЯНЫЕ ГОРЫ", "КРИСТАЛЬНАЯ ДОЛИНА", "СОЛНЕЧНЫЙ КРАЙ"]
    for i in range(centers.size()):
        var pad := MeshInstance3D.new()
        var c := CylinderMesh.new()
        c.top_radius = 8.0
        c.bottom_radius = 8.0
        c.height = 0.22
        pad.mesh = c
        pad.material_override = _mat(ZONE_COLORS[i])
        pad.position = centers[i] + Vector3(0, 0.05, 0)
        add_child(pad)
        var ring := MeshInstance3D.new()
        var torus := TorusMesh.new()
        torus.inner_radius = 7.8
        torus.outer_radius = 8.1
        ring.mesh = torus
        ring.material_override = _mat(Color("#fff5cb"), 0.3, 0.15)
        ring.position = centers[i] + Vector3(0, 0.2, 0)
        ring.rotation_degrees.x = 90
        add_child(ring)
        var sign := Label3D.new()
        sign.text = names[i]
        sign.font_size = 48
        sign.pixel_size = 0.009
        sign.modulate = Color("#ffffff")
        sign.position = centers[i] + Vector3(0, 2.3, -6.7)
        add_child(sign)
        if i > 0:
            _box(self, centers[i] + Vector3(0, 0.12, 0), Vector3(3.5, 0.22, 3.5), Color("#fff0c6"))

func _make_road() -> void:
    var road := MeshInstance3D.new()
    var p := BoxMesh.new()
    p.size = Vector3(5.0, 0.16, 47.0)
    road.mesh = p
    road.material_override = _mat(Color("#f6dca1"))
    road.position = Vector3(0, 0.08, -12)
    add_child(road)
    for z in range(-34, 12, 4):
        _box(self, Vector3(0, 0.18, z), Vector3(0.16, 0.025, 1.4), Color("#fff8dc"))

func _make_eggs() -> void:
    var positions := [Vector3(0, 0, -16), Vector3(-19, 0, -22), Vector3(20, 0, -25), Vector3(0, 0, -43)]
    for i in range(4):
        _spawn_egg(i, positions[i])

func _spawn_egg(kind: int, pos: Vector3) -> void:
    var egg := Node3D.new()
    egg.position = pos + Vector3(0, 1.1, 0)
    egg.set_meta("kind", kind)
    egg.set_meta("home", pos)
    egg.add_to_group("world_egg")
    add_child(egg)
    var shell := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.72
    sphere.height = 1.55
    shell.mesh = sphere
    shell.material_override = _mat(EGG_COLORS[kind], 0.24, 0.05)
    egg.add_child(shell)
    var spotmat := _mat(Color("#ffffff"), 0.3)
    for j in range(5):
        var spot := MeshInstance3D.new()
        var s := SphereMesh.new()
        s.radius = 0.09 if j % 2 == 0 else 0.13
        spot.mesh = s
        spot.material_override = spotmat
        spot.position = Vector3(sin(float(j) * 1.25) * 0.48, cos(float(j) * 1.8) * 0.4, 0.55)
        egg.add_child(spot)
    var glow := OmniLight3D.new()
    glow.light_color = EGG_COLORS[kind]
    glow.light_energy = 0.65
    glow.omni_range = 4.0
    egg.add_child(glow)
    var label := Label3D.new()
    label.text = EGG_NAMES[kind] + "\nЗАБРАТЬ"
    label.font_size = 30
    label.pixel_size = 0.008
    label.modulate = Color("#ffffff")
    label.position.y = 1.25
    egg.add_child(label)
    var area := Area3D.new()
    var cs := SphereShape3D.new()
    cs.radius = 1.6
    var col := CollisionShape3D.new()
    col.shape = cs
    area.add_child(col)
    egg.add_child(area)
    eggs.append(egg)
    var tween := create_tween().set_loops()
    tween.tween_property(egg, "position:y", pos.y + 1.35, 0.9).set_trans(Tween.TRANS_SINE)
    tween.tween_property(egg, "position:y", pos.y + 1.0, 0.9).set_trans(Tween.TRANS_SINE)

func _make_guard() -> void:
    guard = Node3D.new()
    guard.position = Vector3(0, 0, -19)
    add_child(guard)
    var body := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.95
    sphere.height = 1.8
    body.mesh = sphere
    body.material_override = _mat(Color("#ef6d5d"))
    body.position.y = 0.95
    guard.add_child(body)
    var eye_mat := _mat(Color("#fff5dc"))
    for x in [-0.3, 0.3]:
        var eye := MeshInstance3D.new()
        var e := SphereMesh.new()
        e.radius = 0.16
        eye.mesh = e
        eye.material_override = eye_mat
        eye.position = Vector3(x, 1.2, 0.78)
        guard.add_child(eye)
    var label := Label3D.new()
    label.text = "СТРАЖ"
    label.font_size = 26
    label.pixel_size = 0.01
    label.position.y = 2.2
    guard.add_child(label)

func _make_ui() -> void:
    world_ui = CanvasLayer.new()
    add_child(world_ui)
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 14)
    panel.add_theme_stylebox_override("panel", _panel_style())
    world_ui.add_child(panel)
    stats_label = Label.new()
    stats_label.add_theme_font_size_override("font_size", 19)
    stats_label.add_theme_color_override("font_color", Color("#fff7dc"))
    panel.add_child(stats_label)
    hint_label = Label.new()
    hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint_label.add_theme_font_size_override("font_size", 17)
    hint_label.add_theme_color_override("font_color", Color("#fff7dc"))
    world_ui.add_child(hint_label)
    toast_label = Label.new()
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_label.add_theme_font_size_override("font_size", 22)
    toast_label.add_theme_color_override("font_color", Color("#ffe18b"))
    world_ui.add_child(toast_label)
    action_button = _button("🥚  ВЗЯТЬ ЯЙЦО")
    action_button.pressed.connect(_interact)
    world_ui.add_child(action_button)
    upgrade_button = _button("⚡  УЛУЧШИТЬ")
    upgrade_button.pressed.connect(_upgrade_speed)
    world_ui.add_child(upgrade_button)
    _layout_ui()
    get_viewport().size_changed.connect(_layout_ui)

func _panel_style() -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color(0.08, 0.16, 0.23, 0.88)
    s.border_color = Color("#ffe08a")
    s.set_border_width_all(2)
    s.set_corner_radius_all(16)
    s.content_margin_left = 15
    s.content_margin_right = 15
    s.content_margin_top = 10
    s.content_margin_bottom = 10
    return s

func _button(text_value: String) -> Button:
    var b := Button.new()
    b.text = text_value
    b.custom_minimum_size = Vector2(170, 58)
    b.add_theme_font_size_override("font_size", 16)
    b.add_theme_color_override("font_color", Color("#ffffff"))
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color("#208dca")
    normal.border_color = Color("#b9edff")
    normal.set_border_width_all(2)
    normal.set_corner_radius_all(18)
    b.add_theme_stylebox_override("normal", normal)
    var hover := normal.duplicate()
    hover.bg_color = Color("#36b5e8")
    b.add_theme_stylebox_override("hover", hover)
    b.add_theme_stylebox_override("pressed", hover)
    return b

func _layout_ui() -> void:
    if not is_instance_valid(stats_label):
        return
    var size := get_viewport().get_visible_rect().size
    var portrait := size.y > size.x
    action_button.position = Vector2(size.x - (184 if not portrait else 176), size.y - (150 if not portrait else 224))
    upgrade_button.position = Vector2(size.x - (184 if not portrait else 176), size.y - (82 if not portrait else 150))
    action_button.custom_minimum_size = Vector2(168, 58)
    upgrade_button.custom_minimum_size = Vector2(168, 58)
    hint_label.position = Vector2(170, 16)
    hint_label.size = Vector2(maxf(100, size.x - 360), 58)
    toast_label.position = Vector2(30, size.y * 0.22)
    toast_label.size = Vector2(size.x - 60, 60)

func _process(delta: float) -> void:
    income_timer += delta
    if income_timer >= 1.0:
        income_timer = 0.0
        for pet in pets:
            coins += int(pet.get_meta("income", 1))
        _update_ui()
    if incubating:
        hatch_time -= delta
        if hatch_time <= 0.0:
            _hatch_pet()
    if toast_timer > 0.0:
        toast_timer -= delta
        if toast_timer <= 0.0:
            toast_label.text = ""
    if carried_egg != null:
        carried_egg.position = player.global_position + Vector3(0, 2.3, 0)
        carried_egg.rotation.y += delta * 1.8
        guard_active = true
        var direction := player.global_position - guard.global_position
        direction.y = 0
        if direction.length() > 1.5:
            guard.global_position += direction.normalized() * delta * 3.6
        if direction.length() < 1.7:
            _drop_carried_egg()
            say("Страж догнал тебя! Яйцо потеряно 😵")
    else:
        guard_active = false
        guard.global_position = guard.global_position.move_toward(Vector3(0, 0, -19), delta * 2.0)
    if player.global_position.distance_to(base_center) < 7.0 and carried_egg != null:
        _deposit_egg()
    var near := _nearest_egg()
    if carried_egg == null and near != null:
        hint_label.text = "Подойди и нажми ВЗЯТЬ ЯЙЦО • " + EGG_NAMES[int(near.get_meta("kind"))]
    elif carried_egg != null:
        hint_label.text = "НЕСИ ЯЙЦО НА БАЗУ! Страж уже рядом!"
    elif incubating:
        hint_label.text = "Яйцо вылупляется... осталось %.0f сек." % hatch_time
    else:
        hint_label.text = "Кради яйца • неси на базу • собирай питомцев"
    if player.global_position.distance_to(base_center + Vector3(4, 0, 2)) < 3.0:
        upgrade_button.modulate = Color("#ffffff")
    else:
        upgrade_button.modulate = Color(1, 1, 1, 0.72)

func _nearest_egg() -> Node3D:
    var best: Node3D
    var distance := 3.3
    for egg in eggs:
        if is_instance_valid(egg):
            var d := player.global_position.distance_to(egg.global_position)
            if d < distance:
                distance = d
                best = egg
    return best

func _interact() -> void:
    if carried_egg != null:
        say("Яйцо уже у тебя! Беги к базе 🏃")
        return
    var egg := _nearest_egg()
    if egg == null:
        say("Подойди ближе к яйцу.")
        return
    var kind := int(egg.get_meta("kind"))
    if speed_level < kind + 1:
        say("Нужен уровень скорости %d!" % (kind + 1))
        return
    carried_type = kind
    carried_egg = egg
    eggs.erase(egg)
    egg.reparent(self)
    egg.position = player.global_position + Vector3(0, 2.3, 0)
    say("ЯЙЦО УКРАДЕНО! Уноси его на базу!")
    _update_ui()

func _deposit_egg() -> void:
    if carried_egg == null or incubating:
        return
    carried_egg.queue_free()
    carried_egg = null
    incubating = true
    hatch_time = 6.0
    say("Яйцо в гнезде! Скоро вылупится питомец 🐣")
    _update_ui()

func _hatch_pet() -> void:
    incubating = false
    var kind := carried_type
    var pet := Node3D.new()
    pet.position = base_center + Vector3(randf_range(-2.5, 2.5), 0.8, randf_range(-2.0, 2.0))
    pet.set_meta("income", PET_INCOME[kind])
    add_child(pet)
    var body := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.62
    sphere.height = 1.1
    body.mesh = sphere
    body.material_override = _mat(EGG_COLORS[kind], 0.3)
    pet.add_child(body)
    var face := Label3D.new()
    face.text = ["🐰", "🐧", "🦄", "🐲"][kind]
    face.font_size = 72
    face.pixel_size = 0.012
    face.position = Vector3(0, 0.15, 0.62)
    pet.add_child(face)
    var sparkle := OmniLight3D.new()
    sparkle.light_color = EGG_COLORS[kind]
    sparkle.light_energy = 0.7
    sparkle.omni_range = 3
    pet.add_child(sparkle)
    pets.append(pet)
    var tween := create_tween().set_loops()
    tween.tween_property(pet, "position:y", pet.position.y + 0.35, 0.55)
    tween.tween_property(pet, "position:y", pet.position.y, 0.55)
    say("НОВЫЙ ПИТОМЕЦ! +%d монет/сек 🎉" % PET_INCOME[kind])
    carried_type = -1
    _update_ui()

func _drop_carried_egg() -> void:
    if carried_egg != null:
        carried_egg.queue_free()
        carried_egg = null
    carried_type = -1
    guard_active = false
    _update_ui()

func _upgrade_speed() -> void:
    if player.global_position.distance_to(base_center + Vector3(4, 0, 2)) > 4.0:
        say("Подойди к синей беговой дорожке на базе.")
        return
    var cost := speed_level * 150
    if coins < cost:
        say("Не хватает монет! Нужно %d 🪙" % cost)
        return
    coins -= cost
    speed_level += 1
    player.speed = 5.2 + float(speed_level - 1) * 1.35
    say("СКОРОСТЬ УЛУЧШЕНА! Уровень %d ⚡" % speed_level)
    _update_ui()

func _update_ui() -> void:
    if not is_instance_valid(stats_label):
        return
    var income := 0
    for pet in pets:
        income += int(pet.get_meta("income", 0))
    stats_label.text = "🪙 %d    ⚡ ур. %d\n🐾 %d питомцев  •  +%d/сек" % [coins, speed_level, pets.size(), income]
    upgrade_button.text = "⚡ УЛУЧШИТЬ • %d" % (speed_level * 150)

func say(message: String) -> void:
    if is_instance_valid(toast_label):
        toast_label.text = message
        toast_timer = 3.2

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_origin = event.position
            camera_drag = event.position.x > get_viewport().get_visible_rect().size.x * 0.42
        else:
            camera_drag = false
            player.set_touch_move(Vector2.ZERO)
    elif event is InputEventScreenDrag:
        if camera_drag:
            player.rotate_camera(event.relative)
        else:
            player.set_touch_move((event.relative / 70.0).limit_length(1.0))
    elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        player.rotate_camera(event.relative)
    elif event is InputEventKey and event.pressed:
        if event.keycode == KEY_E or event.keycode == KEY_SPACE:
            _interact()
        elif event.keycode == KEY_ESCAPE:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
