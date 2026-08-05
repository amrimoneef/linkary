import os
import re

def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # Replace getters with methods
    content = re.sub(r'Color get (\w+) => Get\.isDarkMode', r'Color \1(BuildContext context) => Theme.of(context).brightness == Brightness.dark', content)
    content = re.sub(r'List<Color> get (\w+) => Get\.isDarkMode', r'List<Color> \1(BuildContext context) => Theme.of(context).brightness == Brightness.dark', content)

    props = ['bgColor', 'cardColor', 'textColor', 'subTextColor', 'glowColor', 'headerGradient', 'bottomBarColor', 'inactiveIconColor']
    
    # Replace property accesses with method calls
    for prop in props:
        content = re.sub(r'(?<!Color\s)(?<!List<Color>\s)\b' + prop + r'\b(?!\()', prop + '(context)', content)

    # Some remaining Get.isDarkMode that might be hardcoded inline
    content = content.replace('Get.isDarkMode', 'Theme.of(context).brightness == Brightness.dark')

    # Now find all private methods _build... that don't take context
    method_pattern = r'(?:Widget|void|List<Widget>|PreferredSizeWidget)\s+(_\w+)\s*\((.*?)\)'
    methods = re.findall(method_pattern, content)
    
    for method, args in methods:
        if 'BuildContext context' not in args:
            # We need to add BuildContext context to definition
            new_args = 'BuildContext context' + (', ' + args if args.strip() else '')
            # Update definition
            def_pattern = r'((?:Widget|void|List<Widget>|PreferredSizeWidget)\s+' + method + r'\s*\()' + re.escape(args) + r'(\))'
            content = re.sub(def_pattern, r'\g<1>' + new_args + r'\g<2>', content)
            
            # Now update calls. Calls don't have Widget/void before them
            # Calls look like _buildSomething(...)
            # We use negative lookbehind to avoid matching the definition we just changed
            # But we already changed the definition, so it now has (BuildContext context
            # And the calls still have the old arguments or no context
            call_pattern = r'(?<!(?:Widget\s)|(?:void\s)|(?:List<Widget>\s)|(?:PreferredSizeWidget\s))\b' + method + r'\s*\('
            content = re.sub(call_pattern, method + '(context, ', content)
            
            # Clean up (context, ) -> (context)
            content = content.replace(method + '(context, )', method + '(context)')

    if content != original:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {file_path}")

for root, _, files in os.walk('lib/features'):
    for file in files:
        if file.endswith('_page.dart'):
            process_file(os.path.join(root, file))
