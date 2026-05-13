with open('lib/main.dart', 'r') as f:
    content = f.read()

import re

# `placeholder` is invalid on Image.network. We must remove it.
# The user's original code in 209f12c did NOT have placeholder. I added it when switching to CachedNetworkImage.
content = re.sub(r'placeholder: \(context, url\) =>[\s\S]*?errorBuilder:', 'errorBuilder:', content)

with open('lib/main.dart', 'w') as f:
    f.write(content)
