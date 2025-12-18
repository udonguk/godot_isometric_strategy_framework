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


# ============================================================
# 초기화
# ============================================================

## GridSystem 초기화
## 게임 시작 시 test_map.gd에서 호출해야 함
func initialize(tile_layer: TileMapLayer) -> void:
	ground_layer = tile_layer
	print("[GridSystem] 초기화 완료 - Ground Layer: ", tile_layer.name)
	print("[GridSystem] TileSet: ", tile_layer.tile_set)


# ============================================================
# 좌표 변환 함수 (TileMapLayer 기준)
# ============================================================

## 그리드 좌표 → 월드 좌표 변환
## TileMapLayer.map_to_local()을 사용하여 정확한 좌표 계산
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	if not ground_layer:
		push_error("[GridSystem] ground_layer가 초기화되지 않았습니다! initialize()를 먼저 호출하세요.")
		return Vector2.ZERO

	return ground_layer.map_to_local(grid_pos)


## 월드 좌표 → 그리드 좌표 변환
## TileMapLayer.local_to_map()을 사용하여 정확한 좌표 계산
func world_to_grid(world_pos: Vector2) -> Vector2i:
	if not ground_layer:
		push_error("[GridSystem] ground_layer가 초기화되지 않았습니다! initialize()를 먼저 호출하세요.")
		return Vector2i.ZERO

	return ground_layer.local_to_map(world_pos)


# ============================================================
# 유틸리티 함수
# ============================================================

## 두 그리드 좌표 사이의 맨해튼 거리 계산
static func get_manhattan_distance(pos1: Vector2i, pos2: Vector2i) -> int:
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)


## 그리드 좌표가 유효한 범위 내에 있는지 확인
## min_pos: 최소 그리드 좌표 (포함)
## max_pos: 최대 그리드 좌표 (포함)
static func is_valid_grid_position(grid_pos: Vector2i, min_pos: Vector2i, max_pos: Vector2i) -> bool:
	return (grid_pos.x >= min_pos.x and grid_pos.x <= max_pos.x and
			grid_pos.y >= min_pos.y and grid_pos.y <= max_pos.y)


## 그리드 좌표를 문자열로 변환 (디버그용)
static func grid_to_string(grid_pos: Vector2i) -> String:
	return "(%d, %d)" % [grid_pos.x, grid_pos.y]
