class_name BuildingEntity
extends Node2D

## 건물 기본 클래스
## 감염 시스템의 핵심 엔티티

# ============================================================
# 노드 참조 (씬에서 설정)
# ============================================================

## Sprite2D 노드 참조 (비주얼)
@onready var sprite: Sprite2D = $Sprite2D

## Area2D 노드 참조 (클릭 감지용)
## 주의: 씬에 Area2D 노드가 있어야 함
@onready var area: Area2D = $Area2D

## SelectionIndicator 노드 참조 (선택 표시)
## 주의: 씬에 SelectionIndicator 노드가 있어야 함
@onready var selection_indicator: Sprite2D = $SelectionIndicator if has_node("SelectionIndicator") else null


# ============================================================
# 상태 변수
# ============================================================

## 그리드 좌표 (논리적 위치)
var grid_position: Vector2i = Vector2i.ZERO

## 선택 상태 (SelectionManager가 사용)
var is_selected: bool = false:
	set(value):
		is_selected = value
		_update_selection_indicator()

## 현재 이 엔티티가 가지고 있는 데이터 (Resource 기반)
var data: BuildingData = null


# ============================================================
# 생명주기
# ============================================================

func _ready() -> void:
	# 그룹 등록 (main.gd에서 찾을 수 있도록)
	add_to_group("buildings")

	# 디버그: 건물 생성 로그
	print("[BuildingEntity] 건물 생성됨: ", name, " at ", global_position)
	print("  - Area2D collision_layer: ", $Area2D.collision_layer if has_node("Area2D") else "없음")

	# 초기 비주얼 설정 (기본 색상)
	if sprite:
		sprite.modulate = Color.WHITE

	# 선택 인디케이터 초기 숨김
	if selection_indicator:
		selection_indicator.visible = false

	# StaticBody2D는 Navigation 장애물 전용
	# collision_layer = 4 (Layer 3)는 씬에서 이미 설정됨
	# NavigationRegion2D의 parsed_collision_mask = 4와 매칭하여 장애물로 인식됨
	# 클릭 감지는 Area2D가 담당하므로 StaticBody2D는 수정하지 않음

	# 데이터가 있으면 비주얼 업데이트 (Resource 기반 시스템)
	if data:
		_update_visuals(data)


# ============================================================
# 선택 인디케이터
# ============================================================

## 선택 상태에 따라 인디케이터 표시/숨김
func _update_selection_indicator() -> void:
	"""선택 상태에 따라 인디케이터 표시/숨김 (UnitEntity와 동일)"""
	if not selection_indicator:
		return

	selection_indicator.visible = is_selected


# ============================================================
# Resource 기반 초기화 (의존성 주입 패턴)
# ============================================================

## 외부(건설 시스템)에서 호출하는 초기화 함수
  ## BuildingData를 주입받아 건물 외형을 설정
  ##
  ## @param new_data: BuildingData Resource (텍스처, 스케일, 오프셋 포함)
  ## @example: building.initialize(BuildingDatabase.get_building("house"))
func initialize(new_data: BuildingData) -> void:
	data = new_data
	_update_visuals(data)  # 명시적으로 데이터 전달
	print("[BuildingEntity] initialize() 호출됨: ", data.entity_name if data else "null")

## 뷰를 데이터에 맞게 갱신하는 내부 함수
## @param building_data: 비주얼 업데이트에 사용할 BuildingData (명시적 의존성)
func _update_visuals(building_data: BuildingData) -> void:
	assert(building_data != null, "[BuildingEntity] building_data는 null일 수 없습니다")

	# 텍스처 설정
	if building_data.sprite_texture:
		sprite.texture = building_data.sprite_texture

		# 스케일 적용
		if building_data.sprite_scale != Vector2.ONE:
			sprite.scale = building_data.sprite_scale

		# 오프셋 적용: 바닥면 중심 오프셋
		var center_offset: Vector2 = _calculate_center_offset(building_data.grid_size)
		sprite.position = center_offset
	else:
		push_warning("BuildingData에 텍스처가 설정되지 않았습니다: %s" % building_data.entity_name)

	# Collision Polygon 업데이트 (grid_size 반영)
	_update_collision_polygon(building_data.grid_size)


