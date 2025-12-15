extends Node

## 그리드 시스템
## 그리드 좌표 ↔ 월드 좌표 변환 (Diamond Right Isometric)

# ============================================================
# 그리드 설정
# ============================================================

## 타일 크기 (픽셀 단위)
## 주의: 이 값은 GameConfig의 TILE_SIZE와 동기화되어야 함
const TILE_WIDTH: int = 32
const TILE_HEIGHT: int = 32


# ============================================================
# 좌표 변환 함수 (Static)
# ============================================================

## 그리드 좌표 → 월드 좌표 변환
## Diamond Right 아이소메트릭 공식 사용
static func grid_to_world(grid_pos: Vector2i) -> Vector2:
	var world_x: float = (grid_pos.x - grid_pos.y) * (TILE_WIDTH / 2.0)
	var world_y: float = (grid_pos.x + grid_pos.y) * (TILE_HEIGHT / 2.0)
	return Vector2(world_x, world_y)


## 월드 좌표 → 그리드 좌표 변환
## 역변환 공식 사용
static func world_to_grid(world_pos: Vector2) -> Vector2i:
	# 정규화된 좌표 계산
	var normalized_x: float = world_pos.x / (TILE_WIDTH / 2.0)
	var normalized_y: float = world_pos.y / (TILE_HEIGHT / 2.0)

	# 그리드 좌표 계산
	var grid_x: int = int(floor((normalized_x + normalized_y) / 2.0))
	var grid_y: int = int(floor((normalized_y - normalized_x) / 2.0))

	return Vector2i(grid_x, grid_y)


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
