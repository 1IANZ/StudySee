use std::sync::{Arc};
use std::collections::HashMap;
use regex::Regex;
use reqwest::header::HeaderMap;
use reqwest::Client;
use reqwest_cookie_store::{CookieStore, CookieStoreMutex};
use crate::api::{aescbc::aes_cbc_encrypt, conwork::encode_inp};

pub struct HttpSession {
    pub client: Client,
    pub _cookie_store: Arc<CookieStoreMutex>,
}

impl HttpSession {
    pub fn new() -> Self {
        let cookie_store = Arc::new(CookieStoreMutex::new(CookieStore::default()));
        let client = Client::builder()
            .cookie_provider(cookie_store.clone())
            .build()
            .expect("构建 HTTP 客户端失败");

        Self {
            client,
            _cookie_store: cookie_store,
        }
    }

    pub async fn get_flow_execution_key(&self) -> Result<String, String> {
        let response = self
            .client
            .get("https://oa-443.v.hbfu.edu.cn/backstage/cas/login")
            .send()
            .await
            .map_err(|e| e.to_string())?;
        let text = response.text().await.map_err(|e| e.to_string())?;
        let pattern = Regex::new(r#"flowExecutionKey: "(.*?)""#).map_err(|e| e.to_string())?;

        if let Some(captures) = pattern.captures(&text) {
            if let Some(matched) = captures.get(1) {
                Ok(matched.as_str().to_string())
            } else {
                Err("未找到 flowExecutionKey".to_string())
            }
        } else {
            Err("未找到 flowExecutionKey".to_string())
        }
    }

    async fn login_vpn(
        &self,
        username: &str,
        password: &str,
    ) -> Result<bool, String> {
        let  flow_execution_key = self.get_flow_execution_key().await?;
        let encrypted_password = aes_cbc_encrypt(password).map_err(|e| format!("密码加密失败: {}", e))?;

        let mut form_data = HashMap::new();
        form_data.insert("username", username);
        form_data.insert("password", &encrypted_password);
        form_data.insert("execution", &flow_execution_key);
        form_data.insert("_eventId", "submit");
        form_data.insert("rememberMe", "false");
        form_data.insert("domain", "oa-443.v.hbfu.edu.cn");

        let res = self
            .client
            .post("https://oa-443.v.hbfu.edu.cn/backstage/cas/login")
            .form(&form_data)
            .send()
            .await
            .map_err(|e| e.to_string())?;

        let text = res.text().await.map_err(|e| e.to_string())?;

        Ok(text.contains("修改密码"))
    }

    pub async fn access_jwxt(&self) -> Result<bool, String> {
        let mut headers = HeaderMap::new();
        headers.insert(
            "Content-Type",
            "text/html;charset=utf-8".parse().unwrap(),
        );
        headers.insert("Vary", "Accept-Encoding".parse().unwrap());
        headers.insert(
            "User-Agent",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36"
                .parse()
                .unwrap(),
        );

        let res = self
            .client
            .get("https://jw.v.hbfu.edu.cn/")
            .headers(headers)
            .send()
            .await
            .map_err(|e| e.to_string())?;

        let text = res.text().await.map_err(|e| e.to_string())?;

        Ok(text.contains("用户登录"))
    }

    async fn login_jwxt(&self, username: &str, password: &str) -> Result<bool, String> {
        let encoded_username = encode_inp(username);
        let encoded_password = encode_inp(password);
        let encoded_data = format!("{}%%%{}", encoded_username, encoded_password);

        let response = self
            .client
            .post("https://jw.v.hbfu.edu.cn/jsxsd/xk/LoginToXk")
            .form(&[("encoded", &encoded_data)])
            .send()
            .await
            .map_err(|e| e.to_string())?;

        let text = response.text().await.map_err(|e| e.to_string())?;

        Ok(text.contains("学生个人中心"))
    }

    pub async fn complete_login(
        &self,
        username: &str,
        vpn_password: &str,
        oa_password: &str,
    ) -> Result<String, String> {
        let vpn_login_result = self.login_vpn(username, vpn_password).await?;
        if !vpn_login_result {
            return Err("VPN登录失败,请检查账号密码".to_string());
        }

        let access_jwxt = self.access_jwxt().await?;
        if !access_jwxt {
            return Err("教务系统访问失败".to_string());
        }

        let jwxt_login_result = self.login_jwxt(username, oa_password).await?;
        if !jwxt_login_result {
            return Err("教务系统登录失败,请检查账号密码".to_string());
        }
        Ok("登录成功".to_string())
    }
}


