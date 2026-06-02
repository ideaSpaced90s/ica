import os
import re

root_dir = r"c:\Users\Public\Documents\ideaspace\kingslayer_flutter\lib"
output_file = r"c:\Users\Public\Documents\ideaspace\kingslayer_flutter\brain\8d950d2b-3b57-4b1c-bd7e-434051ab06ad\matching_widgets.txt"

with open(output_file, "w", encoding="utf-8") as out:
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith(".dart"):
                filepath = os.path.join(dirpath, filename)
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                
                # Look for files containing a Row that might be inside a Column inside a Padding inside a Container/DecoratedBox
                # We can search for files that have Row, Column, Padding, Container
                if "Row" in content and "Column" in content and "Padding" in content and "Container" in content:
                    out.write(f"Candidate: {filepath}\n")
