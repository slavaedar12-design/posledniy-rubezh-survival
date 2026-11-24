extends Node3D
const PLAYER = preload("res://scenes/Player.tscn")
var player
var inventory = {"Дерево":0,"Камень":0,"Металл":0,"Ткань":0}
var health=100.0
var hunger=100.0
var thirst=100.0
var hud: Label
var notice: Label
var notice_text=""
var notice_timer=0.0
var building=false
var preview: MeshInstance3D
var hud_panel: PanelContainer
var help_label: Label
var gather_button: Button
var build_button: Button

func _ready():
    _input_setup()
    _environment()
    _ground()
    _settlement()
    _forest()
    _loot()
    player=PLAYER.instantiate()
    add_child(player)
    player.global_position=Vector3(0,2,12)
    player.main=self
    _preview()
    _ui()
    Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
    say("Ты на острове. Исследуй поселение, собирай ресурсы и строй убежище.")

func _input_setup():
    var keys={"move_forward":KEY_W,"move_back":KEY_S,"move_left":KEY_A,"move_right":KEY_D,"sprint":KEY_SHIFT,"jump":KEY_SPACE,"interact":KEY_E,"inventory":KEY_TAB,"build":KEY_B}
    for a in keys:
        if not InputMap.has_action(a):
            InputMap.add_action(a)
            var e=InputEventKey.new()
            e.physical_keycode=keys[a]
            InputMap.action_add_event(a,e)
    if not InputMap.has_action("attack"):
        InputMap.add_action("attack")
        var e=InputEventMouseButton.new()
        e.button_index=MOUSE_BUTTON_LEFT
        InputMap.action_add_event("attack",e)

func _environment():
    var env=Environment.new()
    env.background_mode=Environment.BG_SKY
    env.sky=Sky.new()
    env.sky.sky_material=ProceduralSkyMaterial.new()
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color(0.62,0.68,0.75)
    env.ambient_light_energy=0.8
    env.fog_enabled=true
    env.fog_light_color=Color("#aab9b4")
    env.fog_density=0.0015
    var we=WorldEnvironment.new()
    we.environment=env
    add_child(we)
    var sun=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-48,-32,0)
    sun.light_energy=1.25
    sun.shadow_enabled=true
    add_child(sun)

func _ground():
    var body=StaticBody3D.new()
    add_child(body)
    var mesh=MeshInstance3D.new()
    var plane=PlaneMesh.new()
    plane.size=Vector2(180,180)
    mesh.mesh=plane
    var mat=StandardMaterial3D.new()
    mat.albedo_color=Color("#65794b")
    mat.roughness=1.0
    mat.albedo_texture=_noise_texture(0.035,5)
    mesh.material_override=mat
    body.add_child(mesh)
    var col=CollisionShape3D.new()
    var shape=BoxShape3D.new()
    shape.size=Vector3(180,1,180)
    col.shape=shape
    col.position.y=-0.5
    body.add_child(col)

func _settlement():
    _house(Vector3(-17,0,-15),Vector3(12,7,10),Color("#9b886b"))
    _house(Vector3(14,0,-23),Vector3(10,6,9),Color("#777b76"))
    _house(Vector3(31,0,9),Vector3(13,7,11),Color("#8b735b"))
    _house(Vector3(-32,0,20),Vector3(11,6,9),Color("#8a8270"))
    _house(Vector3(0,0,-43),Vector3(19,8,14),Color("#686e6b"))

func _house(p:Vector3,s:Vector3,c:Color):
    var root=StaticBody3D.new()
    root.position=p+Vector3(0,s.y/2,0)
    add_child(root)
    var wall=StandardMaterial3D.new()
    wall.albedo_color=c
    wall.roughness=0.96
    wall.albedo_texture=_noise_texture(0.08,4)
    var roof=StandardMaterial3D.new()
    roof.albedo_color=Color("#414744")
    roof.roughness=0.92
    roof.albedo_texture=_noise_texture(0.12,3)
    var door=StandardMaterial3D.new()
    door.albedo_color=Color("#493a2b")
    door.roughness=0.88
    door.albedo_texture=_noise_texture(0.16,3)
    _solid_box(root,Vector3(0,-s.y/2+0.2,0),Vector3(s.x,0.4,s.z),roof)
    _solid_box(root,Vector3(0,0,-s.z/2),Vector3(s.x,s.y,0.35),wall)
    _solid_box(root,Vector3(-s.x/2,0,0),Vector3(0.35,s.y,s.z),wall)
    _solid_box(root,Vector3(s.x/2,0,0),Vector3(0.35,s.y,s.z),wall)
    _solid_box(root,Vector3(0,0,s.z/2),Vector3(s.x,s.y,0.35),wall)
    _solid_box(root,Vector3(0,s.y/2+0.35,0),Vector3(s.x+1,0.7,s.z+1),roof)
    _solid_box(root,Vector3(0,-0.3,s.z/2+0.2),Vector3(1.7,3.4,0.15),door)
    var glass=StandardMaterial3D.new()
    glass.albedo_color=Color("#263d43")
    glass.roughness=0.22
    glass.metallic=0.18
    _solid_box(root,Vector3(-s.x/2-0.02,0.8,0),Vector3(0.08,1.5,2),glass)

