extends CharacterBody3D

var main
var camera: Camera3D
var speed := 5.2
var pitch := -0.18
var gravity := 18.0
var touch_move := Vector2.ZERO
var visual: Node3D

func _ready() -> void:
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.38
    capsule.height = 1.8
    collision.shape = capsule
    collision.position.y = 0.9
    add_child(collision)

    visual = Node3D.new()
    add_child(visual)
    var torso := MeshInstance3D.new()
    var body := CapsuleMesh.new()
    body.radius = 0.42
    body.height = 1.0
    torso.mesh = body
    torso.material_override = _material(Color("#2586d4"))
    torso.position.y = 0.95
    visual.add_child(torso)
    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.34
    sphere.height = 0.68
    head.mesh = sphere
    head.material_override = _material(Color("#f4c99f"))
    head.position = Vector3(0, 1.7, 0)
    visual.add_child(head)
    for x in [-0.13, 0.13]:
        var eye := MeshInstance3D.new()
        var e := SphereMesh.new()
        e.radius = 0.045
        eye.mesh = e
        eye.material_override = _material(Color("#252b38"))
        eye.position = Vector3(x, 1.74, -0.3)
        visual.add_child(eye)
    for x in [-0.2, 0.2]:
        var leg := MeshInstance3D.new()
        var l := BoxMesh.new()
        l.size = Vector3(0.2, 0.55, 0.24)
        leg.mesh = l
        leg.material_override = _material(Color("#33445c"))
        leg.position = Vector3(x, 0.28, 0)
        visual.add_child(leg)

    camera = Camera3D.new()
    camera.position = Vector3(0, 3.0, 6.8)
    camera.rotation_degrees = Vector3(-15, 180, 0)
    camera.current = true
    camera.fov = 70
    add_child(camera)

func _material(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.8
    return m

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back") + touch_move
    input_dir = input_dir.limit_length()
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    if direction.length() > 0.05:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
        var target_angle := atan2(direction.x, direction.z)
        visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, delta * 10.0)
    else:
        velocity.x = move_toward(velocity.x, 0, speed * 8.0 * delta)
        velocity.z = move_toward(velocity.z, 0, speed * 8.0 * delta)
    move_and_slide()
    camera.position = camera.position.lerp(Vector3(0, 3.0, 6.8), delta * 5.0)

func rotate_camera(relative: Vector2) -> void:
    rotate_y(-relative.x * 0.003)
    pitch = clampf(pitch - relative.y * 0.002, -0.45, 0.25)
    camera.rotation.x = deg_to_rad(-15) + pitch

func set_touch_move(value: Vector2) -> void:
    touch_move = value.limit_length(1.0)
