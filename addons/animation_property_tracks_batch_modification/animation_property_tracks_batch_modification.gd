@tool
extends EditorPlugin

const ANIMATION_PLAYER = preload("uid://7mxxr6b1iha6")
const PACKED_SCENE = preload("uid://byyql5sgawwh1")

const SEARCH = preload("uid://dioxr0g13xolu")



const CONTINUOUS = preload("uid://cqlab1mjhj3dg")
const DISCRETE = preload("uid://p82grnl4oama")
const CAPTURE = preload("uid://cy3n7qajgu3be")

const NEAREST = preload("uid://d0m8k01gu0sj1")
const LINEAR = preload("uid://b78gqadudp2wp")
const CUBIC = preload("uid://drrscwrbybblm")
const LINEAR_ANGLE = preload("uid://djbvsb87pjncm")
const CUBIC_ANGLE = preload("uid://dj2itiw74dmu6")

const WRAP_CLAMP = preload("uid://bgjg5sysqvo17")
const WRAP_LOOP = preload("uid://bqtpn3phg7usu")

const LOOP = preload("uid://c6a60pbjriaw4")
const LOOP_K = preload("uid://dlpkvplqga0sj")
const PING_PONG_LOOP_K = preload("uid://da7x2qcrfvr8y")



const PLUGIN_NAME = "动画属性轨道批量修改"

const gengxin_moshi_miaoshu = "更新模式：决定播放过程中，属性值何时被更新。\n\n连续：(需要平滑过渡效果,如颜色渐变、透明度变化)(需要配合插值类型) - 每帧都使用「插值模式」计算更新属性值。\n\n离散：(需要突然变化,跳跃式变化,类似开关或切换行为) - 只在关键帧时突然跳跃式更新属性值，关键帧之间不插值。\n\n捕获：(同连续, 且需要恢复动画开始播放时的原貌) - 在播放时捕获属性的当前值，并在动画结束时恢复。"

const chazhi_moshi_miaoshu = "插值模式(性能消耗情况)：决定了关键帧之间属性值如何过渡。\n\n临近(最低)：(不要平滑过渡，要突然变化,阶梯式变化,如开关或切换) - 突然从一个关键帧的值跳转到下一个关键帧的值，中间没有过渡。\n\n线性(低)：(需要匀速变化,没有加速或减速效果) - 属性值会在两个关键帧之间以恒定速率变化。\n\n三次方(中)：(自然平滑运动,要自然加速和减速效果,如弹跳、摆动) - 使用三次多项式来平滑过渡。会在关键帧处考虑前后关键帧的值，以创建更平滑更复杂的曲线。\n\n线性角(低)：专门用于角度（如旋转）。(使用最短路径,如，从350到10的旋转，会选择旋转20,而不是340度) - 会选择最短路径进行角度插值，避免不必要的旋转。\n\n三次角(中)：专门用于角度（如旋转）。(需要平滑旋转,模拟自然旋转,复杂的3D对象旋转) - 类似三次插值，会在考虑最短路径的同时，提供平滑的角度变化曲线。"

const xunhuan_moshi_miaoshu = "无缝循环模式(需要开启动画循环的从头播式模式)：决定动画从头播循环时到结尾时如何循环到开头。\n\n钳制循环：(播完结尾会瞬间闪现到开头播放,没有中间动画) - 播放到结尾时，会钳制在最后一帧，然后立即跳回第一帧继续播放。(适用于要明确起始和结束点的动画)\n帧序列: [1, 2, 3] → 播放到3 → 暂停 → 跳回1 → 继续播放\n\n环绕循环：(播完结尾会快速平滑回到开头播放,有中间动画) - 动画会在结尾和开头之间创建平滑过渡，形成一个真正无缝的循环。(适用于没有明显的跳跃或暂停)\n帧序列: [1, 2, 3] → 播放到3 → 平滑过渡到1 → 继续播放"

const douhua_xunhuan_miaoshu = "动画循环模式(应用于无缝循环的环绕循环)：\n\n不启用循环：(一次性、不重复的动画。)动画碰到第一帧或最后一帧，都会立即停止。\n\n从头播循环: (需要无限重复的动画)播放到结尾后立刻跳回开头重新播放，无限循环。\n\n反播式循环：(适合来回运动的动画,乒乓式播放)	播放到结尾后反向播放，反向播放完再正向播放,无限循环。"

# 单动画模式
var animation_selector: OptionButton
var current_animation: String = ""
var animation_container: HBoxContainer
var animation_label: Label
var select_all_animations_checkbox: CheckBox
var duo_changjing_dir_path: String
# 单场景模式变量
var animation_player: AnimationPlayer = null
var property_groups: Dictionary = {}
var all_properties: Array = []
var current_property_type: String = ""
var last_selected_index: int = -1
var search_edit: LineEdit
var group_checkbox: CheckBox

var single_scene_instruction2: Label
# 多场景模式变量
var all_animation_data: Dictionary = {}
var selected_folder: String = ""
# 共享UI变量
var dock: VBoxContainer
var toggle_button: Button
var content_container: VBoxContainer
var is_expanded: bool = true
var mode_switch_container: HBoxContainer
var single_scene_button: Button
var property_list: ItemList
var mode_combo: OptionButton
var apply_button: Button
var progress_bar: ProgressBar
var status_label: Label
var select_all_button: Button
var invert_selection_button: Button
var current_mode_type: String = "interpolation"
var current_edit_mode: String = "single"  # "single" 或 "multi"
var is_applying: bool = false
var scene_label: Label
var selected_scenes: PackedStringArray = []
var scene_selector: OptionButton
var select_all_scenes_checkbox: CheckBox
var multi_scene_button: Button
var multi_scene_files_button: Button
var folder_edit: LineEdit
var update_mode_button: Button
var interpolation_mode_button: Button
var loop_mode_button: Button
var animation_loop_mode_button : Button
# 颜色调色板
var color_palette: Array = [
	Color(0.8, 0.5, 0.5),
	Color(0.5, 0.8, 0.5),
	Color(0.5, 0.5, 0.8),
	Color(0.8, 0.8, 0.5),
	Color(0.8, 0.5, 0.8),
	Color(0.5, 0.8, 0.8),
	Color(0.8, 0.6, 0.4),
	Color(0.4, 0.8, 0.6)
]

func _enter_tree():
	# 创建停靠面板
	dock = VBoxContainer.new()
	dock.name = PLUGIN_NAME
	add_control_to_dock(DOCK_SLOT_LEFT_BR, dock)

	# 创建标题栏
	var title_container = HBoxContainer.new()
	title_container.add_theme_constant_override("separation", 4)
	dock.add_child(title_container)

	# 创建开关按钮
	toggle_button = Button.new()
	toggle_button.text = "▼ 收起面板"
	toggle_button.custom_minimum_size.x = 150
	toggle_button.pressed.connect(_on_toggle_button_pressed)
	title_container.add_child(toggle_button)

	# 创建内容容器
	content_container = VBoxContainer.new()
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dock.add_child(content_container)

	# 创建模式切换按钮容器
	mode_switch_container = HBoxContainer.new()
	mode_switch_container.add_theme_constant_override("separation", 3)
	content_container.add_child(mode_switch_container)

	# 创建单场景修改按钮
	single_scene_button = Button.new()
	single_scene_button.text = "单场景修改"
	single_scene_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	single_scene_button.custom_minimum_size = Vector2(0, 25)
	single_scene_button.toggle_mode = true
	single_scene_button.button_pressed = true
	single_scene_button.disabled = true
	single_scene_button.icon = ANIMATION_PLAYER
	single_scene_button.pressed.connect(_on_single_scene_pressed)
	mode_switch_container.add_child(single_scene_button)

	# 创建多场景修改按钮
	multi_scene_button = Button.new()
	multi_scene_button.text = "多场景修改"
	multi_scene_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	multi_scene_button.custom_minimum_size = Vector2(0, 25)
	multi_scene_button.toggle_mode = true
	multi_scene_button.disabled = false
	multi_scene_button.icon = PACKED_SCENE
	multi_scene_button.pressed.connect(_on_multi_scene_pressed)
	mode_switch_container.add_child(multi_scene_button)

	# 创建动画选择容器 (单动画模式)
	animation_container = HBoxContainer.new()
	animation_container.add_theme_constant_override("separation", 5)
	animation_container.name = "AnimationContainer"
	animation_container.visible = true
	content_container.add_child(animation_container)

	animation_label = Label.new()
	animation_label.text = "已全选动画:"
	animation_container.add_child(animation_label)

	animation_label.self_modulate = Color(0.0, 1.0, 0.0, 1.0)
	animation_selector = OptionButton.new()
	animation_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	animation_selector.disabled = true
	animation_selector.add_item("点AnimationPlayer, 刷新→")
	animation_selector.item_selected.connect(_on_animation_selected)
	animation_container.add_child(animation_selector)


	var refresh_animation_button = Button.new()
	refresh_animation_button.text = "刷新列表"
	refresh_animation_button.pressed.connect(_on_refresh_animation_list_pressed)
	animation_container.add_child(refresh_animation_button)


	# 添加动画全选复选框
	select_all_animations_checkbox = CheckBox.new()
	select_all_animations_checkbox.text = "动画全选"
	select_all_animations_checkbox.button_pressed = true
	select_all_animations_checkbox.toggled.connect(_on_select_all_animations_toggled)
	select_all_animations_checkbox.self_modulate = Color(0.0, 1.0, 0.0, 1.0)
	animation_container.add_child(select_all_animations_checkbox)

	# 创建文件夹选择区域 (多场景模式)
	var folder_container = VBoxContainer.new()
	folder_container.add_theme_constant_override("separation", 5)
	folder_container.name = "FolderContainer"
	folder_container.visible = false
	content_container.add_child(folder_container)

	# 创建文件夹选择行
	var folder_selection_container = HBoxContainer.new()
	folder_selection_container.add_theme_constant_override("separation", 5)
	folder_container.add_child(folder_selection_container)

	var folder_label = Label.new()
	folder_label.text = "(方法一)选文件夹:"
	folder_selection_container.add_child(folder_label)

	folder_edit = LineEdit.new()
	folder_edit.placeholder_text = "包括所有子文件夹的场景"
	folder_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	folder_edit.editable = false
	folder_selection_container.add_child(folder_edit)

	var folder_button = Button.new()
	folder_button.text = "浏览"
	folder_button.pressed.connect(_on_folder_button_pressed)
	folder_selection_container.add_child(folder_button)

	# 创建场景文件多选容器
	var multi_scene_container = HBoxContainer.new()
	multi_scene_container.add_theme_constant_override("separation", 5)
	folder_container.add_child(multi_scene_container)

	var multi_scene_label = Label.new()
	multi_scene_label.text = "(方法二)多选场景:"
	multi_scene_container.add_child(multi_scene_label)

	multi_scene_files_button = Button.new()
	multi_scene_files_button.text = "支持shift/ctrl多选"
	multi_scene_files_button.pressed.connect(_on_multi_scene_files_button_pressed)
	multi_scene_container.add_child(multi_scene_files_button)

	# 创建场景文件选择行
	var scene_selection_container = HBoxContainer.new()
	scene_selection_container.add_theme_constant_override("separation", 5)
	folder_container.add_child(scene_selection_container)

	scene_label = Label.new()
	scene_label.text = "已全选场景:"
	scene_selection_container.add_child(scene_label)

	scene_label.self_modulate = Color(0.0, 1.0, 0.0, 1.0)
	scene_selector = OptionButton.new()
	scene_selector.add_item("使用方法一或二")
	scene_selector.disabled = false
	scene_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_selector.item_selected.connect(_on_scene_selector_button_pressed)
	scene_selection_container.add_child(scene_selector)

	# 添加场景全选 CheckBox
	select_all_scenes_checkbox = CheckBox.new()
	select_all_scenes_checkbox.text = "场景全选"
	select_all_scenes_checkbox.button_pressed = true

	select_all_scenes_checkbox.self_modulate = Color(0.0, 1.0, 0.0, 1.0)
	select_all_scenes_checkbox.toggled.connect(_on_select_all_scenes_toggled)
	scene_selection_container.add_child(select_all_scenes_checkbox)

	# 创建模式选择按钮容器
	var mode_button_container = HBoxContainer.new()
	mode_button_container.add_theme_constant_override("separation", 3)
	content_container.add_child(mode_button_container)

	# 创建说明标签容器
	var instruction_container = VBoxContainer.new()
	instruction_container.name = "InstructionContainer"
	content_container.add_child(instruction_container)

	# 单场景说明标签
	var single_scene_instruction = Label.new()
	single_scene_instruction.name = "SingleSceneInstruction"
	single_scene_instruction.text = "1.选AnimationPlayer 2.刷新列表 4.刷新 3.支持shift/ctrl多选"
	single_scene_instruction.visible = true
	instruction_container.add_child(single_scene_instruction)

	# 多场景说明标签
	var multi_scene_instruction = Label.new()
	multi_scene_instruction.name = "MultiSceneInstruction"
	multi_scene_instruction.text = "1.选择方法一或二 2. 刷新 3.支持shift/ctrl多选"
	multi_scene_instruction.visible = false
	instruction_container.add_child(multi_scene_instruction)

	# 创建更新模式按钮
	update_mode_button = Button.new()
	update_mode_button.text = "更新模式\nUpdate"
	update_mode_button.tooltip_text = gengxin_moshi_miaoshu
	update_mode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	update_mode_button.custom_minimum_size = Vector2(0, 25)
	update_mode_button.toggle_mode = true
	update_mode_button.pressed.connect(_on_update_mode_pressed)
	mode_button_container.add_child(update_mode_button)

	# 创建插值模式按钮
	interpolation_mode_button = Button.new()
	interpolation_mode_button.text = "插值模式\nInterpolation"
	interpolation_mode_button.tooltip_text = chazhi_moshi_miaoshu
	interpolation_mode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	interpolation_mode_button.custom_minimum_size = Vector2(0, 25)
	interpolation_mode_button.toggle_mode = true
	interpolation_mode_button.button_pressed = true
	interpolation_mode_button.pressed.connect(_on_interpolation_mode_pressed)
	mode_button_container.add_child(interpolation_mode_button)

	# 创建无缝循环模式按钮
	loop_mode_button = Button.new()
	loop_mode_button.text = "无缝循环模式\nLoop Wrap"
	loop_mode_button.tooltip_text = xunhuan_moshi_miaoshu
	loop_mode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loop_mode_button.custom_minimum_size = Vector2(0, 25)
	loop_mode_button.toggle_mode = true
	loop_mode_button.pressed.connect(_on_loop_mode_pressed)
	mode_button_container.add_child(loop_mode_button)

	# 创建动画循环模式按钮
	animation_loop_mode_button = Button.new()
	animation_loop_mode_button.text = "动画循环\nAnimation Loop"
	animation_loop_mode_button.tooltip_text = douhua_xunhuan_miaoshu
	animation_loop_mode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	animation_loop_mode_button.custom_minimum_size = Vector2(0, 25)
	animation_loop_mode_button.toggle_mode = true
	animation_loop_mode_button.pressed.connect(_on_animation_loop_mode_pressed)
	mode_button_container.add_child(animation_loop_mode_button)

	# 设置初始状态
	update_mode_button.disabled = false
	interpolation_mode_button.disabled = true
	loop_mode_button.disabled = false

	# 创建搜索和分组区域 (单场景模式)
	var search_group_container = HBoxContainer.new()
	search_group_container.add_theme_constant_override("separation", 5)
	search_group_container.name = "SearchGroupContainer"
	content_container.add_child(search_group_container)

	search_edit = LineEdit.new()
	search_edit.placeholder_text = "搜索属性..."
	search_edit.right_icon = SEARCH
	search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_edit.text_changed.connect(_on_search_text_changed)
	search_group_container.add_child(search_edit)

	group_checkbox = CheckBox.new()
	group_checkbox.text = "按属性名分组"
	group_checkbox.button_pressed = true
	group_checkbox.toggled.connect(_on_group_checkbox_toggled)
	search_group_container.add_child(group_checkbox)



	# 创建选择按钮容器
	var selection_container = HBoxContainer.new()
	selection_container.add_theme_constant_override("separation", 3)
	content_container.add_child(selection_container)

	# 创建全选按钮
	select_all_button = Button.new()
	select_all_button.text = "全选(Select All)"
	select_all_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select_all_button.custom_minimum_size = Vector2(0, 25)
	select_all_button.pressed.connect(_on_select_all_pressed)
	selection_container.add_child(select_all_button)

	# 创建反选按钮
	invert_selection_button = Button.new()
	invert_selection_button.text = "反选(Invert selection)"
	invert_selection_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	invert_selection_button.custom_minimum_size = Vector2(0, 25)
	invert_selection_button.pressed.connect(_on_invert_selection_pressed)
	selection_container.add_child(invert_selection_button)

	# 创建属性列表
	property_list = ItemList.new()
	property_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	property_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	property_list.custom_minimum_size = Vector2(0, 80)
	property_list.select_mode = ItemList.SELECT_MULTI
	property_list.item_clicked.connect(_on_qiehuan_selected)

	property_list.item_selected.connect(_on_property_selected)
	property_list.multi_selected.connect(_on_property_multi_selected)
	content_container.add_child(property_list)

	# 警告说明标签
	single_scene_instruction2 = Label.new()
	single_scene_instruction2.name = "SingleSceneInstruction2"
	single_scene_instruction2.text = "线性角、三次角,有些轨道没有,要避免错误修改\n(Not all tracks have linear/cubic angles.)"
	single_scene_instruction2.self_modulate = Color(1.0, 0.398, 0.329, 1.0)
	content_container.add_child(single_scene_instruction2)

	# 创建模式选择框
	mode_combo = OptionButton.new()
	mode_combo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_combo.custom_minimum_size = Vector2(0, 25)
	mode_combo.disabled = true
	content_container.add_child(mode_combo)

	# 创建进度条
	progress_bar = ProgressBar.new()
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.visible = false
	content_container.add_child(progress_bar)

	# 创建状态标签
	status_label = Label.new()
	status_label.text = "待刷新(Refresh)"
	content_container.add_child(status_label)

	# 创建刷新和应用按钮的容器
	var refresh_apply_container = HBoxContainer.new()
	refresh_apply_container.name = "RefreshApplyContainer"
	refresh_apply_container.add_theme_constant_override("separation", 5)
	content_container.add_child(refresh_apply_container)

	# 创建刷新按钮
	var refresh_button = Button.new()
	refresh_button.text = "刷新(Refresh)"
	refresh_button.pressed.connect(_on_refresh_button_pressed)
	refresh_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	refresh_apply_container.add_child(refresh_button)

	# 创建应用按钮
	apply_button = Button.new()
	apply_button.text = "应用修改(Application Modified)"
	apply_button.pressed.connect(_on_apply_button_pressed)
	apply_button.disabled = true
	apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	refresh_apply_container.add_child(apply_button)


	# 初始化模式选择框
	update_mode_options()

	print(PLUGIN_NAME + " 插件已加载")

