extends Node
class_name GridSystemNode

## 그리드 시스템 (Autoload 싱글톤)
## 모든 그리드 좌표 ↔ 월드 좌표 변환을 담당
##
## SOLID 원칙 준수:
## - Single Responsibility: 모든 좌표 변환 책임을 GridSystem이 담당
## - Dependency Inversion: 다른 매니저들은 TileMapLayer 대신 GridSystem에 의존
## - Open/Closed: TileMapLayer 변경 시 GridSystem만 수정하면 됨

# ============================================================
# 그리드 레퍼런스
# ============================================================

## 그라운드 TileMapLayer 참조
## 모든 entity는 ground 타일을 기준으로 배치됨
var ground_layer: TileMapLayer = null

## Navigation Map RID (캐시)
## NavigationServer2D 쿼리에 사용
var cached_navigation_map: RID


# ============================================================
# 내비게이션 관리
# ============================================================

## 장애물로 등록된 그리드 좌표들
## Key: Vector2i (그리드 좌표), Value: Vector2i (건물 크기)
var obstacles: Dictionary = {}


# ============================================================
# 초기화
# ============================================================

## GridSystem 초기화
## 게임 시작 시 test_map.gd에서 호출해야 함
func initialize(tile_layer: TileMapLayer) -> void:
	ground_layer = tile_layer
	print("[GridSystem] 초기화 완료 - Ground Layer: ", tile_layer.name)
	print("[GridSystem] TileSet: ", tile_layer.tile_set)


## Navigation Map 캐싱 (타일 배치 후 호출)
## NavigationServer2D 쿼리 성능 향상을 위해 RID를 미리 저장
func cache_navigation_map() -> void:
	if not ground_layer:
		push_error("[GridSystem] ground_layer가 초기화되지 않았습니다!")
		return

	# NavigationServer2D에서 모든 맵 가져오기
	var maps = NavigationServer2D.get_maps()
	print("[GridSystem] === NavigationServer2D 상태 확인 ===")
	print("[GridSystem] - 총 Navigation Maps: ", maps.size())

	if maps.size() == 0:
		push_error("[GridSystem] NavigationServer2D에 등록된 맵이 없습니다!")
		return

	# 각 맵의 상태 확인
	for i in range(maps.size()):
		var map_rid = maps[i]
		var regions = NavigationServer2D.map_get_regions(map_rid)
		print("[GridSystem] - Map[%d] RID: %s | Regions: %d" % [i, map_rid, regions.size()])

		# Regions가 있는 맵을 찾음
		if regions.size() > 0:
			cached_navigation_map = map_rid
			print("[GridSystem] ✅ Navigation Map 캐시 완료 - Regions가 있는 맵 선택")
			return

	# Regions가 없으면 첫 번째 맵 사용 (기본 동작)
	cached_navigation_map = maps[0]
	push_warning("[GridSystem] ⚠️ 모든 맵에 Regions가 없습니다! 첫 번째 맵 사용")
	print("[GridSystem] Navigation Map 캐시 완료 - RID: ", cached_navigation_map)


# ============================================================
# 좌표 변환 함수 (TileMapLayer 기준)
# ============================================================

## 그리드 좌표 → 월드 좌표 변환 (글로벌 좌표 반환)
## TileMapLayer.map_to_local()로 로컬 좌표를 얻은 후 글로벌로 변환
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	if not ground_layer:
		push_error("[GridSystem] ground_layer가 초기화되지 않았습니다! initialize()를 먼저 호출하세요.")
		return Vector2.ZERO

	var local_pos: Vector2 = ground_layer.map_to_local(grid_pos)
	return ground_layer.to_global(local_pos)


## 월드 좌표 → 그리드 좌표 변환 (글로벌 좌표 입력)
## 글로벌 좌표를 로컬로 변환 후 TileMapLayer.local_to_map() 호출
func world_to_grid(world_pos: Vector2) -> Vector2i:
	if not ground_layer:
		push_error("[GridSystem] ground_layer가 초기화되지 않았습니다! initialize()를 먼저 호출하세요.")
		return Vector2i.ZERO

	var local_pos: Vector2 = ground_layer.to_local(world_pos)
	return ground_layer.local_to_map(local_pos)


# ============================================================
# 유틸리티 함수
# ============================================================

## 두 그리드 좌표 사이의 맨해튼 거리 계산
static func get_manhattan_distance(pos1: Vector2i, pos2: Vector2i) -> int:
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)


