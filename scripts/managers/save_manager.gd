extends Node
class_name SaveManagerClass

## 저장 시스템 매니저
##
## FileAccess + JSON 기반으로 게임 상태를 저장/로드합니다.
##
## SOLID 원칙:
## - Single Responsibility: 저장/로드 작업만 담당
## - 각 매니저의 serialize/deserialize는 해당 매니저가 담당

# ============================================================
# 상수
# ============================================================

## 저장 파일 디렉토리 경로
const SAVE_DIR: String = "user://saves/"

## 저장 파일 확장자
const SAVE_EXTENSION: String = ".save"

## 저장 파일 버전 (호환성 체크용)
const VERSION: String = "1.0.0"

## 최대 저장 슬롯 수
const MAX_SLOTS: int = 3

## 자동 저장 간격 (초)
const AUTOSAVE_INTERVAL: float = 600.0  # 10분


# ============================================================
# 시그널
# ============================================================

## 게임 저장 완료 시 발생
signal game_saved(slot: int)

## 게임 로드 완료 시 발생
signal game_loaded(slot: int)

## 저장 실패 시 발생
signal save_failed(reason: String)

## 로드 실패 시 발생
signal load_failed(reason: String)

## 저장 파일 삭제 시 발생
signal save_deleted(slot: int)


# ============================================================
# 빠른 저장/자동 저장 상태 (Task 4)
# ============================================================

## 빠른 저장 슬롯 (기본값: 1)
var quick_save_slot: int = 1

## 자동 저장 타이머
var autosave_timer: Timer = null

## 자동 저장 활성화 여부
var autosave_enabled: bool = true


# ============================================================
# 생명주기
# ============================================================

func _ready() -> void:
	_ensure_save_directory()
	_setup_autosave_timer()
	print("[SaveManager] 초기화 완료")
	print("[SaveManager] 저장 경로: ", SAVE_DIR)


# ============================================================
# 저장 디렉토리 관리 (Task 1.2)
# ============================================================

## 저장 디렉토리가 존재하는지 확인하고, 없으면 생성
func _ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		var error = DirAccess.make_dir_recursive_absolute(SAVE_DIR)
		if error == OK:
			print("[SaveManager] 저장 디렉토리 생성: ", SAVE_DIR)
		else:
			push_error("[SaveManager] 저장 디렉토리 생성 실패: ", error)


## 슬롯별 저장 파일 경로 반환
## @param slot: 슬롯 번호 (1 ~ MAX_SLOTS)
## @return: 저장 파일 전체 경로
func get_save_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d%s" % [slot, SAVE_EXTENSION]


## 자동 저장 파일 경로 반환
func get_autosave_path() -> String:
	return SAVE_DIR + "autosave" + SAVE_EXTENSION


## 슬롯에 저장 파일이 있는지 확인
func has_save(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))


## 자동 저장 파일이 있는지 확인
func has_autosave() -> bool:
	return FileAccess.file_exists(get_autosave_path())


# ============================================================
# JSON 저장/로드 (Task 1.3)
# ============================================================

## JSON 데이터를 파일로 저장 (내부 헬퍼)
## @param path: 저장 파일 경로
## @param data: 저장할 Dictionary 데이터
## @return: 저장 성공 여부
func _save_json(path: String, data: Dictionary) -> bool:
	print("[SaveManager] _save_json() 호출 - 경로: %s" % path)

	var json_string = JSON.stringify(data, "\t")  # 들여쓰기로 가독성 향상
	print("[SaveManager] JSON 문자열 길이: %d bytes" % json_string.length())

	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var error = FileAccess.get_open_error()
		push_error("[SaveManager] 파일 열기 실패: %s (에러코드: %d)" % [path, error])
		return false

	file.store_string(json_string)
	file.close()
	print("[SaveManager] 파일 저장 완료")
	return true


## 파일에서 JSON 데이터 로드 (내부 헬퍼)
## @param path: 로드할 파일 경로
## @return: 로드된 Dictionary (실패 시 빈 Dictionary)
func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("[SaveManager] 파일이 존재하지 않음: ", path)
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var error = FileAccess.get_open_error()
		push_error("[SaveManager] 파일 열기 실패: %s (에러: %s)" % [path, error])
		return {}

	var json_string = file.get_as_text()
	file.close()

	var result = JSON.parse_string(json_string)
	if result == null:
		push_error("[SaveManager] JSON 파싱 실패: ", path)
		return {}

	return result