func _exit_tree():
	# 清理资源
	cleanup_resources()

	remove_control_from_docks(dock)
	if is_instance_valid(dock):
		dock.queue_free()

	print(PLUGIN_NAME + " 插件已卸载")

# 修改单场景模式处理函数
func _on_single_scene_pressed():
	# 清空搜索栏
	search_edit.text = ""
	if not single_scene_button.button_pressed:
		if current_edit_mode == "single":
			single_scene_button.button_pressed = true
		return

	multi_scene_button.button_pressed = false

	# 更新按钮状态
	single_scene_button.disabled = true
	multi_scene_button.disabled = false
	select_all_animations_checkbox.button_pressed = true
	animation_selector.add_item("点AnimationPlayer, 刷新→")
	group_checkbox.button_pressed = true
	group_checkbox.show()


	single_scene_button.button_pressed = false
	multi_scene_button.button_pressed = false

	# 更新按钮状态
	single_scene_button.disabled = true
	multi_scene_button.disabled = false

	current_edit_mode = "single"
	_update_ui_for_mode()

	# 清空属性栏
	property_list.clear()
	property_groups.clear()
	all_properties.clear()
	all_animation_data.clear()

	animation_label.text = "已全选动画:"

	# 刷新动画列表但不改变当前选择的动画
	_refresh_animation_list(false)
	_on_interpolation_mode_pressed()
	# 更新按钮状态
	_update_selection_buttons_state()

func _on_multi_scene_pressed():
	# 清空搜索栏
	search_edit.text = ""
	group_checkbox.hide()
	#search_edit.show()
	#scene_selector.clear()
	#folder_edit.clear()
	#folder_edit.placeholder_text = "包括所有子文件夹的场景"
	#scene_selector.text = "先使用 方法一或二"
	select_all_scenes_checkbox.button_pressed = true
	if current_edit_mode == "multi":
		return

	# 确保按钮被按下
	multi_scene_button.button_pressed = true

	# 取消其他按钮的按下状态
	single_scene_button.button_pressed = false
	select_all_scenes_checkbox.text = "场景全选"
	# 更新按钮状态
	single_scene_button.disabled = false
	multi_scene_button.disabled = true
	group_checkbox.button_pressed = true
	# 更新当前编辑模式
	current_edit_mode = "multi"

	# 更新UI以反映新模式
	_update_ui_for_mode()

	# 清空属性栏
	#property_list.clear()
	#all_animation_data.clear()
	#property_groups.clear()
	#all_properties.clear()

	# 更新按钮状态
	_update_selection_buttons_state()
	_on_interpolation_mode_pressed()

func _update_ui_for_mode():
	var folder_container = content_container.get_node("FolderContainer")
	var animation_container = content_container.get_node("AnimationContainer")
	var single_scene_instruction = content_container.get_node("InstructionContainer/SingleSceneInstruction")
	var multi_scene_instruction = content_container.get_node("InstructionContainer/MultiSceneInstruction")

	if current_edit_mode == "single":
		folder_container.visible = false
		animation_container.visible = true
		single_scene_instruction.visible = true
		multi_scene_instruction.visible = false
		animation_loop_mode_button.visible = true
	else:
		folder_container.visible = true
		animation_container.visible = false
		single_scene_instruction.visible = false
		multi_scene_instruction.visible = true
		animation_loop_mode_button.visible = true

func _refresh_animation_list(reset_selection: bool = true):
	var current_selection = current_animation

	animation_selector.clear()



	# 检查AnimationPlayer是否仍然有效
	if animation_player and not is_instance_valid(animation_player):
		animation_player = null


	# 获取选中的 AnimationPlayer
	var selected_nodes = get_editor_interface().get_selection().get_selected_nodes()
	if selected_nodes.size() == 0:
		push_warning("请先选择一个 AnimationPlayer 节点")
		return

	# 查找有效的AnimationPlayer
	animation_player = null
	for node in selected_nodes:
		if node is AnimationPlayer and is_instance_valid(node):
			animation_player = node
			break
	# 检查是否有选中的AnimationPlayer
	if not animation_player or not is_instance_valid(animation_player):
		animation_selector.add_item("点AnimationPlayer, 刷新→")
		animation_selector.disabled = true
		current_animation = ""
		return

	var douhuam_zi = str(animation_player.name)
	var douhuam_xunz = "%s 没有动画存在" % douhuam_zi
	# 获取所有动画
	var animations = animation_player.get_animation_list()
	if animations.size() == 0:
		animation_selector.add_item(douhuam_xunz)
		animation_selector.disabled = true
		current_animation = ""
		return

	# 添加动画到选择器
	animation_selector.disabled = false
	for anim_name in animations:
		animation_selector.add_item(anim_name)


	# 决定如何设置当前选择的动画
	if reset_selection or current_selection == "" or not animations.has(current_selection):
		# 尝试获取当前在动画编辑器中选择的动画
		var current_editor_animation = _get_editor_selected_animation()
		if current_editor_animation != "" and animations.has(current_editor_animation):
			animation_selector.select(animations.find(current_editor_animation))
			current_animation = current_editor_animation
		else:
			# 默认选择第一个动画
			animation_selector.select(0)
			current_animation = animations[0]
			refresh_animation_data()
	else:
		# 保持当前选择的动画
		animation_selector.select(animations.find(current_selection))
		current_animation = current_selection

func _get_editor_selected_animation() -> String:
	# 尝试获取动画编辑器当前选择的动画
	var editor_interface = get_editor_interface()

	# 方法1: 尝试通过动画播放器编辑器获取
	if editor_interface.has_method("get_animation_player_editor"):
		var animation_player_editor = editor_interface.get_animation_player_editor()
		if animation_player_editor and animation_player_editor.has_method("get_current_animation"):
			return animation_player_editor.get_current_animation()

	# 方法2: 尝试通过选中的AnimationPlayer获取当前播放的动画
	if animation_player and is_instance_valid(animation_player):
		return animation_player.current_animation

	return ""

func refresh_animation_data():
	if not is_expanded:
		return

	# 根据当前模式显示或隐藏搜索和分组UI
	if current_mode_type == "animation_loop":
		search_edit.visible = true
		group_checkbox.visible = false
	else:
		search_edit.visible = true
		group_checkbox.visible = true

	# 根据当前模式调用不同的刷新函数
	if current_edit_mode == "single":
		if current_mode_type == "animation_loop":
			_refresh_single_scene_animation_loop_data()
		else:
			_refresh_single_scene_data()
	else:
		if current_mode_type == "animation_loop":
			_refresh_multi_scene_animation_loop_data()
		else:
			_refresh_multi_scene_data()

func _refresh_single_scene_animation_loop_data():
	# 检查AnimationPlayer是否仍然有效
	if animation_player and not is_instance_valid(animation_player):
		animation_player = null

	property_list.clear()
	all_properties.clear()

	# 获取选中的 AnimationPlayer
	var selected_nodes = get_editor_interface().get_selection().get_selected_nodes()
	if selected_nodes.size() == 0:
		push_warning("请先选择一个 AnimationPlayer 节点")
		return

	# 查找有效的AnimationPlayer
	animation_player = null
	for node in selected_nodes:
		if node is AnimationPlayer and is_instance_valid(node):
			animation_player = node
			break

	if not animation_player:
		push_warning("请选择一个有效的 AnimationPlayer 节点")
		return

	# 显示搜索栏
	search_edit.visible = true
	group_checkbox.visible = false

	# 收集所有动画
	var animations = animation_player.get_animation_list()
	var search_text = search_edit.text.to_lower()

	# 显示所有动画名称及其循环模式
	for anim_name in animations:
		# 应用搜索过滤
		if search_text != "" and anim_name.to_lower().find(search_text) == -1:
			continue

		var animation = animation_player.get_animation(anim_name)
		if animation:
			var loop_mode = animation.loop_mode
			var loop_mode_text = get_animation_loop_mode_name(loop_mode)
			var item_text = "%s (%s)" % [anim_name, loop_mode_text]
			property_list.add_item(item_text,get_mode_name_icons(current_mode_type,loop_mode))
			all_properties.append({
				"display_text": item_text,
				"animation": animation,
				"loop_mode": loop_mode
			})

	update_selected_properties_info()

