import os
import shutil
import re

scratch_dir = r"c:\Users\user\.gemini\antigravity\scratch"
aviutl_dir = r"C:\ProgramData\aviutl2"
script_roots = [
    r"C:\ProgramData\aviutl2\Script",
    r"C:\Program Files\AviUtl2\script"
]
alias_dir = os.path.join(aviutl_dir, "Alias")
legacy_rtav2_alias_dir = os.path.join(alias_dir, "RtAv2")
preset_dir = os.path.join(aviutl_dir, "Preset")

# Create directories
for script_root in script_roots:
    os.makedirs(script_root, exist_ok=True)
os.makedirs(alias_dir, exist_ok=True)
os.makedirs(preset_dir, exist_ok=True)
os.makedirs(os.path.join(aviutl_dir, "Log"), exist_ok=True)

# Clean up old files in Script roots
files_to_remove = [
    "@RtAv2.anm",
    "@RtAv2.anm2",
    "@RtAv2(エフェクト).anm",
    "@RtAv2(エフェクト).anm2",
    "@RtAv2(描画系).anm",
    "@RtAv2(描画系).anm2",
    "@RtAv2(読込系).anm",
    "@RtAv2(読込系).anm2",
    "RtAv2.lua",
    "RtAv2Function.lua"
]
for script_root in script_roots:
    for f in files_to_remove:
        p = os.path.join(script_root, f)
        if os.path.exists(p):
            try:
                os.remove(p)
                print(f"Removed old file: {p}")
            except Exception as e:
                print(f"Failed to remove {p}: {e}")
    # Clean up old subfolder completely since we deploy everything to Script root
    shutil.rmtree(os.path.join(script_root, "RtAv2"), ignore_errors=True)

# Clean up old files in Alias root
old_alias_files = os.listdir(alias_dir)
for f in old_alias_files:
    p = os.path.join(alias_dir, f)
    if os.path.isfile(p) and f.endswith(".object") and f not in ["つくよみちゃん.object", "モニ教室.object", "字幕表示.object", "最初.object"]:
        os.remove(p)
        print(f"Cleaned up old Alias: {f}")

# Clean up RtAv2 legacy alias folder and preset folder
shutil.rmtree(legacy_rtav2_alias_dir, ignore_errors=True)

for f in os.listdir(preset_dir):
    if ".RtAv2." in f:
        os.remove(os.path.join(preset_dir, f))
        print(f"Removed old preset: {f}")

# Helper functions
def parse_param(param_str):
    if not param_str:
        return {}
    res = {}
    parts = param_str.split(";")
    for part in parts:
        part = part.strip()
        if not part:
            continue
        if "=" in part:
            k, v = part.split("=", 1)
            k = k.strip()
            v = v.strip()
            if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
                v = v[1:-1]
            res[k] = v
    return res

def decode_hex_text(hex_str):
    try:
        if len(hex_str) % 2 != 0:
            hex_str += "0"
        b = bytes.fromhex(hex_str)
        if len(b) % 2 != 0:
            b = b + b'\x00'
        return b.decode("utf-16-le", errors="replace").strip("\x00")
    except Exception as e:
        print(f"Error decoding hex text: {e}")
        return ""

def parse_ini(filepath):
    with open(filepath, "rb") as f:
        raw = f.read()
    text = raw.decode("cp932", errors="replace")
    
    sections = {}
    current_sec = None
    
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith("[") and line.endswith("]"):
            current_sec = line[1:-1].strip()
            sections[current_sec] = {}
        elif current_sec is not None and "=" in line:
            k, v = line.split("=", 1)
            sections[current_sec][k.strip()] = v.strip()
            
    return sections