# ============================================================
# 의존성 (Task 2.4)
# ============================================================

## 유닛 부모 노드 (로드 시 유닛 생성 위치)
var units_parent: Node2D = null

## UnitEntity 씬 참조 (preload)
const UnitEntityScene = preload("res://scenes/entitys/unit_entity.tscn")


## SaveManager 초기화 (main.gd에서 호출)
## @param unit_parent: 유닛을 생성할 부모 노드
func initialize(unit_parent: Node2D) -> void:
	units_parent = unit_parent
	print("[SaveManager] 유닛 부모 노드 설정: ", unit_parent.name if unit_parent else "null")


# ============================================================
# 유닛 직렬화 (Task 2.2)
# ============================================================

## 유닛 데이터 직렬화
## @return: [{grid_pos, direction, state}, ...] 형태의 Array
func _serialize_units() -> Array:
	var units_data: Array = []

	var units = get_tree().get_nodes_in_group("units")
	for unit in units:
		if unit is UnitEntity:
			units_data.append({
				"grid_pos": {"x": unit.grid_position.x, "y": unit.grid_position.y},
				"direction": unit.current_direction,
				"state": unit.current_state
			})

	return units_data


## 유닛 데이터 복원 (동기 방식)
## @param units_data: _serialize_units()가 반환한 형태의 Array
## @param parent_node: 유닛을 추가할 부모 노드
func _deserialize_units(units_data: Array, parent_node: Node2D) -> void:
	# 선택 해제 (삭제될 유닛 참조 방지)
	SelectionManager.deselect_all()

	# 기존 유닛 모두 제거
	var existing_units = get_tree().get_nodes_in_group("units")
	for unit in existing_units:
		unit.queue_free()

	# 새 유닛 생성 (queue_free와 충돌 없음 - 다른 인스턴스)
	for unit_info in units_data:
		var pos_data = unit_info.get("grid_pos", {})
		var grid_pos = Vector2i(pos_data.get("x", 0), pos_data.get("y", 0))
		var direction = unit_info.get("direction", 0)

		# 유닛 생성
		var unit = UnitEntityScene.instantiate()
		unit.grid_position = grid_pos
		unit.position = GridSystem.grid_to_world(grid_pos)
		unit.current_direction = direction

		parent_node.add_child(unit)

		# 유닛 그룹 등록 (UnitEntity._ready에서 처리되지만 명시적으로)
		if not unit.is_in_group("units"):
			unit.add_to_group("units")

	print("[SaveManager] 유닛 복원 완료: %d개" % units_data.size())


# ============================================================
# 카메라 직렬화 (Task 2.3)
# ============================================================

## 카메라 데이터 직렬화
## @return: {position, zoom} 형태의 Dictionary
func _serialize_camera() -> Dictionary:
	var camera = get_viewport().get_camera_2d()
	if camera:
		return {
			"position": {"x": camera.global_position.x, "y": camera.global_position.y},
			"zoom": {"x": camera.zoom.x, "y": camera.zoom.y}
		}
	return {}


## 카메라 데이터 복원
## @param camera_data: _serialize_camera()가 반환한 형태의 Dictionary
func _deserialize_camera(camera_data: Dictionary) -> void:
	var camera = get_viewport().get_camera_2d()
	if camera and not camera_data.is_empty():
		var pos_data = camera_data.get("position", {})
		camera.global_position = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))

		var zoom_data = camera_data.get("zoom", {"x": 1, "y": 1})
		camera.zoom = Vector2(zoom_data.get("x", 1), zoom_data.get("y", 1))

		print("[SaveManager] 카메라 복원 완료")


# ============================================================
# 통합 저장/로드 (Task 2.4)
# ============================================================

