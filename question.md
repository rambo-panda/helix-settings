Helix 的核心理念是「selection → action」：先选中对象，再对其执行操作。

与 Vim 的「action → motion」不同，Helix 把光标视为“宽度为 1 的选择”。因此很多操作更像是：
1) 用移动/扩展命令选中目标（字符、单词、行、语法节点、多处匹配）
2) 再执行动作（删除、替换、复制、缩进等）

这样做的结果是：多选和结构化编辑成为“默认能力”，而不是插件功能；代价是部分 Vim 行为不会完全一致。

------------------------------

* ❓  ”禁止Helix光标定位到回车换行符上“ 这一点是不是无论如何都无法修改？
  - Helix 是 selection→action 模型，光标本身就是“单字符选择”，因此换行符也属于可被选中的字符；这会导致光标能落
    在行末换行符上。(docs.helix-editor.com (https://docs.helix-editor.com/usage.html))
  - 官方的编辑器配置项参考里没有提供“禁止光标落在换行符/虚拟位”的设置，所以现阶段无法通过配置关闭这一行为。
    (docs.helix-editor.com (https://docs.helix-editor.com/editor.html?utm_source=openai))

  如果只是想避免停在换行符上再进入插入模式，可以直接用 vim中的A（insert_at_line_end）在行末进入插入。(docs.helix-editor.com (https://docs.helix-editor.com/commands.html?utm_source=openai))
  * [`x_`](https://github.com/helix-editor/helix/discussions/2503) 
  * [Unexpected behavior because of newline characters being selectable](https://github.com/helix-editor/helix/issues/2956) 
  * [Add option to not have newlines selectable](https://github.com/helix-editor/helix/issues/3076)
