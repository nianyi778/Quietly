# 变更记录

## 版本
- N/A（UI/视觉变更）

## 日期
- 2025-12-25

## 摘要
- 更新菜单栏图标渲染：底图保持 template 渲染，在其上叠加单个“行星/小球”沿倾斜轨道运动。
- 运行/暂停行为：运行时小球运动；暂停时小球停在当前位置但保持可见，并切换为暂停色。
- 优化伪 3D 背面效果：保留背面遮挡，同时在背面轻微降低小球透明度，并缩短/变细遮挡段，避免浅色模式下出现“发黑”。
- 遮挡段描边颜色跟随小球当前颜色，消除“黑边”伪影。

## 批准人
- likai（“批准实现”）

## 备注
- 涉及文件：
  - Quietly/App/StatusBarController.swift
  - Quietly/App/MenuBarIconAnimator.swift
  - Quietly/Assets.xcassets/MenuBarIcon.imageset/menubar_icon.svg
- 背面表现采用“短弧段遮挡 + 透明度降低”组合，以保持层次感且不引入明显黑色覆盖。
