import zipfile
import xml.etree.ElementTree as ET
import sys
import os

def read_docx(file_path):
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    try:
        with zipfile.ZipFile(file_path) as docx:
            xml_content = docx.read('word/document.xml')
            root = ET.fromstring(xml_content)
            
            # The namespace for Word XML elements
            ns = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
            
            paragraphs = []
            for paragraph in root.iter('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}p'):
                texts = [node.text for node in paragraph.iter('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}t') if node.text]
                if texts:
                    paragraphs.append(''.join(texts))
            
            full_text = '\n'.join(paragraphs)
            with open("docx_content.txt", "w", encoding="utf-8") as f:
                f.write(full_text)
            print("Successfully wrote docx content to docx_content.txt")
    except Exception as e:
        print(f"Error reading docx: {e}")

if __name__ == "__main__":
    file_path = r"c:\Users\Lenovo\OneDrive\Desktop\fluuter\cycle\cahier_des_charges_cyclia.docx"
    read_docx(file_path)
