use std::{collections::HashMap, sync::Arc};

use flutter_rust_bridge::frb;
use once_cell::sync::OnceCell;
use tokio::sync::Mutex;

use crate::api::{
    jwxt::{
        course::{parse_course_schedule, CourseSchedule},
        dekt::{parse_dekt, parse_dekt_detail, DEKTDetail, DEKT},
        elective::{parse_elective, ElectiveResponse},
        exam::{parse_exam, ExamSchedule},
        info::{parse_student_info, StudentInfo},
        plan::{parse_plan, ExecutionPlanResponse},
        score::{parse_score_all, ScoreTotal},
        semester::{parse_semester, SemesterInfo},
    },
    session::HttpSession,
};
static SESSION: OnceCell<Arc<Mutex<Option<HttpSession>>>> = OnceCell::new();

#[frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
    let _ = SESSION.set(Arc::new(Mutex::new(None)));
}

#[frb(dart_async)]
pub async fn api_login(
    username: String,
    vpn_password: String,
    oa_password: String,
    captcha: String,
) -> Result<String, String> {
    let session_arc = SESSION.get().ok_or("SESSION 未初始化")?;
    let mut guard = session_arc.lock().await;

    let session = guard.as_ref().ok_or("SESSION 锁定失败")?;

    session
        .complete_login(&username, &vpn_password, &oa_password, &captcha)
        .await
        .map_err(|e| format!("登录失败: {}", e))?;

    // 这里通过克隆或移动来更新 guard 中的 session
    *guard = Some(session.clone()); // 克隆 session（如果需要深拷贝）

    Ok("登录成功".to_string())
}