## 게임 저장
## @param slot: 저장 슬롯 번호 (1 ~ MAX_SLOTS)
## @return: 저장 성공 여부
func save_game(slot: int) -> bool:
	print("[SaveManager] === save_game() 시작 (슬롯: %d) ===" % slot)

	_ensure_save_directory()

	# 전체 게임 상태 수집
	var buildings_data = BuildingManager.serialize().get("buildings", [])
	var units_data = _serialize_units()
	var camera_data = _serialize_camera()

	print("[SaveManager] 수집된 데이터:")
	print("[SaveManager]   - 건물: %d개" % buildings_data.size())
	print("[SaveManager]   - 유닛: %d개" % units_data.size())
	print("[SaveManager]   - 카메라: %s" % str(camera_data))

	var save_data: Dictionary = {
		"version": VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_state": {
			"buildings": buildings_data,
			"units": units_data,
			"camera": camera_data
		}
	}

	# JSON 저장
	var path = get_save_path(slot)
	print("[SaveManager] 저장 경로: %s" % path)

	# 실제 파일 시스템 경로 출력
	var global_path = ProjectSettings.globalize_path(path)
	print("[SaveManager] 실제 파일 경로: %s" % global_path)

	if _save_json(path, save_data):
		game_saved.emit(slot)
		print("[SaveManager] ✅ 게임 저장 성공!")
		return true
	else:
		save_failed.emit("파일 저장 실패")
		print("[SaveManager] ❌ 게임 저장 실패!")
		return false


## 게임 로드
## @param slot: 로드할 슬롯 번호 (1 ~ MAX_SLOTS)
## @return: 로드 성공 여부
func load_game(slot: int) -> bool:
	var path = get_save_path(slot)
	var save_data = _load_json(path)

	if save_data.is_empty():
		load_failed.emit("저장 파일이 없거나 손상됨")
		return false

	# 버전 호환성 체크
	var saved_version = save_data.get("version", "0.0.0")
	if saved_version != VERSION:
		push_warning("[SaveManager] 버전 불일치: saved=%s, current=%s" % [saved_version, VERSION])

	# 게임 상태 복원
	var game_state = save_data.get("game_state", {})

	# 건물 복원
	BuildingManager.deserialize({"buildings": game_state.get("buildings", [])})

	# 유닛 복원
	if units_parent:
		_deserialize_units(game_state.get("units", []), units_parent)
	else:
		push_warning("[SaveManager] 유닛 부모 노드가 설정되지 않음. initialize()를 호출하세요.")

	# 카메라 복원
	_deserialize_camera(game_state.get("camera", {}))

	game_loaded.emit(slot)
	print("[SaveManager] 게임 로드 완료: ", path)
	return true


# ============================================================
# 슬롯 정보 조회 (Task 3.1)
# ============================================================

## 슬롯의 저장 정보 조회 (메타데이터만)
## @param slot: 슬롯 번호 (1 ~ MAX_SLOTS)
## @return: {exists, version, timestamp, building_count, unit_count} 형태의 Dictionary
func get_save_info(slot: int) -> Dictionary:
	var path = get_save_path(slot)

	if not FileAccess.file_exists(path):
		return {"exists": false}

	var save_data = _load_json(path)
	if save_data.is_empty():
		return {"exists": false, "corrupted": true}

	var game_state = save_data.get("game_state", {})

	return {
		"exists": true,
		"version": save_data.get("version", "unknown"),
		"timestamp": save_data.get("timestamp", 0),
		"building_count": game_state.get("buildings", []).size(),
		"unit_count": game_state.get("units", []).size()
	}


## 모든 슬롯의 저장 정보 조회
## @return: [{slot, info}, ...] 형태의 Array
func get_all_saves_info() -> Array:
	var infos: Array = []

	# 일반 슬롯 정보 수집
	for i in range(1, MAX_SLOTS + 1):
		infos.append({"slot": i, "info": get_save_info(i)})

	# 자동 저장 정보 추가 (slot = 0)
	var autosave_path = get_autosave_path()
	if FileAccess.file_exists(autosave_path):
		var autosave_data = _load_json(autosave_path)
		if not autosave_data.is_empty():
			var game_state = autosave_data.get("game_state", {})
			infos.append({
				"slot": 0,  # 0 = autosave
				"info": {
					"exists": true,
					"version": autosave_data.get("version", "unknown"),
					"timestamp": autosave_data.get("timestamp", 0),
					"building_count": game_state.get("buildings", []).size(),
					"unit_count": game_state.get("units", []).size()
				}
			})
	else:
		infos.append({"slot": 0, "info": {"exists": false}})

	return infos


