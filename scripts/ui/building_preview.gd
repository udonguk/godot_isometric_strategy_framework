class_name BuildingPreview
extends Node2D

## 건물 배치 미리보기
## 건설 모드에서 마우스 커서를 따라다니며 건설 가능/불가 색상 표시
##
## 사용법:
##   1. BuildingManager가 건설 모드 시작 시 show_preview() 호출
##   2. _process()에서 마우스 추적 + 색상 업데이트
##   3. 배치 완료/취소 시 hide_preview() 호출

# ============================================================
# 상수
# ============================================================

## 건설 가능 색상 (녹색 반투명)
const COLOR_VALID := Color(0, 1, 0, 0.5)

## 건설 불가 색상 (빨간색 반투명)
const COLOR_INVALID := Color(1, 0, 0, 0.5)

## 바닥면 오버레이 색상 (더 투명하게)
const COLOR_OVERLAY_VALID := Color(0, 1, 0, 0.3)
const COLOR_OVERLAY_INVALID := Color(1, 0, 0, 0.3)


# ============================================================
# 노드 참조
# ============================================================

@onready var sprite: Sprite2D = $Sprite2D
@onready var debug_label: Label = $DebugLabel
@onready var grid_overlay: Polygon2D = $GridOverlay


# ============================================================
# 상태 변수
# ============================================================

## 현재 미리보기 중인 건물 데이터
var current_building_data: BuildingData = null

## 현재 마우스가 위치한 그리드 좌표
var current_grid_pos: Vector2i = Vector2i.ZERO

## 미리보기 활성화 여부
var is_active: bool = false


# ============================================================
# 생명주기
# ============================================================

func _ready() -> void:
	# 초기에는 숨김
	visible = false
	is_active = false


func _process(_delta: float) -> void:
	if not is_active or current_building_data == null:
		return

	# 마우스 위치 추적 + 그리드 스냅
	_update_position()

	# 건설 가능 여부에 따른 색상 업데이트
	_update_validity_color()


# ============================================================
# 공개 메서드
# ============================================================

## 미리보기 표시
##
## @param building_data: 미리보기할 건물 데이터
func show_preview(building_data: BuildingData) -> void:
	if building_data == null:
		push_error("[BuildingPreview] building_data가 null입니다")
		return

	current_building_data = building_data
	is_active = true
	visible = true

	# 텍스처 설정
	_update_texture(building_data)

	# Grid 바닥면 오버레이 설정
	_update_grid_overlay(building_data.grid_size)

	print("[BuildingPreview] 미리보기 시작: ", building_data.entity_name)


## 미리보기 숨김
func hide_preview() -> void:
	is_active = false
	visible = false
	current_building_data = null

	print("[BuildingPreview] 미리보기 종료")


# ============================================================
# 내부 메서드
# ============================================================

## 마우스 위치에 따라 미리보기 위치 업데이트 (그리드 스냅)
func _update_position() -> void:
	# 마우스 월드 좌표 가져오기
	var mouse_world_pos: Vector2 = get_global_mouse_position()

	# 월드 좌표 → 그리드 좌표 변환
	current_grid_pos = GridSystem.world_to_grid(mouse_world_pos)

	# 그리드 좌표 → 월드 좌표 (스냅된 위치)
	var snapped_world_pos: Vector2 = GridSystem.grid_to_world(current_grid_pos)

	# 위치 적용
	global_position = snapped_world_pos

	# 디버그: 그리드 좌표 표시
	if debug_label:
		debug_label.text = "Grid: %s" % current_grid_pos


## 디버그: 현재 등록된 모든 건물 좌표 출력 (스페이스바로 호출)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		var all_buildings: Array = BuildingManager.grid_buildings.keys()
		print("[BuildingPreview] === 등록된 건물 좌표 ===")
		print("[BuildingPreview] 현재 미리보기 Grid: %s" % current_grid_pos)
		print("[BuildingPreview] 등록된 모든 좌표: %s" % [all_buildings])
		print("[BuildingPreview] 총 %d개 타일 점유 중" % all_buildings.size())


## 건설 가능 여부에 따른 색상 업데이트
func _update_validity_color() -> void:
	if current_building_data == null:
		return

	# BuildingManager의 can_build_at()으로 검증
	var result: Dictionary = BuildingManager.can_build_at(current_building_data, current_grid_pos)

	# 스프라이트 색상 적용
	if result.success:
		sprite.modulate = COLOR_VALID
	else:
		sprite.modulate = COLOR_INVALID

	# 개별 타일 오버레이 색상 업데이트
	_update_tile_overlay_colors()


## 건물 데이터에 맞게 텍스처 업데이트
func _update_texture(building_data: BuildingData) -> void:
	if building_data.sprite_texture:
		sprite.texture = building_data.sprite_texture

		# 스케일 적용
		if building_data.sprite_scale != Vector2.ONE:
			sprite.scale = building_data.sprite_scale
		else:
			sprite.scale = Vector2.ONE

		# 오프셋 적용: 바닥면 중심 + 데이터에서 지정한 추가 오프셋
		var center_offset: Vector2 = BuildingEntity._calculate_center_offset(building_data.grid_size)
		sprite.position = center_offset + building_data.sprite_offset


## Grid 바닥면 오버레이 폴리곤 생성
##
## 건물이 차지할 아이소메트릭 영역을 다이아몬드 형태로 표시
## @param grid_size: 건물 크기 (예: Vector2i(2, 2))
func _update_grid_overlay(grid_size: Vector2i) -> void:
	if not grid_overlay:
		return

	# 기존 개별 타일 오버레이 제거
	for child in grid_overlay.get_children():
		child.queue_free()

	var half_w: float = GameConfig.HALF_TILE_WIDTH
	var half_h: float = GameConfig.HALF_TILE_HEIGHT

	# 단일 타일의 다이아몬드 폴리곤
	var single_tile_polygon = PackedVector2Array([
		Vector2(0, -half_h),      # 상단
		Vector2(half_w, 0),       # 우측
		Vector2(0, half_h),       # 하단
		Vector2(-half_w, 0)       # 좌측
	])

	# 메인 오버레이는 숨기고, 개별 타일 오버레이 사용
	grid_overlay.polygon = PackedVector2Array()

	# 각 타일별로 개별 Polygon2D 생성
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var tile_overlay = Polygon2D.new()
			tile_overlay.polygon = single_tile_polygon

			# GridSystem 공통 함수로 화면 오프셋 계산
			tile_overlay.position = GridSystemNode.grid_offset_to_screen(Vector2i(x, y))

			# 이름으로 좌표 저장 (나중에 색상 업데이트 시 사용)
			tile_overlay.name = "Tile_%d_%d" % [x, y]

			grid_overlay.add_child(tile_overlay)


## 개별 타일별 색상 업데이트
func _update_tile_overlay_colors() -> void:
	if not grid_overlay or current_building_data == null:
		return

	var grid_size: Vector2i = current_building_data.grid_size

	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var tile_name = "Tile_%d_%d" % [x, y]
			var tile_overlay = grid_overlay.get_node_or_null(tile_name)
			if tile_overlay:
				var check_pos = current_grid_pos + Vector2i(x, y)
				var is_occupied = BuildingManager.has_building(check_pos)
				var is_valid = GridSystem.is_valid_position(check_pos)

				if not is_valid or is_occupied:
					tile_overlay.color = COLOR_OVERLAY_INVALID
				else:
					tile_overlay.color = COLOR_OVERLAY_VALID
