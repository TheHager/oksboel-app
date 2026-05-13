with open('lib/main.dart', 'r') as f:
    content = f.read()

# Replace any CachedNetworkImage with Image.network
content = content.replace("CachedNetworkImage(", "Image.network(")
content = content.replace("import 'package:cached_network_image/cached_network_image.dart';", "")

import re
# We need to change errorWidget to errorBuilder
content = re.sub(
    r'errorWidget:\s*\(context, url, error\) =>',
    r'errorBuilder: (context, error, stackTrace) =>',
    content
)

# And replace `PlatformAwareImage` with `Image.network` if there is any remaining
content = content.replace("PlatformAwareImage(", "Image.network(")
content = content.replace("import 'utils/platform_aware_image.dart';", "")

with open('lib/main.dart', 'w') as f:
    f.write(content)

with open('pubspec.yaml', 'r') as f:
    pubspec = f.read()

pubspec = pubspec.replace("  cached_network_image: ^3.4.1\n", "")

with open('pubspec.yaml', 'w') as f:
    f.write(pubspec)
