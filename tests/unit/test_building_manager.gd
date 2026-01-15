extends GutTest

## BuildingManager 단위 테스트
## BuildingManager.can_build_at() 및 create_building() 메서드 검증

# ============================================================
# 테스트 환경 설정
# ============================================================

var building_manager: Node  # BuildingManager 타입 (Autoload 스크립트)
var grid_system: GridSystemNode
var ground_layer: TileMapLayer
var entities_parent: Node2D

# Mock BuildingData
var test_building_data_1x1: BuildingData
var test_building_data_2x2: BuildingData
var test_building_data_3x3: BuildingData


func before_each():
	# Autoload GridSystem 사용
	grid_system = GridSystemNode.new()
	add_child(grid_system)

	# Mock TileMapLayer 생성
	ground_layer = TileMapLayer.new()
	add_child(ground_layer)

	# TileSet 설정
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(64, 32)
	ground_layer.tile_set = tileset

	# 테스트용 타일 배치 (10x10 맵)
	_setup_test_map()

	# GridSystem 초기화
	grid_system.initialize(ground_layer)

	# BuildingManager 인스턴스 생성
	var BuildingManagerScript = load("res://scripts/managers/building_manager.gd")
	building_manager = BuildingManagerScript.new()
	add_child(building_manager)

	# Entities 부모 노드 생성
	entities_parent = Node2D.new()
	add_child(entities_parent)

	# ✅ BuildingManager 초기화 (Mock GridSystem 주입)
	# 하이브리드 의존성 주입 패턴: 테스트에서는 Mock을 주입하여 Autoload 대신 사용
	building_manager.initialize(entities_parent, grid_system)

	# Mock BuildingData 생성
	_create_mock_building_data()


func after_each():
	# 정리
	building_manager.clear_all_buildings()
	entities_parent.queue_free()
	building_manager.queue_free()
	ground_layer.queue_free()
	grid_system.queue_free()


## 테스트용 10x10 맵 생성
func _setup_test_map():
	# TileSet에 소스 추가
	var source = TileSetAtlasSource.new()

	# ✅ 더미 텍스처 생성 및 할당 (필수!)
	# TileSetAtlasSource는 텍스처가 없으면 get_cell_tile_data()가 null을 반환함
	var dummy_image = Image.create(64, 32, false, Image.FORMAT_RGBA8)
	var dummy_texture = ImageTexture.create_from_image(dummy_image)
	source.texture = dummy_texture

	source.texture_region_size = Vector2i(64, 32)
	# ✅ 아틀라스 좌표 (0, 0)에 타일 생성 (TileData 생성)
	source.create_tile(Vector2i(0, 0))
	ground_layer.tile_set.add_source(source, 0)

	# 10x10 타일 배치
	for x in range(10):
		for y in range(10):
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))


## Mock BuildingData 생성
func _create_mock_building_data():
	# ✅ 더미 텍스처 생성 (BuildingEntity가 텍스처를 요구함)
	var dummy_image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var dummy_texture = ImageTexture.create_from_image(dummy_image)

	# 1x1 건물
	test_building_data_1x1 = BuildingData.new()
	test_building_data_1x1.entity_id = "test_house_1x1"
	test_building_data_1x1.entity_name = "테스트 주택 1x1"
	test_building_data_1x1.grid_size = Vector2i(1, 1)
	test_building_data_1x1.sprite_texture = dummy_texture  # ✅ 텍스처 설정

	# 2x2 건물
	test_building_data_2x2 = BuildingData.new()
	test_building_data_2x2.entity_id = "test_house_2x2"
	test_building_data_2x2.entity_name = "테스트 주택 2x2"
	test_building_data_2x2.grid_size = Vector2i(2, 2)
	test_building_data_2x2.sprite_texture = dummy_texture  # ✅ 텍스처 설정

	# 3x3 건물
	test_building_data_3x3 = BuildingData.new()
	test_building_data_3x3.entity_id = "test_house_3x3"
	test_building_data_3x3.entity_name = "테스트 주택 3x3"
	test_building_data_3x3.grid_size = Vector2i(3, 3)
	test_building_data_3x3.sprite_texture = dummy_texture  # ✅ 텍스처 설정


