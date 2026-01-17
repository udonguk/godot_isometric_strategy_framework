extends Camera2D

## RTS 스타일 카메라 컨트롤러
## WASD 키보드 이동 + 마우스 엣지 스크롤 지원

# 카메라 이동 속도 (픽셀/초)
@export var speed: float = 300.0

# 화면 가장자리 감지 영역 (픽셀)
@export var edge_margin: int = 20


func _ready() -> void:
	# 카메라를 현재 카메라로 설정
	make_current()


func _process(delta: float) -> void:
	# 입력 방향 수집 (명시적 반환값 사용)
	var keyboard_direction = _get_keyboard_input_direction()
	#var mouse_edge_direction = _get_mouse_edge_scroll_direction()

	# 모든 입력 방향 합산
	#var movement_direction = keyboard_direction + mouse_edge_direction
	var movement_direction = keyboard_direction

	# 카메라 이동 적용
	if movement_direction.length() > 0:
		# 대각선 이동 시 속도 정규화
		var velocity = movement_direction.normalized() * speed
		position += velocity * delta


## 키보드 입력(WASD, 방향키)을 기반으로 이동 방향을 계산합니다.
##
## @return 정규화되지 않은 입력 방향 벡터 (-1~1 범위, 대각선은 길이 sqrt(2))
##
## ✅ Hidden Dependency 제거: velocity 멤버 변수 대신 반환값 사용
## ✅ 테스트 용이: 다양한 입력 조합을 독립적으로 테스트 가능
## ✅ 순수 함수: 외부 상태를 변경하지 않음 (side effect 없음)
func _get_keyboard_input_direction() -> Vector2:
	var direction = Vector2.ZERO

	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction.x += 1

	return direction


## 마우스가 화면 가장자리에 위치할 때 스크롤 방향을 계산합니다.
##
## @return 정규화되지 않은 스크롤 방향 벡터 (-1~1 범위, 대각선은 길이 sqrt(2))
##
## ✅ Hidden Dependency 제거: velocity 멤버 변수 대신 반환값 사용
## ✅ 테스트 용이: 다양한 마우스 위치로 독립적으로 테스트 가능
## ✅ 순수 함수: 외부 상태를 변경하지 않음 (side effect 없음)
func _get_mouse_edge_scroll_direction() -> Vector2:
	var direction = Vector2.ZERO
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_rect = get_viewport().get_visible_rect()

	# 상단 엣지
	if mouse_pos.y < edge_margin:
		direction.y -= 1
	# 하단 엣지
	if mouse_pos.y > viewport_rect.size.y - edge_margin:
		direction.y += 1
	# 좌측 엣지
	if mouse_pos.x < edge_margin:
		direction.x -= 1
	# 우측 엣지
	if mouse_pos.x > viewport_rect.size.x - edge_margin:
		direction.x += 1

	return direction
