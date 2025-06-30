import sys
import zipfile
import os
import shutil

def normalize_zip(input_zip, output_zip):
    temp_dir = "__zip_temp__"

    with zipfile.ZipFile(input_zip, 'r') as zip_ref:
        zip_ref.extractall(temp_dir)

    with zipfile.ZipFile(output_zip, 'w', zipfile.ZIP_DEFLATED) as new_zip:
        for root, dirs, files in os.walk(temp_dir):
            for file in files:
                full_path = os.path.join(root, file)
                arcname = os.path.relpath(full_path, temp_dir).replace("\\", "/")
                new_zip.write(full_path, arcname)

    shutil.rmtree(temp_dir)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python fix_zip_paths.py <zip_path>")
    else:
        zip_path = sys.argv[1]
        normalize_zip(zip_path, zip_path)
