# scripts/resources/building_data.gd
class_name BuildingData extends EntityData

# 건물 전용 속성
@export var cost_wood: int = 0
@export var cost_stone: int = 0
@export var cost_gold: int = 100
@export var grid_size: Vector2i = Vector2i(1, 1)

# 카테고리
enum BuildingCategory {
	RESIDENTIAL,  # 주거
	PRODUCTION,   # 생산
	MILITARY,     # 군사
	DECORATION    # 장식
}
@export var category: BuildingCategory = BuildingCategory.RESIDENTIAL

# 헬퍼 함수
func get_total_cost() -> Dictionary:
	return {
		"wood": cost_wood,
		"stone": cost_stone,
		"gold": cost_gold
	}
