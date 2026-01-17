extends Node2D

## 메인 씬 스크립트

# ============================================================
# 노드 참조
# ============================================================

@onready var test_map = $test_map_Node2D
@onready var construction_menu = $UILayer/ConstructionMenu


# ============================================================
# 생명주기
# ============================================================

func _ready() -> void:
	print("[Main] 게임 시작")
	print("[Main] 건물/유닛을 클릭하면 선택됩니다 (Ctrl+클릭으로 유닛 다중 선택)")
	print("[Main] 빈 공간 클릭 시 모든 선택이 해제됩니다")

	# test_map 비동기 초기화 완료 대기
	await test_map.initialize_async()

	# ConstructionMenu 초기화 (BuildingManager Autoload 직접 전달)
	if construction_menu:
		construction_menu.initialize(BuildingManager)
		print("[Main] ConstructionMenu 초기화 완료")
	else:
		push_error("[Main] ConstructionMenu를 찾을 수 없습니다")
