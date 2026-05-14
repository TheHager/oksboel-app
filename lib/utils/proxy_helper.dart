String getProxyUrl(String originalUrl) {
  if (originalUrl.isEmpty) {
    return originalUrl;
  }
  // If it's already using wsrv.nl or it's not http/https (e.g. data uri or local asset), ignore it
  if (originalUrl.contains('wsrv.nl') || (!originalUrl.startsWith('http://') && !originalUrl.startsWith('https://'))) {
    return originalUrl;
  }

  return 'https://wsrv.nl/?url=${Uri.encodeComponent(originalUrl)}';
}
