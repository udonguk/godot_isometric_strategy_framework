extends GutTest

## GridSystem 단위 테스트
## GridSystem.is_valid_position() 메서드의 다양한 시나리오 검증

# ============================================================
# 테스트 환경 설정
# ============================================================

var grid_system: GridSystemNode
var ground_layer: TileMapLayer

func before_each():
	# GridSystem 인스턴스 생성
	grid_system = GridSystemNode.new()
	add_child(grid_system)

	# Mock TileMapLayer 생성
	ground_layer = TileMapLayer.new()
	add_child(ground_layer)

	# TileSet 생성 및 설정
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(64, 32)  # 아이소메트릭 타일 크기
	ground_layer.tile_set = tileset

	# 테스트용 타일 배치 (10x10 맵)
	_setup_test_map()

	# GridSystem 초기화
	grid_system.initialize(ground_layer)


func after_each():
	# 정리
	ground_layer.queue_free()
	grid_system.queue_free()


## 테스트용 10x10 맵 생성
func _setup_test_map():
	# TileSet에 소스 추가 (더미)
	var source = TileSetAtlasSource.new()
	source.texture_region_size = Vector2i(64, 32)
	ground_layer.tile_set.add_source(source, 0)

	# 10x10 타일 배치
	for x in range(10):
		for y in range(10):
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))


# ============================================================
# 테스트: 1x1 건물
# ============================================================

func test_valid_position_1x1_inside_map():
	# Given: 맵 안의 유효한 위치
	var grid_pos = Vector2i(5, 5)
	var grid_size = Vector2i(1, 1)

	# When: 위치 검증
	var result = grid_system.is_valid_position(grid_pos, grid_size)

	# Then: 검증 성공
	assert_true(result, "맵 중앙 (5, 5)는 유효한 위치여야 함")


func test_invalid_position_1x1_outside_map_negative():
	# Given: 맵 밖 위치 (음수)
	var grid_pos = Vector2i(-1, 5)
	var grid_size = Vector2i(1, 1)

	# When: 위치 검증
	var result = grid_system.is_valid_position(grid_pos, grid_size)

	# Then: 검증 실패
	assert_false(result, "음수 좌표는 맵 밖이므로 유효하지 않아야 함")


func test_invalid_position_1x1_outside_map_too_large():
	# Given: 맵 밖 위치 (범위 초과)
	var grid_pos = Vector2i(10, 5)
	var grid_size = Vector2i(1, 1)

	# When: 위치 검증
	var result = grid_system.is_valid_position(grid_pos, grid_size)

	# Then: 검증 실패
	assert_false(result, "(10, 5)는 맵 범위(0-9)를 벗어나므로 유효하지 않아야 함")


func test_valid_position_1x1_corner():
	# Given: 맵 모서리 (0, 0)
	var grid_pos = Vector2i(0, 0)
	var grid_size = Vector2i(1, 1)

	# When: 위치 검증
	var result = grid_system.is_valid_position(grid_pos, grid_size)

	# Then: 검증 성공
	assert_true(result, "맵 모서리 (0, 0)는 유효한 위치여야 함")


func test_valid_position_1x1_bottom_right():
	# Given: 맵 오른쪽 아래 (9, 9)
	var grid_pos = Vector2i(9, 9)
	var grid_size = Vector2i(1, 1)

	# When: 위치 검증
	var result = grid_system.is_valid_position(grid_pos, grid_size)

	# Then: 검증 성공
	assert_true(result, "맵 오른쪽 아래 (9, 9)는 유효한 위치여야 함")


# ============================================================
# 테스트: 2x2 건물
# ============================================================

func test_valid_position_2x2_inside_map():
	# Given: 2x2 건물이 완전히 맵 안에 들어가는 위치
	var grid_pos = Vector2i(4, 4)  # (4,4), (5,4), (4,5), (5,5)
	var grid_size = Vector2i(2, 2)

	# When: 위치 검증
	var result = grid_system.is_valid_position(grid_pos, grid_size)

	# Then: 검증 성공
	assert_true(result, "2x2 건물이 맵 안에 완전히 들어가므로 유효해야 함")


func test_invalid_position_2x2_partial_outside():
	# Given: 2x2 건물이 일부만 맵 안에 있는 위치
	var grid_pos = Vector2i(9, 9)  # (9,9), (10,9), (9,10), (10,10) - 일부 범위 초과
	var grid_size = Vector2i(2, 2)

	# When: 위치 검증
	var result = grid_system.is_valid_position(grid_pos, grid_size)

	# Then: 검증 실패
	assert_false(result, "2x2 건물이 맵 범위를 벗어나므로 유효하지 않아야 함")


