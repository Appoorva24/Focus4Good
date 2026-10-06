import re
import os

path = os.path.abspath('Focus4Good/Stores/CommunityStore.swift')

with open(path, 'r') as f:
    content = f.read()

# For functions that return void
content = re.sub(r'catch \{\s*errorMessage = "Failed to (load|join|remove|accept|reject|leave|create|delete|add|transfer|dissolve|update|seed)(.*?): \\\(error\.localizedDescription\)"\s*\}',
                 r'catch {\n            if error is CancellationError { return }\n            errorMessage = "Failed to \1\2: \\(error.localizedDescription)"\n        }',
                 content)

# For fetchProfiles (returns [])
content = re.sub(r'catch \{\s*errorMessage = "Failed to fetch profiles: \\\(error\.localizedDescription\)"\s*return \[\]\s*\}',
                 r'catch {\n            if error is CancellationError { return [] }\n            errorMessage = "Failed to fetch profiles: \\(error.localizedDescription)"\n            return []\n        }',
                 content)

with open(path, 'w') as f:
    f.write(content)
