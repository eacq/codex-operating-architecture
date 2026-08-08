from pathlib import Path
from zipfile import ZipFile
from lxml import etree
import re
import sys

W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
NS = {"w": W}
Q = lambda tag: f"{{{W}}}{tag}"
CIT_RE = re.compile(r"\[[1-9][0-9]*(?:[-,，][1-9][0-9]*)*\]")


def text_of(el):
    return "".join(t.text or "" for t in el.xpath(".//w:t", namespaces=NS))


def is_super(run):
    va = run.find(".//w:vertAlign", NS)
    return va is not None and va.get(Q("val")) == "superscript"


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: python audit_citations_refs.py manuscript.docx")
    docx = Path(sys.argv[1])
    with ZipFile(docx) as z:
        root = etree.fromstring(z.read("word/document.xml"))
    body = root.find("w:body", NS)
    in_refs = False
    body_hits = 0
    body_not_super = []
    ref_super = []
    interval_super = []
    for i, p in enumerate(body.findall("w:p", NS)):
        ptxt = text_of(p)
        if "参考文献" in ptxt:
            in_refs = True
        if "[0,1]" in ptxt:
            for r in p.findall(Q("r")):
                if "[0,1]" in text_of(r) and is_super(r):
                    interval_super.append(i)
        for r in p.findall(Q("r")):
            rtxt = text_of(r)
            if not CIT_RE.search(rtxt):
                continue
            if in_refs:
                if is_super(r):
                    ref_super.append((i, rtxt))
            else:
                body_hits += len(CIT_RE.findall(rtxt))
                if not is_super(r):
                    body_not_super.append((i, rtxt, ptxt[:120]))
    print(f"body_citation_runs={body_hits}")
    print(f"body_not_superscript={len(body_not_super)}")
    print(f"reference_superscript_runs={len(ref_super)}")
    print(f"math_interval_superscript={len(interval_super)}")
    if body_not_super:
        print("body_not_superscript_sample=", body_not_super[:10])
    if ref_super:
        print("reference_superscript_sample=", ref_super[:10])


if __name__ == "__main__":
    main()