func get_animation_loop_mode_name(loop_mode: int) -> String:
	match loop_mode:
		Animation.LOOP_NONE:
			return "不启用循环"
		Animation.LOOP_LINEAR:
			return "从头播循环"
		Animation.LOOP_PINGPONG:
			return "反播式循环"
		_:
			return "未知"

# 修改 _refresh_multi_scene_animation_loop_data 函数，避免获取不在场景树中的节点路径
func _refresh_multi_scene_animation_loop_data():
	property_list.clear()
	all_properties.clear()

	# 确定要处理的场景文件
	var scenes_to_process = []

	# 方法二：直接多选场景文件
	if selected_scenes.size() > 0:
		# 根据场景全选状态决定处理哪些场景
		if select_all_scenes_checkbox.button_pressed:
			# 全选模式：处理所有选中的场景
			scenes_to_process = selected_scenes
		else:
			# 非全选模式：只处理当前选中的场景
			var selected_index = scene_selector.selected
			if selected_index >= 0 and selected_index < selected_scenes.size():
				scenes_to_process = [selected_scenes[selected_index]]
			else:
				push_warning("请先在场景列表中选择一个场景")
				return

	# 方法一：从文件夹选择场景
	elif duo_changjing_dir_path != "" and scene_selector.item_count > 0:
		# 使用从文件夹选择的场景文件
		var dir_path = duo_changjing_dir_path

		# 根据场景全选状态决定处理哪些场景
		if select_all_scenes_checkbox.button_pressed:
			# 全选模式：处理所有场景
			for i in range(scene_selector.item_count):
				var scene_file = scene_selector.get_item_text(i)
				scenes_to_process.append(dir_path.path_join(scene_file))
		else:
			# 非全选模式：只处理当前选中的场景
			var selected_index = scene_selector.selected
			if selected_index >= 0:
				var scene_file = scene_selector.get_item_text(selected_index)
				scenes_to_process.append(dir_path.path_join(scene_file))
	else:
		push_warning("请先选择场景文件或文件夹")
		return

	# 显示搜索栏
	search_edit.visible = true
	group_checkbox.visible = false

	# 获取搜索文本
	var search_text = search_edit.text.to_lower()

	# 处理场景文件
	var total_scenes = scenes_to_process.size()
	var processed_scenes = 0

	# 显示进度条
	progress_bar.max_value = total_scenes
	progress_bar.value = 0
	progress_bar.visible = true

	for scene_path in scenes_to_process:
		# 加载场景
		var scene = load(scene_path)
		if not scene:
			push_warning("无法加载场景: " + scene_path)
			continue

		# 实例化场景以获取AnimationPlayer
		var scene_instance = scene.instantiate()
		if not scene_instance:
			push_warning("无法实例化场景: " + scene_path)
			continue

		# 查找场景中的所有AnimationPlayer
		var animation_players = _find_animation_players(scene_instance)

		# 处理每个AnimationPlayer
		for anim_player in animation_players:
			var anim_list = anim_player.get_animation_list()
			for anim_name in anim_list:
				var animation = anim_player.get_animation(anim_name)
				if animation:
					var loop_mode = animation.loop_mode
					var loop_mode_text = get_animation_loop_mode_name(loop_mode)

					# 格式：场景名-动画节点名-动画名
					#var scene_name = scene_path.get_file().get_basename()
					var scene_name2 = scene_path.replace(duo_changjing_dir_path + "/", "").trim_suffix(".tscn")

					var node_name = anim_player.name
					var display_name = "%s〖tscn〗-%s『节点』-%s" % [scene_name2, node_name, anim_name]
					var item_text = "%s (%s)" % [display_name, loop_mode_text]


					# 应用搜索过滤 - 搜索完整的显示名称（场景名-动画节点名-动画名）
					if search_text != "" and display_name.to_lower().find(search_text) == -1:
						continue

					property_list.add_item(item_text,get_mode_name_icons(current_mode_type,loop_mode))
					all_properties.append({
						"display_text": item_text,
						"display_name": display_name,  # 存储显示名称，便于后续匹配
						"scene_path": scene_path,      # 存储场景路径，便于保存
						"animation_player_name": node_name,  # 存储动画播放器名称而不是路径
						"animation_name": anim_name,   # 存储动画名称
						"animation": animation,        # 存储动画资源引用
						"loop_mode": loop_mode         # 存储当前循环模式
					})

		# 释放场景实例
		scene_instance.queue_free()

		# 更新进度
		processed_scenes += 1
		progress_bar.value = processed_scenes

		# 处理事件循环，确保UI更新
		if processed_scenes % 5 == 0:
			await get_tree().process_frame

	# 隐藏进度条
	progress_bar.visible = false

	update_selected_properties_info()

func _refresh_single_animation_data():
	# 检查是否有选中的动画
	if current_animation == "" or current_animation == "请先选择一个AnimationPlayer" or current_animation == "没有找到动画":
		push_warning("请先选择一个动画")
		return

	# 检查AnimationPlayer是否有效
	if not animation_player or not is_instance_valid(animation_player):
		push_warning("请先选择一个有效的AnimationPlayer节点")
		return

	property_list.clear()
	property_groups.clear()
	all_properties.clear()
	current_property_type = ""
	last_selected_index = -1

	# 获取选中的动画
	var animation = animation_player.get_animation(current_animation)
	if not animation:
		push_warning("无法获取动画: " + current_animation)
		return

	# 收集动画中的所有属性
	if group_checkbox.button_pressed:
		# 按属性名分组
		for track_idx in animation.get_track_count():
			var track_type = animation.track_get_type(track_idx)
			if track_type == Animation.TYPE_VALUE:
				var path = animation.track_get_path(track_idx)
				var interpolation = animation.track_get_interpolation_type(track_idx)
				var update_mode = animation.value_track_get_update_mode(track_idx)
				# 先尝试获取循环模式，如果函数不存在则使用默认值
				var loop_wrap = false
				if animation.has_method("track_get_interpolation_loop_wrap"):
					loop_wrap = animation.track_get_interpolation_loop_wrap(track_idx)
				var path_str = str(path)
				var property_name = extract_property_name(path_str)

				if property_name != "":
					if not property_groups.has(property_name):
						property_groups[property_name] = {
							"paths": [],
							"interpolation": interpolation,
							"update_mode": update_mode,
							"loop_wrap": loop_wrap,
							"count": 0,
							"property_type": detect_property_type(property_name)
						}
					property_groups[property_name].paths.append(path_str)
					property_groups[property_name].count += 1

		# 显示分组后的属性
		for property_name in property_groups:
			var group = property_groups[property_name]
			var item_text = "%s (%d个轨道)" % [property_name, group.count]
			var item_count:int
			if current_mode_type == "interpolation":
				item_count = group.interpolation
				item_text += ", %s" % get_interpolation_name(group.interpolation)
			elif current_mode_type == "update":
				item_count = group.update_mode
				item_text += ", %s" % get_update_mode_name(group.update_mode)
			elif current_mode_type == "loop":
				item_count = group.loop_wrap
				item_text += ", %s" % get_loop_mode_name(group.loop_wrap)

			property_list.add_item(item_text,get_mode_name_icons(current_mode_type,item_count))
			all_properties.append({"display_text": item_text})

		print("按属性名分组: 找到 %d 个属性组，共 %d 个轨道" % [property_groups.size(), get_total_track_count()])
	else:
		# 按完整路径显示
		var paths_by_node = {}
		var path_index = 0

		for track_idx in animation.get_track_count():
			var track_type = animation.track_get_type(track_idx)
			if track_type == Animation.TYPE_VALUE:
				var path = animation.track_get_path(track_idx)
				var interpolation = animation.track_get_interpolation_type(track_idx)
				var update_mode = animation.value_track_get_update_mode(track_idx)
				# 先尝试获取循环模式，如果函数不存在则使用默认值
				var loop_wrap = false
				if animation.has_method("track_get_interpolation_loop_wrap"):
					loop_wrap = animation.track_get_interpolation_loop_wrap(track_idx)
				var path_str = str(path)

				# 提取节点路径（去掉属性部分）
				var node_path = extract_node_path(path_str)

				if not paths_by_node.has(node_path):
					paths_by_node[node_path] = {
						"properties": [],
						"color_index": path_index % color_palette.size()
					}
					path_index += 1

				paths_by_node[node_path].properties.append({
					"full_path": path_str,
					"interpolation": interpolation,
					"update_mode": update_mode,
					"loop_wrap": loop_wrap,
					"property_name": extract_property_name(path_str)
				})

		# 按节点路径分组显示，并添加颜色
		var display_index = 0
		for node_path in paths_by_node:
			var node_data = paths_by_node[node_path]
			var color = color_palette[node_data.color_index]

			# 添加节点路径分隔标题
			var separator_text = "--- 节点: " + node_path + " ---"
			property_list.add_item(separator_text)
			property_list.set_item_custom_fg_color(display_index, Color(0.5, 0.5, 0.5))
			all_properties.append({"display_text": separator_text, "is_separator": true})
			display_index += 1

			# 添加该节点的所有属性
			for prop in node_data.properties:

				var mode_text = ""
				var item_count:int
				if current_mode_type == "interpolation":
					item_count = prop.interpolation
					mode_text = get_interpolation_name(prop.interpolation)
				elif current_mode_type == "update":
					item_count = prop.update_mode
					mode_text = get_update_mode_name(prop.update_mode)
				elif current_mode_type == "loop":
					item_count = prop.loop_wrap
					mode_text = get_loop_mode_name(prop.loop_wrap)

				var item_text = "%s (%s)" % [prop.full_path, mode_text]
				property_list.add_item(item_text,get_mode_name_icons(current_mode_type,item_count))
				property_list.set_item_custom_fg_color(display_index, color)
				all_properties.append({"display_text": item_text, "color": color})
				display_index += 1

		print("按路径显示: 找到 %d 个节点，共 %d 个属性轨道" % [paths_by_node.size(), get_total_track_count()])

	update_selected_properties_info()

func get_total_track_count_for_animation(animation: Animation) -> int:
	var count = 0
	for track_idx in animation.get_track_count():
		var track_type = animation.track_get_type(track_idx)
		if track_type == Animation.TYPE_VALUE:
			count += 1
	return count

