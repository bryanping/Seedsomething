import os
from PIL import Image, ImageDraw, ImageFont

# 植物列表（必须与 Swift 代码中的 PlantSpecies 枚举顺序完全一致）
PLANTS = [
    "绿豆芽", "豆苗", "苜蓿", "芝麻苗",  # 豆类
    "小白菜", "韭菜", "羽衣甘蓝", "芋头",  # 蔬菜类
    "绿萝", "三叶草", "四叶草", "蕨类植物", "橡皮树", "牵牛花", "郁金香花苞", "金盏花", "茶花花苞", "夜来香", "白掌", "多肉植物", "紫叶酢浆草", "蓝星花", "银叶菊", "苔藓", "狗尾草", "仙客来", "常春藤", "仙人掌", "彩叶草", "彩虹尤加利", "彩虹菊", "蓝色罂粟",  # 观赏植物
    "枫香", "瑞香", "樱花花芽", "银杏", "枫树", "榕树", "樟树", "橄榄树", "柳树嫩叶", "松树", "枫叶（秋季）",  # 树木类
    "向日葵幼苗", "向日葵",  # 花卉类
    "小麦苗", "玉米苗", "稻苗",  # 作物类
    "月桂", "迷迭香"  # 香草类
]

# 输出目录
OUTPUT_DIR = "Seedsomething/Assets.xcassets/Plants"
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

# 字体颜色
TEXT_COLOR = (74, 74, 74) # #4A4A4A (brandDarkGray)
BG_COLOR = (168, 230, 163, 100) # #A8E6A3 (brandLightGreen) with transparency

def generate_placeholder(plant_name, index, stage):
    # 创建透明背景图片
    img = Image.new('RGBA', (500, 500), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 绘制圆形背景
    draw.ellipse([50, 50, 450, 450], fill=BG_COLOR)
    
    # 绘制文字
    text = f"{plant_name}\nv{stage}"
    # 尝试加载中文字体，如果失败则使用默认
    try:
        # macOS 常见中文字体
        font = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 60)
    except:
        try:
            font = ImageFont.truetype("Arial", 40)
        except:
            font = ImageFont.load_default()
            
    # 计算文字位置居中
    # Pillow 9.2.0+ 使用 draw.textbbox
    try:
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
    except AttributeError:
        # 旧版 Pillow
        text_width, text_height = draw.textsize(text, font=font)
        
    x = (500 - text_width) / 2
    y = (500 - text_height) / 2
    
    draw.text((x, y), text, font=font, fill=TEXT_COLOR, align="center")
    
    # 创建 .imageset 目录
    image_name_no_ext = f"plant_{index:02d}_{plant_name}_v{stage}"
    imageset_dir = os.path.join(OUTPUT_DIR, f"{image_name_no_ext}.imageset")
    if not os.path.exists(imageset_dir):
        os.makedirs(imageset_dir)
    
    # 保存图片
    filename = f"{image_name_no_ext}.png"
    filepath = os.path.join(imageset_dir, filename)
    img.save(filepath)
    
    # 生成 Contents.json
    json_content = f'''{{
  "images" : [
    {{
      "filename" : "{filename}",
      "idiom" : "universal",
      "scale" : "1x"
    }},
    {{
      "idiom" : "universal",
      "scale" : "2x"
    }},
    {{
      "idiom" : "universal",
      "scale" : "3x"
    }}
  ],
  "info" : {{
    "author" : "xcode",
    "version" : 1
  }}
}}'''
    
    with open(os.path.join(imageset_dir, "Contents.json"), "w") as f:
        f.write(json_content)
        
    print(f"Generated: {imageset_dir}")

def main():
    print(f"Start generating {len(PLANTS) * 5} placeholder images...")
    
    for i, plant in enumerate(PLANTS):
        index = i + 1
        for stage in range(1, 6):
            generate_placeholder(plant, index, stage)
            
    print("Done! All placeholders generated.")
    print(f"Images saved to: {OUTPUT_DIR}")

if __name__ == "__main__":
    main()

