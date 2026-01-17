# Sprint 06: 저장/로드 시스템 구현

**관련 PRD 섹션:** `../../product/prd.md` 섹션 2.12

## 📋 개요

FileAccess + JSON 기반의 게임 상태 저장/로드 시스템을 구현합니다.

### 목표
- SaveManager Autoload 싱글톤 구현
- 건물/유닛/카메라 상태 직렬화
- 여러 슬롯 지원 (slot_1 ~ slot_3 + autosave)
- 빠른 저장/로드 (F5/F9) 및 자동 저장

### 저장 데이터 구조 (JSON)
```json
{
  "version": "1.0.0",
  "timestamp": 1704362400,
  "playtime": 3600,
  "game_state": {
    "buildings": [...],
    "units": [...],
    "camera": {...}
  }
}
```

---

## 📋 구현 우선순위

### Phase 1: SaveManager 기본 구조 + JSON 저장/로드 테스트

#### Task 1.1: SaveManager Autoload 생성
- [ ] `scripts/managers/save_manager.gd` 생성
- [ ] `project.godot`에 Autoload 등록
- [ ] 기본 구조 작성:
  - `SAVE_DIR = "user://saves/"`
  - `SAVE_EXTENSION = ".save"`
  - `VERSION = "1.0.0"`

```gdscript
extends Node
class_name SaveManagerClass

## 저장 시스템 매니저
##
## FileAccess + JSON 기반으로 게임 상태를 저장/로드합니다.
## SOLID 원칙:
## - Single Responsibility: 저장/로드 작업만 담당
## - 각 매니저의 serialize/deserialize는 해당 매니저가 담당

# ============================================================
# 상수
# ============================================================

const SAVE_DIR: String = "user://saves/"
const SAVE_EXTENSION: String = ".save"
const VERSION: String = "1.0.0"
const MAX_SLOTS: int = 3

# ============================================================
# 시그널
# ============================================================

signal game_saved(slot: int)
signal game_loaded(slot: int)
signal save_failed(reason: String)
signal load_failed(reason: String)
```

#### Task 1.2: 저장 디렉토리 관리
- [ ] `_ensure_save_directory()` 구현
- [ ] `get_save_path(slot: int)` 구현
- [ ] `get_autosave_path()` 구현

```gdscript
## 저장 디렉토리가 존재하는지 확인하고, 없으면 생성
func _ensure_save_directory() -> void:
    if not DirAccess.dir_exists_absolute(SAVE_DIR):
        DirAccess.make_dir_absolute(SAVE_DIR)
        print("[SaveManager] 저장 디렉토리 생성: ", SAVE_DIR)

## 슬롯별 저장 파일 경로 반환
func get_save_path(slot: int) -> String:
    return SAVE_DIR + "slot_%d%s" % [slot, SAVE_EXTENSION]

## 자동 저장 파일 경로 반환
func get_autosave_path() -> String:
    return SAVE_DIR + "autosave" + SAVE_EXTENSION
```

#### Task 1.3: 기본 JSON 저장/로드 테스트
- [ ] `_save_json(path: String, data: Dictionary)` 구현
- [ ] `_load_json(path: String) -> Dictionary` 구현
- [ ] 테스트: 간단한 Dictionary 저장/로드 검증

```gdscript
## JSON 데이터를 파일로 저장
func _save_json(path: String, data: Dictionary) -> bool:
    var json_string = JSON.stringify(data, "\t")  # 들여쓰기로 가독성 향상

    var file = FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("[SaveManager] 파일 열기 실패: %s (에러: %s)" % [path, FileAccess.get_open_error()])
        return false

    file.store_string(json_string)
    file.close()
    return true

## 파일에서 JSON 데이터 로드
func _load_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        push_warning("[SaveManager] 파일이 존재하지 않음: ", path)
        return {}

    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("[SaveManager] 파일 열기 실패: %s (에러: %s)" % [path, FileAccess.get_open_error()])
        return {}

    var json_string = file.get_as_text()
    file.close()

    var result = JSON.parse_string(json_string)
    if result == null:
        push_error("[SaveManager] JSON 파싱 실패: ", path)
        return {}

    return result
```

#### Task 1.4: 단위 테스트 작성
- [ ] `tests/unit/test_save_manager.gd` 생성
- [ ] 테스트 케이스:
  - `test_save_and_load_json()` - 기본 저장/로드
  - `test_save_directory_creation()` - 디렉토리 자동 생성
  - `test_load_nonexistent_file()` - 존재하지 않는 파일 로드 시 빈 Dictionary 반환
  - `test_invalid_json_handling()` - 손상된 JSON 처리

