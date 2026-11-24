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
    var roof=StandardMaterial3D.new()
    roof.albedo_color=Color("#414744")
    var door=StandardMaterial3D.new()
    door.albedo_color=Color("#493a2b")
    _solid_box(root,Vector3(0,-s.y/2+0.2,0),Vector3(s.x,0.4,s.z),roof)
    _solid_box(root,Vector3(0,0,-s.z/2),Vector3(s.x,s.y,0.35),wall)
    _solid_box(root,Vector3(-s.x/2,0,0),Vector3(0.35,s.y,s.z),wall)
    _solid_box(root,Vector3(s.x/2,0,0),Vector3(0.35,s.y,s.z),wall)
    _solid_box(root,Vector3(0,0,s.z/2),Vector3(s.x,s.y,0.35),wall)
    _solid_box(root,Vector3(0,s.y/2+0.35,0),Vector3(s.x+1,0.7,s.z+1),roof)
    _solid_box(root,Vector3(0,-0.3,s.z/2+0.2),Vector3(1.7,3.4,0.15),door)
    var glass=StandardMaterial3D.new()
    glass.albedo_color=Color("#263d43")
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
    if hunger<=0 or thirst<=0: health=maxf(0,health-delta*1.5)
    if notice_timer>0:
        notice_timer-=delta
        notice.text=notice_text if notice_timer>0 else ""
    hud.text="♥ %d     ГОЛОД %d     ЖАЖДА %d\nДЕРЕВО %d   КАМЕНЬ %d   МЕТАЛЛ %d   ТКАНЬ %d" % [int(health),int(hunger),int(thirst),inventory["Дерево"],inventory["Камень"],inventory["Металл"],inventory["Ткань"]]
    if building:
        var target=player.global_position-player.global_transform.basis.z*5
        preview.global_position=Vector3(round(target.x/2)*2,0.15,round(target.z/2)*2)
    if Input.is_action_just_pressed("interact"): _interact()
    if Input.is_action_just_pressed("inventory"): say("РЮКЗАК: "+str(inventory))
    if Input.is_action_just_pressed("build"):
        building=not building
        preview.visible=building
        say("Режим строительства включён" if building else "Строительство выключено")
    if building and Input.is_action_just_pressed("attack"): _place_wall()

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
    _solid_box(root,Vector3.ZERO,Vector3(4,3,0.25),mat)
    say("Деревянная стена построена.")

func _ui():
    var layer=CanvasLayer.new()
    add_child(layer)
    hud=Label.new()
    hud.position=Vector2(22,18)
    hud.add_theme_font_size_override("font_size",19)
    hud.add_theme_color_override("font_color",Color("#fff2d8"))
    layer.add_child(hud)
    notice=Label.new()
    notice.position=Vector2(22,90)
    notice.add_theme_font_size_override("font_size",18)
    notice.add_theme_color_override("font_color",Color("#ffd28a"))
    layer.add_child(notice)
    var cross=Label.new()
    cross.text="+"
    cross.set_anchors_preset(Control.PRESET_CENTER)
    cross.add_theme_font_size_override("font_size",25)
    layer.add_child(cross)
    var help=Label.new()
    help.text="WASD — ходьба   SHIFT — бег   E — сбор   B — стройка   TAB — рюкзак"
    help.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    help.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    help.add_theme_color_override("font_color",Color.WHITE)
    layer.add_child(help)
    var gather=Button.new()
    gather.text="СОБРАТЬ"
    gather.anchor_left=1
    gather.anchor_right=1
    gather.anchor_top=1
    gather.anchor_bottom=1
    gather.offset_left=-160
    gather.offset_top=-115
    gather.offset_right=-20
    gather.offset_bottom=-55
    gather.pressed.connect(_interact)
    layer.add_child(gather)
    var build_btn=Button.new()
    build_btn.text="СТРОИТЬ"
    build_btn.anchor_left=1
    build_btn.anchor_right=1
    build_btn.anchor_top=1
    build_btn.anchor_bottom=1
    build_btn.offset_left=-160
    build_btn.offset_top=-185
    build_btn.offset_right=-20
    build_btn.offset_bottom=-125
    build_btn.pressed.connect(func():
        building=not building
        preview.visible=building
    )
    layer.add_child(build_btn)

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
