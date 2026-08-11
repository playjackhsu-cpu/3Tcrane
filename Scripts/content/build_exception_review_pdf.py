#!/usr/bin/env python3
"""Build the private, formal PDF report for question-bank review exceptions."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    KeepTogether,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[2]
PRIVATE_ROOT = ROOT / "PrivateResources/QuestionBank-Inbox"
INVENTORY_PATH = PRIVATE_ROOT / "official-question-inventory.json"
EXCLUSIONS_PATH = PRIVATE_ROOT / "review-exclusions.json"
DEFAULT_OUTPUT = ROOT / "output/pdf/3Tcrane-題庫未納入與答案法規衝突審查報告.pdf"
SUBMISSION_OUTPUT = ROOT / "output/pdf/固定式起重機操作學科題庫疑義詢問文件.pdf"
REPORT_DATE = "2026-08-11"

FONT_CANDIDATES = (
    Path("/System/Library/AssetsV2/com_apple.MobileAsset_Font8/86ba2c91f017a3749571a82f2c6d890ac7ffb2fb.asset/AssetData/PingFang.ttc"),
    Path("/System/Library/Fonts/STHeiti Light.ttc"),
    Path("/System/Library/Fonts/Supplemental/Arial Unicode.ttf"),
    Path("/Library/Fonts/Arial Unicode.ttf"),
)

CATEGORY_LABELS = {
    "official-deleted": "官方刪題",
    "hard-answer-conflict": "明顯答案或題意衝突",
    "regulatory-transition-hold": "法規修正生效過渡期",
}

CATEGORY_ORDER = (
    "official-deleted",
    "hard-answer-conflict",
    "regulatory-transition-hold",
)


def register_cjk_font() -> str:
    for path in FONT_CANDIDATES:
        if not path.is_file():
            continue
        try:
            pdfmetrics.registerFont(TTFont("ReviewCJK", str(path), subfontIndex=0))
            return "ReviewCJK"
        except Exception:
            continue
    raise RuntimeError("No compatible Traditional Chinese font was found.")


def clean_prompt(prompt: str) -> str:
    return re.sub(r"^\s*\(本題刪題\s*\)\s*", "", prompt).strip()


def safe(value: object) -> str:
    text = str(value if value is not None else "")
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def build_styles(font_name: str) -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    return {
        "cover_title": ParagraphStyle(
            "CoverTitle",
            parent=base["Title"],
            fontName=font_name,
            fontSize=23,
            leading=32,
            textColor=colors.HexColor("#17324D"),
            alignment=TA_CENTER,
            spaceAfter=12 * mm,
        ),
        "cover_subtitle": ParagraphStyle(
            "CoverSubtitle",
            parent=base["Normal"],
            fontName=font_name,
            fontSize=12,
            leading=20,
            textColor=colors.HexColor("#455A64"),
            alignment=TA_CENTER,
        ),
        "h1": ParagraphStyle(
            "H1",
            parent=base["Heading1"],
            fontName=font_name,
            fontSize=17,
            leading=24,
            textColor=colors.HexColor("#17324D"),
            spaceBefore=4 * mm,
            spaceAfter=4 * mm,
        ),
        "h2": ParagraphStyle(
            "H2",
            parent=base["Heading2"],
            fontName=font_name,
            fontSize=13,
            leading=19,
            textColor=colors.HexColor("#00695C"),
            spaceBefore=4 * mm,
            spaceAfter=3 * mm,
        ),
        "body": ParagraphStyle(
            "Body",
            parent=base["BodyText"],
            fontName=font_name,
            fontSize=9.5,
            leading=15,
            textColor=colors.HexColor("#263238"),
            alignment=TA_LEFT,
        ),
        "small": ParagraphStyle(
            "Small",
            parent=base["BodyText"],
            fontName=font_name,
            fontSize=8,
            leading=12,
            textColor=colors.HexColor("#546E7A"),
        ),
        "label": ParagraphStyle(
            "Label",
            parent=base["BodyText"],
            fontName=font_name,
            fontSize=8.5,
            leading=13,
            textColor=colors.HexColor("#17324D"),
        ),
        "value": ParagraphStyle(
            "Value",
            parent=base["BodyText"],
            fontName=font_name,
            fontSize=8.7,
            leading=13.5,
            textColor=colors.HexColor("#263238"),
        ),
        "summary_number": ParagraphStyle(
            "SummaryNumber",
            parent=base["BodyText"],
            fontName=font_name,
            fontSize=15,
            leading=20,
            textColor=colors.HexColor("#00695C"),
            alignment=TA_CENTER,
        ),
        "summary_label": ParagraphStyle(
            "SummaryLabel",
            parent=base["BodyText"],
            fontName=font_name,
            fontSize=8,
            leading=12,
            textColor=colors.HexColor("#455A64"),
            alignment=TA_CENTER,
        ),
    }


class ReviewDocTemplate(BaseDocTemplate):
    def __init__(self, filename: str, font_name: str, **kwargs: object) -> None:
        super().__init__(filename, **kwargs)
        frame = Frame(
            self.leftMargin,
            self.bottomMargin,
            self.width,
            self.height,
            id="content",
        )
        self.addPageTemplates(
            PageTemplate(id="review", frames=[frame], onPage=self.draw_page)
        )
        self.font_name = font_name

    def draw_page(self, canvas: object, doc: object) -> None:
        canvas.saveState()
        canvas.setFont(self.font_name, 7.5)
        canvas.setFillColor(colors.HexColor("#607D8B"))
        if doc.page > 1:
            canvas.drawString(18 * mm, A4[1] - 12 * mm, "3Tcrane 題庫內容治理 - 私有審查文件")
            canvas.drawRightString(A4[0] - 18 * mm, A4[1] - 12 * mm, f"文件日期 {REPORT_DATE}")
            canvas.setStrokeColor(colors.HexColor("#CFD8DC"))
            canvas.line(18 * mm, A4[1] - 15 * mm, A4[0] - 18 * mm, A4[1] - 15 * mm)
        canvas.setStrokeColor(colors.HexColor("#CFD8DC"))
        canvas.line(18 * mm, 14 * mm, A4[0] - 18 * mm, 14 * mm)
        canvas.drawString(18 * mm, 9 * mm, "治理狀態：內部審查用，不得直接公開或作為正式考試答案依據")
        canvas.drawRightString(A4[0] - 18 * mm, 9 * mm, f"第 {doc.page} 頁")
        canvas.restoreState()


class InquiryDocTemplate(BaseDocTemplate):
    def __init__(self, filename: str, font_name: str, **kwargs: object) -> None:
        super().__init__(filename, **kwargs)
        frame = Frame(
            self.leftMargin,
            self.bottomMargin,
            self.width,
            self.height,
            id="content",
        )
        self.addPageTemplates(
            PageTemplate(id="inquiry", frames=[frame], onPage=self.draw_page)
        )
        self.font_name = font_name

    def draw_page(self, canvas: object, doc: object) -> None:
        canvas.saveState()
        canvas.setFont(self.font_name, 7.5)
        canvas.setFillColor(colors.HexColor("#52616B"))
        if doc.page > 1:
            canvas.drawString(18 * mm, A4[1] - 12 * mm, "固定式起重機操作學科參考題目疑義詢問")
            canvas.drawRightString(A4[0] - 18 * mm, A4[1] - 12 * mm, f"資料核對日 {REPORT_DATE}")
            canvas.setStrokeColor(colors.HexColor("#CBD5E1"))
            canvas.line(18 * mm, A4[1] - 15 * mm, A4[0] - 18 * mm, A4[1] - 15 * mm)
        canvas.setStrokeColor(colors.HexColor("#CBD5E1"))
        canvas.line(18 * mm, 14 * mm, A4[0] - 18 * mm, 14 * mm)
        canvas.drawString(18 * mm, 9 * mm, "用途：提交命題／題庫維護單位協助確認")
        canvas.drawRightString(A4[0] - 18 * mm, 9 * mm, f"第 {doc.page} 頁")
        canvas.restoreState()


def summary_box(styles: dict[str, ParagraphStyle], values: list[tuple[str, int]]) -> Table:
    row1 = [Paragraph(str(count), styles["summary_number"]) for _, count in values]
    row2 = [Paragraph(label, styles["summary_label"]) for label, _ in values]
    table = Table([row1, row2], colWidths=[40 * mm] * len(values))
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F1F7F6")),
                ("BOX", (0, 0), (-1, -1), 0.7, colors.HexColor("#A7C7C2")),
                ("INNERGRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#D8E6E3")),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("TOPPADDING", (0, 0), (-1, 0), 5),
                ("BOTTOMPADDING", (0, 1), (-1, 1), 6),
            ]
        )
    )
    return table


def location_text(question: dict[str, object], scan: bool) -> str:
    source = question["sourceLocator"]
    work_item = f"工作項 {question['workItemCode']}「{question['workItemName']}」"
    number = source["questionNumber"]
    if scan:
        cross = source["scanCrossReference"]
        side = "左頁" if cross["spreadSide"] == "left" else "右頁"
        return (
            f"掃描檔題庫.pdf：PDF 第 {cross['pdfPage']} 頁（{side}），"
            f"書本印刷第 {cross['printedPage']} 頁；{work_item}第 {number} 題"
        )
    return (
        f"{source['officialFile']}：PDF 第 {source['officialPdfPage']} 頁，"
        f"官方印刷第 {source['officialPrintedPage']} 頁；{work_item}第 {number} 題"
    )


def record_block(
    number: int,
    exclusion: dict[str, object],
    question: dict[str, object],
    styles: dict[str, ParagraphStyle],
) -> KeepTogether:
    category = CATEGORY_LABELS[exclusion["category"]]
    prompt = clean_prompt(question["transcription"]["prompt"])
    conflict = question["verification"].get("answerConflict") or exclusion.get("reason")
    if exclusion["category"] == "official-deleted":
        conflict = (
            "主管機關最新下載版本已將本題標示為刪題。題目與原印刷答案僅保留於完整歷史清冊供版本追溯，"
            "不得進入練習、模擬測驗或正式發行題數。"
        )
    disposition = exclusion.get("releaseDecision") or exclusion.get("disposition") or "暫停納入候選抽題池"
    header = Paragraph(
        f"{number:02d}. {safe(category)} - <font color='#607D8B'>{safe(question['questionId'])}</font>",
        styles["h2"],
    )
    rows = [
        [Paragraph("掃描書本頁碼／題號", styles["label"]), Paragraph(safe(location_text(question, True)), styles["value"])],
        [Paragraph("官方下載頁碼／題號", styles["label"]), Paragraph(safe(location_text(question, False)), styles["value"])],
        [Paragraph("題目名稱", styles["label"]), Paragraph(safe(prompt), styles["value"])],
        [Paragraph("錯誤內容", styles["label"]), Paragraph(safe(conflict), styles["value"])],
        [Paragraph("現行處置", styles["label"]), Paragraph(safe(disposition), styles["value"])],
    ]
    table = Table(rows, colWidths=[35 * mm, 132 * mm], repeatRows=0, hAlign="LEFT")
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#EEF3F5")),
                ("BOX", (0, 0), (-1, -1), 0.7, colors.HexColor("#B0BEC5")),
                ("INNERGRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#CFD8DC")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    return KeepTogether([header, table, Spacer(1, 4 * mm)])


def inquiry_sources(question: dict[str, object], styles: dict[str, ParagraphStyle]) -> Paragraph:
    sources = question["verification"].get("publicSources") or []
    if not sources:
        return Paragraph("主管機關官方下載題庫（詳本文件來源頁）", styles["value"])
    lines = []
    for source in sources:
        title = safe(source.get("title") or "參考來源")
        url = safe(source.get("url") or "")
        checked_at = safe(source.get("checkedAt") or "")
        suffix = f"（核對：{checked_at}）" if checked_at else ""
        if url:
            lines.append(f"{title}{suffix}<br/><font size='7' color='#52616B'>{url}</font>")
        else:
            lines.append(f"{title}{suffix}")
    return Paragraph("<br/>".join(lines), styles["value"])


def external_conflict_text(value: object) -> str:
    text = str(value if value is not None else "")
    replacements = {
        "不得以推測改套情境。": "因此需確認本題原擬適用的是哪一種人行道情境。",
        "必須停用或改版。": "現有四個選項可能無法對應修正後規定。",
        "發版前須重查適用條文與施行日期。": "因此需確認本題適用條文及修正條文的施行日期。",
    }
    for original, replacement in replacements.items():
        text = text.replace(original, replacement)
    return text


def inquiry_record_block(
    number: int,
    exclusion: dict[str, object],
    question: dict[str, object],
    styles: dict[str, ParagraphStyle],
) -> KeepTogether:
    category = (
        "答案／題意疑義"
        if exclusion["category"] == "hard-answer-conflict"
        else "法規修正施行狀態疑義"
    )
    prompt = clean_prompt(question["transcription"]["prompt"])
    options = question["transcription"].get("options") or []
    options_text = "<br/>".join(
        f"{index}. {safe(option)}" for index, option in enumerate(options, start=1)
    )
    printed_number = int(question["transcription"]["printedAnswerNumber"])
    printed_answer = options[printed_number - 1] if 0 < printed_number <= len(options) else ""
    conflict = external_conflict_text(
        question["verification"].get("answerConflict") or exclusion.get("reason")
    )
    confirmation = (
        "敬請確認本題題幹、適用情境及唯一正確答案；如已有勘誤或新版題庫，敬請提供修正內容與適用日期。"
        if exclusion["category"] == "hard-answer-conflict"
        else "敬請確認修正條文的最新施行狀態，以及施行前後本題應採答案、題文與適用日期。"
    )
    header = Paragraph(
        f"{number:02d}. {safe(category)}｜06100 工作項 {safe(question['workItemCode'])}「{safe(question['workItemName'])}」第 {question['sourceLocator']['questionNumber']} 題",
        styles["h2"],
    )
    rows = [
        [Paragraph("掃描書本頁碼／題號", styles["label"]), Paragraph(safe(location_text(question, True)), styles["value"])],
        [Paragraph("官方下載頁碼／題號", styles["label"]), Paragraph(safe(location_text(question, False)), styles["value"])],
        [Paragraph("題目名稱／題幹", styles["label"]), Paragraph(safe(prompt), styles["value"])],
        [Paragraph("題目選項", styles["label"]), Paragraph(options_text, styles["value"])],
        [Paragraph("官方參考答案", styles["label"]), Paragraph(f"第 {printed_number} 項：{safe(printed_answer)}", styles["value"])],
        [Paragraph("疑義／問題說明", styles["label"]), Paragraph(safe(conflict), styles["value"])],
        [Paragraph("敬請確認事項", styles["label"]), Paragraph(safe(confirmation), styles["value"])],
        [Paragraph("核對來源", styles["label"]), inquiry_sources(question, styles)],
    ]
    table = Table(rows, colWidths=[35 * mm, 132 * mm], repeatRows=0, hAlign="LEFT")
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#EEF5F8")),
                ("BOX", (0, 0), (-1, -1), 0.7, colors.HexColor("#9FB3C1")),
                ("INNERGRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#D7E0E5")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    return KeepTogether([header, table, Spacer(1, 5 * mm)])


def build_pdf(output_path: Path = DEFAULT_OUTPUT) -> None:
    if not INVENTORY_PATH.is_file() or not EXCLUSIONS_PATH.is_file():
        raise FileNotFoundError("Private reviewed inventory or exclusions manifest is missing.")

    inventory = json.loads(INVENTORY_PATH.read_text(encoding="utf-8"))
    manifest = json.loads(EXCLUSIONS_PATH.read_text(encoding="utf-8"))
    by_id = {question["questionId"]: question for question in inventory["questions"]}
    exclusions = manifest["exclusions"]
    if len(inventory["questions"]) != 1000 or len(exclusions) != 17:
        raise ValueError("Unexpected inventory or exclusion count; rebuild review reports first.")
    if len({item["questionId"] for item in exclusions}) != len(exclusions):
        raise ValueError("Duplicate question ID in exclusions manifest.")

    font_name = register_cjk_font()
    styles = build_styles(font_name)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    doc = ReviewDocTemplate(
        str(output_path),
        font_name,
        pagesize=A4,
        leftMargin=18 * mm,
        rightMargin=18 * mm,
        topMargin=20 * mm,
        bottomMargin=18 * mm,
        title="3Tcrane 題庫未納入與答案法規衝突審查報告",
        author="3Tcrane 專案內容治理",
        subject="題庫例外、雙重頁碼定位與錯誤內容",
    )

    counts = manifest["categoryCounts"]
    story = [
        Spacer(1, 28 * mm),
        Paragraph("3Tcrane 題庫", styles["cover_subtitle"]),
        Spacer(1, 5 * mm),
        Paragraph("未納入與答案／法規衝突<br/>正式審查報告", styles["cover_title"]),
        Paragraph(
            "三噸以上固定式起重機考照學習系統<br/>完整題庫例外、掃描書本與官方下載版本雙重定位",
            styles["cover_subtitle"],
        ),
        Spacer(1, 18 * mm),
        summary_box(
            styles,
            [
                ("完整私有清冊", manifest["fullInventoryCount"]),
                ("候選抽題池", manifest["candidatePoolCount"]),
                ("暫不納入", manifest["exclusionCount"]),
                ("答案／法規風險", counts["hardAnswerConflict"] + counts["regulatoryTransitionHold"]),
            ],
        ),
        Spacer(1, 18 * mm),
        Paragraph(f"文件日期：{REPORT_DATE}", styles["cover_subtitle"]),
        Spacer(1, 5 * mm),
        Paragraph("文件屬性：私有內容治理文件／非公開發行題庫", styles["cover_subtitle"]),
        PageBreak(),
        Paragraph("一、文件目的與判讀原則", styles["h1"]),
        Paragraph(
            "本報告彙整全部 17 題暫不納入候選抽題池的題目，逐題列出掃描書本與主管機關官方下載 PDF 的頁碼、題號、題目名稱及錯誤或風險內容。所有題目仍保留於 1,000 題完整私有清冊，不做實體刪除。",
            styles["body"],
        ),
        Spacer(1, 4 * mm),
        Paragraph(
            "頁碼說明：『PDF 第幾頁』是檔案檢視器的實體頁序；『印刷第幾頁』是頁面上印出的書本頁碼。掃描檔每個 PDF 頁通常包含左右兩個書頁，因此另標示左頁或右頁。",
            styles["body"],
        ),
        Spacer(1, 6 * mm),
        summary_box(
            styles,
            [
                ("官方刪題", counts["officialDeleted"]),
                ("明顯答案／題意衝突", counts["hardAnswerConflict"]),
                ("法規過渡期", counts["regulatoryTransitionHold"]),
            ],
        ),
        Spacer(1, 7 * mm),
        Paragraph("二、納入與解除原則", styles["h1"]),
        Paragraph(
            "除下列 17 題外，其餘 983 題均保留於候選抽題池。官方刪題只作版本追溯；明顯衝突題須取得主管機關勘誤或足以排除爭議的權威證據；法規過渡題須於每次 App 發版時重新核對施行日期與有效條文。不得用推測覆蓋官方印刷答案。",
            styles["body"],
        ),
        PageBreak(),
        Paragraph("三、逐題未納入與衝突明細", styles["h1"]),
    ]

    record_number = 0
    for category in CATEGORY_ORDER:
        category_items = [item for item in exclusions if item["category"] == category]
        story.append(Paragraph(CATEGORY_LABELS[category], styles["h1"]))
        for item in category_items:
            record_number += 1
            story.append(record_block(record_number, item, by_id[item["questionId"]], styles))

    story.extend(
        [
            PageBreak(),
            Paragraph("四、官方下載來源", styles["h1"]),
            Paragraph(
                "06100 固定式起重機操作單一級學科參考資料：<br/>https://owinform.wdasec.gov.tw/owInform/DLowFile/061004A13.pdf",
                styles["body"],
            ),
            Spacer(1, 4 * mm),
            Paragraph(
                "90008 環境保護共同科目：<br/>https://owinform.wdasec.gov.tw/owInform/DLowFile/900080A16.pdf",
                styles["body"],
            ),
            Spacer(1, 7 * mm),
            Paragraph("五、治理結論", styles["h1"]),
            Paragraph(
                "本報告所列 17 題已全部從候選抽題池暫停，但仍完整保留穩定 ID、原題、印刷答案、雙重頁碼定位與審查歷程。除這 17 題外，沒有因頁面不清或辨識失敗而未納入的題目。",
                styles["body"],
            ),
        ]
    )

    doc.build(story)
    print(output_path)


def build_submission_pdf(output_path: Path = SUBMISSION_OUTPUT) -> None:
    if not INVENTORY_PATH.is_file() or not EXCLUSIONS_PATH.is_file():
        raise FileNotFoundError("Private reviewed inventory or exclusions manifest is missing.")

    inventory = json.loads(INVENTORY_PATH.read_text(encoding="utf-8"))
    manifest = json.loads(EXCLUSIONS_PATH.read_text(encoding="utf-8"))
    by_id = {question["questionId"]: question for question in inventory["questions"]}
    categories = {"hard-answer-conflict", "regulatory-transition-hold"}
    exclusions = [item for item in manifest["exclusions"] if item["category"] in categories]
    if len(exclusions) != 9:
        raise ValueError("Expected exactly 9 inquiry items after excluding official-deleted questions.")
    if len({item["questionId"] for item in exclusions}) != len(exclusions):
        raise ValueError("Duplicate question ID in inquiry items.")

    font_name = register_cjk_font()
    styles = build_styles(font_name)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    doc = InquiryDocTemplate(
        str(output_path),
        font_name,
        pagesize=A4,
        leftMargin=18 * mm,
        rightMargin=18 * mm,
        topMargin=20 * mm,
        bottomMargin=18 * mm,
        title="固定式起重機操作學科題庫疑義詢問文件",
        author="題庫使用者",
        subject="06100 固定式起重機操作學科參考題目答案、題意及法規施行狀態疑義",
    )

    story = [
        Spacer(1, 22 * mm),
        Paragraph("06100 固定式起重機操作", styles["cover_subtitle"]),
        Spacer(1, 5 * mm),
        Paragraph("學科參考題目疑義<br/>彙整暨詢問文件", styles["cover_title"]),
        Paragraph(
            "針對答案／題意疑義及法規修正施行狀態<br/>敬請命題或題庫維護單位協助確認",
            styles["cover_subtitle"],
        ),
        Spacer(1, 16 * mm),
        summary_box(
            styles,
            [
                ("提報疑義合計", 9),
                ("答案／題意疑義", 5),
                ("法規施行狀態", 4),
            ],
        ),
        Spacer(1, 16 * mm),
        Paragraph(f"資料核對日：{REPORT_DATE}", styles["cover_subtitle"]),
        Spacer(1, 10 * mm),
        Table(
            [
                [Paragraph("提報人／單位", styles["label"]), Paragraph("________________________________", styles["value"])],
                [Paragraph("聯絡方式", styles["label"]), Paragraph("________________________________", styles["value"])],
                [Paragraph("送件日期", styles["label"]), Paragraph("________________________________", styles["value"])],
            ],
            colWidths=[35 * mm, 105 * mm],
            hAlign="CENTER",
            style=TableStyle(
                [
                    ("BOX", (0, 0), (-1, -1), 0.7, colors.HexColor("#B0BEC5")),
                    ("INNERGRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#CFD8DC")),
                    ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#EEF5F8")),
                    ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                    ("LEFTPADDING", (0, 0), (-1, -1), 7),
                    ("TOPPADDING", (0, 0), (-1, -1), 8),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
                ]
            ),
        ),
        PageBreak(),
        Paragraph("一、提報目的", styles["h1"]),
        Paragraph(
            "本文件依技能檢定中心官方下載之 061004A13.pdf 及掃描書本交叉核對，彙整 9 題希望由命題／題庫維護單位協助確認的學科參考題目。內容分為 5 題答案或題意疑義，以及 4 題因職業安全衛生法修正而涉及施行時點的疑義。",
            styles["body"],
        ),
        Spacer(1, 4 * mm),
        Paragraph(
            "以下說明僅為釐清題意、適用條件、答案及法規施行狀態，最終解釋及後續修訂仍以命題／題庫維護單位正式回覆為準。",
            styles["body"],
        ),
        Spacer(1, 6 * mm),
        Paragraph("二、頁碼及欄位說明", styles["h1"]),
        Paragraph(
            "「PDF 第幾頁」是檔案檢視器顯示的實體頁序；「印刷第幾頁」是頁面印出的頁碼。掃描書本每個 PDF 頁通常包含左右兩個書頁，因此另外標示左頁或右頁。官方參考答案依 061004A13.pdf 所示答案記錄。",
            styles["body"],
        ),
        Spacer(1, 6 * mm),
        Paragraph("三、建議回覆內容", styles["h1"]),
        Paragraph(
            "敬請逐題確認：(1) 現行唯一正確答案；(2) 題幹與選項是否需要勘誤；(3) 適用情境或條件；(4) 如涉及法規修正，修正前後答案及適用日期；(5) 如已有新版題庫，敬請提供檔名、版本或公告連結。",
            styles["body"],
        ),
        PageBreak(),
        Paragraph("四、逐題疑義明細", styles["h1"]),
    ]

    record_number = 0
    for category in ("hard-answer-conflict", "regulatory-transition-hold"):
        items = [item for item in exclusions if item["category"] == category]
        if category == "regulatory-transition-hold":
            story.append(PageBreak())
        heading = "A. 答案／題意疑義" if category == "hard-answer-conflict" else "B. 法規修正施行狀態疑義"
        story.append(Paragraph(heading, styles["h1"]))
        for item in items:
            record_number += 1
            story.append(inquiry_record_block(record_number, item, by_id[item["questionId"]], styles))

    story.extend(
        [
            PageBreak(),
            Paragraph("五、官方題庫來源", styles["h1"]),
            Paragraph(
                "技能檢定中心 06100 固定式起重機操作單一級學科參考資料：<br/>https://owinform.wdasec.gov.tw/owInform/DLowFile/061004A13.pdf",
                styles["body"],
            ),
            Spacer(1, 7 * mm),
            Paragraph("六、回覆欄", styles["h1"]),
            Paragraph(
                "命題／題庫維護單位回覆：<br/><br/>________________________________________________________________________________<br/><br/>________________________________________________________________________________<br/><br/>________________________________________________________________________________<br/><br/>________________________________________________________________________________",
                styles["body"],
            ),
            Spacer(1, 12 * mm),
            Paragraph("回覆人／單位：________________________________", styles["body"]),
            Spacer(1, 6 * mm),
            Paragraph("回覆日期：____________________________________", styles["body"]),
        ]
    )

    doc.build(story)
    print(output_path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--submission",
        action="store_true",
        help="Build the external inquiry document without deleted items or internal dispositions.",
    )
    args = parser.parse_args()
    if args.submission:
        build_submission_pdf()
    else:
        build_pdf()