#[frb(dart_async)]
pub async fn api_student_info() -> Result<StudentInfo, String> {
    let session_arc = SESSION.get().expect("SESSION 未初始化");
    let guard = session_arc.lock().await;
    let session = guard.as_ref().unwrap();
    let res = session
        .client
        .get("https://jw.v.hbfu.edu.cn/jsxsd/grxx/xsxx")
        .send()
        .await
        .map_err(|_| "请求失败".to_string())?
        .text()
        .await
        .map_err(|_| "读取响应失败".to_string())?;
    parse_student_info(&res)
}
#[frb(dart_async)]
pub async fn api_semester(is_all: bool) -> Result<Vec<SemesterInfo>, String> {
    let session_arc = SESSION.get().expect("SESSION 未初始化");
    let guard = session_arc.lock().await;
    let session = guard.as_ref().unwrap();
    let res = session
        .client
        .get("https://jw.v.hbfu.edu.cn/jsxsd/xsks/xsksap_query")
        .send()
        .await
        .map_err(|_| "请求失败".to_string())?
        .text()
        .await
        .map_err(|_| "读取响应失败".to_string())?;
    parse_semester(&res, is_all)
}
#[frb(dart_async)]
pub async fn api_score(semester: String) -> Result<ScoreTotal, String> {
    let session_arc = SESSION.get().expect("SESSION 未初始化");
    let guard = session_arc.lock().await;
    let session = guard.as_ref().unwrap();
    let mut form_data = HashMap::new();
    form_data.insert("kksj", semester.as_str());
    form_data.insert("xsfs", "all");

    let res = session
        .client
        .post("https://jw.v.hbfu.edu.cn/jsxsd/kscj/cjcx_list")
        .form(&form_data)
        .send()
        .await
        .map_err(|_| "请求失败".to_string())?
        .text()
        .await
        .map_err(|_| "读取响应失败".to_string())?;
    parse_score_all(&res)
}
#[frb(dart_async)]
pub async fn api_course(semester: String) -> Result<Vec<CourseSchedule>, String> {
    let session_arc = SESSION.get().expect("SESSION 未初始化");
    let guard = session_arc.lock().await;
    let session = guard.as_ref().unwrap();
    let mut form_data = HashMap::new();
    form_data.insert("xnxq01id", semester.as_str());
    form_data.insert("sfFD", "all");

    let res = session
        .client
        .post("https://jw.v.hbfu.edu.cn/jsxsd/xskb/xskb_list.do")
        .form(&form_data)
        .send()
        .await
        .map_err(|_| "请求失败".to_string())?
        .text()
        .await
        .map_err(|_| "读取响应失败".to_string())?;
    parse_course_schedule(&res)
}
#[frb(dart_async)]
pub async fn api_exam(semester: String) -> Result<Vec<ExamSchedule>, String> {
    let session_arc = SESSION.get().expect("SESSION 未初始化");
    let guard = session_arc.lock().await;
    let session = guard.as_ref().unwrap();
    let mut form_data = HashMap::new();
    form_data.insert("xnxqid", semester.as_str());

    let res = session
        .client
        .post("https://jw.v.hbfu.edu.cn/jsxsd/xsks/xsksap_list")
        .form(&form_data)
        .send()
        .await
        .map_err(|_| "请求失败".to_string())?
        .text()
        .await
        .map_err(|_| "读取响应失败".to_string())?;
    parse_exam(&res)
}
#[frb(dart_async)]
pub async fn api_elective(semester: String) -> Result<ElectiveResponse, String> {
    let session_arc = SESSION.get().expect("SESSION 未初始化");
    let guard = session_arc.lock().await;
    let session = guard.as_ref().unwrap();
    let mut form_data = HashMap::new();
    form_data.insert("xnxqid", semester.as_str());

    let res = session
        .client
        .post("https://jw.v.hbfu.edu.cn/jsxsd/xkgl/xqxkchList")
        .form(&form_data)
        .send()
        .await
        .map_err(|_| "请求失败".to_string())?
        .text()
        .await
        .map_err(|_| "读取响应失败".to_string())?;
    parse_elective(&res)
}
#[frb(dart_async)]
pub async fn api_plan() -> Result<ExecutionPlanResponse, String> {
    let session_arc = SESSION.get().expect("SESSION 未初始化");
    let guard = session_arc.lock().await;
    let session = guard.as_ref().unwrap();
    let res = session
        .client
        .get("https://jw.v.hbfu.edu.cn/jsxsd/pyfa/pyfa_query")
        .send()
        .await
        .map_err(|_| "请求失败".to_string())?
        .text()
        .await
        .map_err(|_| "读取响应失败".to_string())?;
    parse_plan(&res)
}
#[frb(dart_async)]
pub async fn api_dekt() -> Result<DEKT, String> {
    let session_arc = SESSION.get().expect("SESSION 未初始化");
    let guard = session_arc.lock().await;
    let session = guard.as_ref().unwrap();
    let res = session
        .client
        .get("https://jw.v.hbfu.edu.cn/jsxsd/pyfa/cxxf07List")
        .send()
        .await
        .map_err(|_| "请求失败".to_string())?
        .text()
        .await
        .map_err(|_| "读取响应失败".to_string())?;
    parse_dekt(&res)
}
#[frb(dart_async)]
pub async fn api_dekt_detail(id: String) -> Result<DEKTDetail, String> {
    let session_arc = SESSION.get().expect("SESSION 未初始化");
    let guard = session_arc.lock().await;
    let session = guard.as_ref().unwrap();
    let res = session
        .client
        .get(format!(
            "https://jw.v.hbfu.edu.cn/jsxsd/pyfa/cxxf07View?cxxf07id={}&type=view",
            id
        ))
        .send()
        .await
        .map_err(|_| "请求失败".to_string())?
        .text()
        .await
        .map_err(|_| "读取响应失败".to_string())?;
    parse_dekt_detail(&res)
}
// #[frb(dart_async)]
// pub async fn api_get_captcha() -> Result<Vec<u8>, String> {
//     let session_arc = SESSION.get().ok_or("SESSION 未初始化")?;
//     let guard = session_arc.lock().await;
//     let session = guard.as_ref().ok_or("SESSION 锁定失败")?;
//     session.get_captcha().await

// }
#[frb(dart_async)]
pub async fn api_get_captcha() -> Result<Vec<u8>, String> {
    let session_arc = SESSION.get().ok_or("SESSION 未初始化")?;
    let mut guard = session_arc.lock().await;
    if guard.is_none() {
        let session = HttpSession::new();
        *guard = Some(session);
    }

    let session = guard.as_ref().ok_or("SESSION 锁定失败")?;
    session.get_captcha().await
}