def get_filter_name(raw_name):
    if not raw_name:
        return "rpp読み込み@RtAv2"
    raw_name = raw_name.strip()
    
    if raw_name.startswith("@"):
        parts = raw_name[1:].split("@")
        if len(parts) == 1:
            return f"rpp読み込み@{parts[0]}"
        else:
            return f"{parts[0]}@{parts[1]}"
            
    if "@" in raw_name:
        return raw_name
        
    if raw_name == "rpp読込" or raw_name == "rpp読み込み":
        return "rpp読み込み@RtAv2"
    elif raw_name == "基準" or raw_name == "初期化":
        return "初期化@RtAv2"
    elif raw_name == "描画系" or raw_name == "描画":
        return "描画@RtAv2"
    elif raw_name == "動画" or raw_name == "動画読み込み":
        return "動画@RtAv2(読込系)"
    elif raw_name == "エフェクトリセット" or raw_name == "リセット":
        return "エフェクトリセット@RtAv2(読込系)"
    elif raw_name == "両端クリッピング":
        return "両端クリッピング@RtAv2(描画系)"
    elif raw_name == "複数描画":
        return "複数描画@RtAv2(描画系)"
    elif raw_name == "反転":
        return "反転@RtAv2(エフェクト)"
    elif raw_name == "座標":
        return "座標@RtAv2(エフェクト)"
    elif raw_name == "回転":
        return "回転@RtAv2(エフェクト)"
    elif raw_name == "拡大率":
        return "拡大率@RtAv2(エフェクト)"
    elif raw_name == "透明度":
        return "透明度@RtAv2(エフェクト)"
    elif raw_name == "ラスター":
        return "ラスター@RtAv2(エフェクト)"
    elif raw_name == "方向ブラー":
        return "方向ブラー@RtAv2(エフェクト)"
    elif raw_name == "グロー":
        return "グロー@RtAv2(エフェクト)"
    elif raw_name == "クリッピング":
        return "クリッピング@RtAv2(エフェクト)"
        
    return f"{raw_name}@RtAv2"

# Deploy Lua Libraries to Script roots for direct require resolution
for script_root in script_roots:
    try:
        shutil.copy2(os.path.join(scratch_dir, "RtAv2.lua"), os.path.join(script_root, "RtAv2.lua"))
        shutil.copy2(os.path.join(scratch_dir, "RtAv2Function.lua"), os.path.join(script_root, "RtAv2Function.lua"))
        print(f"Deployed RtAv2.lua and RtAv2Function.lua to {script_root}")
    except Exception as e:
        print(f"Failed to deploy Lua libraries to {script_root}: {e}")

# Process and Deploy .anm2 Scripts with @ prefix
package_path_prepend = 'package.path = package.path .. ";C:\\\\Program Files\\\\AviUtl2\\\\script\\\\?.lua;C:\\\\ProgramData\\\\aviutl2\\\\Script\\\\?.lua"\n'

script_mappings = {
    "@RtAv2.anm": "@RtAv2.anm2",
    "@RtAv2(描画系).anm": "@RtAv2(描画系).anm2",
    "@RtAv2(読込系).anm": "@RtAv2(読込系).anm2",
    "@RtAv2(エフェクト).anm": "@RtAv2(エフェクト).anm2"
}