func _refresh_single_scene_data():
	# 检查AnimationPlayer是否仍然有效
	if animation_player and not is_instance_valid(animation_player):
		animation_player = null

	property_list.clear()
	property_groups.clear()
	all_properties.clear()
	current_property_type = ""
	last_selected_index = -1

	# 获取选中的 AnimationPlayer
	var selected_nodes = get_editor_interface().get_selection().get_selected_nodes()
	if selected_nodes.size() == 0:
		push_warning("请先选择一个 AnimationPlayer 节点")
		return

	# 查找有效的AnimationPlayer
	animation_player = null
	for node in selected_nodes:
		if node is AnimationPlayer and is_instance_valid(node):
			animation_player = node
			break

	if not animation_player:
		push_warning("请选择一个有效的 AnimationPlayer 节点")
		return

	# 确定要处理的动画列表
	var animations_to_process = []
	if select_all_animations_checkbox.button_pressed:
		# 全选模式：处理所有动画
		animations_to_process = animation_player.get_animation_list()
	else:
		# 单选模式：只处理当前选中的动画
		if animation_selector.selected >= 0:
			var selected_animation = animation_selector.get_item_text(animation_selector.selected)
			if selected_animation != "":
				animations_to_process.append(selected_animation)
		else:
			push_warning("请先选择一个动画")
			return

	# 收集所有选定动画中的属性
	if group_checkbox.button_pressed:
		# 按属性名分组
		for anim_name in animations_to_process:
			var animation = animation_player.get_animation(anim_name)
			for track_idx in animation.get_track_count():
				var track_type = animation.track_get_type(track_idx)
				if track_type == Animation.TYPE_VALUE:
					var path = animation.track_get_path(track_idx)
					var interpolation = animation.track_get_interpolation_type(track_idx)
					var update_mode = animation.value_track_get_update_mode(track_idx)
					var loop_wrap = false
					if animation.has_method("track_get_interpolation_loop_wrap"):
						loop_wrap = animation.track_get_interpolation_loop_wrap(track_idx)
					var path_str = str(path)
					var property_name = extract_property_name(path_str)

					if property_name != "":
						if not property_groups.has(property_name):
							property_groups[property_name] = {
								"paths": [],
								"interpolation": interpolation,
								"interpolation_s": [0, 0, 0, 0, 0],
								"update_mode": update_mode,
								"update_mode_s": [0, 0, 0],
								"loop_wrap": loop_wrap,
								"loop_wrap_s": [0, 0],
								"count": 0,
								"property_type": detect_property_type(property_name)
							}
						property_groups[property_name].paths.append(path_str)
						property_groups[property_name].count += 1

						property_groups[property_name]["interpolation_s"][interpolation] += 1
						property_groups[property_name]["update_mode_s"][update_mode] += 1
						if loop_wrap:
							property_groups[property_name]["loop_wrap_s"][1] += 1
						else:
							property_groups[property_name]["loop_wrap_s"][0] += 1

		# 显示分组后的属性
		for property_name in property_groups:
			var group = property_groups[property_name]
			var item_text = "%s (%d个轨道)" % [property_name, group.count]
			var item_count:int = 0
			var shuz = -1
			var bij = 0
			if current_mode_type == "interpolation":
				for i in group["interpolation_s"]:
					shuz += 1
					if i == 0:
						continue
					if i > bij:
						bij = i
						item_count = shuz
					item_text += ", %s*%s" % [get_interpolation_name(shuz), i]
			elif current_mode_type == "update":
				for i in group["update_mode_s"]:
					shuz += 1
					if i == 0:
						continue
					if i > bij:
						bij = i
						item_count = shuz
					item_text += ", %s*%s" % [get_update_mode_name(shuz), i]
			elif current_mode_type == "loop":
				for i in group["loop_wrap_s"]:
					shuz += 1
					if i == 0:
						continue
					if i > bij:
						bij = i
						item_count = shuz
					item_text += ", %s*%s" % [get_loop_mode_name(shuz), i]

			property_list.add_item(item_text, get_mode_name_icons(current_mode_type, item_count))
			all_properties.append({"display_text": item_text})

		print("按属性名分组: 找到 %d 个属性组，共 %d 个轨道" % [property_groups.size(), get_total_track_count()])
	else:
		# 按完整路径显示
		var paths_by_node = {}
		var path_index = 0

		for anim_name in animations_to_process:
			var animation = animation_player.get_animation(anim_name)
			for track_idx in animation.get_track_count():
				var track_type = animation.track_get_type(track_idx)
				if track_type == Animation.TYPE_VALUE:
					var path = animation.track_get_path(track_idx)
					var interpolation = animation.track_get_interpolation_type(track_idx)
					var update_mode = animation.value_track_get_update_mode(track_idx)
					var loop_wrap = false
					if animation.has_method("track_get_interpolation_loop_wrap"):
						loop_wrap = animation.track_get_interpolation_loop_wrap(track_idx)
					var path_str = str(path)

					# 提取节点路径（去掉属性部分）
					var node_path = extract_node_path(path_str)

					if not paths_by_node.has(node_path):
						paths_by_node[node_path] = {
							"properties": [],
							"color_index": path_index % color_palette.size()
						}
						path_index += 1

					paths_by_node[node_path].properties.append({
						"full_path": path_str,
						"interpolation": interpolation,
						"update_mode": update_mode,
						"loop_wrap": loop_wrap,
						"property_name": extract_property_name(path_str)
					})

		# 按节点路径分组显示，并添加颜色
		var display_index = 0
		for node_path in paths_by_node:
			var node_data = paths_by_node[node_path]
			var color = color_palette[node_data.color_index]

			# 添加节点路径分隔标题
			var separator_text = "--- 节点: " + node_path + " ---"
			property_list.add_item(separator_text)
			property_list.set_item_custom_fg_color(display_index, Color(0.5, 0.5, 0.5))
			all_properties.append({"display_text": separator_text, "is_separator": true})
			display_index += 1

			# 添加该节点的所有属性
			for prop in node_data.properties:
				var mode_text = ""
				var item_count:int
				if current_mode_type == "interpolation":
					item_count = prop.interpolation
					mode_text = get_interpolation_name(prop.interpolation)
				elif current_mode_type == "update":
					item_count = prop.update_mode
					mode_text = get_update_mode_name(prop.update_mode)
				elif current_mode_type == "loop":
					item_count = prop.loop_wrap
					mode_text = get_loop_mode_name(prop.loop_wrap)

				var item_text = "%s (%s)" % [prop.full_path, mode_text]
				property_list.add_item(item_text, get_mode_name_icons(current_mode_type, item_count))
				property_list.set_item_custom_fg_color(display_index, color)
				all_properties.append({"display_text": item_text, "color": color})
				display_index += 1

		print("按路径显示: 找到 %d 个节点，共 %d 个属性轨道" % [paths_by_node.size(), get_total_track_count()])

	update_selected_properties_info()

func _refresh_multi_scene_data():
	property_list.clear()
	all_animation_data.clear()

	# 确定要处理的场景文件
	var scenes_to_process = []

	# 方法二：直接多选场景文件
	if selected_scenes.size() > 0:
		# 根据场景全选状态决定处理哪些场景
		if select_all_scenes_checkbox.button_pressed:
			# 全选模式：处理所有选中的场景
			scenes_to_process = selected_scenes
		else:
			# 非全选模式：只处理当前选中的场景
			var selected_index = scene_selector.selected
			if selected_index >= 0 and selected_index < selected_scenes.size():
				scenes_to_process = [selected_scenes[selected_index]]
			else:
				push_warning("请先在场景列表中选择一个场景")
				return

	# 方法一：从文件夹选择场景
	elif duo_changjing_dir_path != "" and scene_selector.item_count > 0:
		# 使用从文件夹选择的场景文件
		var dir_path = duo_changjing_dir_path

		# 根据场景全选状态决定处理哪些场景
		if select_all_scenes_checkbox.button_pressed:
			# 全选模式：处理所有场景
			for i in range(scene_selector.item_count):
				var scene_file = scene_selector.get_item_text(i)
				scenes_to_process.append(dir_path.path_join(scene_file))
		else:
			# 非全选模式：只处理当前选中的场景
			var selected_index = scene_selector.selected
			if selected_index >= 0:
				var scene_file = scene_selector.get_item_text(selected_index)
				scenes_to_process.append(dir_path.path_join(scene_file))
	else:
		push_warning("请先选择场景文件或文件夹")
		return

	# 显示搜索栏
	search_edit.visible = true
	group_checkbox.visible = false

	# 获取搜索文本
	var search_text = search_edit.text.to_lower()

	# 处理场景文件
	var total_scenes = scenes_to_process.size()
	var processed_scenes = 0

	# 显示进度条
	progress_bar.max_value = total_scenes
	progress_bar.value = 0
	progress_bar.visible = true

	for scene_path in scenes_to_process:
		# 加载场景
		var scene = load(scene_path)
		if not scene:
			push_warning("无法加载场景: " + scene_path)
			continue

		# 实例化场景以获取AnimationPlayer
		var scene_instance = scene.instantiate()
		if not scene_instance:
			push_warning("无法实例化场景: " + scene_path)
			continue

		# 查找场景中的所有AnimationPlayer
		var animation_players = _find_animation_players(scene_instance)

		# 处理每个AnimationPlayer
		for anim_player in animation_players:
			var anim_list = anim_player.get_animation_list()
			for anim_name in anim_list:
				var animation = anim_player.get_animation(anim_name)
				if animation:
					# 处理动画中的轨道
					for track_idx in animation.get_track_count():
						var track_type = animation.track_get_type(track_idx)
						if track_type == Animation.TYPE_VALUE:
							var path = animation.track_get_path(track_idx)
							var path_str = str(path)
							var property_name = extract_property_name(path_str)

							if property_name != "":
								# 应用搜索过滤
								if search_text != "" and property_name.to_lower().find(search_text) == -1:
									continue

								# 获取当前模式值
								var current_mode = -1
								match current_mode_type:
									"update":
										current_mode = animation.value_track_get_update_mode(track_idx)
									"interpolation":
										current_mode = animation.track_get_interpolation_type(track_idx)
									"loop":
										if animation.has_method("track_get_interpolation_loop_wrap"):
											current_mode = 1 if animation.track_get_interpolation_loop_wrap(track_idx) else 0
										else:
											current_mode = 0

								# 添加到数据中
								if not all_animation_data.has(property_name):
									all_animation_data[property_name] = {
										"scenes": {},
										"total_tracks": 0,
										"current_mode": current_mode,
										"current_mode_s": [0, 0, 0, 0 ,0],
									}
								if not all_animation_data[property_name].scenes.has(scene_path):
									all_animation_data[property_name].scenes[scene_path] = 0

								all_animation_data[property_name].scenes[scene_path] += 1
								all_animation_data[property_name].total_tracks += 1

								all_animation_data[property_name]["current_mode_s"][current_mode] += 1
		# 释放场景实例
		scene_instance.queue_free()

		# 更新进度
		processed_scenes += 1
		progress_bar.value = processed_scenes

		# 处理事件循环，确保UI更新
		if processed_scenes % 5 == 0:
			await get_tree().process_frame

	# 隐藏进度条
	progress_bar.visible = false
	# 显示属性
	for property_name in all_animation_data:
		var data = all_animation_data[property_name]
		var item_text = "%s (%d个轨道, %d个场景)" % [property_name, data.total_tracks, data.scenes.size()]

		var item_count:int = 0
		var shuz = -1
		var bij = 0
		for i in data["current_mode_s"]:
			shuz += 1
			if i == 0:
				continue
			if i > bij:
				bij = i
				item_count = shuz
			item_text += ", %s*%s" % [_get_mode_name_by_value(current_mode_type, shuz),i]
		property_list.add_item(item_text,get_mode_name_icons(current_mode_type,item_count))

	print("多场景模式: 找到 %d 个属性，共 %d 个轨道" % [all_animation_data.size(), get_total_track_count()])
	update_selected_properties_info()

func _find_animation_players(node: Node) -> Array:
	var result = []

	# 如果当前节点是AnimationPlayer，添加到结果
	if node is AnimationPlayer:
		result.append(node)

	# 递归查找子节点
	for child in node.get_children():
		result.append_array(_find_animation_players(child))

	return result

func _on_language_selected(index: int):
	pass


func _on_toggle_button_pressed():
	is_expanded = !is_expanded
	content_container.visible = is_expanded

	# 更新停靠面板的大小
	if is_expanded:
		toggle_button.text = "▼ 收起面板"
		# 设置最小高度以确保内容可见
		dock.custom_minimum_size = Vector2(0, 500)
	else:
		toggle_button.text = "▶ 展开面板"
		# 收起时恢复最小高度
		dock.custom_minimum_size = Vector2(0, 30)

	# 强制更新布局
	dock.queue_redraw()

func _on_refresh_button_pressed():
	# 确保面板是展开状态
	if not is_expanded:
		is_expanded = true
		content_container.visible = true
		toggle_button.text = "▼ 收起面板"
		dock.custom_minimum_size = Vector2(0, 500)

	# 根据当前模式刷新相应数据
	if current_edit_mode == "animation":
		# 单动画模式：只刷新当前动画数据，不重置动画选择
		refresh_animation_data()
	else:
		# 单场景或多场景模式：直接刷新数据
		refresh_animation_data()

func _on_animation_selected(index: int):
	current_animation = animation_selector.get_item_text(index)
	refresh_animation_data()

func _on_select_all_animations_toggled(button_pressed: bool):
	if button_pressed:
		animation_label.text = "已全选动画:"
		animation_label.self_modulate = Color(0.0, 1.0, 0.0, 1.0)
		select_all_animations_checkbox.self_modulate = Color(0.0, 1.0, 0.0, 1.0)
	else :
		animation_label.text = "选择单动画:"
		animation_label.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		select_all_animations_checkbox.self_modulate = Color(1.0, 1.0, 1.0, 1.0)


	refresh_animation_data()
	_refresh_animation_list()

func _on_refresh_animation_list_pressed():
	if select_all_animations_checkbox.button_pressed:
		animation_label.text = "已全选动画:"
		animation_label.self_modulate = Color(0.0, 0.976, 0.0, 1.0)
	else :
		animation_label.text = "选择单动画:"
		animation_label.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	_refresh_animation_list()

func _on_folder_button_pressed():
	var file_dialog = EditorFileDialog.new()
	file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	file_dialog.dir_selected.connect(_on_folder_selected)
	get_editor_interface().get_base_control().add_child(file_dialog)
	file_dialog.popup_centered(Vector2i(700, 500))

func _on_folder_selected(dir_path: String):
	duo_changjing_dir_path = dir_path

	#folder_edit.text = dir_path
	_scan_folder_for_scenes(dir_path)
	# 清空多选场景
	selected_scenes.clear()

	property_list.clear()
	property_groups.clear()
	all_properties.clear()
	all_animation_data.clear()

func _scan_folder_for_scenes(dir_path: String):
	scene_selector.clear()

	# 显示进度条
	progress_bar.max_value = 0  # 先设置为0，稍后更新
	progress_bar.value = 0
	progress_bar.visible = true

	# 递归收集所有场景文件
	var scene_files = []
	var folders_to_process = [dir_path]
	var processed_folders = 0

	# 首先收集所有文件夹和子文件夹中的.tscn文件
	while folders_to_process.size() > 0:
		var current_folder = folders_to_process.pop_front()
		var dir = DirAccess.open(current_folder)
		if not dir:
			push_error("无法打开文件夹: " + current_folder)
			continue

		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			var full_path = current_folder.path_join(file_name)

			if dir.current_is_dir() and file_name != "." and file_name != "..":
				# 如果是子文件夹，添加到待处理列表
				folders_to_process.append(full_path)
			elif not dir.current_is_dir() and file_name.ends_with(".tscn"):
				# 如果是.tscn文件，添加到场景文件列表
				scene_files.append(full_path)

			file_name = dir.get_next()
		dir.list_dir_end()

		processed_folders += 1

		# 更新进度条显示当前处理的文件夹数量
		progress_bar.max_value = processed_folders + folders_to_process.size()
		progress_bar.value = processed_folders

		# 处理事件循环，确保UI更新
		if processed_folders % 5 == 0:
			await get_tree().process_frame

	# 设置进度条最大值
	progress_bar.max_value = scene_files.size()
	var processed_files = 0

	# 检查每个场景文件是否包含动画节点
	for scene_path in scene_files:
		# 加载场景资源
		var scene = load(scene_path)
		if scene:
			# 实例化场景以检查是否有动画节点
			var scene_instance = scene.instantiate()
			if scene_instance:
				# 查找场景中的所有AnimationPlayer
				var animation_players = _find_animation_players(scene_instance)
				if animation_players.size() > 0:
					# 如果有动画节点，添加到选择器
					# 显示相对路径以便识别
					var relative_path = scene_path.replace(dir_path + "/", "")
					scene_selector.add_item(relative_path)

				# 释放场景实例
				scene_instance.queue_free()
		select_all_scenes_checkbox.text = "场景全选(%s)" % scene_selector.get_item_count()

		folder_edit.text = "%d个有动画（%d个场景）%s" % [scene_selector.get_item_count(), scene_files.size(),dir_path]


		# 更新进度
		processed_files += 1
		progress_bar.value = processed_files

		# 处理事件循环，确保UI更新
		if processed_files % 5 == 0:
			await get_tree().process_frame

	# 隐藏进度条
	progress_bar.visible = false

	# 更新状态
	status_label.text = "已选择文件夹，找到 %d 个有动画的场景文件（共 %d 个场景文件）" % [scene_selector.item_count, scene_files.size()]


