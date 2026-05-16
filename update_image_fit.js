const fs = require('fs');
let content = fs.readFileSync('lib/main.dart', 'utf-8');

// For Næste begivenhed
const target1 = `              SizedBox(
                height: 150,
                width: double.infinity,
                child: Image.network(
                  getProxyUrl(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),`;

const replacement1 = `              SizedBox(
                height: 150,
                width: double.infinity,
                child: Image.network(
                  getProxyUrl(imageUrl),
                  fit: BoxFit.contain,
                ),
              ),`;

content = content.replace(target1, replacement1);

// For Seneste nyt
const target2 = `                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        getProxyUrl(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),`;

const replacement2 = `                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        getProxyUrl(imageUrl),
                        fit: BoxFit.contain,
                      ),
                    ),`;

content = content.replace(target2, replacement2);

fs.writeFileSync('lib/main.dart', content);