func _solid_box(parent:Node3D,p:Vector3,s:Vector3,m:Material):
    var mesh=MeshInstance3D.new()
    var b=BoxMesh.new()
    b.size=s
    mesh.mesh=b
    mesh.material_override=m
    mesh.position=p
    parent.add_child(mesh)
    var col=CollisionShape3D.new()
    var sh=BoxShape3D.new()
    sh.size=s
    col.shape=sh
    col.position=p
    parent.add_child(col)

func _forest():
    var rng=RandomNumberGenerator.new()
    rng.randomize()
    for i in range(130):
        var p=Vector3(rng.randf_range(-82,82),0,rng.randf_range(-82,82))
        if Vector2(p.x,p.z).length()<43: continue
        _tree(p,rng.randf_range(0.8,1.35))

func _tree(p:Vector3,k:float):
    var root=StaticBody3D.new()
    root.position=p
    root.add_to_group("harvest")
    root.set_meta("kind","Дерево")
    root.set_meta("amount",4)
    add_child(root)
    var trunk=MeshInstance3D.new()
    var cm=CylinderMesh.new()
    cm.top_radius=0.2*k
    cm.bottom_radius=0.32*k
    cm.height=3.2*k
    trunk.mesh=cm
    var bark=StandardMaterial3D.new()
    bark.albedo_color=Color("#594431")
    bark.roughness=1.0
    bark.albedo_texture=_noise_texture(0.18,4)
    trunk.material_override=bark
    trunk.position.y=1.6*k
    root.add_child(trunk)
    var crown=MeshInstance3D.new()
    var sm=SphereMesh.new()
    sm.radius=1.55*k
    sm.height=3.2*k
    crown.mesh=sm
    var green=StandardMaterial3D.new()
    green.albedo_color=Color("#31583a")
    green.roughness=1.0
    green.albedo_texture=_noise_texture(0.07,5)
    crown.material_override=green
    crown.position.y=3.5*k
    root.add_child(crown)
    var col=CollisionShape3D.new()
    var cs=CylinderShape3D.new()
    cs.radius=0.48*k
    cs.height=3.2*k
    col.shape=cs
    col.position.y=1.6*k
    root.add_child(col)

func _loot():
    var rng=RandomNumberGenerator.new()
    rng.randomize()
    for i in range(35):
        var p=Vector3(rng.randf_range(-75,75),0,rng.randf_range(-75,75))
        if Vector2(p.x,p.z).length()<14: p.x+=28
        _rock(p,rng.randf_range(0.8,1.5))
    for i in range(24):
        _crate(Vector3(rng.randf_range(-40,40),0,rng.randf_range(-40,40)))

func _rock(p:Vector3,k:float):
    var root=StaticBody3D.new()
    root.position=p
    root.add_to_group("harvest")
    root.set_meta("kind","Камень")
    root.set_meta("amount",3)
    add_child(root)
    var mesh=MeshInstance3D.new()
    var sm=SphereMesh.new()
    sm.radius=k
    sm.height=k*1.4
    mesh.mesh=sm
    mesh.scale=Vector3(1.3,0.8,1)
    var m=StandardMaterial3D.new()
    m.albedo_color=Color("#777a76")
    m.roughness=0.98
    m.albedo_texture=_noise_texture(0.11,4)
    mesh.material_override=m
    mesh.position.y=k*0.55
    root.add_child(mesh)
    var col=CollisionShape3D.new()
    var sh=SphereShape3D.new()
    sh.radius=k
    col.shape=sh
    col.position.y=k*0.6
    root.add_child(col)

func _crate(p:Vector3):
    var root=StaticBody3D.new()
    root.position=p
    root.add_to_group("harvest")
    root.set_meta("kind","Ящик")
    root.set_meta("amount",1)
    add_child(root)
    var mesh=MeshInstance3D.new()
    var b=BoxMesh.new()
    b.size=Vector3(1.3,1,1.1)
    mesh.mesh=b
    var m=StandardMaterial3D.new()
    m.albedo_color=Color("#80613d")
    m.roughness=0.95
    m.albedo_texture=_noise_texture(0.16,4)
    mesh.material_override=m
    mesh.position.y=0.5
    root.add_child(mesh)
    var col=CollisionShape3D.new()
    var sh=BoxShape3D.new()
    sh.size=b.size
    col.shape=sh
    col.position.y=0.5
    root.add_child(col)