func _on_update_mode_pressed():
	# 清空搜索栏
	search_edit.text = ""
	if current_mode_type == "update":
		return

	# 确保按钮被按下
	update_mode_button.button_pressed = true

	# 取消其他按钮的按下状态
	interpolation_mode_button.button_pressed = false
	loop_mode_button.button_pressed = false
	animation_loop_mode_button.button_pressed = false

	# 更新按钮状态
	update_mode_button.disabled = true
	interpolation_mode_button.disabled = false
	loop_mode_button.disabled = false
	animation_loop_mode_button.disabled = false
	single_scene_instruction2.hide()
	group_checkbox.button_pressed = true


	current_mode_type = "update"
	_update_mode_options()

	# 刷新属性栏
	refresh_animation_data()

func _update_mode_options():
	# 清空模式选择框
	mode_combo.clear()

	# 根据当前模式类型添加选项

	match current_mode_type:
		"update":
			mode_combo.add_icon_item(CONTINUOUS,"连续(Continuous)", Animation.UPDATE_CONTINUOUS)
			mode_combo.add_icon_item(DISCRETE,"离散(Discrete)", Animation.UPDATE_DISCRETE)
			mode_combo.add_icon_item(CAPTURE,"捕获(Capture)", Animation.UPDATE_CAPTURE)
		"interpolation":
			mode_combo.add_icon_item(NEAREST,"临近(Nearest)", Animation.INTERPOLATION_NEAREST)
			mode_combo.add_icon_item(LINEAR,"线性(Linear)", Animation.INTERPOLATION_LINEAR)
			mode_combo.add_icon_item(CUBIC,"三次方(Cubic)", Animation.INTERPOLATION_CUBIC)
			mode_combo.add_icon_item(LINEAR_ANGLE,"线性角(Linear Angle)", Animation.INTERPOLATION_LINEAR_ANGLE)
			mode_combo.add_icon_item(CUBIC_ANGLE,"三次角(Cubic Angle)", Animation.INTERPOLATION_CUBIC_ANGLE)
		"loop":
			mode_combo.add_icon_item(WRAP_CLAMP,"钳制循环 (Clamp Loop Interp)", 0)
			mode_combo.add_icon_item(WRAP_LOOP,"环绕循环 (Wrap Loop Interp)", 1)

			mode_combo.add_icon_item(LOOP_K,"(<-该模式需要启用从头播循环)", 3)
			mode_combo.set_item_disabled(2, true)

		"animation_loop":
			mode_combo.add_icon_item(LOOP,"不启用循环", 0)
			mode_combo.add_icon_item(LOOP_K,"从头播循环", 1)
			mode_combo.add_icon_item(PING_PONG_LOOP_K,"反播式循环", 2)

	# 默认选择第一个选项
	if mode_combo.item_count > 0:
		mode_combo.select(0)

func _on_animation_loop_mode_pressed():

	search_edit.text = ""
	if current_mode_type == "animation_loop":
		return

	# 确保按钮被按下
	animation_loop_mode_button.button_pressed = true

	# 取消其他按钮的按下状态
	update_mode_button.button_pressed = false
	interpolation_mode_button.button_pressed = false
	loop_mode_button.button_pressed = false
	single_scene_instruction2.hide()

	# 更新按钮状态
	update_mode_button.disabled = false
	interpolation_mode_button.disabled = false
	loop_mode_button.disabled = false
	animation_loop_mode_button.disabled = true
	group_checkbox.button_pressed = false
	current_mode_type = "animation_loop"
	_update_mode_options()

	# 刷新属性栏
	refresh_animation_data()

func _on_interpolation_mode_pressed():

	search_edit.text = ""

	if current_mode_type == "interpolation":
		return

	# 确保按钮被按下
	interpolation_mode_button.button_pressed = true

	# 取消其他按钮的按下状态
	update_mode_button.button_pressed = false
	loop_mode_button.button_pressed = false
	animation_loop_mode_button.button_pressed = false

	# 更新按钮状态
	update_mode_button.disabled = false
	interpolation_mode_button.disabled = true
	loop_mode_button.disabled = false
	animation_loop_mode_button.disabled = false
	group_checkbox.button_pressed = true
	single_scene_instruction2.show()

	current_mode_type = "interpolation"
	_update_mode_options()

	# 刷新属性栏
	refresh_animation_data()

func _on_loop_mode_pressed():
	# 清空搜索栏
	search_edit.text = ""

	if not loop_mode_button.button_pressed:
		if current_mode_type == "loop":
			loop_mode_button.button_pressed = true
		return

	update_mode_button.button_pressed = false
	interpolation_mode_button.button_pressed = false
	animation_loop_mode_button.button_pressed = false

	# 更新按钮状态
	update_mode_button.disabled = false
	interpolation_mode_button.disabled = false
	loop_mode_button.disabled = true
	animation_loop_mode_button.disabled = false
	group_checkbox.button_pressed = true
	group_checkbox.show()
	single_scene_instruction2.hide()

	current_mode_type = "loop"
	_update_mode_options()

	# 刷新属性栏
	refresh_animation_data()

func update_mode_options():
	mode_combo.clear()

	match current_mode_type:
		"update":
			mode_combo.add_icon_item(CONTINUOUS, "连续 (CONTINUOUS)", Animation.UPDATE_CONTINUOUS)
			mode_combo.add_icon_item(DISCRETE, "离散 (DISCRETE)", Animation.UPDATE_DISCRETE)
			mode_combo.add_icon_item(CAPTURE, "捕获 (CAPTURE)", Animation.UPDATE_CAPTURE)
		"interpolation":
			mode_combo.add_icon_item(NEAREST,"临近 (NEAREST)", 0)
			mode_combo.add_icon_item(LINEAR, "线性 (LINEAR)", 1)
			mode_combo.add_icon_item(CUBIC, "三次方 (CUBIC)", 2)
			mode_combo.add_icon_item(LINEAR_ANGLE, "线性角 (LINEAR_ANGLE)", 3)
			mode_combo.add_icon_item(CUBIC_ANGLE, "三次角 (CUBIC_ANGLE)", 4)
		"loop":
			mode_combo.add_icon_item(WRAP_CLAMP, "钳制循环 (Clamp Loop Interp)", 0)
			mode_combo.add_icon_item(WRAP_LOOP, "环绕循环 (Wrap Loop Interp)", 1)
		"animation_loop":
			mode_combo.add_icon_item(LOOP, "不启用循环", 0)
			mode_combo.add_icon_item(LOOP_K, "从头播循环", 1)
			mode_combo.add_icon_item(PING_PONG_LOOP_K, "反播式循环", 2)
			mode_combo.tooltip_text = douhua_xunhuan_miaoshu

func _on_select_all_pressed():
	# 全选功能
	for i in range(property_list.item_count):
		property_list.select(i, false)
	_update_selection_buttons_state()

func _on_invert_selection_pressed():
	# 反转选择功能
	for i in range(property_list.item_count):
		if property_list.is_selected(i):
			property_list.deselect(i)
		else:
			property_list.select(i, false)
	_update_selection_buttons_state()

func _on_property_selected(index: int):
	_update_selection_buttons_state()


func _on_qiehuan_selected(index: int, _at_position: Vector2, _mouse_button_index: int):
	#mode_combo
	var ss = property_list.get_item_text(index)
	#mode_combo.selected = get_mode_name_leixing(current_mode_type, )

	if group_checkbox.button_pressed:

		mode_combo.selected = get_mode_name_leixing(current_mode_type, xunzhao_wenzi_mubiao(ss))
	else :
		mode_combo.selected = get_mode_name_leixing(current_mode_type, xunzhao_kuohao_mubiao(ss))

func xunzhao_kuohao_mubiao(text: String) -> String:
	var zuo_wz = text.rfind("(")
	var you_wz = text.rfind(")")

	if zuo_wz == -1 or you_wz == -1:
		return ""
	return text.substr(zuo_wz + 1, you_wz - zuo_wz - 1)


func xunzhao_wenzi_mubiao(text: String) -> String:
	var zuo_wz = text.rfind("), ")
	var you_wz = text.find("*")
	if zuo_wz == -1:
		return ""
	if you_wz != -1:
		you_wz = you_wz - zuo_wz - 3
	return text.substr(zuo_wz + 3, you_wz)

func get_mode_name_leixing(mode:String, leixing:String):
	match mode:
		"update":
			match leixing:
				"连续": return 0
				"离散": return 1
				"捕获": return 2
				_: return 0
		"interpolation":
			match leixing:
				"临近": return 0
				"线性": return 1
				"三次方": return 2
				"线性角": return 3
				"三次角": return 4
				_: return 0
		"loop":
			match leixing:
				"钳制循环": return 0
				"环绕循环": return 1
				_: return 0
		"animation_loop":
			match leixing:
				"不启用循环": return 0
				"从头播循环": return 1
				"反播式循环": return 2
				_: return 0




func _on_property_multi_selected(index: int, selected: bool):
	_update_selection_buttons_state()

func _update_selection_buttons_state():
	var selected_count = property_list.get_selected_items().size()
	var total_count = property_list.item_count

	if total_count == 0:
		status_label.text = "需要刷新 | 模式: %s" % _get_mode_type_name()
	else :
		## 更新状态标签
		status_label.text = "已选择: %d/%d 个属性 | 模式: %s" % [selected_count, total_count, _get_mode_type_name()]


	# 启用/禁用模式选择框和应用按钮
	if selected_count > 0:
		mode_combo.disabled = false
		apply_button.disabled = false
	else:
		mode_combo.disabled = true
		apply_button.disabled = true

	# 启用/禁用选择按钮
	select_all_button.disabled = (total_count == 0)
	invert_selection_button.disabled = (total_count == 0)

func _get_mode_type_name() -> String:
	match current_mode_type:
		"update": return "更新模式"
		"interpolation": return "插值模式"
		"loop": return "无缝循环模式"
		"animation_loop": return "动画循环"
		_: return "未知模式"

func _on_apply_button_pressed():
	if is_applying:
		return

	# 获取选中的项
	var selected_indices = property_list.get_selected_items()
	if selected_indices.size() == 0:
		push_warning("请先选择要修改的属性")
		return

	# 获取选中的模式
	if mode_combo.selected < 0:
		push_warning("请先选择一个模式")
		return

	var selected_mode = mode_combo.get_item_id(mode_combo.selected)

	# 禁用按钮，防止重复点击
	is_applying = true
	apply_button.disabled = true
	select_all_button.disabled = true
	invert_selection_button.disabled = true

	# 根据当前模式调用不同的应用函数
	if current_edit_mode == "animation":
		_apply_single_animation_mode(selected_indices, selected_mode)
	elif current_edit_mode == "single":
		if current_mode_type == "animation_loop":
			_apply_single_scene_animation_loop_mode(selected_indices, selected_mode)
		else:
			_apply_single_scene_mode(selected_indices, selected_mode)
	else:
		if current_mode_type == "animation_loop":
			_apply_multi_scene_animation_loop_mode(selected_indices, selected_mode)
		else:
			# 使用通用的多场景应用函数
			_apply_multi_scene_mode(selected_indices, selected_mode)

func _apply_single_scene_animation_loop_mode(selected_indices: Array, selected_mode: int):
	# 确保有选中的AnimationPlayer
	if not animation_player or not is_instance_valid(animation_player):
		push_error("没有有效的AnimationPlayer，请重新选择")
		is_applying = false
		apply_button.disabled = false
		select_all_button.disabled = false
		invert_selection_button.disabled = true
		progress_bar.visible = false
		return

	var modified_total = 0

	# 处理每个选中的动画
	for index in selected_indices:
		var item_data = all_properties[index]
		if item_data.has("animation"):
			var animation = item_data["animation"]
			animation.loop_mode = selected_mode
			modified_total += 1

	# 重新启用按钮
	is_applying = false
	apply_button.disabled = false
	select_all_button.disabled = false
	invert_selection_button.disabled = true

	# 更新状态信息
	if modified_total > 0:
		status_label.text = "成功修改了 %d 个动画的循环模式！" % modified_total
		# 刷新文件系统
		get_editor_interface().get_resource_filesystem().scan()
	else:
		status_label.text = "没有需要修改的动画"

	# 刷新显示以反映修改后的状态
	refresh_animation_data()