---

### Phase 2: 게임 상태 직렬화 (Serialization)

#### Task 2.1: BuildingManager.serialize() 구현
- [ ] `BuildingManager`에 `serialize() -> Dictionary` 메서드 추가
- [ ] `BuildingManager`에 `deserialize(data: Dictionary)` 메서드 추가
- [ ] 저장할 데이터:
  - `building_type` (BuildingData 이름)
  - `grid_pos` (Vector2i → {x, y})

```gdscript
# building_manager.gd에 추가

## 건물 데이터를 직렬화 (저장용)
func serialize() -> Dictionary:
    var buildings_data: Array = []

    # grid_buildings에서 고유한 건물만 추출 (여러 타일을 차지하는 건물 중복 방지)
    var processed_buildings: Array = []

    for grid_pos in grid_buildings.keys():
        var building = grid_buildings[grid_pos]

        # null 체크 (기존 타일 동기화된 것은 skip)
        if building == null:
            continue

        # 이미 처리된 건물이면 skip
        if building in processed_buildings:
            continue

        processed_buildings.append(building)

        # 건물 데이터 추출
        if building.data:
            buildings_data.append({
                "type": building.data.entity_name,
                "grid_pos": {"x": building.grid_position.x, "y": building.grid_position.y}
            })

    return {"buildings": buildings_data}


## 직렬화된 데이터로 건물 복원 (로드용)
func deserialize(data: Dictionary) -> void:
    # 기존 건물 모두 제거
    clear_all_buildings()

    var buildings_data = data.get("buildings", [])

    for building_info in buildings_data:
        var type_name: String = building_info.get("type", "")
        var pos_data = building_info.get("grid_pos", {})
        var grid_pos = Vector2i(pos_data.get("x", 0), pos_data.get("y", 0))

        # BuildingDatabase에서 BuildingData 조회
        var building_data = BuildingDatabase.get_building(type_name)
        if building_data:
            create_building(grid_pos, building_data)
        else:
            push_warning("[BuildingManager] 알 수 없는 건물 타입: ", type_name)

    print("[BuildingManager] 건물 복원 완료: %d개" % buildings_data.size())
```

#### Task 2.2: 유닛 직렬화 구현
- [ ] `SaveManager`에서 유닛 그룹("units")으로 유닛 수집
- [ ] 저장할 데이터:
  - `grid_pos` (Vector2i → {x, y})
  - `direction` (Direction enum → int)
  - `state` (State enum → int)

```gdscript
# save_manager.gd에 추가

## 유닛 데이터 직렬화
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


## 유닛 데이터 복원
func _deserialize_units(units_data: Array, parent_node: Node2D) -> void:
    # 기존 유닛 모두 제거
    var existing_units = get_tree().get_nodes_in_group("units")
    for unit in existing_units:
        unit.queue_free()

    # 프레임 대기 (queue_free 처리)
    await get_tree().process_frame

    # UnitEntity 씬 로드
    var UnitEntityScene = preload("res://scenes/entitys/unit_entity.tscn")

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

    print("[SaveManager] 유닛 복원 완료: %d개" % units_data.size())
```

#### Task 2.3: 카메라 상태 직렬화
- [ ] 카메라 위치 저장/복원
- [ ] 저장할 데이터:
  - `position` (Vector2 → {x, y})
  - `zoom` (Vector2 → {x, y})

```gdscript
## 카메라 데이터 직렬화
func _serialize_camera() -> Dictionary:
    var camera = get_viewport().get_camera_2d()
    if camera:
        return {
            "position": {"x": camera.global_position.x, "y": camera.global_position.y},
            "zoom": {"x": camera.zoom.x, "y": camera.zoom.y}
        }
    return {}


## 카메라 데이터 복원
func _deserialize_camera(camera_data: Dictionary) -> void:
    var camera = get_viewport().get_camera_2d()
    if camera and not camera_data.is_empty():
        var pos_data = camera_data.get("position", {})
        camera.global_position = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))

        var zoom_data = camera_data.get("zoom", {"x": 1, "y": 1})
        camera.zoom = Vector2(zoom_data.get("x", 1), zoom_data.get("y", 1))

        print("[SaveManager] 카메라 복원 완료")
```

#### Task 2.4: 통합 저장/로드 메서드
- [ ] `save_game(slot: int)` 구현
- [ ] `load_game(slot: int)` 구현
- [ ] 유닛 부모 노드 참조 관리

