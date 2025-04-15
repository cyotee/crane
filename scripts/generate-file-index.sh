#!/bin/bash

# Generate file index for project structure
echo "# File Index" > memory-bank/file-index.md
echo "" >> memory-bank/file-index.md

# Solidity Files
echo "## Solidity Files" >> memory-bank/file-index.md
find . -type f -name "*.sol" ! -path "./node_modules/*" ! -path "./build/*" ! -path "./dist/*" >> memory-bank/file-index.md
echo "" >> memory-bank/file-index.md

# TypeScript Files
echo "## TypeScript Files" >> memory-bank/file-index.md
find . -type f -name "*.ts" ! -path "./node_modules/*" ! -path "./build/*" ! -path "./dist/*" >> memory-bank/file-index.md
echo "" >> memory-bank/file-index.md

# Documentation
echo "## Documentation" >> memory-bank/file-index.md
find . -type f -name "*.md" ! -path "./node_modules/*" ! -path "./build/*" ! -path "./dist/*" >> memory-bank/file-index.md
echo "" >> memory-bank/file-index.md