## 그리드 오프셋을 화면 오프셋으로 변환
##
## Godot TileMapLayer 좌표계 기준:
## - Grid X+1: (+half_w, -half_h) = 오른쪽 위
## - Grid Y+1: (+half_w, +half_h) = 오른쪽 아래
##
## @param grid_offset: 그리드 좌표 오프셋 (예: Vector2i(1, 0))
## @return: 화면 좌표 오프셋 (픽셀 단위)
##
## 예시:
##   (0, 0) → (0, 0)
##   (1, 0) → (16, -8)
##   (0, 1) → (16, 8)
##   (1, 1) → (32, 0)
func grid_offset_to_screen(grid_offset: Vector2i) -> Vector2:
	var half_w: float = GameConfig.HALF_TILE_WIDTH
	var half_h: float = GameConfig.HALF_TILE_HEIGHT
	var offset_x: float = grid_offset.x * half_w + grid_offset.y * half_w
	var offset_y: float = -grid_offset.x * half_h + grid_offset.y * half_h
	return Vector2(offset_x, offset_y)


## 그리드 좌표가 유효한 범위 내에 있는지 확인
## min_pos: 최소 그리드 좌표 (포함)
## max_pos: 최대 그리드 좌표 (포함)
static func is_valid_grid_position(grid_pos: Vector2i, min_pos: Vector2i, max_pos: Vector2i) -> bool:
	return (grid_pos.x >= min_pos.x and grid_pos.x <= max_pos.x and
			grid_pos.y >= min_pos.y and grid_pos.y <= max_pos.y)


## 그리드 좌표가 맵 범위 내에 있는지 확인 (건물 크기 고려)
##
## TileMapLayer의 사용 중인 타일 범위를 기준으로 검증
## 건물 크기(grid_size)를 고려하여 모든 타일이 맵 안에 있는지 확인
##
## @param grid_pos: 검증할 그리드 좌표 (건물의 좌상단 위치)
## @param grid_size: 건물 크기 (그리드 단위, 기본값: 1x1)
## @return: 모든 타일이 맵 범위 내에 있으면 true, 하나라도 벗어나면 false
func is_valid_position(grid_pos: Vector2i, grid_size: Vector2i = Vector2i(1, 1)) -> bool:
	# 1. ground_layer 초기화 확인
	if not ground_layer:
		print("[GridSystem] ERROR: ground_layer가 초기화되지 않았습니다!")
		return false

	# 2. 맵의 사용 중인 타일 범위 가져오기
	var used_rect: Rect2i = ground_layer.get_used_rect()

	# 3. 건물이 차지하는 모든 타일이 맵 범위 내에 있는지 확인
	# grid_pos는 건물의 좌상단 위치
	# grid_size만큼의 영역을 검사
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var check_pos = grid_pos + Vector2i(x, y)

			# used_rect 범위를 벗어나면 false
			if not used_rect.has_point(check_pos):
				return false

			# 해당 위치에 타일이 실제로 존재하는지 확인
			var tile_data: TileData = ground_layer.get_cell_tile_data(check_pos)
			if tile_data == null:
				return false  # 타일이 없는 빈 공간

	return true


## 그리드 좌표를 문자열로 변환 (디버그용)
static func grid_to_string(grid_pos: Vector2i) -> String:
	return "(%d, %d)" % [grid_pos.x, grid_pos.y]


# ============================================================
# 내비게이션 검증
# ============================================================

## 특정 그리드 좌표가 Navigation 가능한지 검증
##
## TileMapLayer의 Navigation Polygon 존재 여부로 판단
## 맵 밖 좌표는 자동으로 false 반환 (타일이 없으므로)
##
## @param grid_pos: 검증할 그리드 좌표
## @return: Navigation 가능하면 true, 불가능하면 false
func is_valid_navigation_position(grid_pos: Vector2i) -> bool:
	# 1. ground_layer 초기화 확인
	if not ground_layer:
		push_error("[GridSystem] ground_layer가 초기화되지 않았습니다!")
		return false

	# 2. 타일 데이터 조회 (맵 밖이면 null 반환)
	var tile_data: TileData = ground_layer.get_cell_tile_data(grid_pos)
	if tile_data == null:
		return false  # 타일이 없음 (맵 밖 or 빈 공간)

	# 3. Navigation Polygon 확인
	var nav_polygon = tile_data.get_navigation_polygon(0)  # Layer 0
	return (nav_polygon != null)


## 특정 그리드 위치를 장애물로 등록
##
## 내부 obstacles Dictionary에 추가하여 추후 검증 및 디버그에 활용
## 실제 Navigation 차단은 NavigationObstacle2D가 담당 (Phase 5)
##
## @param grid_pos: 장애물의 그리드 좌표
## @param size: 장애물 크기 (그리드 단위, 기본값: 1x1)
func mark_as_obstacle(grid_pos: Vector2i, size: Vector2i = Vector2i(1, 1)) -> void:
	# 1. 장애물 Dictionary에 등록
	obstacles[grid_pos] = size

	# 2. 디버그 로그
	print("[GridSystem] 장애물 등록: Grid %s, Size: %s" % [grid_to_string(grid_pos), size])

	# 참고: 실제 Navigation 차단은 BuildingEntity의 NavigationObstacle2D가 처리함 (Phase 5)
	# 이 메서드는 주로 내부 상태 관리 및 검증용
