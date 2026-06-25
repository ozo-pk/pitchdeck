import os
import re

files = [
    r"public\index.html",
    r"public\login.html",
    r"public\admin\dashboard.html",
    r"public\judge\panel.html",
    r"public\student\portal.html"
]

tailwind_config = """<script src="https://cdn.tailwindcss.com"></script>
  <script>
    tailwind.config = {
      theme: {
        extend: {
          colors: {
            'grey-olive': {
              "50": "#f1f3f3", "100": "#e3e8e7", "200": "#c7d1cf", "300": "#acb9b7",
              "400": "#90a29f", "500": "#748b87", "600": "#5d6f6c", "700": "#465351",
              "800": "#2e3836", "900": "#171c1b", "950": "#101313"
            },
            'muted-teal': {
              "50": "#eff5f0", "100": "#dfece2", "200": "#bfd9c5", "300": "#9fc6a8",
              "400": "#80b38b", "500": "#609f6d", "600": "#4d8058", "700": "#396042",
              "800": "#26402c", "900": "#132016", "950": "#0d160f"
            },
            'tea-green': {
              "50": "#f2ffe6", "100": "#e6fecd", "200": "#ccfd9b", "300": "#b3fd68",
              "400": "#99fc36", "500": "#80fb04", "600": "#66c903", "700": "#4d9702",
              "800": "#336402", "900": "#1a3201", "950": "#122301"
            }
          }
        }
      }
    }
  </script>"""

for fpath in files:
    full_path = os.path.join(os.getcwd(), fpath)
    if not os.path.exists(full_path):
        print(f"Skipping {full_path}")
        continue
        
    with open(full_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Inject config if not already there
    if "tailwind.config =" not in content:
        content = content.replace('<script src="https://cdn.tailwindcss.com"></script>', tailwind_config)
    
    # Replace colors
    # slate -> grey-olive
    content = re.sub(r'\bslate-', 'grey-olive-', content)
    # gray -> grey-olive (just in case)
    content = re.sub(r'\bgray-', 'grey-olive-', content)
    
    # indigo -> muted-teal
    content = re.sub(r'\bindigo-', 'muted-teal-', content)
    # blue -> muted-teal
    content = re.sub(r'\bblue-', 'muted-teal-', content)
    
    # emerald -> tea-green
    content = re.sub(r'\bemerald-', 'tea-green-', content)
    # green -> tea-green
    content = re.sub(r'\bgreen-', 'tea-green-', content)

    with open(full_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Updated {full_path}")
