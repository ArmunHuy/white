//Floorbot assemblies
/obj/item/weapon/robot_assembly/toolbox_tiles
	desc = "It's a toolbox with tiles sticking out the top"
	name = "tiles and toolbox"
	icon = 'aibots.dmi'
	icon_state = "toolbox_tiles"
	force = 3.0
	throwforce = 10.0
	throw_speed = 2
	throw_range = 5
	w_class = 3.0
	var/color = null
	flags = TABLEPASS

	New()
		..()
		spawn(1) icon_state = "[color]toolbox_tiles"

/obj/item/weapon/robot_assembly/toolbox_tiles_sensor
	desc = "It's a toolbox with tiles sticking out the top and a sensor attached"
	name = "tiles, toolbox and sensor arrangement"
	icon = 'aibots.dmi'
	icon_state = "toolbox_tiles_sensor"
	force = 3.0
	throwforce = 10.0
	throw_speed = 2
	throw_range = 5
	var/created_name
	var/color = null
	w_class = 3.0
	flags = TABLEPASS

	New()
		..()
		spawn(1) icon_state = "[color]toolbox_tiles"

//Floorbot
/obj/machinery/bot/floorbot
	name = "Floorbot"
	desc = "A little floor repairing robot, he looks so excited!"
	icon = 'aibots.dmi'
	icon_state = "floorbot0"
	layer = 5.0
	density = 0
	anchored = 0
	//weight = 1.0E7
	var/amount = 10
	var/repairing = 0
	var/improvefloors = 0
	var/eattiles = 0
	var/maketiles = 0
	var/locked = 1
	var/turf/target
	var/turf/oldtarget
	var/oldloc = null
	var/color = null
	req_access = list(access_atmospherics)


/obj/machinery/bot/floorbot/New()
	..()
	spawn(1) src.update_icon()

