
extends Node

enum Player {
	white
	black
}

var turn = Player.white setget swapTurn

var who = null
var pieces = []
var pieces_cells = []

var pawn = null
var pawn_pos = null
var en_passant = false
onready var board = get_node("board")

func _ready():
	calc_pieces()
	
func swapTurn(newValue):
	calc_pieces()
	if newValue == Player.black || newValue == Player.white:
		turn = newValue
	toggle_en_passant()

func toggle_turn():
	calc_pieces()
	if turn == Player.white:
		turn = Player.black
	else:
		turn = Player.white
	toggle_en_passant()


func kingPosition(side):
	print("Getting King position for " + str(side))
	var kingPosition = get_node("player_" + str(side)).get_node("king").get_position()
	var kingSquare = board.world_to_map(kingPosition)	
	return kingSquare
				
func opponentKingPosition():
	if turn == Player.white:		
		return kingPosition(Player.black)
	else:
		return kingPosition(Player.white)
	
func calc_pieces():
	print("calc pieces")
	pieces_cells.clear()
	pieces = get_node("player_0").get_children() + get_node("player_1").get_children()
	for piece in pieces:
		pieces_cells.append(board.world_to_map(piece.get_position()))
		
func toggle_en_passant():
	if pawn != null and pawn.is_in_group(str(turn)):
		print("cleaning")
		pawn = null
		pawn_pos = null
		en_passant = false
	elif pawn == null:
		en_passant = false
		print("Cannot Passant")
	else:
		en_passant = true
		print("Can En Passant")