func _preview():
    preview=MeshInstance3D.new()
    var b=BoxMesh.new()
    b.size=Vector3(4,0.25,4)
    preview.mesh=b
    var m=StandardMaterial3D.new()
    m.albedo_color=Color(0.2,0.8,0.35,0.45)
    m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    preview.material_override=m
    preview.visible=false
    add_child(preview)

func _process(delta):
    hunger=maxf(0,hunger-delta*0.035)
    thirst=maxf(0,thirst-delta*0.055)
    if hunger<=0 or thirst<=0:
        health=maxf(0,health-delta*1.5)
    if notice_timer>0:
        notice_timer-=delta
        if is_instance_valid(notice):
            notice.text=notice_text if notice_timer>0 else ""
    if is_instance_valid(hud):
        hud.text="♥ %d     ГОЛОД %d     ЖАЖДА %d\\nДЕРЕВО %d   КАМЕНЬ %d   МЕТАЛЛ %d   ТКАНЬ %d" % [int(health),int(hunger),int(thirst),inventory["Дерево"],inventory["Камень"],inventory["Металл"],inventory["Ткань"]]
    if building:
        var target=player.global_position-player.global_transform.basis.z*5
        preview.global_position=Vector3(round(target.x/2)*2,0.15,round(target.z/2)*2)
    if Input.is_action_just_pressed("interact"):
        _interact()
    if Input.is_action_just_pressed("inventory"):
        say("РЮКЗАК: "+str(inventory))
    if Input.is_action_just_pressed("build"):
        _toggle_building()
    if building and Input.is_action_just_pressed("attack"):
        _place_wall()

func _interact():
    var from=player.camera.global_position
    var to=from-player.camera.global_transform.basis.z*5
    var q=PhysicsRayQueryParameters3D.create(from,to)
    q.exclude=[player.get_rid()]
    var hit=get_world_3d().direct_space_state.intersect_ray(q)
    if hit.is_empty():
        say("Наведи прицел на дерево, камень или ящик.")
        return
    var obj=hit.collider
    if obj is Node and obj.is_in_group("harvest"):
        var kind=obj.get_meta("kind")
        if kind=="Ящик":
            inventory["Металл"]+=randi_range(1,3)
            inventory["Ткань"]+=randi_range(0,2)
            say("Ящик обыскан: найден металлолом и ткань.")
        else:
            inventory[kind]+=int(obj.get_meta("amount"))
            say("Добыто: %s" % kind)
        obj.queue_free()
    else:
        say("Здесь нечего собирать.")

func _place_wall():
    if inventory["Дерево"]<10:
        say("Для стены нужно 10 дерева.")
        return
    inventory["Дерево"]-=10
    var root=StaticBody3D.new()
    root.position=preview.global_position+Vector3(0,1.5,0)
    add_child(root)
    var mat=StandardMaterial3D.new()
    mat.albedo_color=Color("#806044")
    mat.roughness=0.92
    mat.albedo_texture=_noise_texture(0.16,4)
    _solid_box(root,Vector3.ZERO,Vector3(4,3,0.25),mat)
    say("Деревянная стена построена.")

func _ui():
    var layer=CanvasLayer.new()
    add_child(layer)

    hud_panel=PanelContainer.new()
    hud_panel.add_theme_stylebox_override("panel",_panel_style(Color(0.055,0.075,0.065,0.86)))
    layer.add_child(hud_panel)
    hud=Label.new()
    hud.add_theme_font_size_override("font_size",18)
    hud.add_theme_color_override("font_color",Color("#e8e6d5"))
    hud.add_theme_constant_override("line_spacing",5)
    hud_panel.add_child(hud)

    notice=Label.new()
    notice.add_theme_font_size_override("font_size",18)
    notice.add_theme_color_override("font_color",Color("#f0c77c"))
    notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    notice.add_theme_color_override("font_shadow_color",Color(0,0,0,0.8))
    notice.add_theme_constant_override("shadow_offset_x",2)
    notice.add_theme_constant_override("shadow_offset_y",2)
    layer.add_child(notice)

    var cross=Label.new()
    cross.text="+"
    cross.set_anchors_preset(Control.PRESET_CENTER)
    cross.add_theme_font_size_override("font_size",27)
    cross.add_theme_color_override("font_color",Color(1,1,1,0.85))
    layer.add_child(cross)

    help_label=Label.new()
    help_label.text="WASD — движение   SHIFT — бег   E — сбор   B — строительство   TAB — рюкзак"
    help_label.add_theme_font_size_override("font_size",13)
    help_label.add_theme_color_override("font_color",Color("#e4e1d2"))
    help_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    layer.add_child(help_label)

    gather_button=_styled_button("СОБРАТЬ")
    gather_button.pressed.connect(_interact)
    layer.add_child(gather_button)

    build_button=_styled_button("СТРОИТЬ")
    build_button.pressed.connect(_toggle_building)
    layer.add_child(build_button)

    _layout_ui()
    get_viewport().size_changed.connect(_layout_ui)