# 修改 _apply_multi_scene_animation_loop_mode 函数，使用名称而不是路径来查找动画播放器
func _apply_multi_scene_animation_loop_mode(selected_indices: Array, selected_mode: int):
	var modified_total = 0
	var scenes_to_save = {}  # 用于记录需要保存的场景

	# 显示进度条
	progress_bar.max_value = selected_indices.size()
	progress_bar.value = 0
	progress_bar.visible = true
	var processed_work = 0

	# 处理每个选中的项
	for index in selected_indices:
		var item_data = all_properties[index]
		if item_data.has("animation"):
			var animation = item_data["animation"]
			animation.loop_mode = selected_mode
			modified_total += 1

			# 记录需要保存的场景
			var scene_path = item_data["scene_path"]
			if not scenes_to_save.has(scene_path):
				scenes_to_save[scene_path] = true

		# 更新进度
		processed_work += 1
		progress_bar.value = processed_work

		# 处理事件循环，确保UI更新
		if processed_work % 5 == 0:
			await get_tree().process_frame

	# 保存所有修改过的场景
	var saved_scenes = 0
	progress_bar.max_value = scenes_to_save.size()
	progress_bar.value = 0

	for scene_path in scenes_to_save:
		# 加载场景资源
		var scene_resource = load(scene_path)
		if not scene_resource:
			push_warning("无法加载场景资源: " + scene_path)
			continue

		# 实例化场景以获取AnimationPlayer
		var scene_instance = scene_resource.instantiate()
		if not scene_instance:
			push_warning("无法实例化场景: " + scene_path)
			continue

		# 查找场景中的所有AnimationPlayer并应用修改
		var animation_players = _find_animation_players(scene_instance)
		var scene_modified = false

		for anim_player in animation_players:
			var anim_list = anim_player.get_animation_list()
			for anim_name in anim_list:
				var animation = anim_player.get_animation(anim_name)
				if animation:
					# 检查这个动画是否在选中的项中
					var display_name = "%s-%s-%s" % [
						scene_path.get_file().get_basename(),
						anim_player.name,
						anim_name
					]

					# 查找匹配的项
					for item_data in all_properties:
						if item_data.get("display_name", "") == display_name and item_data.has("animation"):
							# 应用相同的修改
							animation.loop_mode = selected_mode
							scene_modified = true
							break

		# 如果场景有修改，保存它
		if scene_modified:
			# 创建一个新的 PackedScene 来保存修改后的场景
			var packed_scene = PackedScene.new()
			var error = packed_scene.pack(scene_instance)
			if error == OK:
				error = ResourceSaver.save(packed_scene, scene_path)
				if error != OK:
					push_warning("保存场景失败: " + scene_path + "，错误代码: " + str(error))
				else:
					print("成功保存场景: " + scene_path)
			else:
				push_warning("打包场景失败: " + scene_path)

		# 释放场景实例
		scene_instance.queue_free()

		# 更新进度
		saved_scenes += 1
		progress_bar.value = saved_scenes

		# 处理事件循环，确保UI更新
		if saved_scenes % 2 == 0:
			await get_tree().process_frame

	# 隐藏进度条
	progress_bar.visible = false

	# 重新启用按钮
	is_applying = false
	apply_button.disabled = false
	select_all_button.disabled = false
	invert_selection_button.disabled = true

	# 更新状态信息
	if modified_total > 0:
		status_label.text = "成功修改了 %d 个动画的循环模式并保存了 %d 个场景！" % [modified_total, scenes_to_save.size()]
		# 刷新文件系统
		get_editor_interface().get_resource_filesystem().scan()
	else:
		status_label.text = "没有需要修改的动画"

	# 刷新显示以反映修改后的状态
	refresh_animation_data()

func _apply_multi_scene_mode(selected_indices: Array, selected_mode: int):
	var modified_total = 0
	var skipped_total = 0

	# 确定要处理的场景文件
	var scenes_to_process = []

	if selected_scenes.size() > 0:
		# 使用多选的场景文件
		scenes_to_process = selected_scenes
	elif duo_changjing_dir_path != "" and scene_selector.item_count > 0:
		# 使用从文件夹选择的场景文件
		var dir_path = duo_changjing_dir_path
		for i in range(scene_selector.item_count):
			var scene_file = scene_selector.get_item_text(i)
			scenes_to_process.append(dir_path.path_join(scene_file))
	else:
		push_warning("请先选择场景文件或文件夹")
		is_applying = false
		apply_button.disabled = false
		select_all_button.disabled = false
		invert_selection_button.disabled = true
		progress_bar.visible = false
		return

	# 计算总工作量
	var total_work = 0
	for index in selected_indices:
		var item_text = property_list.get_item_text(index)
		var property_name = item_text.split(" ")[0]

		if all_animation_data.has(property_name):
			total_work += all_animation_data[property_name].scenes.size()

	# 如果没有有效的工作量，直接返回
	if total_work == 0:
		push_warning("没有需要修改的场景")
		is_applying = false
		apply_button.disabled = false
		select_all_button.disabled = false
		invert_selection_button.disabled = true
		progress_bar.visible = false
		return

	progress_bar.max_value = total_work
	progress_bar.value = 0
	progress_bar.visible = true
	var processed_work = 0

	# 处理每个选中的属性
	for index in selected_indices:
		var item_text = property_list.get_item_text(index)
		var property_name = item_text.split(" ")[0]

		if not all_animation_data.has(property_name):
			continue

		var data = all_animation_data[property_name]
		var property_type = detect_property_type(property_name)

		# 检查该属性类型是否支持请求的模式
		var can_apply = true
		var actual_mode = selected_mode

		if current_mode_type == "interpolation":
			# 对于插值模式，检查是否支持角度插值
			if (selected_mode == 3 or selected_mode == 4) and property_type != "rotation":
				can_apply = false
				actual_mode = min(selected_mode, 2)  # 降级为普通插值

		if can_apply:
			# 处理每个包含该属性的场景
			for scene_path in data.scenes:
				# 加载场景
				var scene = load(scene_path)
				if not scene:
					push_warning("无法加载场景: " + scene_path)
					continue

				# 实例化场景以获取AnimationPlayer
				var scene_instance = scene.instantiate()
				if not scene_instance:
					push_warning("无法实例化场景: " + scene_path)
					continue

				# 查找场景中的所有AnimationPlayer
				var animation_players = _find_animation_players(scene_instance)

				# 处理每个AnimationPlayer
				var modified_in_scene = 0
				for anim_player in animation_players:
					var anim_list = anim_player.get_animation_list()
					for anim_name in anim_list:
						var animation = anim_player.get_animation(anim_name)
						if animation:
							# 处理动画中的轨道
							for track_idx in animation.get_track_count():
								var track_type = animation.track_get_type(track_idx)
								if track_type == Animation.TYPE_VALUE:
									var path = animation.track_get_path(track_idx)
									var path_str = str(path)
									var track_property_name = extract_property_name(path_str)

									if track_property_name == property_name:
										match current_mode_type:
											"update":
												animation.value_track_set_update_mode(track_idx, actual_mode)
											"interpolation":
												animation.track_set_interpolation_type(track_idx, actual_mode)
											"loop":
												if animation.has_method("track_set_interpolation_loop_wrap"):
													animation.track_set_interpolation_loop_wrap(track_idx, actual_mode == 1)
										modified_in_scene += 1
										modified_total += 1

				# 保存修改后的场景
				if modified_in_scene > 0:
					# 创建一个新的 PackedScene 来保存修改后的场景
					var packed_scene = PackedScene.new()
					var error = packed_scene.pack(scene_instance)
					if error == OK:
						error = ResourceSaver.save(packed_scene, scene_path)
						if error != OK:
							push_warning("保存场景失败: " + scene_path)
					else:
						push_warning("打包场景失败: " + scene_path)

				# 释放场景实例
				scene_instance.queue_free()

				# 更新进度
				processed_work += 1
				progress_bar.value = processed_work

				# 处理事件循环，确保UI更新
				if processed_work % 5 == 0:
					await get_tree().process_frame
		else:
			# 不支持该模式，跳过
			skipped_total += data.scenes.size()
			processed_work += data.scenes.size()
			progress_bar.value = processed_work
			print("属性 '%s' 不支持该模式，已跳过" % property_name)

	# 重新启用按钮
	is_applying = false
	apply_button.disabled = false
	select_all_button.disabled = false
	invert_selection_button.disabled = true

	# 更新状态信息
	if modified_total > 0:
		status_label.text = "成功修改了 %d 个轨道的%s！" % [modified_total, _get_mode_type_name()]
		if skipped_total > 0:
			status_label.text += " (跳过了 %d 个不支持的属性)" % skipped_total

		# 刷新文件系统
		get_editor_interface().get_resource_filesystem().scan()

		# 显示成功消息
		push_info(status_label.text)
	elif skipped_total > 0:
		status_label.text = "所有选中的属性都不支持该%s" % _get_mode_type_name()
		push_warning(status_label.text)
	else:
		status_label.text = "没有需要修改的轨道"
		push_warning(status_label.text)

	progress_bar.visible = false

	# 刷新显示以反映修改后的状态
	refresh_animation_data()
func _apply_single_scene_mode(selected_indices: Array, selected_mode: int):
	# 确保有选中的AnimationPlayer
	if not animation_player or not is_instance_valid(animation_player):
		push_error("没有有效的AnimationPlayer，请重新选择")
		is_applying = false
		apply_button.disabled = false
		select_all_button.disabled = false
		invert_selection_button.disabled = true
		progress_bar.visible = false
		return

	# 确定要处理的动画列表
	var animations_to_process = []
	if select_all_animations_checkbox.button_pressed:
		# 全选模式：处理所有动画
		animations_to_process = animation_player.get_animation_list()
	else:
		# 单选模式：只处理当前选中的动画
		if animation_selector.selected >= 0:
			var selected_animation = animation_selector.get_item_text(animation_selector.selected)
			if selected_animation != "":
				animations_to_process.append(selected_animation)
		else:
			push_warning("请先选择一个动画")
			is_applying = false
			apply_button.disabled = false
			select_all_button.disabled = false
			invert_selection_button.disabled = true
			progress_bar.visible = false
			return

	var modified_total = 0
	var skipped_total = 0

	# 计算总工作量
	var total_work = 0
	for index in selected_indices:
		# 跳过分隔符项
		var item_text = property_list.get_item_text(index)
		if item_text.begins_with("---") or (item_text.find("警告:") != -1):
			continue

		if group_checkbox.button_pressed:
			var property_name = item_text.split(" ")[0]
			if property_groups.has(property_name):
				total_work += property_groups[property_name].count
		else:
			total_work += 1

	# 如果没有有效的工作量，直接返回
	if total_work == 0:
		push_warning("没有需要修改的轨道")
		is_applying = false
		apply_button.disabled = false
		select_all_button.disabled = false
		invert_selection_button.disabled = true
		progress_bar.visible = false
		return

	progress_bar.max_value = total_work
	progress_bar.value = 0
	progress_bar.visible = true
	var processed_work = 0

	# 处理每个选中的属性
	for index in selected_indices:
		# 跳过分隔符项
		var item_text = property_list.get_item_text(index)
		if item_text.begins_with("---") or (item_text.find("警告:") != -1):
			continue

		if group_checkbox.button_pressed and property_groups.size() > 0:
			# 分组模式
			var property_name = item_text.split(" ")[0]
			if property_groups.has(property_name):
				var group = property_groups[property_name]
				var property_type = group.property_type

				# 检查该属性类型是否支持请求的模式
				var can_apply = true
				var actual_mode = selected_mode

				if current_mode_type == "interpolation":
					# 对于插值模式，检查是否支持角度插值
					if (selected_mode == 3 or selected_mode == 4) and property_type != "rotation":
						can_apply = false
						actual_mode = min(selected_mode, 2)  # 降级为普通插值

				if can_apply:
					# 支持该模式，进行修改
					for path_str in group.paths:
						var modified = 0
						for anim_name in animations_to_process:
							var animation = animation_player.get_animation(anim_name)
							if animation:
								for track_idx in animation.get_track_count():
									var track_type = animation.track_get_type(track_idx)
									if track_type == Animation.TYPE_VALUE:
										var path = animation.track_get_path(track_idx)
										if str(path) == path_str:
											match current_mode_type:
												"update":
													animation.value_track_set_update_mode(track_idx, actual_mode)
												"interpolation":
													animation.track_set_interpolation_type(track_idx, actual_mode)
												"loop":
													if animation.has_method("track_set_interpolation_loop_wrap"):
														animation.track_set_interpolation_loop_wrap(track_idx, actual_mode == 1)
											modified += 1

						modified_total += modified
						processed_work += 1
						progress_bar.value = processed_work

						# 处理事件循环，确保UI更新
						if Engine.get_main_loop().has_method("process_frame"):
							await get_tree().process_frame
						else:
							# 后备方案：直接延迟一帧
							await get_tree().create_timer(0.01).timeout

					print("属性组 '%s' 修改完成，影响了 %d 个轨道" % [property_name, group.count])
				else:
					# 不支持该模式，跳过
					skipped_total += group.count
					processed_work += group.count
					progress_bar.value = processed_work
					print("属性组 '%s' 不支持该模式，已跳过" % property_name)
		else:
			# 非分组模式
			var path_string = item_text.split(" (")[0]
			var property_name = extract_property_name(path_string)
			if property_name != "":
				var property_type = detect_property_type(property_name)

				# 检查该属性类型是否支持请求的模式
				var can_apply = true
				var actual_mode = selected_mode

				if current_mode_type == "interpolation":
					# 对于插值模式，检查是否支持角度插值
					if (selected_mode == 3 or selected_mode == 4) and property_type != "rotation":
						can_apply = false
						actual_mode = min(selected_mode, 2)  # 降级为普通插值

				if can_apply:
					# 支持该模式，进行修改
					var modified = 0
					for anim_name in animations_to_process:
						var animation = animation_player.get_animation(anim_name)
						if animation:
							for track_idx in animation.get_track_count():
								var track_type = animation.track_get_type(track_idx)
								if track_type == Animation.TYPE_VALUE:
									var path = animation.track_get_path(track_idx)
									if str(path) == path_string:
										match current_mode_type:
											"update":
												animation.value_track_set_update_mode(track_idx, actual_mode)
											"interpolation":
												animation.track_set_interpolation_type(track_idx, actual_mode)
											"loop":
												if animation.has_method("track_set_interpolation_loop_wrap"):
													animation.track_set_interpolation_loop_wrap(track_idx, actual_mode == 1)
										modified += 1

					modified_total += modified
					processed_work += 1
					progress_bar.value = processed_work

					# 处理事件循环，确保UI更新
					if processed_work % 10 == 0:
						# 使用更可靠的方法处理事件循环
						if Engine.get_main_loop().has_method("process_frame"):
							await get_tree().process_frame
						else:
							# 后备方案：直接延迟一帧
							await get_tree().create_timer(0.01).timeout

					print("属性 '%s' 修改完成" % path_string)
				else:
					# 不支持该模式，跳过
					skipped_total += 1
					processed_work += 1
					progress_bar.value = processed_work
					print("属性 '%s' 不支持该模式，已跳过" % path_string)

	# 重新启用按钮
	is_applying = false
	apply_button.disabled = false
	select_all_button.disabled = false
	invert_selection_button.disabled = true

	# 更新状态信息
	if modified_total > 0:
		status_label.text = "成功修改了 %d 个轨道的%s！" % [modified_total, _get_mode_type_name()]
		if skipped_total > 0:
			status_label.text += " (跳过了 %d 个不支持的属性)" % skipped_total

		# 刷新文件系统
		get_editor_interface().get_resource_filesystem().scan()

		# 显示成功消息
		push_info(status_label.text)
	elif skipped_total > 0:
		status_label.text = "所有选中的属性都不支持该%s" % _get_mode_type_name()
		push_warning(status_label.text)
	else:
		status_label.text = "没有需要修改的轨道"
		push_warning(status_label.text)

	progress_bar.visible = false

	# 刷新显示以反映修改后的状态
	refresh_animation_data()

