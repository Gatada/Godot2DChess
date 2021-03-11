
extends Area2D

#Base logic booleans
var is_selected = false
var is_on_top = false
var mouse_click = false
var mouse_clicked = false
var already_moved = false

#Cell movement logic
var movable_cells = []
var parent_cell = null
var selected_cell = null

#Capture required variables
var opponent_pieces = []

#Nodes needed
onready var parent = get_node("..")
onready var board = get_node("/root/main_scene/board")
onready var controller = get_node("/root/main_scene")

onready var kingWhite = controller.get_node("player_0").get_node("king")
onready var kingBlack = controller.get_node("player_1").get_node("king")

func kingThisTurn():
	if controller.turn == controller.Player.white:
		return kingWhite
	else:
		return kingBlack

func _ready():
	set_process(true)
####################################################

func _process(_delta):
	mouse_click = Input.is_action_pressed("mouse")
	if mouse_click and not mouse_clicked:
		if is_on_top:
			select_piece()
		else:
			move_to()
	mouse_clicked = mouse_click
####################################################

#Verifies which piece is being clicked
func _on_base_piece_mouse_enter():
	is_on_top = true
	controller.who = parent
	print("hovering " + parent.name)
	
func _on_base_piece_mouse_exit():
	is_on_top = false
	print("exited " + parent.name)

###################################################

func select_piece():
	
	print("Turn: " + str(controller.turn))
	
	#Toggle between selected and unselected
	if is_selected == false and parent.is_in_group(str(controller.turn)):
		is_selected = true
		movable_cells.clear()
		parent.calc_cell(parent.which_piece)
		print("selected " + parent.name)

	else:
		is_selected = false
		movable_cells.clear()
		opponent_pieces.clear()
		print("deselected " + parent.name)
####################################################

func move_to():

	selected_cell = board.world_to_map(get_viewport().get_mouse_position())
	
# Check if King state - prevent move unless it keeps or makes King safe
	var king = kingThisTurn()
	if king.kingState != king.KingState.safe:
		
		# TODO: Check if King can be saved by another piece.
		# TEMP: King is not safe, prevent selection of other pieces.
		
		print("King not safe; can't select another piece")
		return

	
#Special movements	
	#Rook - Castling
	if controller.who.get_name() == "king" and parent.which_piece == "rook":
		if board.world_to_map(controller.who.get_position()) in movable_cells:
			if controller.who.can_castle and parent.can_castle:
				controller.who.set_global_position(board.map_to_world(Vector2 (parent_cell.x + (1 * parent.rook_var), parent_cell.y)))
				var king_pos = board.world_to_map(controller.who.get_position())
				selected_cell = king_pos
				parent.set_global_position(board.map_to_world(Vector2 (king_pos.x + (1 * parent.rook_var), king_pos.y)))
				
				#Cleaning to the next turn
				parent.can_castle = false
				controller.who.can_castle = false
				movable_cells.clear()
				is_selected = false
				controller.toggle_turn()
	
	#Pawn - En Passant
	if is_selected:
		if parent.which_piece == "pawn":
			if controller.pawn_pos == selected_cell and selected_cell in movable_cells:
				if controller.en_passant and controller.pawn != parent:
					print("En Passant")
					controller.pawn.queue_free()
	####################################################

	#Clear cells that belong to allies
	for piece in parent.get_parent().get_children():
		if piece.is_in_group(parent.get_groups()[0]):
			movable_cells.erase(board.world_to_map(piece.get_position()))
			
	#Clear every cell that is not the board cells
	for cell in movable_cells:
		if board.get_cell(cell.x, cell.y) == -1:
			movable_cells.erase(cell)
	####################################################
	
	#Actual movement
	if not selected_cell == parent_cell:
		if selected_cell in movable_cells:

			#Verifies if the cell is occupied, and sets the right behaviour if it is
			if (board.world_to_map(controller.who.get_position()) in movable_cells):
				print(controller.who.get_groups())
				print(parent.get_groups())
				if (controller.who.get_groups() != parent.get_groups()):
					controller.who.queue_free()
					
			parent.set_global_position(board.map_to_world(selected_cell))
			
			# Check if the King is attacked
			# - Clear valid moves, as they are now outdated.
			# - Calculate new valid moves for selected piece in new position.
			# - Check if new move list includes a square that is occupied by the opposing King
			
			movable_cells.clear()
			
			var kingSquare = controller.opponentKingPosition()
			parent.calc_cell(parent.which_piece)
			
			var opponentKingIsAttacked = false
			for move in movable_cells:
				var square = board.get_cell(move.x, move.y)
				
				if square == 1: # Disregard empty squares
					
					print("Valid move: " + str(square))
					
					var isAttackingKing = move == kingSquare
					if isAttackingKing:
						opponentKingIsAttacked = true
			
			print("King is checked: " + str(opponentKingIsAttacked))
			if opponentKingIsAttacked:
				var opponentKing
				if controller.turn == controller.Player.white:
					opponentKing = controller.get_node("player_1").get_node("king")
				else:
					opponentKing = controller.get_node("player_0").get_node("king")
				opponentKing.kingState = opponentKing.KingState.check
					
					
					# TODO: Check for stalemate too.
					# TODO: We also need to check for checkmate
			
	####################################################

			#Cleaning to the next turn
			movable_cells.clear()
			is_selected = false
			controller.toggle_turn()
####################################################

func _on_base_piece_exit_tree():
	print("I " + str(parent.get_name()) + " was captured")
	
	
func can_attack_king():
	
	# Check if player's King is attacked
	# - Calculate valid moves for selected piece in new position.
	# - Check if new move list includes a square that is occupied by the opposing King

	if not is_selected:
		movable_cells.clear()
		parent.calc_cell(parent.which_piece)
	
	var kingSquare = controller.opponentKingPosition()
	var can_attack = false
	
	for move in movable_cells:
		var square = board.get_cell(move.x, move.y)
		
		if square == 1: # Disregard empty squares
			
			print("Valid move: " + str(square))
			
			var isAttackingKing = move == kingSquare
			if isAttackingKing:
				can_attack = true
	
	return can_attack