func _panel_style(color:Color)->StyleBoxFlat:
    var style=StyleBoxFlat.new()
    style.bg_color=color
    style.border_color=Color(0.65,0.59,0.43,0.75)
    style.set_border_width_all(1)
    style.set_corner_radius_all(9)
    style.content_margin_left=14
    style.content_margin_right=14
    style.content_margin_top=10
    style.content_margin_bottom=10
    return style

func _styled_button(caption:String)->Button:
    var b=Button.new()
    b.text=caption
    b.custom_minimum_size=Vector2(138,54)
    b.add_theme_font_size_override("font_size",15)
    b.add_theme_color_override("font_color",Color("#f4efdc"))
    b.add_theme_color_override("font_hover_color",Color.WHITE)
    var normal=StyleBoxFlat.new()
    normal.bg_color=Color(0.12,0.17,0.13,0.91)
    normal.border_color=Color("#a18a5b")
    normal.set_border_width_all(1)
    normal.set_corner_radius_all(8)
    normal.content_margin_left=12
    normal.content_margin_right=12
    b.add_theme_stylebox_override("normal",normal)
    var pressed=normal.duplicate()
    pressed.bg_color=Color("#4b573d")
    b.add_theme_stylebox_override("pressed",pressed)
    b.add_theme_stylebox_override("hover",pressed)
    return b

func _layout_ui():
    if not is_instance_valid(hud_panel): return
    var view=get_viewport().get_visible_rect().size
    var portrait=view.y>view.x
    var margin=14.0
    hud_panel.position=Vector2(margin,margin)
    hud_panel.size=Vector2(minf(view.x-2*margin,440.0 if not portrait else view.x-2*margin),92 if not portrait else 112)
    hud_panel.custom_minimum_size=hud_panel.size
    hud_panel.get_child(0).text="♥ %d     ГОЛОД %d     ЖАЖДА %d\nДЕРЕВО %d   КАМЕНЬ %d\nМЕТАЛЛ %d   ТКАНЬ %d" % [int(health),int(hunger),int(thirst),inventory["Дерево"],inventory["Камень"],inventory["Металл"],inventory["Ткань"]]
    if portrait:
        gather_button.position=Vector2(view.x-154,view.y-150)
        build_button.position=Vector2(view.x-154,view.y-214)
        gather_button.custom_minimum_size=Vector2(140,56)
        build_button.custom_minimum_size=Vector2(140,56)
        help_label.position=Vector2(12,view.y-44)
        help_label.size=Vector2(view.x-24,30)
        help_label.text="Свайп слева — движение • справа — обзор"
        notice.position=Vector2(12,132)
        notice.size=Vector2(view.x-24,56)
    else:
        gather_button.position=Vector2(view.x-166,view.y-142)
        build_button.position=Vector2(view.x-166,view.y-207)
        gather_button.custom_minimum_size=Vector2(150,56)
        build_button.custom_minimum_size=Vector2(150,56)
        help_label.position=Vector2(220,view.y-38)
        help_label.size=Vector2(view.x-440,28)
        help_label.text="WASD — движение   SHIFT — бег   E — сбор   B — стройка   TAB — рюкзак"
        notice.position=Vector2(view.x*0.25,112)
        notice.size=Vector2(view.x*0.5,50)

func _toggle_building():
    building=not building
    preview.visible=building
    say("Режим строительства включён" if building else "Строительство выключено")

func _noise_texture(freq:float,octaves:int)->Texture2D:
    var noise=FastNoiseLite.new()
    noise.noise_type=FastNoiseLite.TYPE_SIMPLEX
    noise.frequency=freq
    noise.fractal_octaves=octaves
    noise.fractal_gain=0.55
    var texture=NoiseTexture2D.new()
    texture.width=256
    texture.height=256
    texture.seamless=true
    texture.noise=noise
    return texture

func say(t:String):
    notice_text=t
    notice_timer=4.0
    if is_instance_valid(notice): notice.text=t

func _input(event):
    if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
        player.rotate_camera(event.relative)
    elif event is InputEventScreenDrag:
        if event.position.x>get_viewport().get_visible_rect().size.x*0.45:
            player.rotate_camera(event.relative)
        else:
            player.set_touch_move((event.relative/65.0).limit_length(1))
    elif event is InputEventScreenTouch and not event.pressed:
        player.set_touch_move(Vector2.ZERO)
    elif event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
        Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
