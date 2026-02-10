* ❓  ”禁止Helix光标定位到回车换行符上“ 这一点是不是无论如何都无法修改？
  - Helix 是 selection→action 模型，光标本身就是“单字符选择”，因此换行符也属于可被选中的字符；这会导致光标能落
    在行末换行符上。(docs.helix-editor.com (https://docs.helix-editor.com/usage.html))
  - 官方的编辑器配置项参考里没有提供“禁止光标落在换行符/虚拟位”的设置，所以现阶段无法通过配置关闭这一行为。
    (docs.helix-editor.com (https://docs.helix-editor.com/editor.html?utm_source=openai))

  如果只是想避免停在换行符上再进入插入模式，可以直接用 vim中的A（insert_at_line_end）在行末进入插入。(docs.helix-editor.com (https://docs.helix-editor.com/commands.html?utm_source=openai))