```gdscript
# ============================================================
# 의존성 (로드 시 필요)
# ============================================================

## 유닛 부모 노드 (로드 시 유닛 생성 위치)
var units_parent: Node2D = null

## 초기화
func initialize(unit_parent: Node2D) -> void:
    units_parent = unit_parent
    _ensure_save_directory()
    print("[SaveManager] 초기화 완료")


## 게임 저장
func save_game(slot: int) -> bool:
    _ensure_save_directory()

    # 전체 게임 상태 수집
    var save_data: Dictionary = {
        "version": VERSION,
        "timestamp": Time.get_unix_time_from_system(),
        "game_state": {
            "buildings": BuildingManager.serialize().get("buildings", []),
            "units": _serialize_units(),
            "camera": _serialize_camera()
        }
    }

    # JSON 저장
    var path = get_save_path(slot)
    if _save_json(path, save_data):
        game_saved.emit(slot)
        print("[SaveManager] 게임 저장 완료: ", path)
        return true
    else:
        save_failed.emit("파일 저장 실패")
        return false


## 게임 로드
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
        await _deserialize_units(game_state.get("units", []), units_parent)

    # 카메라 복원
    _deserialize_camera(game_state.get("camera", {}))

    game_loaded.emit(slot)
    print("[SaveManager] 게임 로드 완료: ", path)
    return true
```

---

### Phase 3: 슬롯 시스템 + 메타데이터

#### Task 3.1: 저장 슬롯 정보 조회
- [ ] `get_save_info(slot: int) -> Dictionary` 구현
- [ ] `get_all_saves_info() -> Array` 구현
- [ ] 반환 데이터: 타임스탬프, 버전, 건물/유닛 수

```gdscript
## 슬롯의 저장 정보 조회 (메타데이터만)
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
func get_all_saves_info() -> Array:
    var infos: Array = []
    for i in range(1, MAX_SLOTS + 1):
        infos.append({"slot": i, "info": get_save_info(i)})

    # 자동 저장 정보 추가
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

    return infos
```

#### Task 3.2: 저장 파일 삭제
- [ ] `delete_save(slot: int)` 구현
- [ ] 삭제 확인 시그널

```gdscript
signal save_deleted(slot: int)

## 저장 파일 삭제
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
        push_error("[SaveManager] 파일 삭제 실패: ", path)
        return false
```

#### Task 3.3: 저장 슬롯 존재 여부 확인
- [ ] `has_save(slot: int) -> bool` 구현

```gdscript
## 슬롯에 저장 파일이 있는지 확인
func has_save(slot: int) -> bool:
    return FileAccess.file_exists(get_save_path(slot))


## 자동 저장 파일이 있는지 확인
func has_autosave() -> bool:
    return FileAccess.file_exists(get_autosave_path())
```

---

### Phase 4: 빠른 저장/로드 + 자동 저장

#### Task 4.1: 빠른 저장/로드 (F5/F9)
- [ ] Input Actions 등록 (`project.godot`)
  - `quick_save` → F5
  - `quick_load` → F9
- [ ] `InputManager`에서 처리 또는 `SaveManager._input()` 구현

```gdscript
# save_manager.gd에 추가

## 빠른 저장 슬롯 (기본값: 1)
var quick_save_slot: int = 1

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("quick_save"):
        quick_save()
    elif event.is_action_pressed("quick_load"):
        quick_load()


## 빠른 저장 (F5)
func quick_save() -> void:
    print("[SaveManager] 빠른 저장 시작...")
    save_game(quick_save_slot)


## 빠른 로드 (F9)
func quick_load() -> void:
    print("[SaveManager] 빠른 로드 시작...")
    load_game(quick_save_slot)
```

#### Task 4.2: 자동 저장 시스템
- [ ] `Timer` 노드 추가 (Autoload에서 생성)
- [ ] 자동 저장 간격 설정 (GameConfig 또는 상수)
- [ ] `autosave()` 구현

