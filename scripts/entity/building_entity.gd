class_name BuildingEntity
extends Node2D

## 건물 기본 클래스
## 감염 시스템의 핵심 엔티티

# ============================================================
# 건물 상태 정의
# ============================================================

enum BuildingState {
	NORMAL,      ## 일반 상태 (감염되지 않음)
	INFECTING,   ## 감염 진행 중
	INFECTED     ## 완전 감염됨
}


# ============================================================
# 상태 변수
# ============================================================

## 현재 건물 상태
var current_state: BuildingState = BuildingState.NORMAL

## 그리드 좌표 (논리적 위치)
var grid_position: Vector2i = Vector2i.ZERO

## 외곽선 Material (선택 시 사용)
var outline_material: ShaderMaterial = null

## 선택 여부
var is_selected: bool = false


# ============================================================
# 노드 참조 (씬에서 설정)
# ============================================================

## Sprite2D 노드 참조 (비주얼)
@onready var sprite: Sprite2D = $Sprite2D

## Area2D 노드 참조 (클릭 감지용)
## 주의: 씬에 Area2D 노드가 있어야 함
@onready var area: Area2D = $Area2D


# ============================================================
# 생명주기
# ============================================================

func _ready() -> void:
	# 그룹 등록 (main.gd에서 찾을 수 있도록)
	add_to_group("buildings")

	# 초기 비주얼 업데이트
	update_visual()

	# 외곽선 Material 초기화
	_init_outline_material()
	
	# NavigationObstacle2D 설정 업데이트
	_update_navigation_obstacle()


# ============================================================
# 상태 관리
# ============================================================

## NavigationObstacle2D 형상 업데이트
func _update_navigation_obstacle() -> void:
	var nav_obstacle = $NavigationObstacle2D
	var collision_poly = $StaticBody2D/CollisionPolygon2D
	
	if nav_obstacle and collision_poly:
		# CollisionPolygon2D의 점들을 가져옴 (Local 좌표)
		var poly_points = collision_poly.polygon
		
		# NavigationObstacle2D에 vertices 설정
		# 주의: 건물의 모양대로 정확히 깎아내기 위해 사용
		nav_obstacle.vertices = poly_points
		print("[Building] Navigation Obstacle vertices 설정 완료: ", poly_points.size(), "개 점")


## 건물 상태 변경
func set_state(new_state: BuildingState) -> void:
	current_state = new_state
	update_visual()
	print("[Building] 상태 변경: ", _state_to_string(new_state))


## 비주얼 업데이트 (상태별 색상 적용)
func update_visual() -> void:
	if not sprite:
		return

	match current_state:
		BuildingState.NORMAL:
			sprite.modulate = GameConfig.COLOR_NORMAL
		BuildingState.INFECTING:
			sprite.modulate = GameConfig.COLOR_INFECTING
		BuildingState.INFECTED:
			sprite.modulate = GameConfig.COLOR_INFECTED


# ============================================================
# 외곽선 관리
# ============================================================

## 외곽선 Material 초기화
func _init_outline_material() -> void:
	# Shader 로드
	var shader = load("res://assets/shaders/outline.gdshader")
	if not shader:
		push_error("[Building] outline.gdshader를 찾을 수 없습니다!")
		return

	# ShaderMaterial 생성
	outline_material = ShaderMaterial.new()
	outline_material.shader = shader

	# 외곽선 설정
	outline_material.set_shader_parameter("outline_color", Color.BLACK)
	outline_material.set_shader_parameter("outline_width", 2.0)


## 외곽선 표시 (선택됨)
func show_outline() -> void:
	if sprite and outline_material:
		sprite.material = outline_material
		is_selected = true
		print("[Building] 외곽선 표시: ", name)


## 외곽선 제거 (선택 해제)
func hide_outline() -> void:
	if sprite:
		sprite.material = null
		is_selected = false
		print("[Building] 외곽선 제거: ", name)


# ============================================================
# 유틸리티
# ============================================================

## 상태를 문자열로 변환 (디버그용)
func _state_to_string(state: BuildingState) -> String:
	match state:
		BuildingState.NORMAL:
			return "NORMAL"
		BuildingState.INFECTING:
			return "INFECTING"
		BuildingState.INFECTED:
			return "INFECTED"
		_:
			return "UNKNOWN"
