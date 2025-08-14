const KEY_STR: &str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

pub fn encode_inp(input: &str) -> String {
    let mut output = String::new();
    let input_bytes = input.as_bytes();
    let mut i = 0;

    while i < input_bytes.len() {
        let chr1 = input_bytes.get(i).copied().unwrap_or(0);
        let chr2 = input_bytes.get(i + 1).copied().unwrap_or(0);
        let chr3 = input_bytes.get(i + 2).copied().unwrap_or(0);

        let enc1 = chr1 >> 2;
        let enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
        let enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
        let enc4 = chr3 & 63;

        let enc3_final = if i + 1 >= input_bytes.len() { 64 } else { enc3 };
        let enc4_final = if i + 2 >= input_bytes.len() { 64 } else { enc4 };

        output.push(KEY_STR.chars().nth(enc1 as usize).unwrap());
        output.push(KEY_STR.chars().nth(enc2 as usize).unwrap());
        output.push(KEY_STR.chars().nth(enc3_final as usize).unwrap());
        output.push(KEY_STR.chars().nth(enc4_final as usize).unwrap());

        i += 3;
    }

    output
}