# ============================================================
# 테스트: can_build_at() - 정상 케이스
# ============================================================

func test_can_build_at_valid_position_1x1():
	# Given: 유효한 위치와 1x1 건물
	var grid_pos = Vector2i(5, 5)

	# When: 건설 가능 여부 확인
	var result = building_manager.can_build_at(test_building_data_1x1, grid_pos)

	# Then: 성공
	assert_true(result.success, "유효한 위치에 1x1 건물 건설 가능해야 함")
	assert_eq(result.reason, "", "성공 시 이유는 빈 문자열이어야 함")


func test_can_build_at_valid_position_2x2():
	# Given: 유효한 위치와 2x2 건물
	var grid_pos = Vector2i(4, 4)

	# When: 건설 가능 여부 확인
	var result = building_manager.can_build_at(test_building_data_2x2, grid_pos)

	# Then: 성공
	assert_true(result.success, "유효한 위치에 2x2 건물 건설 가능해야 함")


func test_can_build_at_valid_position_3x3():
	# Given: 유효한 위치와 3x3 건물
	var grid_pos = Vector2i(3, 3)

	# When: 건설 가능 여부 확인
	var result = building_manager.can_build_at(test_building_data_3x3, grid_pos)

	# Then: 성공
	assert_true(result.success, "유효한 위치에 3x3 건물 건설 가능해야 함")


# ============================================================
# 테스트: can_build_at() - 맵 범위 초과
# ============================================================

func test_can_build_at_outside_map_1x1():
	# Given: 맵 밖 위치
	var grid_pos = Vector2i(10, 5)

	# When: 건설 가능 여부 확인
	var result = building_manager.can_build_at(test_building_data_1x1, grid_pos)

	# Then: 실패 (맵 범위 초과)
	assert_false(result.success, "맵 밖에는 건설 불가능해야 함")
	assert_eq(result.reason, "맵 범위를 벗어났습니다", "맵 범위 초과 메시지 확인")


func test_can_build_at_outside_map_2x2_partial():
	# Given: 2x2 건물이 일부만 맵 안에 있는 위치
	var grid_pos = Vector2i(9, 9)  # (9,9), (10,9), (9,10), (10,10)

	# When: 건설 가능 여부 확인
	var result = building_manager.can_build_at(test_building_data_2x2, grid_pos)

	# Then: 실패
	assert_false(result.success, "2x2 건물이 일부만 맵 안에 있으면 건설 불가능해야 함")
	assert_eq(result.reason, "맵 범위를 벗어났습니다")


func test_can_build_at_negative_position():
	# Given: 음수 좌표
	var grid_pos = Vector2i(-1, 5)

	# When: 건설 가능 여부 확인
	var result = building_manager.can_build_at(test_building_data_1x1, grid_pos)

	# Then: 실패
	assert_false(result.success, "음수 좌표는 건설 불가능해야 함")


# ============================================================
# 테스트: can_build_at() - 기존 건물 중복
# ============================================================

func test_can_build_at_overlapping_building_1x1():
	# Given: 이미 건물이 있는 위치
	var grid_pos = Vector2i(5, 5)
	building_manager.create_building(grid_pos, test_building_data_1x1)

	# When: 같은 위치에 건설 시도
	var result = building_manager.can_build_at(test_building_data_1x1, grid_pos)

	# Then: 실패 (건물 중복)
	assert_false(result.success, "이미 건물이 있는 위치에는 건설 불가능해야 함")
	assert_true(result.reason.contains("이미 건물이 존재합니다"), "건물 중복 메시지 확인")


func test_can_build_at_overlapping_building_2x2():
	# Given: 2x2 건물 배치
	var grid_pos = Vector2i(4, 4)  # (4,4), (5,4), (4,5), (5,5)
	building_manager.create_building(grid_pos, test_building_data_2x2)

	# When: 겹치는 위치에 건설 시도
	var overlap_pos = Vector2i(5, 5)  # 기존 건물과 겹침
	var result = building_manager.can_build_at(test_building_data_1x1, overlap_pos)

	# Then: 실패
	assert_false(result.success, "2x2 건물이 차지한 타일에는 건설 불가능해야 함")


