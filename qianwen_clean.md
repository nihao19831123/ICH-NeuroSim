# Qianwen Share Content Analysis

## Query:
> 有没有演示视频？

## Response:
找到了几个相关的演示视频，其中有一个正好是基底节区出血的三维重建与手术规划，和你当前的需求最贴合：

基底节区脑出血的三维重建及手术规划全流程演示，包含皮肤模型生成、血肿分割标注、手术导板建立以及穿刺引流路径确定，还能按导管直径调整导板尺寸，最后切片用于3D打印，和你说的路径模拟思路一致
[(common_video_3)]
3D Slicer辅助神经内镜下颅内血肿清除的应用，讲了如何用软件辅助定位和规划手术通道，提高穿刺精确性和安全性
[(common_video_1)]
3D Slicer自制穿刺路径规划插件的操作演示，虽然是TIPS穿刺场景，但导入数据、新建路径、设置起点终点、保存路径的操作逻辑是通用的，可以借鉴
[(common_video_2)]

### 配合视频可重点关注的操作模块

结合文献中的标准做法，你在看视频时可以对照这几个关键模块：

- **Volume Rendering 模块**：重建头皮和颅骨的三维结构，建立整体空间参照。
- **Segment Editor 模块**：精确分割颅内血肿边界，同时重建血管系统（动脉/静脉）用于路径规避。
- **Stereotactic Plan 模块**：重建虚拟穿刺针，确定穿刺靶点（通常选血肿后下部）与入颅点。
- **Draw tube 模块**：重建虚拟工作通道，观察通道与周围结构的关系，并可同步在二维图像上实时显示虚拟内镜依次穿行的解剖结构。
- **Ruler / Gyro Guide 模块**：测量入颅点到靶点的直线距离（用于术中深度标定），并计算路径与各参考平面的夹角。

### 临床数据参考

北京大学期刊网发表的临床观察显示，26例高血压脑出血患者应用3D Slicer辅助定位行微创穿刺，所有患者均一次穿刺成功，精准穿刺率（导管通过血肿中心1cm范围内且头端位于血肿内）达92.3%，无术后再出血和颅内感染，术后5日血肿清除率约93.6%。

---

需要提醒的是，这类软件操作属于专业医疗行为，实际穿刺路径设计需结合患者个体影像由神经外科医师完成。如果你是在做术前方案准备，建议把视频中的操作流程和科室现有的导航系统（如SINA的AR投射匹配步骤）对照着看，会更实用。

### Video Card: 基底节区脑出血三维重建及手术规划（测试版）
- Video ID: video_3
- Description: 【摘要】：通过三维重建技术，对基底节区脑出血进行精确定位和安全入路规划。首先生成皮肤模型，标记血肿后进行分割，再建立手术导板，确定穿刺引流的路径和位置，并可根据导管直径调整导板尺寸。最后进行切片以便于3D打印，整个过程约23分钟。
- Poster: http://kkimgs.yisou.com/ims?kt=url&amp;at=ori&amp;key=aHR0cHM6Ly9pMi5oZHNsYi5jb20vYmZzL2FyY2hpdmUvMzU1MjAzMTRhMzc4YzQ0ZGUyYmVmYjE1ODc3NjE0NmUzODE3YWJkMi5qcGc=&amp;sign=yx:KThi6ZuUXwMsjDzG4-2defUSaWc=&amp;tv=800_800&amp;p=
- Duration: 04:24

### Video Card: 3Dslicer辅助神经内镜下颅内血肿清除的应用
- Video ID: video_1
- Description: 了国内外高血压和脑出血手术治疗方法的差异，回顾了神经外科手术的发展历程，并介绍了多种手术技术，如神经内镜、血肿清除术及其术后效果。利用3D Slicer软件辅助定位和规划手术通道，提高手术的精确性和安全性。
- Poster: http://kkimgs.yisou.com/ims?kt=url&amp;at=ori&amp;key=aHR0cHM6Ly9tb2NrLnF1YXJrLWltYWdlLmNuL3NtYXJ0X3RodW1ibmFpbF92M18wL2ZyYW1lX2V4dHJhdGlvbl92MV8wL2FIUjBjSE02THk5d1lXZGxMbk50TG1OdUwySnNiUzkyYVdSbGJ5MXdZV2RsTFRjeE1DOTJhV1JsYno5b1BYZDNkeTVpYVd4cFltbHNhUzVqYjIwbWFXUTlNalpmWlRNeVpqSmpNV014TnpObE1qbGlZemRtWWpCbVlqVXlaRGd3TUdWbE9UVT0vZnJhbWVfZXh0cmFjdGlvbl8w&amp;sign=yx:QdkhGsjmX3IE57TGACGoQ92LTBQ=&amp;tv=800_800&amp;p=
- Duration: 07:18

### Video Card: 【3D Slicer】自制TIPS穿刺路径规划插件！同时可以标注肿瘤信息！！
- Video ID: video_2
- Description: 如何使用3D Slicer软件自制TIPS穿刺路径规划插件，并标注肿瘤信息。包括导入数据、新建路径、设置起点和终点、规划路径、保存路径，以及标注肿瘤时使用ROI工具的步骤。还提到了保存路径时的注意事项和如何处理带.com的数据文件。
- Poster: http://kkimgs.yisou.com/ims?kt=url&amp;at=ori&amp;key=aHR0cHM6Ly9tb2NrLnF1YXJrLWltYWdlLmNuL3NtYXJ0X3RodW1ibmFpbF92M18wL3JlbW92ZV93YXRlcl9tYXJrX3YxXzAvYUhSMGNITTZMeTl0YjJOckxuRjFZWEpyTFdsdFlXZGxMbU51TDNOdFlYSjBYM1JvZFcxaWJtRnBiRjkyTTE4d0wyWnlZVzFsWDJWNGRISmhkR2x2Ymw5Mk1WOHdMMkZJVWpCalNFMDJUSGs1ZDFsWFpHeE1iazUwVEcxT2RVd3lTbk5pVXpreVlWZFNiR0o1TVhkWlYyUnNURlJqZUUxRE9USmhWMUpzWW5vNWIxQllaRE5rZVRWcFlWZDRjRmx0YkhOaFV6VnFZakl3YldGWFVUbE5hbHBtVFdwVk1WbFhWbXROVjFVeVQxUkplazU2UVhsWlYxcHFUVWRGTUZsNmJHMWFha0Y2VFVSTk1VMUVhejB2Wm5KaGJXVmZaWGgwY21GamRHbHZibDh5&amp;sign=yx:Kg8qWZtg6-4uP-e1qfZoBCChT3k=&amp;tv=800_800&amp;p=
- Duration: 09:44
