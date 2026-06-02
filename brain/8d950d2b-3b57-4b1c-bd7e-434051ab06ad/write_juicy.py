import os
import re

root_dir = r"c:\Users\Public\Documents\ideaspace\kingslayer_flutter\lib"
output_file = r"c:\Users\Public\Documents\ideaspace\kingslayer_flutter\brain\8d950d2b-3b57-4b1c-bd7e-434051ab06ad\all_juicy_instances.txt"

with open(output_file, "w", encoding="utf-8") as out:
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith(".dart"):
                filepath = os.path.join(dirpath, filename)
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                
                lines = content.splitlines()
                for idx, line in enumerate(lines):
                    if "JuicyGlassCard" in line:
                        out.write(f"--- {filepath} : {idx+1}\n")
                        for j in range(max(0, idx - 2), min(len(lines), idx + 8)):
                            out.write(f"  {j+1}: {lines[j]}\n")
                        out.write("\n")
