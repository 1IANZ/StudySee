use regex::Regex;
use scraper::{Html, Selector};
use serde::Serialize;
use std::collections::HashMap;

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DEKTList {
    pub id: String,            // 序号
    pub semester: String,      // 学年学期
    pub category: String,      // 学分类别
    pub sub_category: String,  // 学分子类
    pub activity_name: String, // 活动名称
    pub credit: String,        // 所得学分
    pub operation_id: String,  // 操作ID
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DEKTTotal {
    pub category: String,
    pub total_credit: String,
}

#[derive(Debug, Serialize)]
#[serde(transparent)]
pub struct DEKTDetail(pub HashMap<String, String>);

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DEKT {
    pub list: Vec<DEKTList>,
    pub total: Vec<DEKTTotal>,
}

pub fn parse_dekt_list(html: &str) -> Result<Vec<DEKTList>, String> {
    let document = Html::parse_document(html);
    let table_selector = Selector::parse("#dataList").unwrap();
    let row_selector = Selector::parse("tr").unwrap();
    let cell_selector = Selector::parse("td").unwrap();
    let link_selector = Selector::parse("a").unwrap();

    let table = document
        .select(&table_selector)
        .next()
        .ok_or_else(|| "未找到 id=dataList 的表格".to_string())?;

    let mut dekts = Vec::new();

    for (i, row) in table.select(&row_selector).enumerate() {
        if i == 0 {
            continue;
        } // 跳过表头

        let cells: Vec<_> = row.select(&cell_selector).collect();
        if cells.len() < 7 {
            continue;
        }

        let operation_id = if let Some(link) = cells[6].select(&link_selector).next() {
            if let Some(onclick) = link.value().attr("onclick") {
                let re = Regex::new(r"cxxf07id=([^&]+)").unwrap();
                re.captures(onclick)
                    .and_then(|caps| caps.get(1).map(|m| m.as_str().to_string()))
                    .unwrap_or_default()
            } else {
                String::new()
            }
        } else {
            String::new()
        };

        let get_text = |idx: usize| {
            cells
                .get(idx)
                .map(|c| c.text().collect::<Vec<_>>().join("").trim().to_string())
                .unwrap_or_default()
        };
        dekts.push(DEKTList {
            id: get_text(0),
            semester: get_text(1),
            category: get_text(2),
            sub_category: get_text(3),
            activity_name: get_text(4),
            credit: get_text(5),
            operation_id,
        });
    }

    Ok(dekts)
}
pub fn parse_dekt_total(html: &str) -> Result<Vec<DEKTTotal>, String> {
    let document = Html::parse_document(html);
    let table_selector = Selector::parse("table.Nsb_r_list").unwrap();

    let table = document
        .select(&table_selector)
        .next()
        .ok_or_else(|| "未找到 class=Nsb_r_list 的表格".to_string())?;

    let mut totals = Vec::new();

    for row in table.select(&Selector::parse("tr").unwrap()).skip(1) {
        let cells: Vec<_> = row.select(&Selector::parse("td").unwrap()).collect();
        if cells.len() < 2 {
            continue;
        }

        let category = cells[0]
            .text()
            .collect::<Vec<_>>()
            .join("")
            .trim()
            .to_string();
        let total_credit = cells[1]
            .text()
            .collect::<Vec<_>>()
            .join("")
            .trim()
            .to_string();

        totals.push(DEKTTotal {
            category,
            total_credit,
        });
    }

    Ok(totals)
}
pub fn parse_dekt_detail(html: &str) -> Result<DEKTDetail, String> {
    let document = Html::parse_document(html);
    let table_selector = Selector::parse("table.dataTable").unwrap();

    let table = document
        .select(&table_selector)
        .next()
        .ok_or_else(|| "未找到 class=dataTable 的表格".to_string())?;

    let mut map = HashMap::new();
    let row_selector = Selector::parse("tr").unwrap();

    for row in table.select(&row_selector) {
        let cells: Vec<_> = row.select(&Selector::parse("td").unwrap()).collect();
        for i in (0..cells.len()).step_by(2) {
            if i + 1 >= cells.len() {
                break;
            }

            let label = cells[i]
                .text()
                .collect::<Vec<_>>()
                .join("")
                .trim()
                .trim_end_matches(':')
                .to_string();

            let value = cells[i + 1]
                .select(&Selector::parse("input").unwrap())
                .next()
                .and_then(|input| input.value().attr("value"))
                .unwrap_or("")
                .trim()
                .to_string();

            if !label.is_empty() && !value.is_empty() {
                map.insert(label, value);
            }
        }
    }

    Ok(DEKTDetail(map))
}

pub fn parse_dekt(html: &str) -> Result<DEKT, String> {
    let list = parse_dekt_list(html)?;
    let total = parse_dekt_total(html)?;
    Ok(DEKT { list, total })
}
