
import os

fp = 'lib/screens/ai_insights_screen.dart'
if os.path.exists(fp):
    with open(fp, 'r', encoding='utf-8') as f:
        data = f.read()

    data = data.replace('copyWith(size:', 'copyWith(fontSize:')
    if 'precision_core.dart' not in data:
        data = data.replace('import \'../widgets/precision_core.dart\';\n', '')
        data = data.replace('import \'../theme/app_theme.dart\';', 'import \'../theme/app_theme.dart\';\nimport \'../widgets/precision_core.dart\';')
        
    with open(fp, 'w', encoding='utf-8') as f:
        f.write(data)
