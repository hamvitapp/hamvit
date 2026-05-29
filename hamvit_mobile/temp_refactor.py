import os; import base64
content = base64.b64decode('aW1wb3J0IG9zCgpCQVNFID0gImhhbXZpdF9tb2JpbGUvbGliL2ZlYXR1cmVzL3JlcG9ydHMvcGRmIgo=').decode()
with open('H:\\hamvit_mobile\\temp_refactor.py', 'w', encoding='utf-8') as f:
    f.write(content)
print('OK')