/obj/machinery/bot/floorbot/attack_hand(user as mob)
	var/dat
	dat += text({"
<TT><B>Automatic Station Floor Repairer v1.0</B></TT><BR><BR>
Status: []<BR>
Tiles left: [src.amount]<BR>
Behaviour controls are [src.locked ? "locked" : "unlocked"]"},
text("<A href='?src=\ref[src];operation=start'>[src.on ? "On" : "Off"]</A>"))
	if(!src.locked)
		dat += text({"<BR>
Improves floors: []<BR>
Finds tiles: []<BR>
Make single pieces of metal into tiles when empty: []"},
text("<A href='?src=\ref[src];operation=improve'>[src.improvefloors ? "Yes" : "No"]</A>"),
text("<A href='?src=\ref[src];operation=tiles'>[src.eattiles ? "Yes" : "No"]</A>"),
text("<A href='?src=\ref[src];operation=make'>[src.maketiles ? "Yes" : "No"]</A>"))

	user << browse("<HEAD><TITLE>Repairbot v1.0 controls</TITLE></HEAD>[dat]", "window=autorepair")
	onclose(user, "autorepair")
	return

/obj/machinery/bot/floorbot/attackby(var/obj/item/weapon/W , mob/user as mob)
	if(istype(W, /obj/item/stack/tile/metal))
		var/obj/item/stack/tile/metal/T = W
		if(src.amount >= 50)
			return
		var/loaded = 0
		if(src.amount + T.amount > 50)
			var/i = 50 - src.amount
			src.amount += i
			T.amount -= i
			loaded = i
		else
			src.amount += T.amount
			loaded = T.amount
			del(T)
		user << "\red You load [loaded] tiles into the floorbot. He now contains [src.amount] tiles!"
		src.update_icon()
	if(istype(W, /obj/item/weapon/card/id) || istype(W, /obj/item/device/pda))
		if(src.allowed(usr))
			src.locked = !src.locked
			user << "You [src.locked ? "lock" : "unlock"] the [src] behaviour controls."
		else
			user << "The [src] doesn't seem to accept your authority."
		src.updateUsrDialog()


/obj/machinery/bot/floorbot/Topic(href, href_list)
	if(..())
		return
	usr.machine = src
	src.add_fingerprint(usr)
	switch(href_list["operation"])
		if("start")
			src.on = !src.on
			src.target = null
			src.oldtarget = null
			src.oldloc = null
			src.update_icon()
			src.path = new()
			src.updateUsrDialog()
		if("improve")
			src.improvefloors = !src.improvefloors
			src.updateUsrDialog()
		if("tiles")
			src.eattiles = !src.eattiles
			src.updateUsrDialog()
		if("make")
			src.maketiles = !src.maketiles
			src.updateUsrDialog()
/obj/machinery/bot/floorbot/shutdowns()
	src.on = !src.on
	src.target = null
	src.oldtarget = null
	src.oldloc = null
	src.update_icon()
	src.path = new()
/obj/machinery/bot/floorbot/attack_ai()
	src.on = !src.on
	src.target = null
	src.oldtarget = null
	src.oldloc = null
	src.update_icon()
	src.path = new()

/obj/machinery/bot/floorbot/process()
	if (!src.on)
		return

	if(src.repairing)
		return
	var/list/floorbottargets = list()
	if(!src.target || src.target == null)
		for(var/obj/machinery/bot/floorbot/bot in world)
			if(bot != src)
				floorbottargets += bot.target
	if(src.amount <= 0 && ((src.target == null) || !src.target))
		if(src.eattiles)
			for(var/obj/item/stack/tile/metal/T in view(7, src))
				if(T != src.oldtarget && !(target in floorbottargets))
					src.oldtarget = T
					src.target = T
					break
		if(src.target == null || !src.target)
			if(src.maketiles)
				if(src.target == null || !src.target)
					for(var/obj/item/stack/sheet/metal/M in view(7, src))
						if(!(M in floorbottargets) && M != src.oldtarget && M.amount == 1 && !(istype(M.loc, /turf/simulated/wall)))
							src.oldtarget = M
							src.target = M
							break
		else
			return
	if(prob(5))
		for(var/mob/O in viewers(src, null))
			O.show_message(text("[src] makes an excited booping beeping sound!"), 1)

	if(!src.target || src.target == null)
		for (var/turf/space/D in view(7,src))
			if(!(D in floorbottargets) && D != src.oldtarget && (D.loc.name != "Space"))
				src.oldtarget = D
				src.target = D
				break
		for(var/turf/simulated/floor/open/O in view(7,src))
			if(!(O in floorbottargets) && O != src.oldtarget)
				src.oldtarget = O
				src.target = O
				break
		if((!src.target || src.target == null ) && src.improvefloors)
			for (var/turf/simulated/floor/F in view(7,src))
				if(!(F in floorbottargets) && F != src.oldtarget && F.broken && !(istype(F, /turf/simulated/floor/plating)))
					src.oldtarget = F
					src.target = F
					break
		if((!src.target || src.target == null) && src.eattiles)
			for(var/obj/item/stack/tile/metal/T in view(7, src))
				if(!(T in floorbottargets) && T != src.oldtarget)
					src.oldtarget = T
					src.target = T
					break

	if(!src.target || src.target == null)
		if(src.loc != src.oldloc)
			src.oldtarget = null
		return

	if(src.target && (src.target != null) && src.path.len == 0)
		spawn(0)
			if (istype(src.loc, /turf/))
				if (src.target)
					if(!istype(src.target, /turf/))
						src.path = AStar(src.loc, src.target.loc, /turf/proc/CardinalTurfsWithAccess, /turf/proc/Distance, 0, 120, id=botcard, exclude=list(/obj/effect/landmark/alterations/nopath))
					else
						src.path = AStar(src.loc, src.target, /turf/proc/CardinalTurfsWithAccess, /turf/proc/Distance, 0, 120, id=botcard, exclude=list(/obj/effect/landmark/alterations/nopath))
					src.path = reverselist(src.path)
					if(src.path.len == 0)
						src.oldtarget = src.target
						src.target = null
		return
	if(src.path.len > 1 && src.target && (src.target != null))
		step_towards_3d(src, src.path[1])
		src.path -= src.path[1]
	else if(src.path.len == 1)
		if(!istype(target,/turf/simulated/floor/open))
			step_towards_3d(src, target)
			src.path = new()
		else
			repair(src.target)

	if(src.loc == src.target || src.loc == src.target.loc)
		if(istype(src.target, /obj/item/stack/tile/metal))
			src.eattile(src.target)
		else if(istype(src.target, /obj/item/stack/sheet/metal))
			src.maketile(src.target)
		else if(istype(src.target, /turf/))
			repair(src.target)
		src.path = new()
		return

	src.oldloc = src.loc


/obj/machinery/bot/floorbot/proc/repair(var/turf/target)
	if(istype(target, /turf/space/))
		if(target.loc.name == "Space")
			return
	else if(!istype(target, /turf/simulated/floor))
		return
	if(src.amount <= 0)
		return
	src.anchored = 1
	src.icon_state = "floorbot-c"
	if(istype(target, /turf/space/) || istype(target,/turf/simulated/floor/open))
		for(var/mob/O in viewers(src, null))
			O.show_message(text("\red [src] begins to repair the hole"), 1)
		var/obj/item/stack/tile/metal/T = new /obj/item/stack/tile/metal
		src.repairing = 1
		spawn(50)
			T.build(src.loc)
			src.repairing = 0
			src.amount -= 1
			src.update_icon()
			src.anchored = 0
			src.target = null
	else
		var/turf/simulated/floor/L = src.loc
		for(var/mob/O in viewers(src, null))
			O.show_message(text("\red [src] begins to improve the floor."), 1)
		src.repairing = 1
		spawn(50)
			if (L.icon_old)
				L.icon_state = L.icon_old
			else
				L.icon_state = "floor"
			L.broken = 0
			src.repairing = 0
			src.amount -= 1
			src.update_icon()
			src.anchored = 0
			src.target = null

/obj/machinery/bot/floorbot/proc/eattile(var/obj/item/stack/tile/metal/T)
	if(!istype(T, /obj/item/stack/tile/metal))
		return
	for(var/mob/O in viewers(src, null))
		O.show_message(text("\red [src] begins to collect tiles."), 1)
	src.repairing = 1
	spawn(20)
		if(isnull(T))
			src.target = null
			src.repairing = 0
			return
		if(src.amount + T.amount > 50)
			var/i = 50 - src.amount
			src.amount += i
			T.amount -= i
		else
			src.amount += T.amount
			del(T)
		src.update_icon()
		src.target = null
		src.repairing = 0

/obj/machinery/bot/floorbot/proc/maketile(var/obj/item/stack/sheet/metal/M)
	if(!istype(M, /obj/item/stack/sheet/metal))
		return
	if(M.amount > 1)
		return
	for(var/mob/O in viewers(src, null))
		O.show_message(text("\red [src] begins to create tiles."), 1)
	src.repairing = 1
	spawn(20)
		if(isnull(M))
			src.target = null
			src.repairing = 0
			return
		var/obj/item/stack/tile/metal/T = new /obj/item/stack/tile/metal
		T.amount = 4
		T.loc = M.loc
		del(M)
		src.target = null
		src.repairing = 0

/obj/machinery/bot/floorbot/update_icon()
	if(src.amount > 0)
		src.icon_state = "[color]floorbot[src.on]"
	else
		src.icon_state = "[color]floorbot[src.on]e"


/obj/item/weapon/robot_assembly/toolbox_tiles/attackby(var/obj/item/device/prox_sensor/D, mob/user as mob)
	if(!istype(D, /obj/item/device/prox_sensor))
		return
	var/obj/item/weapon/robot_assembly/toolbox_tiles_sensor/B = new /obj/item/weapon/robot_assembly/toolbox_tiles_sensor
	B.loc = user
	if (user.r_hand == D)
		user.u_equip(D)
		user.r_hand = B
	else
		user.u_equip(D)
		user.l_hand = B
	B.layer = 20
	user << "You add the sensor to the toolbox and tiles!"
	B.color = src.color
	user.update_clothing()
	del(D)
	del(src)

/obj/item/weapon/robot_assembly/toolbox_tiles_sensor/attackby(var/obj/item/W, mob/user as mob)
	if (istype(W, /obj/item/weapon/pen))
		var/t = input(user, "Enter new robot name", src.name, src.created_name) as text
		t = copytext(sanitize(t), 1, MAX_MESSAGE_LEN)
		if (!t)
			return
		if (!in_range(src, usr) && src.loc != usr)
			return
		src.created_name = t
		return
	if(!istype(W, /obj/item/robot_parts/l_arm) && !istype(W, /obj/item/robot_parts/r_arm))
		return
	var/obj/machinery/bot/floorbot/A = new /obj/machinery/bot/floorbot
	if(user.r_hand == src || user.l_hand == src)
		A.loc = user.loc
	else
		A.loc = src.loc
	if(created_name)
		A.name = created_name
	user << "You add the robot arm to the odd looking toolbox assembly! Boop beep!"
	A.color = src.color
	user.update_clothing()
	del(W)
	del(src)