```gdscript
# ============================================================
# 자동 저장
# ============================================================

## 자동 저장 간격 (초)
const AUTOSAVE_INTERVAL: float = 600.0  # 10분

## 자동 저장 타이머
var autosave_timer: Timer = null

## 자동 저장 활성화 여부
var autosave_enabled: bool = true


func _ready() -> void:
    _setup_autosave_timer()


func _setup_autosave_timer() -> void:
    autosave_timer = Timer.new()
    autosave_timer.wait_time = AUTOSAVE_INTERVAL
    autosave_timer.one_shot = false
    autosave_timer.timeout.connect(_on_autosave_timer_timeout)
    add_child(autosave_timer)

    if autosave_enabled:
        autosave_timer.start()
        print("[SaveManager] 자동 저장 활성화 (간격: %.0f초)" % AUTOSAVE_INTERVAL)


func _on_autosave_timer_timeout() -> void:
    if autosave_enabled:
        autosave()


## 자동 저장 실행
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


## 자동 저장 활성화/비활성화
func set_autosave_enabled(enabled: bool) -> void:
    autosave_enabled = enabled
    if enabled:
        autosave_timer.start()
    else:
        autosave_timer.stop()
    print("[SaveManager] 자동 저장: ", "활성화" if enabled else "비활성화")


## 자동 저장 파일 로드
func load_autosave() -> bool:
    var path = get_autosave_path()
    var save_data = _load_json(path)

    if save_data.is_empty():
        load_failed.emit("자동 저장 파일이 없거나 손상됨")
        return false

    # 게임 상태 복원 (load_game과 동일한 로직)
    var game_state = save_data.get("game_state", {})

    BuildingManager.deserialize({"buildings": game_state.get("buildings", [])})

    if units_parent:
        await _deserialize_units(game_state.get("units", []), units_parent)

    _deserialize_camera(game_state.get("camera", {}))

    print("[SaveManager] 자동 저장 로드 완료")
    return true
```

#### Task 4.3: 메인 씬 통합
- [ ] `main.gd`에서 `SaveManager.initialize()` 호출
- [ ] 유닛 부모 노드 전달

```gdscript
# main.gd에 추가

func _ready():
    # ... 기존 초기화 코드 ...

    # SaveManager 초기화
    SaveManager.initialize($Entities)  # 유닛 생성할 부모 노드
```

---

## 📝 테스트 체크리스트

### Phase 1 테스트
- [ ] SaveManager가 Autoload로 정상 등록됨
- [ ] `user://saves/` 디렉토리가 자동 생성됨
- [ ] 간단한 Dictionary가 JSON으로 저장/로드됨
- [ ] 존재하지 않는 파일 로드 시 빈 Dictionary 반환
- [ ] 손상된 JSON 파일 로드 시 에러 처리

### Phase 2 테스트
- [ ] 건물 1개 배치 → 저장 → 로드 → 동일 위치에 복원
- [ ] 건물 여러 개 배치 → 저장 → 로드 → 모두 복원
- [ ] 2x2 건물(grid_size) 저장/로드 정상 동작
- [ ] 유닛 저장/로드 정상 동작
- [ ] 카메라 위치 저장/로드 정상 동작

### Phase 3 테스트
- [ ] `get_save_info(1)` 호출 시 메타데이터 반환
- [ ] `delete_save(1)` 호출 시 파일 삭제됨
- [ ] 슬롯 1, 2, 3에 각각 저장 가능

### Phase 4 테스트
- [ ] F5 키 → 빠른 저장 동작
- [ ] F9 키 → 빠른 로드 동작
- [ ] 10분 후 자동 저장 동작 (테스트 시 간격 줄여서 확인)
- [ ] `set_autosave_enabled(false)` → 자동 저장 중지

---

## 📂 생성/수정 파일 목록

### 새로 생성
- `scripts/managers/save_manager.gd` - SaveManager Autoload
- `tests/unit/test_save_manager.gd` - 단위 테스트

### 수정
- `project.godot` - Autoload 등록, Input Actions 추가
- `scripts/managers/building_manager.gd` - serialize/deserialize 추가
- `scripts/maps/main.gd` - SaveManager 초기화 호출

---

## ⚠️ 주의 사항

### JSON으로 저장하면 안 되는 것
- 씬 인스턴스 참조 (PackedScene)
- 노드 참조 (Node)
- 시그널 연결 상태
- 함수/콜백

### JSON으로 저장해야 하는 것
- 기본 타입 (int, float, String, bool)
- Dictionary, Array
- Vector2i → `{"x": 5, "y": 3}` 형태로 변환
- Enum → int 또는 String으로 변환

### 보안 고려사항
- `user://` 경로는 OS별로 자동 매핑 (안전)
- JSON 파싱 오류 처리 필수
- 저장 파일 버전 호환성 체크

---

## 🔗 관련 문서

- PRD: `../../product/prd.md` 섹션 2.12
- Godot 공식 문서: "Saving games" (FileAccess + JSON 예제)
- Godot 공식 문서: "File I/O" (FileAccess 클래스)
