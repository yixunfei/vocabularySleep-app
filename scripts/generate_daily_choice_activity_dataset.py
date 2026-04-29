#!/usr/bin/env python3
"""Generate the Daily Choice activity library JSON and SQLite database."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sqlite3
from collections import Counter
from pathlib import Path
from typing import Any


DEFAULT_OUTPUT_DIR = Path(r"D:\vocabularySleep-resources\干什么-数据")

LIBRARY_ID = "toolbox_daily_choice_activity_library"
SCHEMA_ID = "vocabulary_sleep.daily_choice.activity_library"
SCHEMA_VERSION = 1


CATEGORY_META: dict[str, dict[str, str]] = {
    "focus": {"zh": "专注", "en": "Focus"},
    "move": {"zh": "运动", "en": "Move"},
    "learn": {"zh": "学习", "en": "Learn"},
    "outdoor": {"zh": "出行", "en": "Out"},
    "home": {"zh": "整理", "en": "Tidy"},
    "relax": {"zh": "放松", "en": "Relax"},
    "create": {"zh": "创作", "en": "Create"},
    "social": {"zh": "社交", "en": "Social"},
}


RAW_ACTIONS: list[dict[str, Any]] = [
    {
        "id": "do_focus_drift_review",
        "category": "focus",
        "titleZh": "无评价复盘走神 2 分钟",
        "titleEn": "Two-minute nonjudgment drift review",
        "subtitleZh": "注意力涣散时先看见原因",
        "subtitleEn": "Notice why attention drifted",
        "detailsZh": "适合刚发现自己在思考、幻想、刷屏或担心评价时使用。目标不是责备自己，而是把跑掉的内容、触发原因和当前目标分开放下。",
        "detailsEn": "Use this when you notice drifting into fantasy, scrolling, or fear of judgment. The goal is to separate drift content, trigger, and current goal without blame.",
        "conditionsZh": ["纸笔或备忘录", "2 分钟计时器", "不需要评价对错"],
        "conditionsEn": ["Notebook or notes app", "Two-minute timer", "No need to judge right or wrong"],
        "stepsZh": ["写下刚才在想什么。", "标注它像是担心、幻想、逃避、疲劳还是无聊。", "写一句当前原本要做的目标。"],
        "stepsEn": ["Write what you were just thinking about.", "Label it as worry, fantasy, avoidance, fatigue, or boredom.", "Write one sentence for the original goal."],
        "notesZh": ["如果身体明显疲劳，允许切换到休息或散步。", "如果只是任务太大，把目标缩成 5 分钟版本。"],
        "notesEn": ["If the body is truly tired, switch to rest or walking.", "If the task is too large, shrink it to a five-minute version."],
        "tagsZh": ["注意力", "复盘", "低刺激"],
        "tagsEn": ["attention", "review", "low stimulation"],
        "duration": "2-5",
        "energy": "low",
        "place": "any",
        "trigger": "attention_drift",
    },
    {
        "id": "do_focus_goal_sentence",
        "category": "focus",
        "titleZh": "重写当前目标一句话",
        "titleEn": "Rewrite the current goal in one sentence",
        "subtitleZh": "把模糊任务压成一句能执行的话",
        "subtitleEn": "Compress a fuzzy task into one executable sentence",
        "detailsZh": "适合任务太大、脑内分支太多时使用。只保留当前一轮的目标，不处理未来所有可能性。",
        "detailsEn": "Use this when a task is too large or branching. Keep only the goal for the next round, not every future possibility.",
        "conditionsZh": ["一张便签或备忘录", "能安静坐 3 分钟"],
        "conditionsEn": ["Sticky note or notes app", "Three quiet minutes"],
        "stepsZh": ["写下“我现在要完成的是……”。", "删掉不属于下一轮的词。", "把它改成 5 到 12 分钟内能开始的动作。"],
        "stepsEn": ["Write: what I am doing now is...", "Remove words that do not belong to the next round.", "Rewrite it as something startable within 5 to 12 minutes."],
        "notesZh": ["一句话目标写完就开始，不继续优化措辞。"],
        "notesEn": ["Start after the sentence is written; do not keep polishing it."],
        "tagsZh": ["目标", "启动", "专注"],
        "tagsEn": ["goal", "start", "focus"],
        "duration": "2-5",
        "energy": "low",
        "place": "indoor",
        "trigger": "unclear_goal",
    },
    {
        "id": "do_focus_five_minute_round",
        "category": "focus",
        "titleZh": "开一轮 5 分钟推进",
        "titleEn": "Start one five-minute progress round",
        "subtitleZh": "只推进，不追求完成整件事",
        "subtitleEn": "Move it forward without finishing everything",
        "detailsZh": "适合知道要做什么但迟迟没有开始时使用。五分钟结束就算完成一轮，可以继续也可以停止。",
        "detailsEn": "Use this when you know the task but cannot start. The five-minute round counts as done whether or not you continue.",
        "conditionsZh": ["5 分钟计时器", "关闭一个最明显的干扰源"],
        "conditionsEn": ["Five-minute timer", "Close one obvious distraction"],
        "stepsZh": ["打开任务现场。", "只做最前面的一个动作。", "到点写下下一步。"],
        "stepsEn": ["Open the task surface.", "Do only the first action.", "When time ends, write the next step."],
        "notesZh": ["如果五分钟后想继续，再追加一轮。"],
        "notesEn": ["If you want to continue after five minutes, add one round."],
        "tagsZh": ["时间盒", "低阻力", "推进"],
        "tagsEn": ["timebox", "low friction", "progress"],
        "duration": "5-10",
        "energy": "low",
        "place": "indoor",
        "trigger": "procrastination",
    },
    {
        "id": "do_focus_close_extra_tabs",
        "category": "focus",
        "titleZh": "关闭多余窗口并留一个入口",
        "titleEn": "Close extra windows and keep one entry point",
        "subtitleZh": "给注意力减噪",
        "subtitleEn": "Reduce attention noise",
        "detailsZh": "适合电脑或手机上打开太多页面，导致每个任务都像在抢注意力时使用。",
        "detailsEn": "Use this when too many windows or apps are competing for attention.",
        "conditionsZh": ["当前设备", "3 分钟计时器"],
        "conditionsEn": ["Current device", "Three-minute timer"],
        "stepsZh": ["只保留当前目标需要的窗口。", "把想稍后看的内容存到一个暂存清单。", "回到目标入口。"],
        "stepsEn": ["Keep only windows needed for the current goal.", "Put later items into one capture list.", "Return to the goal entry point."],
        "notesZh": ["不要顺手整理收藏夹，先结束当前噪声。"],
        "notesEn": ["Do not reorganize bookmarks now; just remove current noise."],
        "tagsZh": ["减噪", "设备", "专注"],
        "tagsEn": ["noise reduction", "device", "focus"],
        "duration": "2-5",
        "energy": "low",
        "place": "indoor",
        "trigger": "digital_clutter",
    },
    {
        "id": "do_focus_capture_intrusions",
        "category": "focus",
        "titleZh": "把干扰念头暂存到清单",
        "titleEn": "Capture intrusive thoughts into a parking list",
        "subtitleZh": "先存放，不立刻处理",
        "subtitleEn": "Park them without processing now",
        "detailsZh": "适合脑内同时冒出待办、担心和灵感时使用。清单只负责暂存，当前不展开。",
        "detailsEn": "Use this when tasks, worries, and ideas appear at once. The list stores them without expanding them.",
        "conditionsZh": ["一个暂存清单", "最多 5 条"],
        "conditionsEn": ["One parking list", "Up to five items"],
        "stepsZh": ["把每个干扰写成短语。", "每条后面标注：今天/以后/不处理。", "回到当前目标一句话。"],
        "stepsEn": ["Write each intrusion as a phrase.", "Mark each as today, later, or ignore.", "Return to the current goal sentence."],
        "notesZh": ["超过 5 条就先停止，避免清单本身变成新任务。"],
        "notesEn": ["Stop after five items so the list does not become a new task."],
        "tagsZh": ["清单", "干扰", "暂存"],
        "tagsEn": ["list", "distraction", "parking"],
        "duration": "2-5",
        "energy": "low",
        "place": "any",
        "trigger": "intrusive_thoughts",
    },
    {
        "id": "do_focus_single_next_action",
        "category": "focus",
        "titleZh": "只写下一步，不写计划",
        "titleEn": "Write the next action, not a plan",
        "subtitleZh": "避免用计划代替行动",
        "subtitleEn": "Avoid replacing action with planning",
        "detailsZh": "适合已经在计划里绕圈，却没有实际推进时使用。只写一个下一步动作，并立刻执行。",
        "detailsEn": "Use this when planning has become a loop. Write one next action and do it immediately.",
        "conditionsZh": ["一行空间", "不打开完整计划表"],
        "conditionsEn": ["One line of space", "Do not open the full plan"],
        "stepsZh": ["问自己：下一步能看见的动作是什么。", "写成动词开头。", "马上执行 3 分钟。"],
        "stepsEn": ["Ask: what visible action comes next?", "Write it starting with a verb.", "Do it for three minutes."],
        "notesZh": ["如果下一步仍然很大，就继续拆到能马上开始。"],
        "notesEn": ["If the next action is still large, split it until it can start now."],
        "tagsZh": ["下一步", "行动", "启动"],
        "tagsEn": ["next action", "action", "start"],
        "duration": "2-5",
        "energy": "low",
        "place": "any",
        "trigger": "overplanning",
    },
]


MORE_ACTIONS: list[tuple[str, str, str, str, str, str, list[str], list[str], list[str], list[str], str, str, str, str]] = [
    ("move", "do_move_brisk_walk_12", "快走 12 分钟", "12-minute brisk walk", "不用换装备，出门一圈", "No gear change; one outside loop", ["手机计时器", "合适鞋子"], ["设 12 分钟。", "按能说话但略喘的速度走。", "回来喝水并记录体感。"], ["天气差或身体不适时改为室内拉伸。"], ["运动", "散步", "重启"], "10-20", "medium", "outdoor", "stale_body"),
    ("move", "do_move_neck_shoulder", "肩颈拉伸一轮", "One neck-shoulder stretch round", "久坐后重启身体", "Reset after sitting", ["椅子或墙面", "3 到 6 分钟"], ["放下手机。", "肩颈、胸椎、手腕各做一轮。", "结束后站起来走 30 秒。"], ["不要追求幅度，避免疼痛。"], ["拉伸", "久坐", "低阻力"], "5-10", "low", "indoor", "long_sitting"),
    ("move", "do_move_stairs", "上下楼梯 5 分钟", "Five-minute stair walk", "短时间提高身体唤醒度", "Raise physical arousal quickly", ["安全楼梯", "不赶时间"], ["慢速上下一到两层。", "保持扶手可触达。", "到点停止。"], ["膝盖不舒服时换成平地走。"], ["运动", "楼梯", "唤醒"], "5-10", "medium", "indoor", "sleepy"),
    ("move", "do_move_wall_push", "靠墙俯卧撑 2 组", "Two sets of wall push-ups", "用低冲击方式激活上肢", "Activate upper body with low impact", ["一面墙", "每组 8 到 12 次"], ["站到舒适距离。", "做两组靠墙俯卧撑。", "放松肩膀和手腕。"], ["动作变形就减少次数。"], ["运动", "上肢", "室内"], "2-5", "low", "indoor", "body_slump"),
    ("move", "do_move_mobility_flow", "髋腿活动 6 分钟", "Six-minute hip-leg mobility", "让久坐后的下肢恢复活动", "Recover lower-body mobility after sitting", ["瑜伽垫可选", "一块安全地面"], ["左右髋各绕环。", "腿后侧轻拉伸。", "原地走 60 秒。"], ["不要压疼，保持轻松呼吸。"], ["活动度", "久坐", "恢复"], "5-10", "low", "indoor", "stiff_body"),
    ("move", "do_move_balance", "单脚站平衡练习", "Single-leg balance practice", "轻量训练稳定性", "Light stability practice", ["墙边或桌边", "每侧 30 秒"], ["站到可扶墙的位置。", "每侧单脚站 2 轮。", "记录哪边更不稳。"], ["头晕或不稳时立即扶墙。"], ["平衡", "低冲击", "身体感"], "2-5", "low", "indoor", "body_awareness"),
    ("learn", "do_learn_review_10_words", "复习 10 个单词", "Review 10 words", "和主应用目标保持连贯", "Stay aligned with the main learning goal", ["词表或错词本", "5 到 8 分钟"], ["只选 10 个词。", "遮住释义回忆。", "错的标记明天复看。"], ["不要扩成整章学习。"], ["单词", "复习", "学习"], "5-10", "low", "indoor", "learning_loop"),
    ("learn", "do_learn_shadowing_5", "跟读 5 分钟", "Five-minute shadowing", "用声音进入学习状态", "Use voice to enter study mode", ["一段音频", "耳机可选"], ["选 30 到 60 秒材料。", "逐句跟读。", "最后录一遍。"], ["环境不适合出声时改为默读。"], ["英语", "听说", "低阻力"], "5-10", "medium", "indoor", "language_practice"),
    ("learn", "do_learn_one_page", "读一页并摘一句", "Read one page and extract one line", "小输入也算闭环", "Small input still closes a loop", ["书或文章", "摘录位置"], ["只读一页。", "摘一句有用的话。", "写一句为什么有用。"], ["不要追求读完整篇。"], ["阅读", "摘录", "输入"], "10-20", "low", "indoor", "input_needed"),
    ("learn", "do_learn_tutorial_8", "看 8 分钟教程并记一个动作", "Watch eight minutes and note one action", "防止教程变成刷视频", "Prevent tutorial watching from becoming scrolling", ["教程视频", "8 分钟计时器"], ["先写要解决的问题。", "只看 8 分钟。", "记下一个能马上试的动作。"], ["到点停止，不连播。"], ["教程", "学习", "行动化"], "5-10", "low", "indoor", "skill_gap"),
    ("learn", "do_learn_error_card", "整理一张错题 / 错词卡", "Make one error card", "把错误变成下次入口", "Turn one error into a next entry point", ["一个最近错误", "卡片或笔记"], ["复制错误原句。", "写正确做法。", "写下次识别信号。"], ["只整理一张。"], ["错题", "复盘", "学习"], "5-10", "medium", "indoor", "mistake_review"),
    ("learn", "do_learn_summary_voice", "语音总结 60 秒", "Sixty-second voice summary", "用口头输出检查理解", "Use speaking to check understanding", ["录音工具", "安静 1 分钟"], ["说出刚学了什么。", "说一个可用例子。", "保存或删除都可以。"], ["不追求流畅，重点是输出。"], ["输出", "总结", "学习"], "2-5", "low", "indoor", "memory_check"),
    ("outdoor", "do_outdoor_after_meal_walk", "饭后出门走一圈", "Take one after-meal loop", "从坐着切到轻活动", "Shift from sitting to light movement", ["天气安全", "钥匙和手机"], ["出门前看天气。", "走固定短路线。", "回来喝水。"], ["太晚、雨大或身体不适时改室内走动。"], ["出门", "饭后", "散步"], "10-20", "low", "outdoor", "after_meal"),
    ("outdoor", "do_outdoor_sunlight_8", "到户外见光 8 分钟", "Get eight minutes of daylight", "给身体一个时间信号", "Give the body a time cue", ["白天", "可安全站立的位置"], ["走到阳台、楼下或街边。", "不刷手机站 8 分钟。", "看远处放松眼睛。"], ["强晒时避开直射。"], ["户外", "见光", "恢复"], "5-10", "low", "outdoor", "low_mood"),
    ("outdoor", "do_outdoor_photo_three", "出门拍 3 张观察照片", "Take three observation photos outside", "用观察代替刷屏", "Use observation instead of scrolling", ["手机", "安全步行路线"], ["出门走 10 分钟。", "拍 3 张不同主题。", "回来选一张保留。"], ["不要为了拍照进入危险位置。"], ["观察", "照片", "出门"], "10-20", "low", "outdoor", "scrolling_loop"),
    ("outdoor", "do_outdoor_small_errand", "完成一个顺路小事", "Finish one nearby errand", "让出门有明确收口", "Give the outing a clear endpoint", ["一个近处小事", "不超过 30 分钟"], ["选最近的一个小事。", "只走一条路线。", "完成后直接回来或转散步。"], ["不要临时追加很多采购。"], ["出门", "小事", "收口"], "20-30", "medium", "outdoor", "errand_needed"),
    ("outdoor", "do_outdoor_trash_walk", "带垃圾下楼并多走 5 分钟", "Take out trash and walk five extra minutes", "把家务变成状态切换", "Turn a chore into a state shift", ["垃圾袋", "楼下路线"], ["带垃圾下楼。", "丢完多走 5 分钟。", "回来洗手。"], ["天气差时只完成丢垃圾。"], ["家务", "出门", "低阻力"], "5-10", "low", "outdoor", "stuck_at_home"),
    ("outdoor", "do_outdoor_cafe_reset", "去附近坐 20 分钟", "Sit nearby for 20 minutes", "换环境但不把行程做大", "Change environment without making a big trip", ["附近可坐地点", "一个小任务"], ["带一个轻任务。", "只坐 20 分钟。", "完成一小步就回。"], ["不要把它变成长期滞留。"], ["换环境", "咖啡", "轻任务"], "20-30", "medium", "outdoor", "environment_stale"),
    ("home", "do_home_desk_corner", "整理桌面一角", "Clear one desk corner", "只处理可见表面", "Handle only the visible surface", ["桌面一角", "5 分钟计时器"], ["拿走明显垃圾。", "物品归到一个临时区。", "擦出一小块空白。"], ["不翻抽屉。"], ["整理", "桌面", "低阻力"], "5-10", "low", "indoor", "visual_clutter"),
    ("home", "do_home_sink_reset", "水槽归零", "Reset the sink", "让下一顿饭阻力变小", "Lower friction for the next meal", ["水槽", "洗洁用品"], ["先处理可见餐具。", "擦一下水槽边缘。", "把抹布晾开。"], ["只做到水槽，不扩展到全厨房。"], ["厨房", "整理", "归零"], "10-20", "medium", "indoor", "kitchen_block"),
    ("home", "do_home_laundry_basket", "衣物归位一篮", "Put away one laundry basket", "一个篮子就是边界", "One basket is the boundary", ["一篮衣物", "衣柜空间"], ["只处理这一篮。", "能挂就挂，能叠就叠。", "剩余问题衣物放一处。"], ["不顺手重整衣柜。"], ["衣物", "整理", "边界"], "10-20", "medium", "indoor", "laundry"),
    ("home", "do_home_entry_reset", "玄关归位 6 分钟", "Six-minute entryway reset", "减少出门阻力", "Reduce leaving-home friction", ["玄关区域", "6 分钟计时器"], ["鞋放回位置。", "钥匙和包归位。", "丢掉明显垃圾。"], ["只处理出门相关物品。"], ["玄关", "出门", "整理"], "5-10", "low", "indoor", "exit_friction"),
    ("home", "do_home_floor_patch", "地面清出一小块", "Clear one patch of floor", "让房间先恢复可走动", "Make the room walkable first", ["一个地面区域", "垃圾袋可选"], ["选一平方米左右。", "垃圾丢掉，物品归堆。", "能扫就扫一下。"], ["不追求全屋完成。"], ["地面", "整理", "可见成果"], "5-10", "medium", "indoor", "messy_room"),
    ("home", "do_home_trash_one_bag", "收一袋明显垃圾", "Collect one bag of obvious trash", "只处理没有争议的东西", "Handle only obvious trash", ["垃圾袋", "5 到 10 分钟"], ["拿一个袋子。", "只收明显垃圾。", "袋满或到点就停。"], ["不要处理需要判断的物品。"], ["垃圾", "整理", "低判断"], "5-10", "low", "indoor", "mess"),
    ("relax", "do_relax_breathing_3", "呼吸训练 3 分钟", "Three-minute breathing practice", "低刺激重置", "Low-stimulation reset", ["计时器", "可坐下的位置"], ["坐稳。", "吸气、停顿、呼气放慢。", "结束后观察身体感受。"], ["不追求特殊体验，只要降低刺激。"], ["呼吸", "放松", "重置"], "2-5", "low", "any", "overstimulated"),
    ("relax", "do_relax_warm_drink", "泡一杯热饮", "Make one warm drink", "用慢动作结束焦躁", "Use one slow action to close agitation", ["热水", "杯子"], ["烧水或接热水。", "冲泡饮品。", "喝前三口不看屏幕。"], ["晚上避免影响睡眠的咖啡因。"], ["热饮", "放松", "慢下来"], "5-10", "low", "indoor", "restless"),
    ("relax", "do_relax_full_track", "听完一首完整音乐", "Listen to one full track", "给注意力一个完整段落", "Give attention one complete segment", ["一首歌", "耳机可选"], ["选一首不切歌。", "听完整首。", "结束后再决定下一步。"], ["避免滑入无限歌单。"], ["音乐", "放松", "完整段落"], "5-10", "low", "any", "fragmented_attention"),
    ("relax", "do_relax_body_scan", "身体扫描 5 分钟", "Five-minute body scan", "检查疲劳来自哪里", "Check where fatigue sits", ["安静位置", "5 分钟"], ["从头到脚扫一遍。", "标记紧张部位。", "选一个部位放松。"], ["如果明显不适，优先休息或求助。"], ["身体", "放松", "觉察"], "5-10", "low", "indoor", "fatigue"),
    ("relax", "do_relax_screen_off_10", "离屏 10 分钟", "Ten minutes off-screen", "让刺激降下来", "Lower stimulation", ["放下手机", "一个替代动作"], ["把屏幕放远。", "做热饮、拉伸或看窗外。", "到点再回来。"], ["提前设定回来后做什么。"], ["离屏", "恢复", "低刺激"], "10-20", "low", "any", "screen_fatigue"),
    ("relax", "do_relax_shower_reset", "洗个短澡重置", "Take a short shower reset", "用身体切换状态", "Use the body to switch state", ["可洗澡时间", "换洗衣物"], ["准备衣物。", "洗 5 到 10 分钟。", "出来后喝水。"], ["太晚或太累时改为洗脸泡脚。"], ["洗澡", "重置", "身体"], "10-20", "medium", "indoor", "state_shift"),
    ("create", "do_create_100_words", "写 100 字碎片", "Write a 100-word fragment", "不求完整，只留下痕迹", "Not complete, just leave a trace", ["纸笔或文档", "10 分钟"], ["写标题。", "连续写到约 100 字。", "标注下一句可能写什么。"], ["不要马上编辑。"], ["写作", "创作", "碎片"], "10-20", "medium", "indoor", "creative_block"),
    ("create", "do_create_sketch_5", "画一个 5 分钟草图", "Draw a five-minute sketch", "让手先动起来", "Let the hand move first", ["纸笔或画板", "5 分钟"], ["选一个眼前物体。", "画轮廓，不追求像。", "写下一个可改进点。"], ["不要评价作品好坏。"], ["绘画", "创作", "启动"], "5-10", "low", "indoor", "creative_start"),
    ("create", "do_create_voice_memo", "录 60 秒想法备忘", "Record a sixty-second idea memo", "先保留想法，不整理它", "Capture the idea before organizing it", ["录音工具", "60 秒"], ["说出想法是什么。", "说适合谁或解决什么。", "说下一步。"], ["录完不必立刻整理。"], ["想法", "录音", "创作"], "2-5", "low", "any", "idea"),
    ("create", "do_create_photo_sort", "整理 9 张照片", "Sort nine photos", "小型审美整理", "A small visual edit", ["相册", "最多 9 张"], ["选一个主题。", "删除或收藏 9 张以内。", "选一张代表图。"], ["不要滑完整个相册。"], ["照片", "整理", "审美"], "5-10", "low", "indoor", "visual_clutter"),
    ("create", "do_create_playlist_5", "整理 5 首歌歌单", "Curate a five-song playlist", "用有限数量收口", "Close with a limited number", ["音乐 App", "一个主题"], ["写一个歌单主题。", "只选 5 首。", "排序一次就停。"], ["不要进入无限试听。"], ["歌单", "审美", "创作"], "10-20", "low", "indoor", "mood_design"),
    ("create", "do_create_idea_card", "做一张想法卡片", "Make one idea card", "把模糊灵感落成结构", "Turn a fuzzy idea into structure", ["卡片或笔记", "一个想法"], ["写问题。", "写三个关键词。", "写一个最小验证动作。"], ["只做一张。"], ["卡片", "想法", "结构"], "5-10", "medium", "indoor", "idea"),
    ("social", "do_social_update_one", "给一个人发近况", "Send one update message", "轻量连接，不必长聊", "Light contact without a long chat", ["一个联系人", "一句近况"], ["选一个人。", "发一句真实近况。", "不强迫对方立刻回应。"], ["不适合深夜打扰时改为明天提醒。"], ["社交", "近况", "轻连接"], "2-5", "low", "any", "social_gap"),
    ("social", "do_social_thanks", "补一句感谢", "Send one thank-you note", "把想过但没说的话补上", "Say the thanks you thought but did not send", ["感谢对象", "一件具体事"], ["写对方做了什么。", "写这件事帮到了哪里。", "发出或保存草稿。"], ["真诚短句即可。"], ["感谢", "社交", "关系"], "2-5", "low", "any", "gratitude"),
    ("social", "do_social_plan_walk", "约一个低压力见面", "Suggest a low-pressure meetup", "把见面压成容易答应的形式", "Make meeting easy to say yes to", ["一个候选人", "一个低压力选项"], ["提出散步、咖啡或简单吃饭。", "给两个时间窗口。", "允许对方拒绝或改期。"], ["不要一次塞入复杂安排。"], ["约见", "低压力", "社交"], "5-10", "medium", "any", "connection"),
    ("social", "do_social_reply_one", "回复一条欠着的信息", "Reply to one pending message", "只处理一条，不清空全部", "Reply to one, not the whole backlog", ["一条待回复消息", "3 分钟"], ["打开消息。", "只回复当前这一条。", "回复后关闭应用。"], ["难回复的消息可以先写草稿。"], ["回复", "社交", "收口"], "2-5", "low", "any", "message_backlog"),
    ("social", "do_social_family_checkin", "给家人发一个确认", "Send one family check-in", "维护低成本连接", "Maintain low-cost connection", ["一个家人", "一句问候"], ["问一个具体近况。", "补一句自己的状态。", "不展开争论话题。"], ["关系紧张时选择更安全的联系人。"], ["家人", "问候", "社交"], "2-5", "low", "any", "family"),
    ("social", "do_social_ask_small_help", "提出一个小请求", "Ask for one small help", "练习具体求助", "Practice specific help-seeking", ["一个可信任对象", "一个具体请求"], ["写清楚需要什么。", "说明对方可以拒绝。", "给一个明确截止点。"], ["不要把模糊压力丢给别人。"], ["求助", "社交", "边界"], "5-10", "medium", "any", "need_help"),
]


def make_option(raw: dict[str, Any], sort_key: int) -> dict[str, Any]:
    category = raw["category"]
    category_meta = CATEGORY_META[category]
    duration = raw["duration"]
    energy = raw["energy"]
    place = raw["place"]
    trigger = raw["trigger"]
    tags_zh = list(dict.fromkeys([*raw["tagsZh"], category_meta["zh"], duration]))
    tags_en = list(dict.fromkeys([*raw["tagsEn"], category_meta["en"], duration]))
    return {
        "id": raw["id"],
        "moduleId": "activity",
        "categoryId": category,
        "contextId": None,
        "contextIds": [],
        "titleZh": raw["titleZh"],
        "titleEn": raw["titleEn"],
        "subtitleZh": raw["subtitleZh"],
        "subtitleEn": raw["subtitleEn"],
        "detailsZh": raw["detailsZh"],
        "detailsEn": raw["detailsEn"],
        "materialsZh": raw["conditionsZh"],
        "materialsEn": raw["conditionsEn"],
        "stepsZh": raw["stepsZh"],
        "stepsEn": raw["stepsEn"],
        "notesZh": raw["notesZh"],
        "notesEn": raw["notesEn"],
        "tagsZh": tags_zh,
        "tagsEn": tags_en,
        "sourceLabel": "vocabularySleep curated activity set v1",
        "sourceUrl": None,
        "references": [],
        "attributes": {
            "duration": [duration],
            "energy": [energy],
            "place": [place],
            "trigger": [trigger],
        },
        "custom": False,
        "status": "active",
        "isAvailable": True,
        "sortKey": sort_key,
    }


def expand_more_actions(start_sort_key: int) -> list[dict[str, Any]]:
    result = []
    for offset, item in enumerate(MORE_ACTIONS):
        (
            category,
            option_id,
            title_zh,
            title_en,
            subtitle_zh,
            subtitle_en,
            conditions_zh,
            steps_zh,
            notes_zh,
            tags_zh,
            duration,
            energy,
            place,
            trigger,
        ) = item
        result.append(
            make_option(
                {
                    "id": option_id,
                    "category": category,
                    "titleZh": title_zh,
                    "titleEn": title_en,
                    "subtitleZh": subtitle_zh,
                    "subtitleEn": subtitle_en,
                    "detailsZh": f"{subtitle_zh}。这个行动的边界是 {duration} 分钟内完成一轮，先让状态发生可见变化，而不是把整天重新规划一遍。",
                    "detailsEn": f"{subtitle_en}. The boundary is one {duration} minute round that creates a visible state shift instead of replanning the whole day.",
                    "conditionsZh": conditions_zh,
                    "conditionsEn": [translate_condition(text) for text in conditions_zh],
                    "stepsZh": steps_zh,
                    "stepsEn": [translate_step(text) for text in steps_zh],
                    "notesZh": notes_zh,
                    "notesEn": [translate_note(text) for text in notes_zh],
                    "tagsZh": tags_zh,
                    "tagsEn": [slug_tag(text) for text in tags_zh],
                    "duration": duration,
                    "energy": energy,
                    "place": place,
                    "trigger": trigger,
                },
                start_sort_key + offset,
            )
        )
    return result


def translate_condition(text: str) -> str:
    known = {
        "手机计时器": "Phone timer",
        "合适鞋子": "Suitable shoes",
        "椅子或墙面": "Chair or wall",
        "3 到 6 分钟": "Three to six minutes",
        "安全楼梯": "Safe stairs",
        "不赶时间": "No rush",
        "一面墙": "A wall",
        "每组 8 到 12 次": "Eight to twelve reps per set",
        "瑜伽垫可选": "Yoga mat optional",
        "一块安全地面": "A safe floor area",
        "墙边或桌边": "Near a wall or table",
        "每侧 30 秒": "Thirty seconds each side",
    }
    return known.get(text, text)


def translate_step(text: str) -> str:
    return text.rstrip("。")


def translate_note(text: str) -> str:
    return text.rstrip("。")


def slug_tag(text: str) -> str:
    mapping = {
        "运动": "move",
        "散步": "walk",
        "重启": "reset",
        "拉伸": "stretch",
        "久坐": "sitting",
        "低阻力": "low friction",
        "学习": "learn",
        "整理": "tidy",
        "出门": "outside",
        "放松": "relax",
        "社交": "social",
        "创作": "create",
    }
    return mapping.get(text, text)


def build_library() -> dict[str, Any]:
    options = [make_option(raw, index) for index, raw in enumerate(RAW_ACTIONS)]
    options.extend(expand_more_actions(len(options)))
    ids = [option["id"] for option in options]
    if len(ids) != len(set(ids)):
        duplicates = [item for item, count in Counter(ids).items() if count > 1]
        raise ValueError(f"Duplicate option ids: {duplicates}")
    return {
        "libraryId": LIBRARY_ID,
        "libraryVersion": f"2026-04-29-{len(options)}",
        "schemaId": SCHEMA_ID,
        "schemaVersion": SCHEMA_VERSION,
        "generatedAt": dt.datetime.now(dt.UTC).isoformat(),
        "referenceTitles": [
            "Everyday low-friction action design",
            "Attention reset and behavioral activation patterns",
        ],
        "categories": CATEGORY_META,
        "options": options,
    }


def create_schema(db: sqlite3.Connection) -> None:
    db.executescript(
        """
        PRAGMA user_version = 1;
        CREATE TABLE daily_choice_activity_options (
          option_id TEXT PRIMARY KEY,
          category_id TEXT NOT NULL,
          context_id TEXT,
          context_ids_json TEXT NOT NULL DEFAULT '[]',
          title_zh TEXT NOT NULL,
          title_en TEXT NOT NULL,
          subtitle_zh TEXT NOT NULL,
          subtitle_en TEXT NOT NULL,
          details_zh TEXT NOT NULL,
          details_en TEXT NOT NULL,
          materials_zh_json TEXT NOT NULL DEFAULT '[]',
          materials_en_json TEXT NOT NULL DEFAULT '[]',
          steps_zh_json TEXT NOT NULL DEFAULT '[]',
          steps_en_json TEXT NOT NULL DEFAULT '[]',
          notes_zh_json TEXT NOT NULL DEFAULT '[]',
          notes_en_json TEXT NOT NULL DEFAULT '[]',
          tags_zh_json TEXT NOT NULL DEFAULT '[]',
          tags_en_json TEXT NOT NULL DEFAULT '[]',
          source_label TEXT,
          source_url TEXT,
          references_json TEXT NOT NULL DEFAULT '[]',
          attributes_json TEXT NOT NULL DEFAULT '{}',
          custom INTEGER NOT NULL DEFAULT 0,
          status TEXT NOT NULL DEFAULT 'active',
          is_available INTEGER NOT NULL DEFAULT 1,
          sort_key INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE daily_choice_activity_meta (
          meta_key TEXT PRIMARY KEY,
          meta_value TEXT NOT NULL
        );
        CREATE INDEX idx_activity_cat_ctx
          ON daily_choice_activity_options(category_id, context_id, status, is_available);
        """
    )


def write_sqlite(library: dict[str, Any], db_path: Path) -> None:
    if db_path.exists():
        db_path.unlink()
    db = sqlite3.connect(db_path)
    try:
        create_schema(db)
        meta = {
            "library_id": library["libraryId"],
            "library_version": library["libraryVersion"],
            "schema_id": library["schemaId"],
            "schema_version": str(library["schemaVersion"]),
            "reference_titles_json": json.dumps(library["referenceTitles"], ensure_ascii=False),
            "installed_at": library["generatedAt"],
            "updated_at": library["generatedAt"],
        }
        db.executemany(
            "INSERT INTO daily_choice_activity_meta(meta_key, meta_value) VALUES (?, ?)",
            meta.items(),
        )
        db.executemany(
            """
            INSERT INTO daily_choice_activity_options (
              option_id, category_id, context_id, context_ids_json,
              title_zh, title_en, subtitle_zh, subtitle_en,
              details_zh, details_en,
              materials_zh_json, materials_en_json,
              steps_zh_json, steps_en_json,
              notes_zh_json, notes_en_json,
              tags_zh_json, tags_en_json,
              source_label, source_url, references_json,
              attributes_json, custom, status, is_available, sort_key
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [option_row(option) for option in library["options"]],
        )
        db.commit()
    finally:
        db.close()


def option_row(option: dict[str, Any]) -> tuple[Any, ...]:
    dumps = lambda value: json.dumps(value, ensure_ascii=False)
    return (
        option["id"],
        option["categoryId"],
        option.get("contextId"),
        dumps(option.get("contextIds", [])),
        option["titleZh"],
        option["titleEn"],
        option["subtitleZh"],
        option["subtitleEn"],
        option["detailsZh"],
        option["detailsEn"],
        dumps(option["materialsZh"]),
        dumps(option["materialsEn"]),
        dumps(option["stepsZh"]),
        dumps(option["stepsEn"]),
        dumps(option["notesZh"]),
        dumps(option["notesEn"]),
        dumps(option["tagsZh"]),
        dumps(option["tagsEn"]),
        option.get("sourceLabel"),
        option.get("sourceUrl"),
        dumps(option.get("references", [])),
        dumps(option.get("attributes", {})),
        1 if option.get("custom") else 0,
        option.get("status", "active"),
        1 if option.get("isAvailable", True) else 0,
        option.get("sortKey", 0),
    )


def write_docs(library: dict[str, Any], output_dir: Path) -> None:
    count_by_category = Counter(option["categoryId"] for option in library["options"])
    (output_dir / "FORMAT.md").write_text(
        "\n".join(
            [
                "# 干什么数据格式",
                "",
                "- 上传到 S3 的主文件：`activity_data/daily_choice_activity_library.json`",
                "- App 下载 JSON 后安装为本地 SQLite：`toolbox_daily_choice_activity.db`",
                "- 每条 `option` 对应一个 `DailyChoiceOption`，其中 `materials` 表示开始条件，`steps` 表示执行步骤，`notes` 表示退出条件或注意事项。",
                "- `attributes.duration / energy / place / trigger` 用于后续筛选扩展，不直接作为硬规则。",
                "",
                "## 顶层字段",
                "- `libraryId`, `libraryVersion`, `schemaId`, `schemaVersion`",
                "- `referenceTitles`: 数据设计参考说明标题",
                "- `categories`: 行动方向元数据",
                "- `options`: 行动条目列表",
            ]
        ),
        encoding="utf-8",
    )
    summary_lines = [
        "# 干什么数据生成摘要",
        "",
        f"- 生成时间: {library['generatedAt']}",
        f"- 行动总数: {len(library['options'])}",
        f"- libraryVersion: {library['libraryVersion']}",
        "",
        "## 分类分布",
    ]
    for category_id, count in sorted(count_by_category.items()):
        meta = CATEGORY_META[category_id]
        summary_lines.append(f"- {meta['zh']} / {category_id}: {count}")
    (output_dir / "GENERATION_SUMMARY.md").write_text(
        "\n".join(summary_lines),
        encoding="utf-8",
    )


def verify_sqlite(db_path: Path, expected_count: int) -> None:
    db = sqlite3.connect(db_path)
    try:
        integrity = db.execute("PRAGMA integrity_check").fetchone()[0]
        if integrity != "ok":
            raise RuntimeError(f"SQLite integrity_check failed: {integrity}")
        count = db.execute(
            "SELECT COUNT(*) FROM daily_choice_activity_options WHERE status='active' AND is_available=1"
        ).fetchone()[0]
        if count != expected_count:
            raise RuntimeError(f"SQLite row count mismatch: {count} != {expected_count}")
    finally:
        db.close()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    output_dir = args.output_dir
    output_dir.mkdir(parents=True, exist_ok=True)
    library = build_library()
    json_path = output_dir / "daily_choice_activity_library.json"
    db_path = output_dir / "daily_choice_activity_library.db"
    json_path.write_text(
        json.dumps(library, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    write_sqlite(library, db_path)
    verify_sqlite(db_path, len(library["options"]))
    write_docs(library, output_dir)
    print(f"Wrote {len(library['options'])} actions to {output_dir}")


if __name__ == "__main__":
    main()
