class_name BuildingEntity
extends Node2D

## 건물 기본 클래스
## 감염 시스템의 핵심 엔티티

# ============================================================
# 노드 참조 (씬에서 설정)
# ============================================================

## Sprite2D 노드 참조 (비주얼)
@onready var sprite: Sprite2D = $Sprite2D

## Area2D 노드 참조 (클릭 감지용)
## 주의: 씬에 Area2D 노드가 있어야 함
@onready var area: Area2D = $Area2D

## SelectionIndicator 노드 참조 (선택 표시)
## 주의: 씬에 SelectionIndicator 노드가 있어야 함
@onready var selection_indicator: Sprite2D = $SelectionIndicator if has_node("SelectionIndicator") else null


# ============================================================
# 상태 변수
# ============================================================

## 그리드 좌표 (논리적 위치)
var grid_position: Vector2i = Vector2i.ZERO

## 선택 상태 (SelectionManager가 사용)
var is_selected: bool = false:
	set(value):
		is_selected = value
		_update_selection_indicator()


# ============================================================
# 생명주기
# ============================================================

func _ready() -> void:
	# 그룹 등록 (main.gd에서 찾을 수 있도록)
	add_to_group("buildings")

	# 디버그: 건물 생성 로그
	print("[BuildingEntity] 건물 생성됨: ", name, " at ", global_position)
	print("  - Area2D collision_layer: ", $Area2D.collision_layer if has_node("Area2D") else "없음")

	# 초기 비주얼 설정 (기본 색상)
	if sprite:
		sprite.modulate = Color.WHITE

	# 선택 인디케이터 초기 숨김
	if selection_indicator:
		selection_indicator.visible = false

	# StaticBody2D는 Navigation 전용이므로 클릭 레이어에서 제외
	# InputManager가 Area2D만 감지하도록 collision_layer 0으로 설정
	if has_node("StaticBody2D"):
		var static_body = $StaticBody2D as StaticBody2D
		if static_body:
			static_body.collision_layer = 0  # 클릭 감지 비활성화
			static_body.collision_mask = 0   # 충돌 감지 비활성화

	# NavigationObstacle2D 설정 업데이트
	_update_navigation_obstacle()


# ============================================================
# Navigation 설정
# ============================================================

## NavigationObstacle2D 형상 업데이트
func _update_navigation_obstacle() -> void:
	if not has_node("NavigationObstacle2D"):
		return

	var nav_obstacle = $NavigationObstacle2D
	var collision_poly = $StaticBody2D/CollisionPolygon2D
	
	if nav_obstacle and collision_poly:
		# CollisionPolygon2D의 점들을 가져옴 (Local 좌표)
		var poly_points = collision_poly.polygon
		
		# NavigationObstacle2D에 vertices 설정
		# 주의: 건물의 모양대로 정확히 깎아내기 위해 사용
		nav_obstacle.vertices = poly_points
		print("[Building] Navigation Obstacle vertices 설정 완료: ", poly_points.size(), "개 점")


# ============================================================
# 선택 인디케이터
# ============================================================

## 선택 상태에 따라 인디케이터 표시/숨김
func _update_selection_indicator() -> void:
	"""선택 상태에 따라 인디케이터 표시/숨김 (UnitEntity와 동일)"""
	if not selection_indicator:
		return

	selection_indicator.visible = is_selected