for src_name, dest_name in script_mappings.items():
    src_path = os.path.join(scratch_dir, src_name)
    
    with open(src_path, "r", encoding="utf-8") as f:
        content = f.read()
        
    # Process line-by-line to insert package_path_prepend after parameters definition
    lines = content.splitlines()
    new_lines = []
    
    # Add to the very top as fallback
    new_lines.append(package_path_prepend.strip())
    
    in_header = False
    for line in lines:
        line_strip = line.strip()
        if line_strip.startswith('@') and not line_strip.startswith('@@'):
            in_header = True
            new_lines.append(line)
            continue
            
        if in_header:
            if line_strip.startswith('--'):
                # Parameter definition line, keep it
                new_lines.append(line)
            elif line_strip == '':
                # Keep empty line
                new_lines.append(line)
            else:
                # First code line after parameters. Insert package_path_prepend here.
                new_lines.append(package_path_prepend.strip())
                new_lines.append(line)
                in_header = False
        else:
            new_lines.append(line)
            
    new_content = "\n".join(new_lines)
    
    # If RtAv2.anm2, update --file: to --file@file:RPPファイル
    if dest_name == "@RtAv2.anm2":
        new_content = new_content.replace("--file:", "--file@file:RPPファイル")
        
    for script_root in script_roots:
        dest_path = os.path.join(script_root, dest_name)
        try:
            with open(dest_path, "w", encoding="utf-8") as f:
                f.write(new_content)
            print(f"Processed and Deployed Script: {dest_name} to {script_root}")
        except Exception as e:
            print(f"Failed to deploy Script: {dest_name} to {script_root}: {e}")
            
    # Also save the compiled .anm2 to scratch_dir for packaging
    scratch_dest_path = os.path.join(scratch_dir, dest_name)
    try:
        with open(scratch_dest_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"Saved compiled script {dest_name} to scratch_dir")
    except Exception as e:
        print(f"Failed to save {dest_name} to scratch_dir: {e}")


# Convert and Deploy Presets & Object Aliases
base_exa_path = "H:\\eizousamasama\\あｓふぁｓｆｓだ\\RtAv2"
effect_alias_dir = None
obj_alias_dir = None
obj_preset_dir = None

for entry in os.listdir(base_exa_path):
    entry_path = os.path.join(base_exa_path, entry)
    if os.path.isdir(entry_path):
        if "エフェクトエイリアス" in entry or "̪" in entry or "ｴﾌｪｸﾄ" in entry:
            effect_alias_dir = entry_path
        elif "オブジェクトエイリアス" in entry or "޼" in entry or "ｵﾌﾞｼﾞｪｸﾄｴｲﾘｱｽ" in entry:
            obj_alias_dir = entry_path
        elif "オブジェクトプリセット" in entry or "ｵﾌﾞｼﾞｪｸﾄﾌﾟﾘｾｯﾄ" in entry:
            obj_preset_dir = entry_path

# Convert Effect Presets
if effect_alias_dir and os.path.exists(effect_alias_dir):
    for f in os.listdir(effect_alias_dir):
        if f.endswith(".exa"):
            filepath = os.path.join(effect_alias_dir, f)
            preset_name = os.path.splitext(f)[0]
            
            sections = parse_ini(filepath)
            vo_0 = sections.get("vo.0", {})
            raw_script_name = vo_0.get("name", "")
            filter_name = get_filter_name(raw_script_name)
            
            dest_filename = f"{filter_name}.RtAv2.{preset_name}.preset"
            dest_path = os.path.join(preset_dir, dest_filename)
            
            preset_content = [
                "[Preset]",
                "target=self",
                "[Effect.0]",
                f"effect.name={filter_name}"
            ]
            for k, v in vo_0.items():
                if k.startswith("track") or k.startswith("check"):
                    preset_content.append(f"{k}={v}")
                    
            params = parse_param(vo_0.get("param", ""))
            for k, v in params.items():
                preset_content.append(f"{k}={v}")
                
            try:
                with open(dest_path, "w", encoding="utf-8") as out_f:
                    out_f.write("\n".join(preset_content) + "\n")
                print(f"Created Preset: {dest_filename}")
            except Exception as e:
                print(f"Failed to create Preset: {dest_filename}: {e}")

created_object_names = []

