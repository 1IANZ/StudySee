use scraper::{Html, Selector};
use serde::Serialize;

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ExamSchedule {
    pub id: u32,               // 序号
    pub course_code: String,   // 课程编号
    pub course_name: String,   // 课程名称
    pub exam_time: String,     // 考试时间
    pub exam_location: String, // 考场
}

pub fn parse_exam(html: &str) -> Result<Vec<ExamSchedule>, String> {
    let document = Html::parse_document(html);
    let table_selector = Selector::parse("#dataList").unwrap();
    let row_selector = Selector::parse("tr").unwrap();
    let cell_selector = Selector::parse("td").unwrap();
    let table = document
        .select(&table_selector)
        .next()
        .ok_or("无法找到考试表格".to_string())?;

    let mut exams = Vec::new();

    for (i, row) in table.select(&row_selector).enumerate() {
        if i == 0 {
            continue;
        }
        let cells: Vec<_> = row.select(&cell_selector).collect();
        if cells.len() < 9 {
            continue;
        }
        let text_at = |idx: usize| {
            cells
                .get(idx)
                .map(|c| c.text().collect::<String>().trim().to_string())
                .unwrap_or_default()
        };
        let exam = ExamSchedule {
            id: text_at(0).parse::<u32>().unwrap_or(0),
            course_code: text_at(2),
            course_name: text_at(3),
            exam_time: text_at(4),
            exam_location: text_at(5),
        };
        exams.push(exam);
    }

    Ok(exams)
}
