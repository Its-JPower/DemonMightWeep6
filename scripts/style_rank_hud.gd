class_name StyleRankHUD
extends Control

@onready var rank_texture: TextureRect = $VBoxContainer/RankTexture
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar

@export var rank_textures: Array[Texture2D] = []  # index-matched to StyleRankManager.Rank

func _ready() -> void:
	StyleRankManager.rank_changed.connect(_on_rank_changed)
	StyleRankManager.points_changed.connect(_on_points_changed)
	_update_rank_texture(StyleRankManager.current_rank)
	_update_progress(StyleRankManager.style_points)

func _on_rank_changed(_new_rank: String) -> void:
	_update_rank_texture(StyleRankManager.current_rank)
	_play_rank_up_anim()

func _on_points_changed(points: float) -> void:
	_update_progress(points)

func _update_rank_texture(rank: StyleRankManager.Rank) -> void:
	if rank < rank_textures.size():
		rank_texture.texture = rank_textures[rank]

func _update_progress(points: float) -> void:
	var rank := StyleRankManager.current_rank
	var thresholds := StyleRankManager.RANK_THRESHOLDS
	
	if rank >= StyleRankManager.Rank.SSS:
		progress_bar.value = 1.0
		return
	
	var floor_points = thresholds[rank]
	var ceil_points = thresholds[rank + 1]
	var progress = (points - floor_points) / float(ceil_points - floor_points)
	progress_bar.value = clamp(progress, 0.0, 1.0)

func _play_rank_up_anim() -> void:
	rank_texture.scale = Vector2(1.4, 1.4)
	rank_texture.pivot_offset = rank_texture.size / 2.0
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(rank_texture, "scale", Vector2.ONE, 0.35)