def convert_object_alias(src_dir, filename):
    filepath = os.path.join(src_dir, filename)
    preset_name = os.path.splitext(filename)[0]
    
    sections = parse_ini(filepath)
    rtav2_alias_dir = os.path.join(alias_dir, "RtAv2")
    os.makedirs(rtav2_alias_dir, exist_ok=True)
    dest_filename = f"{preset_name}.object"
    dest_path = os.path.join(rtav2_alias_dir, dest_filename)
    created_object_names.append(f"RtAv2/{preset_name}")
    
    object_content = []
    vo = sections.get("vo", {})
    length_val = vo.get("length", "300")
    
    object_content.append("[0]")
    object_content.append("layer=0")
    object_content.append(f"frame=0,{length_val}")
    
    k = 0
    while True:
        sec_name = f"vo.{k}"
        if sec_name not in sections:
            break
        vo_k = sections[sec_name]
        object_content.append(f"[0.{k}]")
        
        _name = vo_k.get("_name", "")
        if "アニメーション効果" in _name or "Aj" in _name:
            raw_script_name = vo_k.get("name", "")
            filter_name = get_filter_name(raw_script_name)
            object_content.append(f"effect.name={filter_name}")
        else:
            object_content.append(f"effect.name={_name}")
            
        is_shape = (_name == "図形")
        shape_params = {}
        for key, val in vo_k.items():
            if key in ["_name", "name", "param", "text"]:
                continue
            shape_params[key] = val
            
        params = parse_param(vo_k.get("param", ""))
        for key, val in params.items():
            shape_params[key] = val
            
        # Write mapped parameters
        for key, val in shape_params.items():
            if is_shape:
                if key == "type":
                    shape_map = {
                        "0": "円",
                        "1": "四角形",
                        "2": "三角形",
                        "3": "五角形",
                        "4": "六角形",
                        "5": "星型"
                    }
                    mapped_type = shape_map.get(val, "円")
                    object_content.append(f"図形の種類={mapped_type}")
                    continue
                elif key == "color":
                    object_content.append(f"色={val}")
                    continue
            object_content.append(f"{key}={val}")
            
        if is_shape:
            written_keys = [line.split("=", 1)[0] for line in object_content[-len(shape_params):]]
            if "図形の種類" not in written_keys:
                object_content.append("図形の種類=円")
            if "色" not in written_keys:
                object_content.append("色=ffffff")
            object_content.append("角を丸くする=0")
            
        if _name == "スクリプト制御" or "XKNvg" in _name:
            hex_text = vo_k.get("text", "")
            decoded_text = decode_hex_text(hex_text)
            if decoded_text:
                formatted_text = f"<?{decoded_text}?>"
                object_content.append(f"text={formatted_text}")
                object_content.append(f"スクリプト={formatted_text}")
                
        k += 1
        
    try:
        with open(dest_path, "w", encoding="utf-8") as out_f:
            out_f.write("\n".join(object_content) + "\n")
        print(f"Created Object Alias: {dest_filename}")
    except Exception as e:
        print(f"Failed to create Object Alias: {dest_filename}: {e}")

for folder_dir in [obj_alias_dir, obj_preset_dir]:
    if folder_dir and os.path.exists(folder_dir):
        for f in os.listdir(folder_dir):
            if f.endswith(".exa"):
                convert_object_alias(folder_dir, f)

