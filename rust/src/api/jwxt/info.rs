use scraper::{Html, Selector};
use serde::Serialize;


#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct StudentInfo {
    pub name: String,
    pub gender: String,
    pub student_id: String,
    pub department: String,
    pub major: String,
    pub class_name: String,
    pub admission_date: String,
    pub admission_number: String,
    pub id_number: String,
}

pub fn parse_student_info(html: &str) -> Result<StudentInfo, String> {
    let document = Html::parse_document(html);

    let table_selector = Selector::parse("#xjkpTable").map_err(|e| e.to_string())?;
    let table = document
        .select(&table_selector)
        .next()
        .ok_or_else(|| "无法找到学籍信息表格".to_string())?;

    let row_selector = Selector::parse("tr").map_err(|e| e.to_string())?;
    let rows: Vec<_> = table.select(&row_selector).collect();

    let get_text = |elem: Option<scraper::element_ref::ElementRef>, selector: Option<&str>| -> String {
        if let Some(el) = elem {
            if let Some(sel) = selector {
                el.select(&Selector::parse(sel).unwrap())
                    .next()
                    .map(|e| e.text().collect::<String>().trim().replace('\u{a0}', " "))
                    .unwrap_or_default()
            } else {
                el.text().collect::<String>().trim().replace('\u{a0}', " ")
            }
        } else {
            "".to_string()
        }
    };

    let info_cells: Vec<_> = rows[2].select(&Selector::parse("td").unwrap()).collect();
    let personal_cells: Vec<_> = rows[3].select(&Selector::parse("td").unwrap()).collect();
    let admission_date_cells: Vec<_> = rows[46].select(&Selector::parse("td").unwrap()).collect();
    let id_number_cells: Vec<_> = rows[47].select(&Selector::parse("td").unwrap()).collect();

    Ok(StudentInfo {
        name: get_text(personal_cells.get(1).cloned(), None),
        gender: get_text(personal_cells.get(3).cloned(), None),
        student_id: get_text(info_cells.get(4).cloned(), None).replace("学号：", ""),
        department: get_text(info_cells.get(0).cloned(), None).replace("院系：", ""),
        major: get_text(info_cells.get(1).cloned(), None).replace("专业：", ""),
        class_name: get_text(info_cells.get(3).cloned(), None).replace("班级：", ""),
        admission_date: get_text(admission_date_cells.get(1).cloned(), None)
            .replace('\u{a0}', "")
            .trim()
            .to_string(),
        admission_number: get_text(id_number_cells.get(1).cloned(), None)
            .replace('\u{a0}', "")
            .trim()
            .to_string(),
        id_number: get_text(id_number_cells.get(3).cloned(), None)
            .replace('\u{a0}', "")
            .trim()
            .to_string(),
    })
}

