use scraper::{ElementRef, Html, Selector};
use serde::Serialize;
use std::collections::HashSet;

#[derive(Serialize)]
pub struct ExecutionPlan {
    pub id: u32,
    pub semester: String,
    pub course_code: String,
    pub course_name: String,
    pub department: String,
    pub credits: f32,
    pub total_hours: f32,
    pub assessment_method: String,
    pub course_type: String,
    pub is_exam: String,
}

#[derive(Serialize)]
pub struct ExecutionPlanResponse {
    pub plans: Vec<ExecutionPlan>,
    pub semesters: Vec<String>,
}

pub fn parse_plan(html: &str) -> Result<ExecutionPlanResponse, String> {
    let document = Html::parse_document(html);

    let selector_str = "table#dataList.Nsb_r_list.Nsb_table";
    let selector = Selector::parse(selector_str).map_err(|_| "选择器解析失败".to_string())?;

    let table = document
        .select(&selector)
        .next()
        .ok_or_else(|| "未找到符合条件的表格元素".to_string())?;

    let tr_selector = Selector::parse("tr").map_err(|_| "tr选择器解析失败".to_string())?;
    let td_selector = Selector::parse("td").map_err(|_| "td选择器解析失败".to_string())?;

    let mut plans = Vec::new();
    let mut semesters_set = HashSet::new();

    for (i, row) in table.select(&tr_selector).enumerate() {
        if i == 0 {
            continue;
        }
        let cells: Vec<ElementRef> = row.select(&td_selector).collect();
        if cells.len() < 10 {
            continue;
        }

        let text =
            |idx: usize| -> String { cells[idx].text().collect::<String>().trim().to_string() };
        let parse_f32 = |idx| text(idx).parse::<f32>().unwrap_or(0.0);
        let id = text(0).parse::<u32>().unwrap_or(i as u32);
        let semester = text(1);

        if semesters_set.len() < 8 {
            semesters_set.insert(semester.clone());
        }

        plans.push(ExecutionPlan {
            id,
            semester: semester.clone(),
            course_code: text(2),
            course_name: text(3),
            department: text(4),
            credits: parse_f32(5),
            total_hours: parse_f32(6),
            assessment_method: text(7),
            course_type: text(8),
            is_exam: text(9),
        });
    }

    Ok(ExecutionPlanResponse {
        plans,
        semesters: semesters_set.into_iter().collect(),
    })
}
