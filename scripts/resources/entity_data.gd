# scripts/resources/entity_data.gd
class_name EntityData extends Resource

# 기본 정보
@export_group("Basic Info")
@export var entity_id: String = ""           # 고유 ID
@export var entity_name: String = ""         # 표시 이름
@export var description: String = ""         # 설명

# 비주얼
@export_group("Visuals")
@export var sprite_texture: Texture2D        # 엔티티 텍스처 (개별 이미지 또는 Atlas)
@export var sprite_scale: Vector2 = Vector2.ONE    # 스프라이트 크기 (1.0 = 원본, 0.5 = 절반)
@export var sprite_offset: Vector2 = Vector2.ZERO  # 스프라이트 위치 보정
@export var icon: Texture2D                  # UI 아이콘

# 씬
@export_group("Scene")
@export var scene_to_spawn: PackedScene      # 실제 씬

func get_id() -> String:
	return entity_id

func get_display_name() -> String:
	return entity_name