# ============================================================
# 저장 파일 삭제 (Task 3.2)
# ============================================================

## 저장 파일 삭제
## @param slot: 삭제할 슬롯 번호 (1 ~ MAX_SLOTS)
## @return: 삭제 성공 여부
func delete_save(slot: int) -> bool:
	var path = get_save_path(slot)

	if not FileAccess.file_exists(path):
		push_warning("[SaveManager] 삭제할 파일이 없음: ", path)
		return false

	var error = DirAccess.remove_absolute(path)
	if error == OK:
		save_deleted.emit(slot)
		print("[SaveManager] 저장 파일 삭제: ", path)
		return true
	else:
		push_error("[SaveManager] 파일 삭제 실패: %s (에러: %s)" % [path, error])
		return false


## 자동 저장 파일 삭제
## @return: 삭제 성공 여부
func delete_autosave() -> bool:
	var path = get_autosave_path()

	if not FileAccess.file_exists(path):
		push_warning("[SaveManager] 삭제할 자동 저장 파일이 없음")
		return false

	var error = DirAccess.remove_absolute(path)
	if error == OK:
		save_deleted.emit(0)  # 0 = autosave
		print("[SaveManager] 자동 저장 파일 삭제: ", path)
		return true
	else:
		push_error("[SaveManager] 자동 저장 파일 삭제 실패: ", error)
		return false


# ============================================================
# 빠른 저장/로드 (Task 4.1)
# ============================================================

## 빠른 저장 (F5)
func quick_save() -> void:
	print("[SaveManager] 빠른 저장 시작... (슬롯 %d)" % quick_save_slot)
	save_game(quick_save_slot)


## 빠른 로드 (F8)
func quick_load() -> void:
	print("[SaveManager] 빠른 로드 시작... (슬롯 %d)" % quick_save_slot)
	load_game(quick_save_slot)


# ============================================================
# 자동 저장 (Task 4.2)
# ============================================================

## 자동 저장 타이머 설정
func _setup_autosave_timer() -> void:
	autosave_timer = Timer.new()
	autosave_timer.wait_time = AUTOSAVE_INTERVAL
	autosave_timer.one_shot = false
	autosave_timer.timeout.connect(_on_autosave_timer_timeout)
	add_child(autosave_timer)

	if autosave_enabled:
		autosave_timer.start()
		print("[SaveManager] 자동 저장 활성화 (간격: %.0f초)" % AUTOSAVE_INTERVAL)


## 자동 저장 타이머 타임아웃 콜백
func _on_autosave_timer_timeout() -> void:
	if autosave_enabled:
		autosave()


## 자동 저장 실행
## @return: 저장 성공 여부
func autosave() -> bool:
	_ensure_save_directory()

	var save_data: Dictionary = {
		"version": VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_state": {
			"buildings": BuildingManager.serialize().get("buildings", []),
			"units": _serialize_units(),
			"camera": _serialize_camera()
		}
	}

	var path = get_autosave_path()
	if _save_json(path, save_data):
		print("[SaveManager] 자동 저장 완료: ", path)
		return true
	return false


## 자동 저장 파일 로드
## @return: 로드 성공 여부
func load_autosave() -> bool:
	var path = get_autosave_path()
	var save_data = _load_json(path)

	if save_data.is_empty():
		load_failed.emit("자동 저장 파일이 없거나 손상됨")
		return false

	# 게임 상태 복원
	var game_state = save_data.get("game_state", {})

	BuildingManager.deserialize({"buildings": game_state.get("buildings", [])})

	if units_parent:
		_deserialize_units(game_state.get("units", []), units_parent)

	_deserialize_camera(game_state.get("camera", {}))

	print("[SaveManager] 자동 저장 로드 완료")
	return true


## 자동 저장 활성화/비활성화
## @param enabled: 활성화 여부
func set_autosave_enabled(enabled: bool) -> void:
	autosave_enabled = enabled
	if enabled:
		autosave_timer.start()
	else:
		autosave_timer.stop()
	print("[SaveManager] 자동 저장: ", "활성화" if enabled else "비활성화")
