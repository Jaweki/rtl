#!/bin/sh
# Rebuild the waveform pictures and the PDF from the markdown guide.
# Needs: iverilog, python3-matplotlib, pandoc, wkhtmltopdf, python3 pypdf + reportlab
cd "$(dirname "$0")" || exit 1
python3 gen_waveforms.py || exit 1
pandoc RV32I-components-guide.md -s --toc --toc-depth=1 --metadata toc-title="Contents" \
  --embed-resources --css guide-style.css --resource-path=. -o /tmp/guide.html || exit 1
wkhtmltopdf --enable-local-file-access --page-size A4 -T 16mm -B 18mm -L 14mm -R 14mm --quiet \
  /tmp/guide.html RV32I-components-guide.pdf
python3 - <<'PY'
import io
from pypdf import PdfReader, PdfWriter
from reportlab.pdfgen import canvas
r = PdfReader("RV32I-components-guide.pdf"); w = PdfWriter(); n = len(r.pages)
for i, pg in enumerate(r.pages, 1):
    W, H = float(pg.mediabox.width), float(pg.mediabox.height)
    buf = io.BytesIO(); c = canvas.Canvas(buf, pagesize=(W, H)); c.setFont("Helvetica", 8); c.setFillGray(0.4)
    c.drawCentredString(W / 2, 22, f"RV32I Components Guide  -  page {i} of {n}"); c.save(); buf.seek(0)
    pg.merge_page(PdfReader(buf).pages[0]); w.add_page(pg)
w.add_metadata({"/Title": "RV32I Processor Core: Components Guide"})
w.write("RV32I-components-guide.pdf"); print("pages:", n)
PY