func _apply_single_animation_mode(selected_indices: Array, selected_mode: int):
	# 确保有选中的AnimationPlayer和动画
	if not animation_player or not is_instance_valid(animation_player) or current_animation == "":
		push_error("没有有效的AnimationPlayer或动画，请重新选择")
		is_applying = false
		apply_button.disabled = false
		select_all_button.disabled = false
		invert_selection_button.disabled = true
		progress_bar.visible = false
		return

	# 获取当前动画
	var animation = animation_player.get_animation(current_animation)
	if not animation:
		push_error("无法获取动画: " + current_animation)
		is_applying = false
		apply_button.disabled = false
		select_all_button.disabled = false
		invert_selection_button.disabled = true
		progress_bar.visible = false
		return

	var modified_total = 0
	var skipped_total = 0

	# 计算总工作量
	var total_work = 0
	for index in selected_indices:
		# 跳过分隔符项
		var item_text = property_list.get_item_text(index)
		if item_text.begins_with("---") or (item_text.find("警告:") != -1):
			continue

		if group_checkbox.button_pressed:
			var property_name = item_text.split(" ")[0]
			if property_groups.has(property_name):
				total_work += property_groups[property_name].count
		else:
			total_work += 1

	# 如果没有有效的工作量，直接返回
	if total_work == 0:
		push_warning("没有需要修改的轨道")
		is_applying = false
		apply_button.disabled = false
		select_all_button.disabled = false
		invert_selection_button.disabled = true
		progress_bar.visible = false
		return

	progress_bar.max_value = total_work
	progress_bar.value = 0
	progress_bar.visible = true
	var processed_work = 0

	for index in selected_indices:
		# 跳过分隔符项
		var item_text = property_list.get_item_text(index)
		if item_text.begins_with("---") or (item_text.find("警告:") != -1):
			continue

		if group_checkbox.button_pressed and property_groups.size() > 0:
			# 分组模式
			var property_name = item_text.split(" ")[0]
			if property_groups.has(property_name):
				var group = property_groups[property_name]
				var property_type = group.property_type

				# 检查该属性类型是否支持请求的模式
				var can_apply = true
				var actual_mode = selected_mode

				if current_mode_type == "interpolation":
					# 对于插值模式，检查是否支持角度插值
					if (selected_mode == 3 or selected_mode == 4) and property_type != "rotation":
						can_apply = false
						actual_mode = min(selected_mode, 2)  # 降级为普通插值

				if can_apply:
					# 支持该模式，进行修改
					for path_str in group.paths:
						var modified = 0
						# 在单动画模式下，只修改当前动画
						for track_idx in animation.get_track_count():
							var track_type = animation.track_get_type(track_idx)
							if track_type == Animation.TYPE_VALUE:
								var path = animation.track_get_path(track_idx)
								if str(path) == path_str:
									match current_mode_type:
										"update":
											animation.value_track_set_update_mode(track_idx, actual_mode)
										"interpolation":
											animation.track_set_interpolation_type(track_idx, actual_mode)
										"loop":
											if animation.has_method("track_set_interpolation_loop_wrap"):
												animation.track_set_interpolation_loop_wrap(track_idx, actual_mode == 1)
									modified += 1

						modified_total += modified
						processed_work += 1
						progress_bar.value = processed_work

						# 处理事件循环，确保UI更新
						if processed_work % 5 == 0:
							await get_tree().process_frame

					print("属性组 '%s' 修改完成，影响了 %d 个轨道" % [property_name, group.count])
				else:
					# 不支持该模式，跳过
					skipped_total += group.count
					processed_work += group.count
					progress_bar.value = processed_work
					print("属性组 '%s' 不支持该模式，已跳过" % property_name)

		else:
			# 非分组模式
			var path_string = item_text.split(" (")[0]
			var property_name = extract_property_name(path_string)
			if property_name != "":
				var property_type = detect_property_type(property_name)

				# 检查该属性类型是否支持请求的模式
				var can_apply = true
				var actual_mode = selected_mode

				if current_mode_type == "interpolation":
					# 对于插值模式，检查是否支持角度插值
					if (selected_mode == 3 or selected_mode == 4) and property_type != "rotation":
						can_apply = false
						actual_mode = min(selected_mode, 2)  # 降级为普通插值

				if can_apply:
					# 支持该模式，进行修改
					var modified = 0
					# 在单动画模式下，只修改当前动画
					for track_idx in animation.get_track_count():
						var track_type = animation.track_get_type(track_idx)
						if track_type == Animation.TYPE_VALUE:
							var path = animation.track_get_path(track_idx)
							if str(path) == path_string:
								match current_mode_type:
									"update":
										animation.value_track_set_update_mode(track_idx, actual_mode)
									"interpolation":
										animation.track_set_interpolation_type(track_idx, actual_mode)
									"loop":
										if animation.has_method("track_set_interpolation_loop_wrap"):
											animation.track_set_interpolation_loop_wrap(track_idx, actual_mode == 1)
								modified += 1

					modified_total += modified
					processed_work += 1
					progress_bar.value = processed_work

					# 处理事件循环，确保UI更新
					if processed_work % 5 == 0:
						await get_tree().process_frame

					print("属性 '%s' 修改完成" % path_string)
				else:
					# 不支持该模式，跳过
					skipped_total += 1
					processed_work += 1
					progress_bar.value = processed_work
					print("属性 '%s' 不支持该模式，已跳过" % path_string)

	# 重新启用按钮
	is_applying = false
	apply_button.disabled = false
	select_all_button.disabled = false
	invert_selection_button.disabled = true

	# 更新状态信息
	if modified_total > 0:
		status_label.text = "成功修改了 %d 个轨道的%s！" % [modified_total, _get_mode_type_name()]
		if skipped_total > 0:
			status_label.text += " (跳过了 %d 个不支持的属性)" % skipped_total

		# 刷新文件系统
		get_editor_interface().get_resource_filesystem().scan()

		# 显示成功消息
		push_info(status_label.text)
	elif skipped_total > 0:
		status_label.text = "所有选中的属性都不支持该%s" % _get_mode_type_name()
		push_warning(status_label.text)
	else:
		status_label.text = "没有需要修改的轨道"
		push_warning(status_label.text)

	progress_bar.visible = false

	# 刷新显示以反映修改后的状态
	refresh_animation_data()

# 添加场景全选切换处理函数
func _on_select_all_scenes_toggled(button_pressed: bool):
	if button_pressed:
		scene_label.text = "已全选场景:"
		scene_label.self_modulate = Color(0.0, 1.0, 0.0, 1.0)
		select_all_scenes_checkbox.self_modulate = Color(0.0, 1.0, 0.0, 1.0)
	else :
		scene_label.text = "选择单场景:"
		scene_label.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		select_all_scenes_checkbox.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

	property_list.clear()
	property_groups.clear()
	all_properties.clear()
	all_animation_data.clear()


	#refresh_animation_data()

func _on_scene_selector_button_pressed(_ff):
	if !select_all_scenes_checkbox.button_pressed:
		_on_refresh_button_pressed()

func _on_multi_scene_files_button_pressed():
	var file_dialog = EditorFileDialog.new()
	file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILES
	file_dialog.filters = PackedStringArray(["*.tscn;Scene Files"])
	file_dialog.files_selected.connect(_on_multi_scene_files_selected)
	get_editor_interface().get_base_control().add_child(file_dialog)
	file_dialog.popup_centered(Vector2(700, 500))

# 在 _on_multi_scene_files_selected 函数中，添加资源全选功能
func _on_multi_scene_files_selected(files: PackedStringArray):
	# 清空选中的场景列表
	selected_scenes.clear()
	# 显示进度条
	progress_bar.max_value = files.size()
	progress_bar.value = 0
	progress_bar.visible = true

	var processed_files = 0
	var valid_scene_files = []

	# 检查每个场景文件是否包含动画节点
	for file_path in files:
		# 加载场景资源
		var scene = load(file_path)
		if scene:
			# 实例化场景以检查是否有动画节点
			var scene_instance = scene.instantiate()
			if scene_instance:
				# 查找场景中的所有AnimationPlayer
				var animation_players = _find_animation_players(scene_instance)
				if animation_players.size() > 0:
					# 如果有动画节点，添加到有效场景列表
					valid_scene_files.append(file_path)
					selected_scenes.append(file_path)

				# 释放场景实例
				scene_instance.queue_free()

		# 更新进度
		processed_files += 1
		progress_bar.value = processed_files

		# 处理事件循环，确保UI更新
		if processed_files % 5 == 0:
			await get_tree().process_frame

	# 隐藏进度条
	progress_bar.visible = false

	# 更新UI
	folder_edit.text = "%d个有动画场景（%d个场景）" % [selected_scenes.size(), files.size()]
	scene_selector.clear()

	# 在场景选择器中显示有效的文件
	for file_path in selected_scenes:
		var file_name = file_path.get_file()
		scene_selector.add_item(file_name)
	select_all_scenes_checkbox.text = "场景全选(%s)" % scene_selector.get_item_count()

	# 自动选中第一个场景
	if scene_selector.item_count > 0:
		scene_selector.select(0)

	# 更新状态
	status_label.text = "已选择 %d 个有动画的场景文件，点击刷新按钮加载属性" % selected_scenes.size()

	# 自动启用场景全选
	select_all_scenes_checkbox.button_pressed = true

	# 刷新属性列表
	_on_refresh_button_pressed()

# 修改 _on_search_text_changed 函数，确保多场景模式下的搜索功能正常工作
func _on_search_text_changed(search_text: String):
	if current_edit_mode == "single" or current_edit_mode == "animation":
		filter_properties(search_text)
	elif current_edit_mode == "multi":
		# 对于多场景模式，直接刷新数据以应用搜索过滤
		refresh_animation_data()

func _on_group_checkbox_toggled(button_pressed: bool):

	# 刷新显示
	refresh_animation_data()