# Update aviutl2.ini to set label=RtAv2 for the deployed objects and custom effects
def update_aviutl2_ini(object_names, effect_names=None, label_name="RtAv2"):
    ini_path = os.path.join(aviutl_dir, "aviutl2.ini")
    if not os.path.exists(ini_path):
        print(f"aviutl2.ini not found at {ini_path}")
        return
        
    with open(ini_path, "rb") as f:
        raw_data = f.read()
    
    # Detect encoding: Check BOM for UTF-8 first, otherwise default to CP932 (Shift_JIS)
    if raw_data.startswith(b'\xef\xbb\xbf'):
        encoding = "utf-8"
        text = raw_data.decode("utf-8")
    else:
        try:
            text = raw_data.decode("cp932")
            encoding = "cp932"
        except Exception:
            text = raw_data.decode("utf-8", errors="replace")
            encoding = "utf-8"
            
    if not text:
        print("Failed to decode aviutl2.ini")
        return
        
    lines = text.splitlines()
    new_lines = []
    updated_sections = set()
    i = 0
    
    remove_sections = set()
    
    while i < len(lines):
        line = lines[i]
        line_strip = line.strip()
        
        if line_strip.startswith("[") and line_strip.endswith("]"):
            current_sec = line_strip[1:-1].strip()
            
            # If this section is to be removed, skip it entirely
            if current_sec in remove_sections:
                i += 1
                while i < len(lines):
                    next_line = lines[i]
                    next_line_strip = next_line.strip()
                    if next_line_strip.startswith("[") and next_line_strip.endswith("]"):
                        i -= 1
                        break
                    i += 1
                i += 1
                continue
                
            new_lines.append(line)
            
            is_target = False
            obj_name = None
            if current_sec.startswith("Effect.object."):
                obj_name = current_sec[len("Effect.object."):]
                if obj_name in object_names:
                    is_target = True
            elif current_sec.startswith("Effect."):
                eff_name = current_sec[len("Effect."):]
                if effect_names and eff_name in effect_names:
                    is_target = True
                    obj_name = eff_name
                    
            if is_target:
                updated_sections.add(obj_name)
                i += 1
                has_label = False
                has_hide = False
                
                sec_lines = []
                while i < len(lines):
                    next_line = lines[i]
                    next_line_strip = next_line.strip()
                    if next_line_strip.startswith("[") and next_line_strip.endswith("]"):
                        i -= 1
                        break
                    
                    if next_line_strip.startswith("label="):
                        sec_lines.append(f"label={label_name}")
                        has_label = True
                    elif next_line_strip.startswith("hide="):
                        sec_lines.append(next_line)
                        has_hide = True
                    else:
                        sec_lines.append(next_line)
                    i += 1
                
                if not has_label:
                    sec_lines.append(f"label={label_name}")
                if not has_hide:
                    sec_lines.append("hide=0")
                    
                new_lines.extend(sec_lines)
            else:
                pass
        else:
            new_lines.append(line)
        i += 1
        
    missing_sections = (set(object_names) | (set(effect_names) if effect_names else set())) - updated_sections
    # Remove any sections from missing_sections that are in remove_sections
    missing_sections = {sec for sec in missing_sections if f"Effect.{sec}" not in remove_sections and f"Effect.object.{sec}" not in remove_sections}
    
    if missing_sections:
        max_order = 0
        for line in lines:
            if line.strip().startswith("order="):
                try:
                    order_val = int(line.strip().split("=", 1)[1])
                    if order_val > max_order:
                        max_order = order_val
                except:
                    pass
                    
        for sec_item in missing_sections:
            max_order += 2
            new_lines.append("")
            if sec_item in object_names:
                new_lines.append(f"[Effect.object.{sec_item}]")
            else:
                new_lines.append(f"[Effect.{sec_item}]")
            new_lines.append(f"label={label_name}")
            new_lines.append("hide=0")
            new_lines.append(f"order={max_order}")
            print(f"Appended new section for {sec_item} to aviutl2.ini")
            
    new_text = "\r\n".join(new_lines) + "\r\n"
    try:
        with open(ini_path, "wb") as f:
            f.write(new_text.encode(encoding))
        print(f"Successfully updated aviutl2.ini for objects and effects with label '{label_name}'")
    except Exception as e:
        print(f"Failed to update aviutl2.ini: {e}")

effects_to_label = [
    "反転@RtAv2(エフェクト)",
    "座標@RtAv2(エフェクト)",
    "回転@RtAv2(エフェクト)",
    "拡大率@RtAv2(エフェクト)",
    "透明度@RtAv2(エフェクト)",
    "ラスター@RtAv2(エフェクト)",
    "方向ブラー@RtAv2(エフェクト)",
    "グロー@RtAv2(エフェクト)",
    "クリッピング@RtAv2(エフェクト)",
    "斜めクリッピング@RtAv2(エフェクト)"
]
update_aviutl2_ini(created_object_names, effect_names=effects_to_label)

print("Deployment and Conversion successfully completed!")
