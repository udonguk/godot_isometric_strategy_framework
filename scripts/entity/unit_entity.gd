extends CharacterBody2D
class_name UnitEntity

## 플레이어가 제어 가능한 유닛 엔티티
##
## 책임:
## - 그리드 좌표 기반 이동
## - 8방향 애니메이션 재생
## - Navigation 경로 추종
## - 상태 관리 (idle, moving)

# ============================================================
# 상태 정의
# ============================================================

enum State {
	IDLE,        # 대기 중
	MOVING,      # 이동 중
}

enum Direction {
	SOUTH = 0,       # 아래 (↓)
	SOUTH_EAST = 1,  # 우하 (↘)
	EAST = 2,        # 우 (→)
	NORTH_EAST = 3,  # 우상 (↗)
	NORTH = 4,       # 위 (↑)
	NORTH_WEST = 5,  # 좌상 (↖)
	WEST = 6,        # 좌 (←)
	SOUTH_WEST = 7   # 좌하 (↙)
}

# ============================================================
# 노드 참조
# ============================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var selection_indicator: Sprite2D = $SelectionIndicator

# ============================================================
# 상태 변수
# ============================================================

## 현재 상태
var current_state: State = State.IDLE

## 현재 애니메이션 방향
var current_direction: Direction = Direction.SOUTH

## 그리드 좌표 (논리적 위치)
var grid_position: Vector2i = Vector2i.ZERO

## 이동 속도 (픽셀/초)
@export var move_speed: float = 100.0

## 선택 상태 (SelectionManager가 사용)
var is_selected: bool = false:
	set(value):
		is_selected = value
		_update_selection_indicator()

# ============================================================
# 생명주기 메서드
# ============================================================

func _ready():
	# NavigationAgent2D 설정
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	nav_agent.avoidance_enabled = true

	# Navigation Layer 설정 (Layer 0 = Ground)
	nav_agent.set_navigation_layers(1)

	# 초기 애니메이션 재생
	play_animation("idle", current_direction)

	# 초기 그리드 위치 계산 (월드 좌표 → 그리드 좌표)
	grid_position = GridSystem.world_to_grid(global_position)

	# 선택 인디케이터 초기 숨김
	if selection_indicator:
		selection_indicator.visible = false


func _physics_process(delta):
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.MOVING:
			_process_moving(delta)


# ============================================================
# 상태별 처리
# ============================================================

func _process_idle(_delta):
	"""대기 상태 처리"""
	# 대기 중에는 아무것도 안 함
	pass


func _process_moving(_delta):
	"""이동 상태 처리"""
	# 목적지 도착 확인
	if nav_agent.is_navigation_finished():
		_arrive_at_destination()
		return

	# 다음 경로 지점 가져오기
	var next_pos = nav_agent.get_next_path_position()
	var direction_vec = (next_pos - global_position).normalized()

	# 이동
	velocity = direction_vec * move_speed
	move_and_slide()

	# 애니메이션 방향 업데이트
	var new_direction = get_direction_from_velocity(velocity)
	if new_direction != current_direction:
		current_direction = new_direction
		play_animation("walk", current_direction)


func _arrive_at_destination():
	"""목적지 도착 처리"""
	current_state = State.IDLE
	velocity = Vector2.ZERO

	# 그리드 위치 업데이트
	grid_position = GridSystem.world_to_grid(global_position)

	# idle 애니메이션 재생
	play_animation("idle", current_direction)


# ============================================================
# 공개 메서드 (외부 인터페이스)
# ============================================================

func move_to_grid(target_grid: Vector2i):
	"""그리드 좌표로 이동 명령

	Args:
		target_grid: 목표 그리드 좌표 (Vector2i)
	"""
	# 그리드 → 월드 좌표 변환 (GridSystem 사용)
	var target_world = GridSystem.grid_to_world(target_grid)

	# NavigationAgent에 목표 설정
	nav_agent.target_position = target_world

	# 상태 전환
	current_state = State.MOVING

	# walk 애니메이션 즉시 시작
	play_animation("walk", current_direction)


