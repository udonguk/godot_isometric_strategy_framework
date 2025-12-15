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

	# 클릭 이벤트 연결
	if area:
		area.input_event.connect(_on_area_input_event)

	# 외곽선 Material 초기화
	_init_outline_material()


# ============================================================
# 상태 관리
# ============================================================

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
# 입력 처리
# ============================================================

## Area2D 입력 이벤트 처리 (클릭 감지)
func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# 마우스 왼쪽 버튼 클릭 감지
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_clicked()


## 건물 클릭 시 호출되는 함수
func _on_clicked() -> void:
	print("[Building] 클릭됨 - Entity명: ", name, ", Grid: ", grid_position)

	# 메인 씬에 선택 이벤트 전달
	get_tree().call_group("main", "_on_building_selected", self)


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
