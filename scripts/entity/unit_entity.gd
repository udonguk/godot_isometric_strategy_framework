class_name UnitEntity
extends CharacterBody2D

## 유닛 엔티티 - RTS 스타일 이동
##
## NavigationAgent2D를 사용한 경로 찾기 및 이동 구현
## SOLID 원칙 준수: 유닛 개체의 이동/선택 상태만 담당

# ============================================================
# 설정값
# ============================================================

## 이동 속도 (픽셀/초)
@export var speed: float = 100.0

## 유닛 반경 (충돌 회피용)
@export var radius: float = 16.0


# ============================================================
# 노드 참조
# ============================================================

## NavigationAgent2D 참조
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

## 선택 인디케이터 스프라이트
@onready var selection_indicator: Sprite2D = $SelectionIndicator


# ============================================================
# 상태
# ============================================================

## 선택 상태 (setter를 통해 인디케이터 표시 제어)
var is_selected: bool = false:
	set(value):
		is_selected = value
		print("[UnitEntity] 선택 상태 변경: ", value)
		if selection_indicator:
			selection_indicator.visible = value
			print("[UnitEntity] SelectionIndicator visible 설정: ", selection_indicator.visible)
		else:
			push_warning("[UnitEntity] SelectionIndicator 노드를 찾을 수 없습니다!")


# ============================================================
# 생명주기
# ============================================================

func _ready() -> void:
	# NavigationAgent2D 설정
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	nav_agent.avoidance_enabled = true  # 유닛 간 충돌 회피
	nav_agent.radius = radius
	nav_agent.max_speed = speed

	# 선택 인디케이터 초기 비활성화
	if selection_indicator:
		selection_indicator.visible = false

	print("[UnitEntity] 유닛 생성 완료 - Position: ", global_position)


func _physics_process(delta: float) -> void:
	# 경로 탐색이 완료되면 이동 중지
	if nav_agent.is_navigation_finished():
		return

	# 다음 경로 지점 가져오기
	var next_position = nav_agent.get_next_path_position()

	# 방향 계산
	var direction = global_position.direction_to(next_position)

	# 속도 설정 및 이동
	velocity = direction * speed
	move_and_slide()


# ============================================================
# Public 메서드
# ============================================================

## 목표 위치로 이동 명령
## @param target_pos: 월드 좌표 기준 목표 위치
func move_to(target_pos: Vector2) -> void:
	# 1. 목표가 너무 가까우면 무시 (이미 도착)
	if global_position.distance_to(target_pos) < 8.0:
		return
		
	# 2. 목표 지점을 가장 가까운 Navigation Mesh 위 좌표로 보정
	# 클릭한 곳이 장애물 내부거나 맵 밖일 경우, 갈 수 있는 가장 가까운 곳으로 안내하기 위함
	var map_rid = get_world_2d().navigation_map
	var optimized_target_pos = NavigationServer2D.map_get_closest_point(map_rid, target_pos)
	
	nav_agent.target_position = optimized_target_pos
	print("[UnitEntity] 이동 명령 - Raw Target: %s -> Optimized Target: %s" % [target_pos, optimized_target_pos])

	# 경로 계산 후 도달 가능 여부 체크
	await get_tree().physics_frame
	if not nav_agent.is_target_reachable():
		push_warning("[UnitEntity] 목표 도달 불가능: ", optimized_target_pos)
		# TODO: 유저 피드백 (소리, 시각 효과)


## 현재 이동 중인지 확인
func is_moving() -> bool:
	return not nav_agent.is_navigation_finished()


## 이동 중지
func stop() -> void:
	nav_agent.target_position = global_position
	velocity = Vector2.ZERO
