# File Tool Profiles

Use these profiles as recorded project intent first. Apply package installation only after the external dependency notice required by the architecture policy.

## office-media-basic

- `python-docx`: DOCX creation and update support. Source checked 2026-07-15: <https://python-docx.readthedocs.io/en/latest/>.
- `python-pptx`: PPTX creation, reading, update, text/image extraction, and no PowerPoint installation requirement for supported operations. Source checked 2026-07-15: <https://python-pptx.readthedocs.io/en/latest/>.
- `pypdf`: PDF text extraction, metadata, attachments, merge, annotations, encryption/decryption, and related pure-Python PDF operations. Source checked 2026-07-15: <https://pypdf.readthedocs.io/en/stable/>.
- `Pillow`: image opening, metadata, validation, conversion, and resizing. Source checked 2026-07-15: <https://pillow.readthedocs.io/en/stable/>.

## pdf-layout-advanced

- `PyMuPDF`: advanced PDF rendering, extraction, annotation, and page-image workflows. Source checked 2026-07-15: <https://pymupdf.readthedocs.io/en/latest/>.

## document-markdown-ai

- `markitdown`: Microsoft-maintained conversion tool for files and Office documents to Markdown. Source checked 2026-07-15: <https://github.com/microsoft/markitdown>.
- `docling`: document preparation and conversion for gen-AI workflows. Source checked 2026-07-15: <https://github.com/docling-project/docling>.

## Secret input pattern

- Use PowerShell `Read-Host -AsSecureString` for hidden console entry and `ConvertFrom-SecureString` for Windows DPAPI-backed local encryption. Sources checked 2026-07-15: <https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/read-host> and <https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/convertfrom-securestring>.
- Generated `*.dpapi` files are machine/user-bound local state and must not enter Git.
