# 第一阶段可行性审查 & 执行准备

**阶段目标**：2026.4.1 - 4.15（2 周）  
**交付物**：月球第 1-2 关完整可玩 + 5 人内测反馈

---

## 一、可行性审查结论

| 系统 | 原策划假设 | 实际评估 | 结论 |
|------|-----------|---------|------|
| 2D 网格拖拽 | 简单实现 | 需自定义，无内置组件 | **可行，3天** |
| 2D↔3D < 0.5s 切换 | 直接切换场景 | `change_scene_to_file()` 有加载卡顿，架构必须重设计 | **需特殊架构** |
| RayCast 链式反射 | 自然延伸 | `RayCast3D` 单次只打一个点，多段反射需手动迭代 | **可行，但有陷阱** |
| SubViewport 镜面渲染 | MVP 核心 | **第一阶段不需要，纯视觉效果，与解谜逻辑无关** | **砍掉，Phase 2** |
| 低重力手感 | 修改 gravity 即可 | Area3D gravity 确实够用 | **可行，0.5天** |
| 基础存档 | JSON 序列化 | **第一阶段不需要，内测只需运行不需存档** | **砍掉，Phase 2** |

---

## 二、最大技术风险：场景切换架构

### 错误做法（原策划隐含的假设）
```gdscript
# 这样做会有 0.3-1s 的黑屏加载，体验极差
func switch_to_3d():
    get_tree().change_scene_to_file("res://scenes/exploration_3d.tscn")
```

### 正确做法：主场景同时持有两个子场景
```
Main.tscn
├── Blueprint2D (CanvasLayer)   ← 始终加载
└── Exploration3D (Node3D)      ← 始终加载
```

切换只是 `show()` / `hide()`，加上淡入淡出 Tween，真正做到 < 0.5s：

```gdscript
# game_manager.gd (Autoload)
var current_mode: String = "2d"

func switch_mode():
    var tween = create_tween()
    tween.tween_property($FadeOverlay, "color:a", 1.0, 0.15)
    await tween.finished
    if current_mode == "2d":
        $Blueprint2D.hide()
        $Exploration3D.show()
        current_mode = "3d"
    else:
        $Exploration3D.hide()
        $Blueprint2D.show()
        current_mode = "2d"
    tween.tween_property($FadeOverlay, "color:a", 0.0, 0.15)
    # 总耗时 0.3s，远小于 0.5s 目标
```

**这是第一阶段 Day 1 必须确定的架构，后期改动代价极高。**

---

## 三、第二大风险：RayCast 链式反射

`RayCast3D` 每帧只处理一次碰撞。要实现光线在多面镜子间弹射，需要手动迭代：

```gdscript
# star_beam.gd
const MAX_BOUNCES = 10  # 必须设上限，防止死循环

func cast_beam(origin: Vector3, direction: Vector3) -> bool:
    var ray = RayCast3D.new()
    add_child(ray)
    
    var current_pos = origin
    var current_dir = direction.normalized()
    
    for i in range(MAX_BOUNCES):
        ray.global_position = current_pos
        ray.target_position = current_dir * 100.0
        ray.force_raycast_update()
        
        if not ray.is_colliding():
            draw_beam_segment(current_pos, current_pos + current_dir * 100.0)
            break
        
        var hit_pos = ray.get_collision_point()
        var hit_normal = ray.get_collision_normal()
        var hit_obj = ray.get_collider()
        
        draw_beam_segment(current_pos, hit_pos)
        
        if hit_obj.is_in_group("target"):
            ray.queue_free()
            return true  # 解谜成功
        
        if not hit_obj.is_in_group("mirror"):
            break  # 打到墙壁，结束
        
        # 反射公式
        current_dir = current_dir - 2 * current_dir.dot(hit_normal) * hit_normal
        current_pos = hit_pos + current_dir * 0.01  # 微小偏移防止自碰撞
    
    ray.queue_free()
    return false

func draw_beam_segment(from: Vector3, to: Vector3):
    # 用 ImmediateMesh 或 MeshInstance3D 画线，Phase 1 用调试颜色即可
    pass
```

**关键陷阱**：`current_pos = hit_pos + current_dir * 0.01` 这个偏移不加会导致光线立刻再次碰到同一面镜子，无限循环。

**触发时机**：不要每帧都跑，只在镜子角度变化时重新计算（事件驱动），否则性能浪费。

---

## 四、2D 网格系统实现

Phase 1 最简单可行方案——不用任何插件：

```gdscript
# grid_system.gd
const CELL_SIZE = 64  # 像素
const GRID_WIDTH = 10
const GRID_HEIGHT = 8

var grid_data: Dictionary = {}  # Vector2i -> MirrorData

func _gui_input(event: InputEvent):
    if event is InputEventMouseButton and event.pressed:
        var cell = Vector2i(event.position / CELL_SIZE)
        if is_valid_cell(cell):
            if event.button_index == MOUSE_BUTTON_LEFT and dragging_mirror_type >= 0:
                place_mirror(cell, dragging_mirror_type)
            elif event.button_index == MOUSE_BUTTON_RIGHT:
                remove_mirror(cell)

func place_mirror(cell: Vector2i, type: int):
    grid_data[cell] = MirrorData.new(cell, type, 0.0)
    redraw()
    # 同步到 3D 世界
    GameManager.sync_mirrors_to_3d(grid_data)

func cell_to_world3d(cell: Vector2i) -> Vector3:
    # 2D 格子坐标 → 3D 世界坐标映射
    return Vector3(
        (cell.x - GRID_WIDTH / 2.0) * 2.0,   # X 轴，间距 2 单位
        0.0,                                    # Y 固定地面高度
        (cell.y - GRID_HEIGHT / 2.0) * 2.0    # Z 轴
    )
```

