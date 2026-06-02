import os
import re

root_dir = r"c:\Users\Public\Documents\ideaspace\kingslayer_flutter\lib"

pattern = re.compile(r"JuicyGlassCard\(")

for dirpath, _, filenames in os.walk(root_dir):
    for filename in filenames:
        if filename.endswith(".dart"):
            filepath = os.path.join(dirpath, filename)
            with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            
            lines = content.splitlines()
            for idx, line in enumerate(lines):
                if "JuicyGlassCard" in line:
                    print(f"--- {filepath} : {idx+1}")
                    for j in range(max(0, idx - 2), min(len(lines), idx + 8)):
                        print(f"  {j+1}: {lines[j]}")
