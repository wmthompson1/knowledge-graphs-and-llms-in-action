import os
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, HRFlowable
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []
    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()
    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            if self._pageNumber > 1:
                self.setFont("Helvetica-Bold", 8)
                self.setFillColor(colors.HexColor("#1A365D"))
                self.drawString(54, 750, "MATERIAL REQUIREMENTS PLANNING (MRP) OPERATIONAL MANUAL")
                self.setFont("Helvetica", 8)
                self.setFillColor(colors.HexColor("#718096"))
                self.drawRightString(letter[0]-54, 750, f"Page {self._pageNumber} of {num_pages}")
                self.setStrokeColor(colors.HexColor("#CBD5E0"))
                self.setLineWidth(0.5)
                self.line(54, 742, letter[0]-54, 742)
                self.line(54, 50, letter[0]-54, 50)
                self.drawString(54, 38, "CONFIDENTIAL - INTERNAL SUPPLY CHAIN USE ONLY")
            super().showPage()
        super().save()

doc_path = "generated/mrp_comprehensive_guide.pdf"
os.makedirs(os.path.dirname(doc_path), exist_ok=True)
doc = SimpleDocTemplate(doc_path, pagesize=letter, leftMargin=54, rightMargin=54, topMargin=54, bottomMargin=54)

styles = getSampleStyleSheet()
c_primary = colors.HexColor("#1A365D")
c_secondary = colors.HexColor("#2B6CB0")
c_dark = colors.HexColor("#2D3748")
c_light = colors.HexColor("#F7FAFC")
c_border = colors.HexColor("#E2E8F0")

h1 = ParagraphStyle('H1', fontName='Helvetica-Bold', fontSize=14, leading=18, textColor=c_primary, spaceAfter=10)
body = ParagraphStyle('B', fontName='Helvetica', fontSize=9, leading=13, textColor=c_dark, spaceAfter=6)
table_lbl = ParagraphStyle('TL', fontName='Helvetica-Bold', fontSize=8, leading=10, textColor=c_dark)
table_hdr = ParagraphStyle('TH', fontName='Helvetica-Bold', fontSize=8, leading=10, textColor=colors.white, alignment=1)
table_txt = ParagraphStyle('TT', fontName='Helvetica', fontSize=8, leading=10, textColor=c_dark, alignment=1)

story = []

# Page 1
story.append(Spacer(1, 150))
story.append(Paragraph("<b>Material Requirements Planning (MRP) Operational Guide</b>", ParagraphStyle('T', fontName='Helvetica-Bold', fontSize=24, leading=28, textColor=c_primary)))
story.append(Spacer(1, 20))
story.append(Paragraph("Multi-Level Time-Phased Planning Grid Manual (Levels 0, 1, and 2)", ParagraphStyle('S', fontName='Helvetica', fontSize=12, leading=16, textColor=c_secondary)))
story.append(PageBreak())

