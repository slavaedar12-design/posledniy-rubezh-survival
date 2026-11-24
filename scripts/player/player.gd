extends CharacterBody3D
var main
var camera:Camera3D
var speed=5.2
var pitch=0.0
var gravity=13.0
var touch_move=Vector2.ZERO

func _ready():
    var col=CollisionShape3D.new()
    var cap=CapsuleShape3D.new()
    cap.radius=0.38
    cap.height=1.8
    col.shape=cap
    col.position.y=0.9
    add_child(col)
    camera=Camera3D.new()
    camera.position=Vector3(0,1.62,0)
    camera.current=true
    camera.fov=82
    add_child(camera)

func _physics_process(delta):
    if not is_on_floor():
        velocity.y-=gravity*delta
    elif Input.is_action_just_pressed("jump"):
        velocity.y=4.5
    var input_dir=Input.get_vector("move_left","move_right","move_forward","move_back")+touch_move
    input_dir=input_dir.limit_length()
    var direction=(transform.basis*Vector3(input_dir.x,0,input_dir.y)).normalized()
    var v=speed*(1.65 if Input.is_action_pressed("sprint") else 1.0)
    if direction:
        velocity.x=direction.x*v
        velocity.z=direction.z*v
    else:
        velocity.x=move_toward(velocity.x,0,v*7*delta)
        velocity.z=move_toward(velocity.z,0,v*7*delta)
    move_and_slide()

func rotate_camera(relative:Vector2):
    rotate_y(-relative.x*0.0025)
    pitch=clampf(pitch-relative.y*0.0025,-1.45,1.45)
    camera.rotation.x=pitch

func set_touch_move(v:Vector2):
    touch_move=v
