extends Camera2D

## RTS 스타일 카메라 컨트롤러
## WASD 키보드 이동 + 마우스 엣지 스크롤 지원

# 카메라 이동 속도 (픽셀/초)
@export var speed: float = 300.0

# 화면 가장자리 감지 영역 (픽셀)
@export var edge_margin: int = 20

# 현재 이동 방향 벡터
var velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	# 카메라를 현재 카메라로 설정
	make_current()


func _process(delta: float) -> void:
	velocity = Vector2.ZERO

	# WASD 키보드 입력 처리
	_handle_keyboard_input()

	# 마우스 엣지 스크롤 처리
	# _handle_mouse_edge_scroll()

	# 카메라 이동 적용
	if velocity.length() > 0:
		# 대각선 이동 시 속도 정규화
		velocity = velocity.normalized() * speed
		position += velocity * delta


## WASD 키보드 입력 처리
func _handle_keyboard_input() -> void:
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		velocity.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		velocity.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		velocity.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		velocity.x += 1


## 마우스 엣지 스크롤 처리
func _handle_mouse_edge_scroll() -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_rect = get_viewport().get_visible_rect()

	# 상단 엣지
	if mouse_pos.y < edge_margin:
		velocity.y -= 1
	# 하단 엣지
	if mouse_pos.y > viewport_rect.size.y - edge_margin:
		velocity.y += 1
	# 좌측 엣지
	if mouse_pos.x < edge_margin:
		velocity.x -= 1
	# 우측 엣지
	if mouse_pos.x > viewport_rect.size.x - edge_margin:
		velocity.x += 1
