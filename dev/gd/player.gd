extends KinematicBody2D

# These variables determine handling of fighter
export (int) var jump_power = 1000
export (int) var move_speed = 400
export (int) var gravity = 50
export (bool) var active = false
var max_lives
var spawn_pos
var anim
var dir = 1
var jumping = false
var jump_flag = 2
var jump_time = 0.0
var on_floor = false
var attacking = false
var attack_time = 0.0
var velocity = Vector2()

#This updates the position on the other end
slave func set_pos_and_motion(p_pos, p_vel, p_dir, attack_state, jump_state, animation, play):
	position = p_pos
	velocity = p_vel
	dir = p_dir
	if dir == 1:
		anim.flip_h = false
	else:
		anim.flip_h = true
	anim.set_animation(animation)
	if play:
		anim.play()
	else:
		anim.stop()
	attacking = attack_state
	jumping = jump_state

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	$head.connect("body_entered", self, "_on_head_entered")
	#$body.connect("body_entered", self, "_on_body_entered")
	anim = $animated_sprite
	anim.connect("animation_finished", self, "_on_animation_finished")
	set_physics_process(true)
	$label.text = get_name()
	gamestate.players["ninja"] = [1234, "ninja"]

func set_player_name(new_name):
	$label.set_text(new_name)

func _process(delta):
	pass

func _physics_process(delta):
	pass
	if active and int(get_name()) == get_tree().get_network_unique_id():
		handle_input(delta)
	handle_collisions()
	rpc("set_pos_and_motion", position, velocity, dir, attacking, jumping, anim.get_animation(), anim.playing)
	if Input.is_action_just_pressed("dodge"):
		rpc("get_killed")
	if Input.is_action_just_pressed("ui_select"):
		print("I'm ALIVE!")

func handle_input(delta):
	var move_left = Input.is_action_pressed("move_left")
	var move_right = Input.is_action_pressed("move_right")
	var jump = Input.is_action_just_pressed("jump")
	var attack = Input.is_action_just_pressed("attack")
	var acceleration = Vector2()
	if jump and jump_flag > 0:
		print("jump")
		velocity.y = -jump_power
		jumping = true
		on_floor = false
		jump_flag -= 1
		jump_time = 0.0
		anim.set_animation("jump")
		anim.set_frame(0)
	if jumping:
		jump_time += delta
		anim.set_animation("jump")
	if move_left and not attacking:
		dir = 0
		velocity.x = -move_speed
		#print("move_left")
		if not jumping:
			anim.set_animation("run")
		anim.flip_h = true
	elif move_right and not attacking:
		dir = 1
		velocity.x = move_speed
		if not jumping:
			anim.set_animation("run")
			anim.play()
		anim.flip_h = false
	elif not jumping and not attacking:
		anim.set_animation("idle")
		anim.play()
		velocity.x = 0
	elif jumping:
		velocity.x = 0
	if attack:
		create_attack_box()
		attack_time = 0.0
		anim.set_animation("attack")
		anim.play()
		attacking = true
	if attacking:
		attack_time += delta
		#print("attacking")
		if attack_time > 0.3 and attack_time < 0.4:
			# Create attack box and connect to _on_attack_box_enter function
			#print(attack_time)
			if dir == 1:
				velocity.x = move_speed
			else:
				velocity.x = -move_speed
	acceleration.y += gravity#*jump_time
	#print(velocity)
	#if not on_floor:
	velocity += acceleration#*jump_time
	# --- FOR NINJA ONLY --- #
#	if on_floor and not jumping:
#		velocity.y = 0
	# --- TYPICAL FIGHTER --- #
	
	#$label.text = str(acceleration) + ", " + str(velocity) + ", " + str(jumping)

func handle_collisions():
	var normal = move_and_slide(velocity) # col = collision
	if get_slide_count() != 0 :
		for i in range (0,get_slide_count()) :
			#$label.text = str(get_slide_collision(i).collider.name) + "   " + str(gamestate.players)
#			for player in gamestate.players:
#				print(player)
			var col = get_slide_collision(i).collider
			#print(col.name)
			if col.name == "floor":
				#print("on floor")
				jump_flag = 2
				jumping = false
				on_floor = true
				velocity.y = 0
			if int(col.name) in gamestate.players:# or col.name == "ninja":
				#print(normal)
				print("got em")
				jump_flag = 1
				jumping = true
				on_floor = false
				if normal == Vector2(0, 0) and not attacking:
					velocity.y -= jump_power
				print("collision")
				print(col.name)
				col.rpc("get_killed")
#	if col:
#		#print(col.collider.name)
#		if col.collider.name == "floor" and velocity.y > 0:
#			velocity.y = 0
#		if col.collider.name == "player" and name != "player":
#			print("player player")
#			get_killed()
#		if col.collider.name == "player_2" and name != "player_2":
#			print("got player_2")
#		jump_flag=2
#		jumping = false

func _on_animation_finished():
	if anim.animation == "attack":
		print("end attack")
		anim.stop()
		attacking = false
		#print($attack_box.name)
		#remove_child($attack_box)
		$attack_box.queue_free()

func _on_head_entered(body):
	print("head enter")
	if int(body.name) in gamestate.players and body.name != get_name():# or body.name == "1":
		print(body.name)
		print(body.attacking)
		print(body.jumping)
#		if body.jumping:
#			rpc("get_killed")

func create_attack_box():
	var attack_box = Area2D.new()
	var hit_box = CollisionShape2D.new()
	var hit_shape = CircleShape2D.new()
	hit_shape.radius = 5
	hit_box.shape = hit_shape
	attack_box.set_name("attack_box")
	attack_box.add_child(hit_box)
	attack_box.connect("body_entered", self, "_on_attack_box_entered")
	add_child(attack_box)
	attack_box.position.x += 10

func _on_attack_box_entered(body):
	print("ATTACK")
	print(body.name)
	if int(body.name) in gamestate.players:# or body.name == "ninja":
		body.rpc("get_killed")

sync func get_killed():
	gamestate.rpc("respawn_player")
	queue_free()
	# TODO: Respawn

remote func player_killed():
	pass


