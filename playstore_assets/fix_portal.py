# -*- coding: utf-8 -*-
with open('playstore_assets/build_feedback_portal.py', 'r', encoding='utf-8') as f:
    text = f.read()

import git

# Let's checkout playstore_assets/build_feedback_portal.py first to start from clean state
import subprocess
subprocess.run(['git', 'checkout', 'playstore_assets/build_feedback_portal.py'], check=True)
print("Checked out clean build_feedback_portal.py")