# Sections 1-10
sections = [
    ("1. Foundations of Material Requirements Planning", "This manual establishes standard protocols for running multi-level deterministic dependent demand calculations. MRP translates independent final product schedules down into structured operational instructions for base subassemblies and components without relying on localized forecasts for internal child parts."),
    ("2. Anatomy of the Time-Phased Planning Grid", "The planning grid consists of Gross Requirements, Scheduled Receipts, Projected On-Hand, Net Requirements, Planned Order Receipts, and Planned Order Releases mapped dynamically across discrete production time-buckets."),
    ("3. Mathematical Mechanics & Algorithmic Process", "Calculations perform strict chronological netting where unadjusted stock balance drafts are continuously cross-checked against safety stock thresholds. Deficits trigger lot-sized order receipts, which are then offset backward dynamically to determine correct launch release dates."),
    ("4. Concrete Worked Example: Level 0 End Item", "Assembly Alpha represents the top-tier independent demand item, utilizing an unbuffered Lot-for-Lot (LFL) heuristic over an 8-week production scope with a 1-week intrinsic assembly lead time offset."),
    ("5. The Bill of Materials (BOM) Explosion Sequence", "Parent planned order releases function as structural dependent gross demand multipliers for underlying component tiers. This architecture links discrete manufacturing sub-schedules across independent engineering bills."),
    ("6. Child Component Worked Example: Level 1", "Component Beta represents the Level 1 subassembly, featuring a 2-week lead time offset, an explicit 10-unit safety stock inventory floor, a 50-unit Fixed Order Quantity (FOQ) size, and a 50-unit opening scheduled receipt in Week 1."),
    ("7. Extending the BOM Explosion: Level 2 Raw Material", "Material Gamma is a base raw material requiring a 3.0x multiplier relative to Component Beta's planned releases. It is governed by a 1-week lead time, a 30-unit safety stock floor, 40 units initial on-hand stock, and a 150-unit order multiple constraint."),
    ("8. Advanced Lot-Sizing Methodologies & Trade-offs", "Planners balance holding costs against operational setup frequencies. Lot-for-Lot minimizing holding costs is systematically weighed against Fixed Order Quantities, Period Order Quantities, and mathematically balanced Economic Order Quantities (EOQ)."),
    ("9. System Dynamics, Nervousness, and Disruptions", "Recalculation volatility is dampened through clear structural boundaries: Frozen Zones lock short-term execution, Slushy Zones grant tactical planner adjustments, and Liquid Zones let software systems balance outer timelines."),
    ("10. Operational Verification Checklist for Planners", "Analysts complete full systemic verification of explosion multipliers, lead-time offsets, lot sizes, and safety buffers prior to authorizing order release generation for procurement networks.")
]

def get_table(type_name):
    headers = ["Row", "W1", "W2", "W3", "W4", "W5", "W6", "W7", "W8"]
    if type_name == "Alpha":
        rows = [
            ["Gross Req", "10", "15", "25", "30", "20", "45", "50", "30"],
            ["Sched Rec", "0", "0", "0", "0", "0", "0", "0", "0"],
            ["On-Hand (20)", "10", "5", "0", "0", "0", "0", "0", "0"],
            ["Net Req", "0", "0", "20", "30", "20", "45", "50", "30"],
            ["Order Rec", "0", "0", "20", "30", "20", "45", "50", "30"],
            ["Order Rel", "0", "20", "30", "20", "45", "50", "30", "0"]
        ]
    elif type_name == "Beta":
        rows = [
            ["Gross Req", "0", "40", "60", "40", "90", "100", "60", "0"],
            ["Sched Rec", "50", "0", "0", "0", "0", "0", "0", "0"],
            ["On-Hand (15)", "65", "25", "15", "25", "35", "35", "25", "25"],
            ["Net Req", "0", "0", "45", "25", "65", "75", "35", "0"],
            ["Order Rec", "0", "0", "50", "50", "100", "100", "50", "0"],
            ["Order Rel", "50", "50", "100", "100", "50", "0", "0", "0"]
        ]
    else:
        rows = [
            ["Gross Req", "150", "150", "300", "300", "150", "0", "0", "0"],
            ["Sched Rec", "0", "0", "0", "0", "0", "0", "0", "0"],
            ["On-Hand (40)", "40", "40", "40", "40", "40", "40", "40", "40"],
            ["Net Req", "140", "150", "300", "300", "150", "0", "0", "0"],
            ["Order Rec", "150", "150", "300", "300", "150", "0", "0", "0"],
            ["Order Rel", "150", "300", "300", "150", "0", "0", "0", "0"]
        ]
    data = [[Paragraph(h, table_hdr) for h in headers]]
    for r in rows:
        data.append([Paragraph(r[0], table_lbl)] + [Paragraph(val, table_txt) for val in r[1:]])
    t = Table(data, colWidths=[100] + [48]*8)
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), c_secondary),
        ('GRID', (0,0), (-1,-1), 0.5, c_border),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, c_light]),
    ]))
    return t

for i, (title, desc) in enumerate(sections, 2):
    story.append(Paragraph(title, h1))
    story.append(Paragraph(desc, body))
    if "Level 0" in title:
        story.append(get_table("Alpha"))
    elif "Level 1" in title:
        story.append(get_table("Beta"))
    elif "Level 2" in title:
        story.append(get_table("Gamma"))
    story.append(PageBreak())

doc.build(story, canvasmaker=NumberedCanvas)
print("Successfully generated exact 11 pages.")
