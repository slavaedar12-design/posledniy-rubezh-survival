extends RefCounted
const SAVE_PATH := "user://posledniy_rubezh_save.json"
static func save_game(player) -> void:
    var data := {"health":player.health,"hunger":player.hunger,"thirst":player.thirst,"energy":player.energy,"level":player.level,"xp":player.xp,"position_x":player.position.x,"position_y":player.position.y,"inventory":player.inventory}
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file: file.store_string(JSON.stringify(data, "\t"))
static func load_game(player) -> void:
    if not FileAccess.file_exists(SAVE_PATH): return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file: return
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY: return
    player.health = clampi(int(parsed.get("health",100)),0,100)
    player.hunger = clampi(int(parsed.get("hunger",100)),0,100)
    player.thirst = clampi(int(parsed.get("thirst",100)),0,100)
    player.energy = clampi(int(parsed.get("energy",100)),0,100)
    player.level = maxi(1,int(parsed.get("level",1)))
    player.xp = maxi(0,int(parsed.get("xp",0)))
    player.position = Vector2(float(parsed.get("position_x",640)),float(parsed.get("position_y",360)))
    var saved = parsed.get("inventory",{})
    if typeof(saved) == TYPE_DICTIONARY: player.inventory = saved