# 修改 filter_properties 函数，确保多场景动画循环模式的搜索功能正常工作
func filter_properties(search_text: String):
	if all_properties.is_empty() and all_animation_data.is_empty():
		return

	property_list.clear()

	var search_lower = search_text.to_lower()

	if current_edit_mode == "animation" or current_edit_mode == "single":
		if current_mode_type == "animation_loop":
			# 动画循环模式的搜索
			for prop_data in all_properties:
				var display_text = prop_data.display_text
				if search_text.is_empty() or display_text.to_lower().find(search_lower) != -1:
					property_list.add_item(display_text)
		elif group_checkbox.button_pressed:
			# 分组模式下的搜索
			for property_name in property_groups:
				if search_text.is_empty() or property_name.to_lower().find(search_lower) != -1:
					var group = property_groups[property_name]
					var item_text = "%s (%d个轨道)" % [property_name, group.count]
					var item_count:int
					if current_mode_type == "interpolation":
						item_count = group.interpolation
						item_text += ", %s" % get_interpolation_name(group.interpolation)
					elif current_mode_type == "update":
						item_count = group.update_mode
						item_text += ", %s" % get_update_mode_name(group.update_mode)
					elif current_mode_type == "loop":
						item_count = group.loop_wrap
						item_text += ", %s" % get_loop_mode_name(group.loop_wrap)

					property_list.add_item(item_text,get_mode_name_icons(current_mode_type,item_count))
		else:
			# 非分组模式下的搜索
			for prop_data in all_properties:
				var display_text = prop_data.display_text
				if search_text.is_empty() or display_text.to_lower().find(search_lower) != -1:
					var index = property_list.add_item(display_text)
					if prop_data.has("color"):
						property_list.set_item_custom_fg_color(index, prop_data.color)
					elif prop_data.has("is_separator") and prop_data.is_separator:
						property_list.set_item_custom_fg_color(index, Color(0.5, 0.5, 0.5))
	elif current_edit_mode == "multi":
		if current_mode_type == "animation_loop":
			# 多场景动画循环模式的搜索 - 使用 display_name 字段进行搜索
			for prop_data in all_properties:
				var display_name = prop_data.get("display_name", prop_data.display_text)
				if search_text.is_empty() or display_name.to_lower().find(search_lower) != -1:
					property_list.add_item(prop_data.display_text)
		else:
			# 多场景模式下的搜索
			for property_name in all_animation_data:
				if search_text.is_empty() or property_name.to_lower().find(search_lower) != -1:
					var data = all_animation_data[property_name]
					var item_text = "%s (%d个轨道, %d个场景)" % [property_name, data.total_tracks, data.scenes.size()]

					# 添加当前模式信息
					var mode_name = _get_mode_name_by_value(current_mode_type, data.current_mode)
					item_text += ", %s" % mode_name

					property_list.add_item(item_text)

func extract_property_name(path_str: String) -> String:
	# 从路径字符串中提取属性名
	if ":" in path_str:
		var last_colon = path_str.rfind(":")
		if last_colon != -1:
			var after_colon = path_str.substr(last_colon + 1)
			after_colon = after_colon.replace("\"", "").replace(")", "").strip_edges()
			return after_colon
	return ""

func detect_property_type(property_name: String) -> String:
	var lower_name = property_name.to_lower()

	# 检测旋转属性
	if ("rotation" in lower_name or
		"rotate" in lower_name or
		"angle" in lower_name or
		"rot" in lower_name):
		return "rotation"

	# 检测位置属性
	elif ("position" in lower_name or
		  "translation" in lower_name or
		  "trans" in lower_name or
		  "location" in lower_name or
		  "pos" in lower_name or
		  "translate" in lower_name):
		return "position"

	# 检测缩放属性
	elif ("scale" in lower_name or
		  "size" in lower_name or
		  "scaling" in lower_name):
		return "scale"

	# 检测颜色属性
	elif ("color" in lower_name or
		  "colour" in lower_name or
		  "modulate" in lower_name):
		return "color"

	# 检测透明度属性
	elif ("alpha" in lower_name or
		  "opacity" in lower_name or
		  "transparency" in lower_name):
		return "alpha"

	# 检测布尔属性
	elif ("visible" in lower_name or
		  "enabled" in lower_name or
		  "active" in lower_name or
		  lower_name.begins_with("is_") or
		  lower_name.begins_with("has_")):
		return "boolean"

	# 检测向量属性
	elif ("vector" in lower_name or
		  "vec" in lower_name or
		  "direction" in lower_name or
		  "normal" in lower_name):
		return "vector"

	else:
		return "value"

func get_total_track_count() -> int:
	var total = 0
	for property_name in property_groups:
		total += property_groups[property_name].count
	return total

func extract_node_path(full_path: String) -> String:
	# 从完整路径中提取节点路径（去掉属性部分）
	if ":" in full_path:
		var colon_pos = full_path.rfind(":")
		if colon_pos != -1:
			return full_path.substr(0, colon_pos)
	return full_path

func get_interpolation_name(interpolation_type: int) -> String:
	match interpolation_type:
		0: return "临近"
		1: return "线性"
		2: return "三次方"
		3: return "线性角"
		4: return "三次角"
		_: return "未知"


func get_update_mode_name(update_mode: int) -> String:
	match update_mode:
		Animation.UPDATE_CONTINUOUS: return "连续"
		Animation.UPDATE_DISCRETE: return "离散"
		Animation.UPDATE_CAPTURE: return "捕获"
		_: return "未知"

func get_mode_name_icons(mode:String, icons:int):
	# 根据当前模式类型添加图标
	match mode:
		"update":
			match icons:
				0: return CONTINUOUS
				1: return DISCRETE
				2: return CAPTURE
				_: return null
		"interpolation":
			match icons:
				0: return NEAREST
				1: return LINEAR
				2: return CUBIC
				3: return LINEAR_ANGLE
				4: return CUBIC_ANGLE
				_: return null
		"loop":
			match icons:
				0: return WRAP_CLAMP
				1: return WRAP_LOOP
				_: return null
		"animation_loop":
			match icons:
				0: return LOOP
				1: return LOOP_K
				2: return PING_PONG_LOOP_K
				_: return null


func get_loop_mode_name(loop_wrap: bool) -> String:
	return "环绕循环" if loop_wrap else "钳制循环"

func update_selected_properties_info():
	# 获取选中项数量和总项数
	var selected_indices = property_list.get_selected_items()
	var selected_count = selected_indices.size()
	var total_count = property_list.item_count

	# 计算选中轨道总数
	var total_tracks_selected = 0
	var total_scenes_affected = 0
	var total_animations_affected = 0

	if current_edit_mode == "animation":
		# 单动画模式：计算选中的轨道数量
		for index in selected_indices:
			var item_text = property_list.get_item_text(index)

			# 跳过分隔符项和警告项
			if item_text.begins_with("---") or item_text.find("警告:") != -1:
				continue

			if group_checkbox.button_pressed:
				# 分组模式：使用属性组数据
				var property_name = item_text.split(" ")[0]
				if property_groups.has(property_name):
					total_tracks_selected += property_groups[property_name].count
			else:
				# 非分组模式：每个选中项代表一个轨道
				total_tracks_selected += 1

		# 单动画模式下，只影响当前动画
		total_animations_affected = 1 if selected_count > 0 else 0

	elif current_edit_mode == "single":
		# 单场景模式：计算选中的轨道数量
		for index in selected_indices:
			var item_text = property_list.get_item_text(index)

			# 跳过分隔符项和警告项
			if item_text.begins_with("---") or item_text.find("警告:") != -1:
				continue

			if group_checkbox.button_pressed:
				# 分组模式：使用属性组数据
				var property_name = item_text.split(" ")[0]
				if property_groups.has(property_name):
					total_tracks_selected += property_groups[property_name].count
			else:
				# 非分组模式：每个选中项代表一个轨道
				total_tracks_selected += 1

		# 单场景模式下，只影响当前场景
		total_scenes_affected = 1 if selected_count > 0 else 0

	else:
		# 多场景模式：计算选中的轨道数量和影响的场景数量
		var affected_scenes = {}

		for index in selected_indices:
			var item_text = property_list.get_item_text(index)
			var property_name = item_text.split(" ")[0]

			if all_animation_data.has(property_name):
				var data = all_animation_data[property_name]
				total_tracks_selected += data.total_tracks

				# 收集所有受影响的场景
				for scene_path in data.scenes:
					affected_scenes[scene_path] = true

		total_scenes_affected = affected_scenes.size()

	# 获取当前模式名称
	var mode_name = _get_mode_type_name()

	# 获取当前选中的模式值（如果有）
	var selected_mode_name = ""
	if not mode_combo.disabled and mode_combo.selected >= 0:
		selected_mode_name = mode_combo.get_item_text(mode_combo.selected)

	# 构建状态信息
	var status_text = ""

	if current_edit_mode == "animation":
		status_text = "单动画模式: "
		if current_animation != "":
			status_text += "动画: %s, " % current_animation
	elif current_edit_mode == "single":
		status_text = "单场景模式: "
	else:
		status_text = "多场景模式: "
	if total_count == 0:
		status_text += "--没有动画存在--"
	else:
		status_text += "已选择 %d/%d 个属性" % [selected_count, total_count]

	if total_tracks_selected > 0:
		status_text += ", %d 个轨道" % total_tracks_selected

	if total_scenes_affected > 0 and current_edit_mode == "multi":
		status_text += ", %d 个场景" % total_scenes_affected

	if total_animations_affected > 0 and current_edit_mode == "animation":
		status_text += ", %d 个动画" % total_animations_affected

	status_text += " | 当前: %s" % mode_name

	# 更新状态标签
	status_label.text = status_text

	# 启用/禁用模式选择框和应用按钮
	if selected_count > 0:
		mode_combo.disabled = false
		apply_button.disabled = false
	else:
		mode_combo.disabled = true
		apply_button.disabled = true

	# 启用/禁用选择按钮
	select_all_button.disabled = (total_count == 0)
	invert_selection_button.disabled = (total_count == 0)

	# 如果有选中项，显示更详细的信息
	if selected_count > 0:
		# 获取第一个选中项的信息
		var first_index = selected_indices[0]
		var first_item_text = property_list.get_item_text(first_index)

		# 如果是分隔符或警告，跳过
		if first_item_text.begins_with("---") or first_item_text.find("警告:") != -1:
			return

		# 提取属性名
		var property_name = first_item_text.split(" ")[0]

		# 获取当前模式值
		var current_mode_value = -1

		if current_edit_mode == "animation" and group_checkbox.button_pressed and property_groups.has(property_name):
			var group = property_groups[property_name]
			match current_mode_type:
				"update":
					current_mode_value = group.update_mode
				"interpolation":
					current_mode_value = group.interpolation
				"loop":
					current_mode_value = 1 if group.loop_wrap else 0

			# 在模式选择框中选中当前模式
			for i in range(mode_combo.item_count):
				if mode_combo.get_item_id(i) == current_mode_value:
					mode_combo.select(i)
					break

		elif current_edit_mode == "single" and group_checkbox.button_pressed and property_groups.has(property_name):
			var group = property_groups[property_name]
			match current_mode_type:
				"update":
					current_mode_value = group.update_mode
				"interpolation":
					current_mode_value = group.interpolation
				"loop":
					current_mode_value = 1 if group.loop_wrap else 0

			# 在模式选择框中选中当前模式
			for i in range(mode_combo.item_count):
				if mode_combo.get_item_id(i) == current_mode_value:
					mode_combo.select(i)
					break

		elif current_edit_mode == "multi" and all_animation_data.has(property_name):
			var data = all_animation_data[property_name]
			current_mode_value = data.current_mode

			# 在模式选择框中选中当前模式
			for i in range(mode_combo.item_count):
				if mode_combo.get_item_id(i) == current_mode_value:
					mode_combo.select(i)
					break

	# 更新工具提示，提供更多信息
	var tooltip_text = "点击属性可查看更多信息"

	if selected_count == 1:
		var index = selected_indices[0]
		var item_text = property_list.get_item_text(index)

		if not item_text.begins_with("---") and item_text.find("警告:") == -1:
			var property_name = item_text.split(" ")[0]

			if current_edit_mode == "animation" and group_checkbox.button_pressed and property_groups.has(property_name):
				var group = property_groups[property_name]
				tooltip_text = "属性: %s\n轨道数: %d\n当前模式: %s" % [
					property_name,
					group.count,
					_get_mode_name_by_value(current_mode_type,
						group.update_mode if current_mode_type == "update" else
						group.interpolation if current_mode_type == "interpolation" else
						1 if group.loop_wrap else 0
					)
				]

			elif current_edit_mode == "single" and group_checkbox.button_pressed and property_groups.has(property_name):
				var group = property_groups[property_name]
				tooltip_text = "属性: %s\n轨道数: %d\n当前模式: %s" % [
					property_name,
					group.count,
					_get_mode_name_by_value(current_mode_type,
						group.update_mode if current_mode_type == "update" else
						group.interpolation if current_mode_type == "interpolation" else
						1 if group.loop_wrap else 0
					)
				]

			elif current_edit_mode == "multi" and all_animation_data.has(property_name):
				var data = all_animation_data[property_name]
				tooltip_text = "属性: %s\n轨道数: %d\n场景数: %d\n当前模式: %s" % [
					property_name,
					data.total_tracks,
					data.scenes.size(),
					_get_mode_name_by_value(current_mode_type, data.current_mode)
				]

	status_label.tooltip_text = tooltip_text

# 辅助函数：根据模式类型和值获取模式名称
func _get_mode_name_by_value(mode_type: String, mode_value: int) -> String:
	match mode_type:
		"update":
			match mode_value:
				Animation.UPDATE_CONTINUOUS: return "连续"
				Animation.UPDATE_DISCRETE: return "离散"
				Animation.UPDATE_CAPTURE: return "捕获"
				_: return "未知"
		"interpolation":
			match mode_value:
				0: return "临近"
				1: return "线性"
				2: return "三次方"
				3: return "线性角"
				4: return "三次角"
				_: return "未知"
		"loop":
			return "环绕循环" if mode_value == 1 else "钳制循环"
		_:
			return "未知"

func cleanup_resources():
	# 清理性能敏感的资源
	property_list.clear()
	property_groups.clear()
	all_properties.clear()
	all_animation_data.clear()
	current_property_type = ""
	last_selected_index = -1
	animation_player = null
	current_animation = ""

	# 清空动画选择器
	if animation_selector:
		animation_selector.clear()

	# 清空搜索框但不触发搜索
	if search_edit:
		search_edit.text = ""

	print("面板已收起，资源已清理")

func push_warning(message: String):
	print("[警告] ", message)
	status_label.text = "警告: " + message

func push_info(message: String):
	print("[信息] ", message)
	status_label.text = "信息: " + message
