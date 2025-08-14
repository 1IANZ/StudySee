use aes::Aes128;
use aes::cipher::{BlockEncrypt, KeyInit};

use base64::{Engine, engine::general_purpose};

const BLOCK_SIZE: usize = 16;
const KEY: &[u8; 16] = b"UH1eN7apoK9lY5VB";
const IV: &[u8; 16] = b"VkRu0s6hLfFriZDW";

#[derive(Debug)]
pub enum CryptoError {
    Utf8(std::string::FromUtf8Error),
    Base64(base64::DecodeError),
}

impl std::fmt::Display for CryptoError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Utf8(e) => write!(f, "UTF-8 conversion error: {}", e),
            Self::Base64(e) => write!(f, "Base64 decode error: {}", e),
        }
    }
}

impl std::error::Error for CryptoError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            CryptoError::Utf8(e) => Some(e),
            CryptoError::Base64(e) => Some(e),
        }
    }
}

impl From<std::string::FromUtf8Error> for CryptoError {
    fn from(err: std::string::FromUtf8Error) -> Self {
        Self::Utf8(err)
    }
}

impl From<base64::DecodeError> for CryptoError {
    fn from(err: base64::DecodeError) -> Self {
        Self::Base64(err)
    }
}

/// AES-128 CBC encryption with PKCS7 padding, output base64 string
pub fn aes_cbc_encrypt(plain_text: &str) -> Result<String, CryptoError> {
    let mut data = plain_text.as_bytes().to_vec();
    let padding_len = BLOCK_SIZE - (data.len() % BLOCK_SIZE);
    data.extend(std::iter::repeat(padding_len as u8).take(padding_len));

    let cipher = Aes128::new(KEY.into());
    let mut ciphertext = Vec::with_capacity(data.len());
    let mut prev_block = IV.clone();

    for block in data.chunks(BLOCK_SIZE as usize) {
        let mut chunk = [0u8; BLOCK_SIZE];
        for i in 0..BLOCK_SIZE {
            chunk[i] = block[i] ^ prev_block[i];
        }
        cipher.encrypt_block((&mut chunk).into());
        ciphertext.extend_from_slice(&chunk);
        prev_block = chunk;
    }

    Ok(general_purpose::STANDARD.encode(&ciphertext))
}
