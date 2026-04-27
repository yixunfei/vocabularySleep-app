from __future__ import annotations

import argparse
import csv
import json
import sqlite3
import urllib.request
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


DEFAULT_COOK_CSV_URL = (
    "https://raw.githubusercontent.com/YunYouJun/cook/main/app/data/recipe.csv"
)

MEAT_OR_SEAFOOD_CONTAINS = {"pork", "beef", "mutton", "seafood"}
ANIMAL_CONTAINS = {"pork", "beef", "mutton", "seafood", "egg", "dairy"}
HALAL_BLOCKING_CONTAINS = {"pork", "alcohol"}

CHINESE_CUISINES = (
    "浙江菜",
    "川菜",
    "粤菜",
    "鲁菜",
    "湘菜",
    "闽菜",
    "苏菜",
    "徽菜",
    "东北菜",
)
CUISINE_MARKERS = (
    *CHINESE_CUISINES,
    "西餐",
    "法式",
    "意大利",
    "西班牙",
)
WESTERN_MARKERS = (
    "西班牙",
    "意大利",
    "披萨",
    "通心粉",
    "意面",
    "土司",
    "吐司",
    "沙拉",
    "奶酪",
    "橄榄油",
)
UNMODELED_ANIMAL_TERMS = (
    "兔肉",
    "兔丁",
    "龟肉",
    "甲鱼",
    "鳖",
    "鸽",
    "鹌鹑",
    "鹿肉",
    "驴肉",
    "鹅肉",
    "肥肠",
    "牛蛙",
    "田鸡",
    "牡蛎",
    "蛤",
    "蚌",
)
SPECIFIC_PORK_TERMS = (
    "排骨",
    "猪蹄",
    "猪肝",
    "猪肚",
    "猪耳",
    "猪腰",
    "火腿",
    "培根",
    "腊肠",
    "腊肉",
    "猪油",
)
GENERIC_PORK_TERMS = (
    "猪肉",
    "瘦猪肉",
    "肥猪肉",
    "猪肉丝",
    "猪肉丁",
    "猪里脊",
    "里脊肉",
    "五花肉",
    "肉末",
    "肉馅",
    "白膘",
    "猪网油",
)
GARBLED_MARKERS = ("??", "□", "�")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Audit the Daily Choice recipe dataset for field conflicts."
    )
    parser.add_argument(
        "--library-json",
        type=Path,
        default=Path(r"D:\vocabularySleep-resources\cook_data\daily_choice_recipe_library.json"),
    )
    parser.add_argument(
        "--summary-json",
        type=Path,
        default=Path(r"D:\vocabularySleep-resources\cook_data\daily_choice_recipe_library_summary.json"),
    )
    parser.add_argument(
        "--sqlite-db",
        type=Path,
        default=Path(r"D:\vocabularySleep-resources\cook_data\daily_choice_recipe_library.db"),
    )
    parser.add_argument("--cook-csv", type=Path)
    parser.add_argument("--cook-csv-url", default=DEFAULT_COOK_CSV_URL)
    parser.add_argument(
        "--output-md",
        type=Path,
        default=Path("records/record_070_daily_choice_recipe_data_audit.md"),
    )
    parser.add_argument(
        "--output-json",
        type=Path,
        default=Path("records/record_070_daily_choice_recipe_data_audit.json"),
    )
    parser.add_argument("--sample-limit", type=int, default=12)
    args = parser.parse_args()

    library = load_json(args.library_json)
    summary = load_json(args.summary_json)
    recipes = library.get("recipes", [])
    summary_recipes = summary.get("recipes", [])
    if not isinstance(recipes, list):
        raise ValueError(f"{args.library_json} does not contain a recipe list")
    if not isinstance(summary_recipes, list):
        raise ValueError(f"{args.summary_json} does not contain a recipe list")

    cook_rows, cook_error = load_cook_csv(args.cook_csv, args.cook_csv_url)
    sqlite_stats = inspect_sqlite(args.sqlite_db)
    issue_buckets = audit_recipes(recipes, sample_limit=args.sample_limit)
    source_coverage = audit_source_coverage(
        library=library,
        recipes=recipes,
        summary_recipes=summary_recipes,
        cook_rows=cook_rows,
        sample_limit=args.sample_limit,
    )

    report: dict[str, Any] = {
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "inputs": {
            "libraryJson": str(args.library_json),
            "summaryJson": str(args.summary_json),
            "sqliteDb": str(args.sqlite_db),
            "cookCsv": str(args.cook_csv) if args.cook_csv else None,
            "cookCsvUrl": args.cook_csv_url,
            "cookCsvError": cook_error,
        },
        "stats": {
            "recipeCount": len(recipes),
            "summaryRecipeCount": len(summary_recipes),
            "cookCsvRowCount": len(cook_rows),
            "sqlite": sqlite_stats,
            "libraryStats": library.get("stats", {}),
        },
        "sourceCoverage": source_coverage,
        "issues": issue_buckets,
    }

    args.output_json.parent.mkdir(parents=True, exist_ok=True)
    args.output_md.parent.mkdir(parents=True, exist_ok=True)
    args.output_json.write_text(
        json.dumps(report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    args.output_md.write_text(render_markdown(report), encoding="utf-8")

    print(f"Wrote {args.output_md}")
    print(f"Wrote {args.output_json}")


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise ValueError(f"{path} is not a JSON object")
    return data


def load_cook_csv(path: Path | None, url: str) -> tuple[list[dict[str, str]], str | None]:
    try:
        if path is not None:
            text = path.read_text(encoding="utf-8-sig")
        else:
            request = urllib.request.Request(
                url,
                headers={"User-Agent": "vocabularySleep-recipe-audit/1.0"},
            )
            with urllib.request.urlopen(request, timeout=45) as response:
                text = response.read().decode("utf-8-sig")
        return list(csv.DictReader(text.splitlines())), None
    except Exception as error:  # pragma: no cover - network fallback path
        return [], str(error)


def inspect_sqlite(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"exists": False}
    conn = sqlite3.connect(path)
    try:
        tables = {
            row[0]: row[1]
            for row in conn.execute(
                "SELECT name, sql FROM sqlite_master WHERE type = 'table' ORDER BY name"
            )
        }
        counts: dict[str, int] = {}
        for table_name in tables:
            counts[table_name] = conn.execute(
                f"SELECT COUNT(*) FROM {table_name}"
            ).fetchone()[0]
        has_v1 = (
            "daily_choice_eat_recipe_summaries" in tables
            and "daily_choice_eat_recipe_details" in tables
        )
        has_v2 = (
            "daily_choice_recipes" in tables
            and "daily_choice_recipe_details" in tables
        )
        if has_v1 and has_v2:
            schema_mode = "v1-v2"
        elif has_v2:
            schema_mode = "v2"
        elif has_v1:
            schema_mode = "v1"
        else:
            schema_mode = "unknown"
        result: dict[str, Any] = {
            "exists": True,
            "schemaMode": schema_mode,
            "userVersion": conn.execute("PRAGMA user_version").fetchone()[0],
            "tables": counts,
            "summaryRowsWithSourceLabel": 0,
            "summaryRowsWithSourceUrl": 0,
            "detailRowsWithReferences": 0,
        }
        if has_v1:
            source_rows = conn.execute(
                """
                SELECT
                  SUM(CASE WHEN source_label IS NOT NULL AND source_label <> '' THEN 1 ELSE 0 END),
                  SUM(CASE WHEN source_url IS NOT NULL AND source_url <> '' THEN 1 ELSE 0 END)
                FROM daily_choice_eat_recipe_summaries
                """
            ).fetchone()
            reference_rows = conn.execute(
                """
                SELECT COUNT(*)
                FROM daily_choice_eat_recipe_details
                WHERE references_json IS NOT NULL
                  AND references_json <> ''
                  AND references_json <> '[]'
                """
            ).fetchone()[0]
            result.update(
                {
                    "summaryRowsWithSourceLabel": source_rows[0] or 0,
                    "summaryRowsWithSourceUrl": source_rows[1] or 0,
                    "detailRowsWithReferences": reference_rows,
                }
            )
        if has_v2 and "daily_choice_recipe_schema_meta" in tables:
            result["v2Meta"] = {
                str(row[0]): str(row[1])
                for row in conn.execute(
                    "SELECT key, value FROM daily_choice_recipe_schema_meta"
                )
            }
        return result
    finally:
        conn.close()


def audit_recipes(
    recipes: list[dict[str, Any]],
    *,
    sample_limit: int,
) -> dict[str, dict[str, Any]]:
    buckets = {
        "vegetarian_profile_conflicts_with_meat_or_seafood": issue_bucket(
            "P0",
            "profile contains vegetarian while contains includes meat or seafood.",
        ),
        "vegan_friendly_conflicts_with_animal_contains": issue_bucket(
            "P0",
            "diet contains vegan_friendly while contains includes animal ingredients.",
        ),
        "halal_friendly_conflicts_with_pork_or_alcohol": issue_bucket(
            "P0",
            "diet contains halal_friendly while contains includes pork or alcohol.",
        ),
        "vegetarian_profile_with_unmodeled_animal_terms": issue_bucket(
            "P0",
            "profile vegetarian was inferred even though raw text includes animal terms not modeled in canonical meat detection.",
        ),
        "recipe_notes_contain_halal_explanation": issue_bucket(
            "P1",
            "Generated halal disclaimer was written into recipe notes instead of staying in UI/help copy.",
        ),
        "recipe_notes_contain_cuisine_labels": issue_bucket(
            "P1",
            "Cuisine labels appear in free-form notes; they are not structured or source-confidence tracked.",
        ),
        "western_marker_with_chinese_cuisine_note": issue_bucket(
            "P1",
            "Recipe title/materials look western or non-Chinese while notes contain a Chinese cuisine label.",
        ),
        "onion_alias_also_indexes_scallion": issue_bucket(
            "P2",
            "Ingredient alias matching adds 葱 when only 洋葱 appears.",
        ),
        "specific_pork_cut_collapsed_to_generic_pork": issue_bucket(
            "P2",
            "Specific pork cuts are collapsed into generic 猪肉, which explains broad matches like 排骨 -> 猪肉.",
        ),
        "garbled_text_markers": issue_bucket(
            "P1",
            "Materials, steps, or notes contain extraction artifacts such as ?? or replacement glyphs.",
        ),
    }
    cuisine_counts: Counter[str] = Counter()
    specific_pork_count = 0

    for recipe in recipes:
        attrs = recipe.get("attributes", {})
        if not isinstance(attrs, dict):
            attrs = {}
        contains = set(as_string_list(attrs.get("contains")))
        profile = set(as_string_list(attrs.get("profile")))
        diet = set(as_string_list(attrs.get("diet")))
        ingredients = set(as_string_list(attrs.get("ingredient")))
        title = str(recipe.get("titleZh", "")).strip()
        materials = " ".join(as_string_list(recipe.get("materialsZh")))
        steps = " ".join(as_string_list(recipe.get("stepsZh")))
        notes = " ".join(as_string_list(recipe.get("notesZh")))
        haystack = " ".join([title, materials, steps, notes])

        if "vegetarian" in profile and contains & MEAT_OR_SEAFOOD_CONTAINS:
            add_sample(
                buckets["vegetarian_profile_conflicts_with_meat_or_seafood"],
                sample_limit,
                recipe,
                conflict=sorted(contains & MEAT_OR_SEAFOOD_CONTAINS),
                materials=shorten(materials),
            )

        if "vegan_friendly" in diet and contains & ANIMAL_CONTAINS:
            add_sample(
                buckets["vegan_friendly_conflicts_with_animal_contains"],
                sample_limit,
                recipe,
                conflict=sorted(contains & ANIMAL_CONTAINS),
                materials=shorten(materials),
            )

        if "halal_friendly" in diet and contains & HALAL_BLOCKING_CONTAINS:
            add_sample(
                buckets["halal_friendly_conflicts_with_pork_or_alcohol"],
                sample_limit,
                recipe,
                conflict=sorted(contains & HALAL_BLOCKING_CONTAINS),
                materials=shorten(materials),
            )

        if "vegetarian" in profile and any(term in haystack for term in UNMODELED_ANIMAL_TERMS):
            add_sample(
                buckets["vegetarian_profile_with_unmodeled_animal_terms"],
                sample_limit,
                recipe,
                materials=shorten(materials),
                matchedTerms=[term for term in UNMODELED_ANIMAL_TERMS if term in haystack],
            )

        if "清真友好" in notes:
            add_sample(
                buckets["recipe_notes_contain_halal_explanation"],
                sample_limit,
                recipe,
                notes=shorten(notes, 180),
            )

        matched_cuisines = [item for item in CUISINE_MARKERS if item in notes]
        if matched_cuisines:
            cuisine_counts.update(matched_cuisines)
            add_sample(
                buckets["recipe_notes_contain_cuisine_labels"],
                sample_limit,
                recipe,
                cuisines=matched_cuisines,
                notes=shorten(notes, 180),
            )

        if any(item in haystack for item in WESTERN_MARKERS) and any(
            item in notes for item in CHINESE_CUISINES
        ):
            add_sample(
                buckets["western_marker_with_chinese_cuisine_note"],
                sample_limit,
                recipe,
                notes=shorten(notes, 180),
                materials=shorten(materials),
            )

        if "洋葱" in ingredients and "葱" in ingredients and not has_standalone_scallion(materials):
            add_sample(
                buckets["onion_alias_also_indexes_scallion"],
                sample_limit,
                recipe,
                materials=shorten(materials),
                ingredients=sorted(ingredients),
            )

        if any(term in haystack for term in SPECIFIC_PORK_TERMS):
            specific_pork_count += 1
            if "猪肉" in ingredients and not any(
                generic_term in haystack for generic_term in GENERIC_PORK_TERMS
            ):
                add_sample(
                    buckets["specific_pork_cut_collapsed_to_generic_pork"],
                    sample_limit,
                    recipe,
                    materials=shorten(materials),
                    ingredients=sorted(ingredients),
                    contains=sorted(contains),
                )

        if any(marker in haystack for marker in GARBLED_MARKERS):
            add_sample(
                buckets["garbled_text_markers"],
                sample_limit,
                recipe,
                materials=shorten(materials),
                notes=shorten(notes),
            )

    buckets["recipe_notes_contain_cuisine_labels"]["breakdown"] = dict(
        cuisine_counts.most_common()
    )
    buckets["specific_pork_cut_collapsed_to_generic_pork"]["specificPorkTextCount"] = (
        specific_pork_count
    )
    return buckets


def audit_source_coverage(
    *,
    library: dict[str, Any],
    recipes: list[dict[str, Any]],
    summary_recipes: list[dict[str, Any]],
    cook_rows: list[dict[str, str]],
    sample_limit: int,
) -> dict[str, Any]:
    titles = {str(recipe.get("titleZh", "")).strip() for recipe in recipes}
    cook_names = [row.get("name", "").strip() for row in cook_rows if row.get("name", "").strip()]
    missing_cook_names = [name for name in cook_names if name not in titles]

    stats = library.get("stats", {})
    per_book_counts = stats.get("perBookCounts", {})
    zero_extract_books = []
    if isinstance(per_book_counts, dict):
        zero_extract_books = [
            {"book": book, "count": count}
            for book, count in per_book_counts.items()
            if count == 0
        ]

    summary_with_source = 0
    summary_with_reference_like_fields = 0
    for recipe in summary_recipes:
        if recipe.get("sourceLabel") or recipe.get("sourceUrl"):
            summary_with_source += 1
        if recipe.get("references"):
            summary_with_reference_like_fields += 1

    missing_count = len(missing_cook_names)
    return {
        "cookCsvRows": len(cook_rows),
        "cookCsvExactTitleMatches": len(cook_names) - missing_count,
        "cookCsvMissingExactTitles": missing_count,
        "cookCsvMissingSamples": missing_cook_names[:sample_limit],
        "zeroExtractedBooks": zero_extract_books,
        "summaryRowsWithSourceLabelOrUrl": summary_with_source,
        "summaryRowsWithReferences": summary_with_reference_like_fields,
        "referenceTitles": library.get("referenceTitles", []),
        "finding": (
            "YunYouJun/cook recipe.csv rows are present in the generated library."
            if cook_names and missing_count == 0
            else "YunYouJun/cook recipe.csv rows are not fully imported into the generated library."
        ),
    }


def issue_bucket(priority: str, description: str) -> dict[str, Any]:
    return {
        "priority": priority,
        "description": description,
        "count": 0,
        "samples": [],
    }


def add_sample(
    bucket: dict[str, Any],
    sample_limit: int,
    recipe: dict[str, Any],
    **extra: Any,
) -> None:
    bucket["count"] += 1
    if len(bucket["samples"]) >= sample_limit:
        return
    sample = {
        "id": recipe.get("id"),
        "title": recipe.get("titleZh"),
        "categoryId": recipe.get("categoryId"),
        "contextId": recipe.get("contextId"),
        "tags": recipe.get("tagsZh", []),
        "attributes": recipe.get("attributes", {}),
    }
    sample.update(extra)
    bucket["samples"].append(sample)


def as_string_list(value: Any) -> list[str]:
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if value is None:
        return []
    return [str(value).strip()] if str(value).strip() else []


def shorten(text: str, limit: int = 140) -> str:
    normalized = " ".join(text.split())
    if len(normalized) <= limit:
        return normalized
    return normalized[: limit - 1] + "…"


def has_standalone_scallion(materials: str) -> bool:
    cleaned = materials.replace("洋葱", "").replace("葱头", "")
    return any(term in cleaned for term in ("葱", "香葱", "青葱", "葱花", "葱段"))


def render_markdown(report: dict[str, Any]) -> str:
    stats = report["stats"]
    source = report["sourceCoverage"]
    issues = report["issues"]
    sqlite_tables = stats["sqlite"].get("tables", {})
    sqlite_summary_rows = sqlite_tables.get(
        "daily_choice_eat_recipe_summaries",
        sqlite_tables.get("daily_choice_recipes", "n/a"),
    )
    if source["cookCsvRows"] and source["cookCsvMissingExactTitles"] == 0:
        cook_coverage_line = (
            f"1. `YunYouJun/cook` 已作为默认 cook 数据来源导入：recipe.csv 共 "
            f"{source['cookCsvRows']} 行，当前库标题精确命中 "
            f"{source['cookCsvExactTitleMatches']} 行，未命中 "
            f"{source['cookCsvMissingExactTitles']} 行。"
        )
    else:
        cook_coverage_line = (
            f"1. `YunYouJun/cook` 尚未完整作为默认 cook 数据来源导入：recipe.csv 共 "
            f"{source['cookCsvRows']} 行，当前库标题精确命中 "
            f"{source['cookCsvExactTitleMatches']} 行，未命中 "
            f"{source['cookCsvMissingExactTitles']} 行。"
        )
    cook_missing_samples = ", ".join(source["cookCsvMissingSamples"][:8]) or "无"

    lines = [
        "# 记录 070: 每日决策吃什么菜谱数据源审计",
        "",
        "## 基本信息",
        f"- **生成时间**: {report['generatedAt']}",
        f"- **菜谱总数**: {stats['recipeCount']}",
        f"- **摘要总数**: {stats['summaryRecipeCount']}",
        f"- **cook recipe.csv 行数**: {stats['cookCsvRowCount']}",
        f"- **SQLite 摘要行数**: {sqlite_summary_rows}",
        "",
        "## 关键结论",
        cook_coverage_line,
        f"2. 素食/纯素字段存在高风险冲突：`vegetarian` 与肉类/海鲜冲突 {issues['vegetarian_profile_conflicts_with_meat_or_seafood']['count']} 条，`vegan_friendly` 与动物性食材冲突 {issues['vegan_friendly_conflicts_with_animal_contains']['count']} 条。",
        f"3. 菜系信息当前混在 notes 中且缺少可信度边界：含菜系标签 notes 共 {issues['recipe_notes_contain_cuisine_labels']['count']} 条，其中西式/非中式标记却带中式菜系 notes 的高疑似错配 {issues['western_marker_with_chinese_cuisine_note']['count']} 条。",
        f"4. `清真友好` 说明被写入菜谱 notes {issues['recipe_notes_contain_halal_explanation']['count']} 条，属于 UI/规则说明污染菜谱正文。",
        f"5. 食材别名存在过宽匹配：`洋葱` 额外索引为 `葱` {issues['onion_alias_also_indexes_scallion']['count']} 条；排骨/猪油等具体猪肉项仍折叠到粗粒度猪肉 {issues['specific_pork_cut_collapsed_to_generic_pork']['count']} 条。",
        "",
        "## 数据源覆盖",
        f"- cook CSV 缺失样例: {cook_missing_samples}",
        f"- 0 提取书籍数: {len(source['zeroExtractedBooks'])}",
        f"- 摘要行 sourceLabel/sourceUrl: {source['summaryRowsWithSourceLabelOrUrl']}",
        f"- 摘要行 references: {source['summaryRowsWithReferences']}",
        "",
        "## 问题桶",
    ]

    for issue_id, issue in issues.items():
        if issue["count"] == 0:
            continue
        lines.extend(
            [
                "",
                f"### {issue_id}",
                f"- **优先级**: {issue['priority']}",
                f"- **数量**: {issue['count']}",
                f"- **说明**: {issue['description']}",
            ]
        )
        if issue.get("breakdown"):
            breakdown = ", ".join(
                f"{key}: {value}" for key, value in issue["breakdown"].items()
            )
            lines.append(f"- **分布**: {breakdown}")
        for sample in issue["samples"][:5]:
            extras = []
            for key in ("conflict", "matchedTerms", "cuisines", "materials", "notes"):
                if key in sample and sample[key]:
                    extras.append(f"{key}={sample[key]}")
            suffix = f" ({'; '.join(extras)})" if extras else ""
            lines.append(f"- `{sample.get('id')}` {sample.get('title')}{suffix}")

    lines.extend(
        [
            "",
        "## 初步修正建议",
            "1. 数据生成阶段不要再写入 `halal_friendly`、`vegan_friendly`、`vegetarian_friendly` 这类高语义饮食友好字段，UI 也不再提供对应辅助筛选。",
            "2. 肉类判断不要只依赖 canonical ingredient；`contains` 与 `profile` 应来自同一套原始材料风险词表，并覆盖兔、龟、鸽、牡蛎等当前漏建模动物食材。",
            "3. 菜系不再写入 notes。若源资料明确给出菜系，后续迁移到 `recipe_filter_index(group=cuisine, confidence=source)`；无明确来源则留空。",
            "4. 食材索引拆成 `raw_ingredient`、`canonical_ingredient`、`family_ingredient` 三层，默认匹配 raw/canonical，只有用户显式扩展时才用 family。",
            "5. 将 YunYouJun/cook 的 `recipe.csv` 单独导入为默认 cook 菜谱集，保留 difficulty/methods/tools/tags/stuff 原始字段；本地书籍资料作为另一个可选资料集。",
        ]
    )

    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    main()