**镜面旋转**：Phase 1 只支持 4 个固定角度（0°/45°/90°/135°），点击镜子循环切换，不做连续旋转——降低实现复杂度，也降低玩家认知负担。

---

## 五、项目文件结构（Day 1 建立）

```
res://
├── autoload/
│   └── game_manager.gd       # 全局状态、场景切换、镜子同步
├── scenes/
│   ├── main.tscn             # 根场景（持有 2D + 3D）
│   ├── ui/
│   │   ├── blueprint_2d.tscn # 2D 网格界面
│   │   └── hud.tscn          # 模式指示、镜面计数
│   ├── world/
│   │   ├── exploration_3d.tscn
│   │   ├── mirror_3d.tscn    # 单面镜子预制体
│   │   └── player.tscn       # FPS 控制器
│   └── levels/
│       ├── level_01.gd       # 关卡数据脚本
│       └── level_02.gd
├── scripts/
│   ├── mirror_data.gd        # class_name MirrorData extends Resource
│   ├── grid_system.gd
│   ├── star_beam.gd
│   ├── mirror_3d.gd
│   └── player.gd
└── assets/                   # Phase 1 全用占位符
    └── placeholder/
```

---

## 六、2 周冲刺任务分解

### 第一周：系统搭建

| 天 | 任务 | 完成标准 |
|----|------|---------|
| D1 | 建 Godot 项目 + 场景架构 + GameManager Autoload | Tab 键能在空白 2D/3D 间切换，有淡入淡出 |
| D2 | MirrorData Resource + 2D 网格绘制（无交互） | 能看到网格线 |
| D3 | 2D 拖拽放置镜子（左键放/右键删/点击旋转） | 能在格子里放 4 个方向的镜子 |
| D4 | FPS 玩家控制器（WASD + 鼠标 + 月球重力） | 能在 3D 空间行走，重力 1.62 |
| D5 | 2D→3D 镜子同步（切换时 3D 生成对应镜子节点） | 在 2D 放镜子，切到 3D 能看到对应位置有方块 |
| D6 | RayCast 链式反射 + 调试可视线 | 光线能在 2 面镜子间弹射，终点显示颜色 |
| D7 | 检查点：完整循环验证 | 放镜→切 3D→光打到目标→控制台输出"WIN" |

**D7 是 Go/No-Go 节点。如果完整循环跑不通，停下来找原因，不要继续堆内容。**

### 第二周：关卡与打磨

| 天 | 任务 | 完成标准 |
|----|------|---------|
| D8 | 第 1 关几何体搭建（用 BoxMesh 占位） | 有地板、墙壁、光源起点、目标点 |
| D9 | 第 1 关完整通关流程（包括 WIN 界面） | 能正常完成并显示过关提示 |
| D10 | 第 2 关设计与搭建 | 3 面镜子，加全息平台概念（用发光 Mesh 表示） |
| D11 | 基础 HUD（当前模式/剩余镜面数/提示文字） | 屏幕左上角有状态信息 |
| D12 | 第 1-2 关 QA：卡穿墙、光线 bug、切换异常 | 10 次通关无崩溃 |
| D13 | 准备 5 人测试版本（打包 + 写测试问卷） | 可执行文件 + 3 个问题的问卷 |
| D14 | 收集反馈 + 记录问题列表 | 有书面反馈，列出 Top 5 问题 |

---

## 七、Phase 1 明确不做的事

以下内容出现在策划书中，但 Phase 1 **一个都不碰**：

- SubViewport 镜面视觉反射效果（纯视觉，不影响解谜）
- 任何音频（BGM、音效）
- 故事日志、角色语音
- 粒子效果、辉光 Shader
- 存档/读档
- 成就、星星评分
- 菜单界面、设置界面
- 低重力漂浮动画（直接改 gravity 值，不做额外动画）
- 3D 中微调镜面角度（只在 2D 中调）

---

## 八、测试问卷（5 人内测用）

发给测试者的 3 个核心问题：

1. **「第一次完成关卡时，你花了多少分钟？」**  
   目标：关 1 < 3 分钟，关 2 < 8 分钟。超出说明提示不足。

2. **「从 2D 蓝图切换到 3D 探索时，你知道镜子在哪里吗？」**  
   （1=完全找不到，5=一眼就找到）目标：≥ 4 分。

3. **「光线路径你能看清楚吗？知道自己需要做什么吗？」**  
   （开放回答）这是发现教学问题的核心数据。

---

## 九、Phase 1 成功标准

**通过条件（全部满足才算 Phase 1 完成）**：
- [ ] 第 1-2 关可完整通关，无崩溃
- [ ] 2D↔3D 切换视觉流畅，无黑屏
- [ ] 5 名测试者中 ≥ 4 人能在 10 分钟内通过第 1 关
- [ ] 5 名测试者中 ≥ 3 人明确表示「知道自己在做什么」
- [ ] RayCast 在 12 面镜子以内无性能问题

**失败条件（任意一个出现立即停工分析）**：
- 切换时有超过 0.5s 的卡顿
- 测试者普遍表示「不知道镜子在哪里」
- 光线逻辑出现无法复现的随机 bug

---

*Phase 1 文档 | 创建：2026-04-07 | 目标截止：2026-04-15*
