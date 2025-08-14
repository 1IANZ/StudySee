use scraper::{Html, Selector};
use serde::Serialize;

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CreditInfo {
    pub category: String,
    pub required: i32,
    pub limited: i32,
    pub elective: i32,
    pub public: i32,
    pub total: i32,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct XqxkchInfo {
    pub course_id: String,
    pub course_name: String,
    pub department: String,
    pub hours: i32,
    pub credits: f32,
    pub course_attribute: String,
    pub selection_type: String,
    pub selected: String,
}

#[derive(Serialize)]
pub struct ElectiveResponse {
    pub credits: Vec<CreditInfo>,
    pub courses: Vec<XqxkchInfo>,
}

pub fn parse_elective(html: &str) -> Result<ElectiveResponse, String> {
    let document = Html::parse_document(html);
    let table_selector = Selector::parse("table.Nsb_r_list.Nsb_table")
        .map_err(|_| "无法找到选课表格".to_string())?;
    let row_selector = Selector::parse("tr").unwrap();
    let td_selector = Selector::parse("td").unwrap();
    let th_selector = Selector::parse("th").unwrap();

    let tables: Vec<_> = document.select(&table_selector).collect();
    if tables.len() < 2 {
        return Err("无法找到选课表格".to_string());
    }

    let mut credits = Vec::new();
    for row in tables[0].select(&row_selector) {
        if row.select(&th_selector).next().is_some() {
            continue;
        }
        let cells: Vec<_> = row.select(&td_selector).collect();
        if cells.len() >= 6 {
            credits.push(CreditInfo {
                category: cells[0].text().collect::<String>().trim().to_string(),
                required: cells[1]
                    .text()
                    .collect::<String>()
                    .trim()
                    .parse()
                    .unwrap_or(0),
                limited: cells[2]
                    .text()
                    .collect::<String>()
                    .trim()
                    .parse()
                    .unwrap_or(0),
                elective: cells[3]
                    .text()
                    .collect::<String>()
                    .trim()
                    .parse()
                    .unwrap_or(0),
                public: cells[4]
                    .text()
                    .collect::<String>()
                    .trim()
                    .parse()
                    .unwrap_or(0),
                total: cells[5]
                    .text()
                    .collect::<String>()
                    .trim()
                    .parse()
                    .unwrap_or(0),
            });
        }
    }
    let mut courses = Vec::new();
    for row in tables[1].select(&row_selector) {
        if row.select(&th_selector).next().is_some() {
            continue;
        }
        let cells: Vec<_> = row.select(&td_selector).collect();
        if cells.len() >= 8 {
            courses.push(XqxkchInfo {
                course_id: cells[0].text().collect::<String>().trim().to_string(),
                course_name: cells[1].text().collect::<String>().trim().to_string(),
                department: cells[2].text().collect::<String>().trim().to_string(),
                hours: cells[3]
                    .text()
                    .collect::<String>()
                    .trim()
                    .parse()
                    .unwrap_or(0),
                credits: cells[4]
                    .text()
                    .collect::<String>()
                    .trim()
                    .parse()
                    .unwrap_or(0.0),
                course_attribute: cells[5].text().collect::<String>().trim().to_string(),
                selection_type: cells[6].text().collect::<String>().trim().to_string(),
                selected: cells[7].text().collect::<String>().trim().to_string(),
            });
        }
    }

    Ok(ElectiveResponse { credits, courses })
}