func stop_movement():
	"""이동 중지"""
	if current_state == State.MOVING:
		nav_agent.target_position = global_position
		_arrive_at_destination()


# ============================================================
# 애니메이션 관련 메서드
# ============================================================

func play_animation(anim_type: String, direction: Direction):
	"""애니메이션 재생

	Args:
		anim_type: "idle" 또는 "walk"
		direction: Direction enum 값 (0~7)
	"""
	var direction_name = get_direction_name(direction)
	var animation_name = "%s_%s" % [anim_type, direction_name]

	# AnimatedSprite2D가 준비되지 않았으면 무시
	if not animated_sprite:
		return

	# 애니메이션이 존재하는지 확인
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		# 애니메이션이 없으면 경고 (개발 중)
		push_warning("Animation not found: %s" % animation_name)


func get_direction_name(direction: Direction) -> String:
	"""Direction enum을 문자열로 변환

	Args:
		direction: Direction enum 값

	Returns:
		"south", "south_east", "east", ... 등
	"""
	match direction:
		Direction.SOUTH:
			return "south"
		Direction.SOUTH_EAST:
			return "south_east"
		Direction.EAST:
			return "east"
		Direction.NORTH_EAST:
			return "north_east"
		Direction.NORTH:
			return "north"
		Direction.NORTH_WEST:
			return "north_west"
		Direction.WEST:
			return "west"
		Direction.SOUTH_WEST:
			return "south_west"
		_:
			return "south"  # 기본값


func get_direction_from_velocity(vel: Vector2) -> Direction:
	"""이동 속도 벡터에서 8방향 결정

	Args:
		vel: 이동 속도 벡터 (velocity)

	Returns:
		Direction enum 값 (0~7)
	"""
	if vel.length_squared() < 0.01:
		# 거의 정지 상태면 현재 방향 유지
		return current_direction

	# 각도 계산 (라디안 → 도)
	var angle = vel.angle()  # -PI ~ PI
	var degree = rad_to_deg(angle)  # -180 ~ 180

	# 0~360 범위로 정규화
	if degree < 0:
		degree += 360.0

	# Godot 좌표계: 0도 = 동쪽(→), 90도 = 남쪽(↓), 180도 = 서쪽(←), 270도 = 북쪽(↑)
	# 8방향 구간 나누기 (45도씩)
	# 각 방향의 중심에서 ±22.5도 범위

	if degree >= 337.5 or degree < 22.5:
		return Direction.EAST  # 0도 중심 (→)
	elif degree >= 22.5 and degree < 67.5:
		return Direction.SOUTH_EAST  # 45도 중심 (↘)
	elif degree >= 67.5 and degree < 112.5:
		return Direction.SOUTH  # 90도 중심 (↓)
	elif degree >= 112.5 and degree < 157.5:
		return Direction.SOUTH_WEST  # 135도 중심 (↙)
	elif degree >= 157.5 and degree < 202.5:
		return Direction.WEST  # 180도 중심 (←)
	elif degree >= 202.5 and degree < 247.5:
		return Direction.NORTH_WEST  # 225도 중심 (↖)
	elif degree >= 247.5 and degree < 292.5:
		return Direction.NORTH  # 270도 중심 (↑)
	elif degree >= 292.5 and degree < 337.5:
		return Direction.NORTH_EAST  # 315도 중심 (↗)
	else:
		return Direction.SOUTH  # 기본값


# ============================================================
# 디버그 메서드
# ============================================================

func _to_string() -> String:
	"""디버그용 문자열 표현"""
	return "UnitEntity(grid: %s, state: %s, direction: %s)" % [
		grid_position,
		State.keys()[current_state],
		Direction.keys()[current_direction]
	]


# ============================================================
# 선택 인디케이터
# ============================================================

func _update_selection_indicator():
	"""선택 상태에 따라 인디케이터 표시/숨김"""
	if not selection_indicator:
		return

	selection_indicator.visible = is_selected