## 바닥면 중심 오프셋 계산
##
## 건물의 기준점(grid_pos)은 좌상단 타일이지만,
## 스프라이트 중심은 건물 바닥면의 기하학적 중심에 위치해야
## 시각적 위치와 Grid 등록 위치가 일치합니다.
##
## @param grid_size: 건물 크기 (예: Vector2i(2, 2))
## @return: 좌상단 타일 중심에서 바닥면 중심까지의 화면 오프셋
##
## 예시:
##   1x1: (0, 0)   - 이동 없음
##   2x2: (0, 8)   - 4개 타일의 중심으로
##   3x2: (8, 12)  - 6개 타일의 중심으로
##   2x3: (-8, 12) - 6개 타일의 중심으로
static func _calculate_center_offset(grid_size: Vector2i) -> Vector2:
	var half_w: float = GameConfig.HALF_TILE_WIDTH
	var half_h: float = GameConfig.HALF_TILE_HEIGHT

	# Godot TileMapLayer 좌표계 기준:
	# Grid X+1: (+half_w, -half_h)
	# Grid Y+1: (+half_w, +half_h)
	# NxM 건물의 바닥면 중심 오프셋
	var offset_x: float = (grid_size.x + grid_size.y - 2) * half_w / 2.0
	var offset_y: float = (grid_size.y - grid_size.x) * half_h / 2.0

	return Vector2(offset_x, offset_y)


## 텍스처 앵커 오프셋 계산
##
## Sprite2D는 centered=true일 때 텍스처 중심이 원점에 옵니다.
## 하지만 아이소메트릭 텍스처에서 "바닥면 중심"은 건물 높이 때문에
## 텍스처 기하학적 중심보다 위쪽에 있습니다.
## 이 차이를 sprite.offset으로 보정합니다.
##
## @param grid_size: 건물 크기
## @param texture: 스프라이트 텍스처
## @return: 바닥면 중심이 스프라이트 원점에 오도록 하는 offset
static func _calculate_texture_anchor_offset(grid_size: Vector2i, texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2.ZERO

	var half_h: float = GameConfig.HALF_TILE_HEIGHT

	# 바닥면 세로 길이 (아이소메트릭 다이아몬드 높이)
	var floor_height: float = (grid_size.x + grid_size.y) * half_h
	# 바닥면 중심 y (텍스처 상단 기준)
	var floor_center_y: float = floor_height / 2.0
	# 텍스처 중심 y
	var texture_center_y: float = texture.get_height() / 2.0

	# offset: 바닥면 중심을 텍스처 중심으로 이동시키는 값
	return Vector2(0, floor_center_y - texture_center_y)


## grid_size에 맞게 Collision Polygon 동적 생성
## 아이소메트릭 다이아몬드 형태로 NxM 타일 영역을 커버
##
## @param grid_size: 건물이 차지하는 타일 수 (예: Vector2i(2, 2))
##
## Godot TileMapLayer 좌표계:
## - Grid X+1: (+half_w, -half_h) = 오른쪽 위
## - Grid Y+1: (+half_w, +half_h) = 오른쪽 아래
func _update_collision_polygon(grid_size: Vector2i) -> void:
	var half_w: float = GameConfig.HALF_TILE_WIDTH
	var half_h: float = GameConfig.HALF_TILE_HEIGHT

	var w: int = grid_size.x
	var h: int = grid_size.y

	# NxM 건물의 외곽 다이아몬드 꼭짓점 계산 (Godot 좌표계 기준)
	# 북쪽: 타일 (w-1, 0)의 북쪽 꼭지점
	var top = Vector2((w - 1) * half_w, -w * half_h)
	# 동쪽: 타일 (w-1, h-1)의 동쪽 꼭지점
	var right = Vector2((w + h - 1) * half_w, (h - w) * half_h)
	# 남쪽: 타일 (0, h-1)의 남쪽 꼭지점
	var bottom = Vector2((h - 1) * half_w, h * half_h)
	# 서쪽: 타일 (0, 0)의 서쪽 꼭지점
	var left = Vector2(-half_w, 0)

	var polygon = PackedVector2Array([top, right, bottom, left])

	# Area2D의 CollisionPolygon2D 업데이트
	if has_node("Area2D/CollisionPolygon2D"):
		$Area2D/CollisionPolygon2D.polygon = polygon

	# StaticBody2D의 CollisionPolygon2D 업데이트 (Navigation 장애물용)
	if has_node("StaticBody2D/CollisionPolygon2D"):
		$StaticBody2D/CollisionPolygon2D.polygon = polygon
