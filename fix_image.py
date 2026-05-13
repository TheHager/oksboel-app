import re

with open('lib/main.dart', 'r') as f:
    content = f.read()

content = content.replace("Image.network(imageUrl: billedeUrl,", "Image.network(billedeUrl,")
content = content.replace("Image.network(imageUrl: _ikonUrl,", "Image.network(_ikonUrl,")
content = content.replace("Image.network(imageUrl: widget.begivenhed['billede'],", "Image.network(widget.begivenhed['billede'],")

with open('lib/main.dart', 'w') as f:
    f.write(content)
