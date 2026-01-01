extends Node2D

## 메인 씬 스크립트

# ============================================================
# 노드 참조
# ============================================================

## GroundTileMapLayer 참조 (좌표 변환용)
@onready var ground_layer: TileMapLayer = $test_map_Node2D/World/NavigationRegion2D/GroundTileMapLayer


# ============================================================
# 생명주기
# ============================================================

func _ready() -> void:
	# GridSystem 초기화 (Autoload 싱글톤)
	if ground_layer:
		GridSystem.initialize(ground_layer)
	else:
		push_warning("[Main] GroundTileMapLayer를 찾을 수 없어 GridSystem 초기화를 건너뜁니다.")

	print("[Main] 게임 시작")
	print("[Main] 건물/유닛을 클릭하면 선택됩니다 (Ctrl+클릭으로 유닛 다중 선택)")
	print("[Main] 빈 공간 클릭 시 모든 선택이 해제됩니다")
