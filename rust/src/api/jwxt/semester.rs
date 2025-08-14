use scraper::{Html, Selector};
use serde::Serialize;

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SemesterInfo {
    pub key: String,
    pub value: String,
}
pub fn parse_semester(html: &str, is_all: bool) -> Result<Vec<SemesterInfo>, String> {
    let document = Html::parse_document(html);
    let selector = Selector::parse(".Nsb_layout_r table tr td").unwrap();

    let mut semesters = Vec::new();

    if let Some(td) = document.select(&selector).next() {
        let raw_text = td.text().collect::<Vec<_>>().join("").trim().to_string();

        let mut semester_list = raw_text
            .split('\n')
            .map(|s| s.trim())
            .filter(|s| !s.is_empty())
            .map(|s| s.to_string())
            .collect::<Vec<String>>();

        semester_list.sort_by(|a, b| b.cmp(a));
        semester_list.truncate(10);

        if is_all {
            semesters.push(SemesterInfo {
                key: "全部学期".to_string(),
                value: "".to_string(),
            });
        }

        for sem in semester_list {
            semesters.push(SemesterInfo {
                key: sem.clone(),
                value: sem,
            });
        }
    }
    Ok(semesters)
}