func test_valid_position_2x2_corner():
	# Given: 2x2 건물이 맵 모서리에 정확히 맞는 위치
	var grid_pos = Vector2i(0, 0)  # (0,0), (1,0), (0,1), (1,1)
	var grid_size = Vector2i(2, 2)

	# When: 위치 검증
	var result = grid_system.is_valid_position(grid_pos, grid_size)

	# Then: 검증 성공
	assert_true(result, "2x2 건물이 맵 모서리에 정확히 맞으므로 유효해야 함")


func test_valid_position_2x2_max_valid_position():
	# Given: 2x2 건물이 배치 가능한 최대 위치
	var grid_pos = Vector2i(8, 8)  # (8,8), (9,8), (8,9), (9,9) - 맵 범위 내 최대
	var grid_size = Vector2i(2, 2)

	# When: 위치 검증
	var result = grid_system.is_valid_position(grid_pos, grid_size)

	# Then: 검증 성공
	assert_true(result, "2x2 건물이 맵 범위 내 최대 위치에 정확히 맞으므로 유효해야 함")


# ============================================================
# 테스트: 3x3 건물
# ============================================================

func test_valid_position_3x3_inside_map():
	# Given: 3x3 건물이 완전히 맵 안에 들어가는 위치
	var grid_pos = Vector2i(3, 3)  # (3,3) ~ (5,5)
	var grid_size = Vector2i(3, 3)

	# When: 위치 검증
	var result = grid_system.is_valid_position(grid_pos, grid_size)

	# Then: 검증 성공
	assert_true(result, "3x3 건물이 맵 안에 완전히 들어가므로 유효해야 함")


func test_invalid_position_3x3_outside_map():
	# Given: 3x3 건물이 맵 범위를 벗어나는 위치
	var grid_pos = Vector2i(8, 8)  # (8,8) ~ (10,10) - 일부 범위 초과
	var grid_size = Vector2i(3, 3)

	# When: 위치 검증
	var result = grid_system.is_valid_position(grid_pos, grid_size)

	# Then: 검증 실패
	assert_false(result, "3x3 건물이 맵 범위를 벗어나므로 유효하지 않아야 함")


func test_valid_position_3x3_max_valid_position():
	# Given: 3x3 건물이 배치 가능한 최대 위치
	var grid_pos = Vector2i(7, 7)  # (7,7) ~ (9,9) - 맵 범위 내 최대
	var grid_size = Vector2i(3, 3)

	# When: 위치 검증
	var result = grid_system.is_valid_position(grid_pos, grid_size)

	# Then: 검증 성공
	assert_true(result, "3x3 건물이 맵 범위 내 최대 위치에 정확히 맞으므로 유효해야 함")


# ============================================================
# 테스트: 경계 케이스
# ============================================================

func test_invalid_position_empty_tile():
	# Given: 타일이 배치되지 않은 빈 공간
	var grid_pos = Vector2i(15, 15)  # 맵 범위 밖
	var grid_size = Vector2i(1, 1)

	# When: 위치 검증
	var result = grid_system.is_valid_position(grid_pos, grid_size)

	# Then: 검증 실패
	assert_false(result, "타일이 없는 빈 공간은 유효하지 않아야 함")


func test_invalid_position_grid_system_not_initialized():
	# Given: GridSystem이 초기화되지 않은 상태
	var uninitialized_grid = GridSystemNode.new()
	add_child(uninitialized_grid)
	var grid_pos = Vector2i(5, 5)
	var grid_size = Vector2i(1, 1)

	# When: 위치 검증
	var result = uninitialized_grid.is_valid_position(grid_pos, grid_size)

	# Then: 검증 실패
	assert_false(result, "GridSystem이 초기화되지 않으면 유효하지 않아야 함")

	# Cleanup
	uninitialized_grid.queue_free()


func test_valid_position_with_default_grid_size():
	# Given: grid_size 파라미터를 생략 (기본값 1x1)
	var grid_pos = Vector2i(5, 5)

	# When: 위치 검증 (grid_size 생략)
	var result = grid_system.is_valid_position(grid_pos)

	# Then: 검증 성공
	assert_true(result, "grid_size 기본값(1x1)으로 정상 동작해야 함")