func test_can_build_at_adjacent_building():
	# Given: 인접한 위치에 건물이 있음
	var grid_pos = Vector2i(5, 5)
	building_manager.create_building(grid_pos, test_building_data_1x1)

	# When: 인접 위치에 건설 시도
	var adjacent_pos = Vector2i(6, 5)
	var result = building_manager.can_build_at(test_building_data_1x1, adjacent_pos)

	# Then: 성공 (겹치지 않음)
	assert_true(result.success, "인접한 위치는 건설 가능해야 함")


# ============================================================
# 테스트: can_build_at() - null 체크
# ============================================================

func test_can_build_at_null_building_data():
	# Given: null building_data
	var grid_pos = Vector2i(5, 5)

	# When: 건설 가능 여부 확인
	var result = building_manager.can_build_at(null, grid_pos)

	# Then: 실패
	assert_false(result.success, "building_data가 null이면 건설 불가능해야 함")
	assert_eq(result.reason, "건물 데이터가 없습니다")


# ============================================================
# 테스트: create_building() - 검증 통합
# ============================================================

func test_create_building_success():
	# Given: 유효한 위치와 건물 데이터
	var grid_pos = Vector2i(5, 5)

	# When: 건물 생성
	var building = building_manager.create_building(grid_pos, test_building_data_1x1)

	# Then: 성공
	assert_not_null(building, "건물이 생성되어야 함")
	assert_true(building_manager.has_building(grid_pos), "Dictionary에 등록되어야 함")


func test_create_building_failure_outside_map():
	# Given: 맵 밖 위치
	var grid_pos = Vector2i(10, 5)

	# When: 건물 생성 시도 (push_warning이 발생하지만 의도된 동작)
	var building = building_manager.create_building(grid_pos, test_building_data_1x1)

	# Then: 실패 (null 반환)
	assert_null(building, "맵 밖에는 건물 생성 불가능해야 함")
	assert_false(building_manager.has_building(grid_pos), "Dictionary에 등록되지 않아야 함")


func test_create_building_failure_overlapping():
	# Given: 이미 건물이 있는 위치
	var grid_pos = Vector2i(5, 5)
	building_manager.create_building(grid_pos, test_building_data_1x1)

	# When: 같은 위치에 건물 생성 시도 (push_warning이 발생하지만 의도된 동작)
	var building = building_manager.create_building(grid_pos, test_building_data_1x1)

	# Then: 실패 (null 반환)
	assert_null(building, "중복 위치에는 건물 생성 불가능해야 함")


func test_create_building_2x2_occupies_all_tiles():
	# Given: 2x2 건물
	var grid_pos = Vector2i(4, 4)

	# When: 건물 생성
	var building = building_manager.create_building(grid_pos, test_building_data_2x2)

	# Then: 2x2 영역 모두 차지
	assert_not_null(building, "건물이 생성되어야 함")
	assert_true(building_manager.has_building(Vector2i(4, 4)), "(4,4) 타일 차지")
	assert_true(building_manager.has_building(Vector2i(5, 4)), "(5,4) 타일 차지")
	assert_true(building_manager.has_building(Vector2i(4, 5)), "(4,5) 타일 차지")
	assert_true(building_manager.has_building(Vector2i(5, 5)), "(5,5) 타일 차지")


# ============================================================
# 테스트: 시그널
# ============================================================

func test_signal_building_placed_emitted():
	# Given: 유효한 위치
	var grid_pos = Vector2i(5, 5)

	# When: 건물 생성
	watch_signals(building_manager)
	building_manager.create_building(grid_pos, test_building_data_1x1)

	# Then: building_placed 시그널 발송
	assert_signal_emitted(building_manager, "building_placed", "building_placed 시그널이 발송되어야 함")


func test_signal_building_placement_failed_emitted():
	# Given: 맵 밖 위치
	var grid_pos = Vector2i(10, 5)

	# When: 건물 생성 시도 (push_warning이 발생하지만 의도된 동작)
	watch_signals(building_manager)
	building_manager.create_building(grid_pos, test_building_data_1x1)

	# Then: building_placement_failed 시그널 발송
	assert_signal_emitted(building_manager, "building_placement_failed", "building_placement_failed 시그널이 발송되어야 함")
