# scripts/config/building_database.gd
extends Node
class_name BuildingDatabase

# 모든 건물 데이터 배열
const BUILDINGS: Array[BuildingData] = [
	preload("res://scripts/resources/house_01.tres"),
	preload("res://scripts/resources/farm_01.tres"),
	preload("res://scripts/resources/shop_01.tres"),
]

# ID로 건물 찾기
static func get_building_by_id(id: String) -> BuildingData:
	for building in BUILDINGS:
		if building.entity_id == id:
			return building
	return null

# 카테고리별 건물 목록
static func get_buildings_by_category(category: BuildingData.BuildingCategory) -> Array[BuildingData]:
	var result: Array[BuildingData] = []
	for building in BUILDINGS:
		if building.category == category:
			result.append(building)
	return result

# 모든 건물 목록
static func get_all_buildings() -> Array[BuildingData]:
	return BUILDINGS.duplicate()
