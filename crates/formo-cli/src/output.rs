use formo_backend_desktop::DesktopBackend;
use formo_backend_web::WebBackend;
use formo_ir::{Backend, BackendOutput, IrProgram};
use std::fs;
use std::path::Path;

pub fn emit_target(
    ir: &IrProgram,
    target: &str,
    out_dir: &str,
    production: bool,
) -> Result<(), String> {
    if !Path::new(out_dir).exists() {
        fs::create_dir_all(out_dir).map_err(|e| format!("cannot create {out_dir}: {e}"))?;
    }

    match target {
        "web" => write_output(WebBackend.emit(ir)?, out_dir, production),
        "desktop" => write_output(DesktopBackend.emit(ir)?, out_dir, false),
        "multi" => {
            write_output(WebBackend.emit(ir)?, &format!("{out_dir}/web"), production)?;
            write_output(
                DesktopBackend.emit(ir)?,
                &format!("{out_dir}/desktop"),
                false,
            )
        }
        other => Err(format!("unsupported target: {other}")),
    }
}

fn write_output(output: BackendOutput, out_dir: &str, production: bool) -> Result<(), String> {
    if !Path::new(out_dir).exists() {
        fs::create_dir_all(out_dir).map_err(|e| format!("cannot create {out_dir}: {e}"))?;
    }

    for mut file in output.files {
        if production {
            if file.path.ends_with(".js") {
                file.content = minify_js(&file.content);
            } else if file.path.ends_with(".css") {
                file.content = minify_css(&file.content);
            }
        }

        let full = format!("{out_dir}/{}", file.path);
        fs::write(&full, file.content).map_err(|e| format!("cannot write {full}: {e}"))?;
    }

    Ok(())
}

fn minify_css(input: &str) -> String {
    let mut out = String::with_capacity(input.len());
    let chars: Vec<char> = input.chars().collect();
    let mut i = 0usize;
    let mut in_single = false;
    let mut in_double = false;
    let mut pending_space = false;

    while i < chars.len() {
        let ch = chars[i];
        if !in_single && !in_double && ch == '/' && i + 1 < chars.len() && chars[i + 1] == '*' {
            i += 2;
            while i + 1 < chars.len() && !(chars[i] == '*' && chars[i + 1] == '/') {
                i += 1;
            }
            i = (i + 2).min(chars.len());
            continue;
        }

        if ch == '\'' && !in_double {
            in_single = !in_single;
            if pending_space && needs_space_css(out.chars().last(), Some(ch)) {
                out.push(' ');
            }
            pending_space = false;
            out.push(ch);
            i += 1;
            continue;
        }
        if ch == '"' && !in_single {
            in_double = !in_double;
            if pending_space && needs_space_css(out.chars().last(), Some(ch)) {
                out.push(' ');
            }
            pending_space = false;
            out.push(ch);
            i += 1;
            continue;
        }

        if !in_single && !in_double && ch.is_whitespace() {
            pending_space = true;
            i += 1;
            continue;
        }

        if pending_space && needs_space_css(out.chars().last(), Some(ch)) {
            out.push(' ');
        }
        pending_space = false;
        out.push(ch);
        i += 1;
    }

    out.trim().to_string()
}

fn needs_space_css(prev: Option<char>, next: Option<char>) -> bool {
    let Some(a) = prev else { return false };
    let Some(b) = next else { return false };
    is_word_char(a) && is_word_char(b)
}

fn minify_js(input: &str) -> String {
    #[derive(Clone, Copy, PartialEq, Eq)]
    enum State {
        Normal,
        Single,
        Double,
        Template,
        LineComment,
        BlockComment,
    }

    let mut out = String::with_capacity(input.len());
    let chars: Vec<char> = input.chars().collect();
    let mut i = 0usize;
    let mut state = State::Normal;
    let mut pending_space = false;
    let mut escaped = false;

    while i < chars.len() {
        let ch = chars[i];
        let next = chars.get(i + 1).copied();

        match state {
            State::Normal => {
                if ch == '/' && next == Some('/') {
                    state = State::LineComment;
                    i += 2;
                    continue;
                }
                if ch == '/' && next == Some('*') {
                    state = State::BlockComment;
                    i += 2;
                    continue;
                }
                if ch.is_whitespace() {
                    pending_space = true;
                    i += 1;
                    continue;
                }
                if ch == '\'' {
                    if pending_space && needs_space_js(out.chars().last(), Some(ch)) {
                        out.push(' ');
                    }
                    pending_space = false;
                    state = State::Single;
                    escaped = false;
                    out.push(ch);
                    i += 1;
                    continue;
                }
                if ch == '"' {
                    if pending_space && needs_space_js(out.chars().last(), Some(ch)) {
                        out.push(' ');
                    }
                    pending_space = false;
                    state = State::Double;
                    escaped = false;
                    out.push(ch);
                    i += 1;
                    continue;
                }
                if ch == '`' {
                    if pending_space && needs_space_js(out.chars().last(), Some(ch)) {
                        out.push(' ');
                    }
                    pending_space = false;
                    state = State::Template;
                    escaped = false;
                    out.push(ch);
                    i += 1;
                    continue;
                }

                if pending_space && needs_space_js(out.chars().last(), Some(ch)) {
                    out.push(' ');
                }
                pending_space = false;
                out.push(ch);
                i += 1;
            }
            State::LineComment => {
                if ch == '\n' || ch == '\r' {
                    state = State::Normal;
                    pending_space = true;
                }
                i += 1;
            }
            State::BlockComment => {
                if ch == '*' && next == Some('/') {
                    state = State::Normal;
                    pending_space = true;
                    i += 2;
                } else {
                    i += 1;
                }
            }
            State::Single => {
                out.push(ch);
                if escaped {
                    escaped = false;
                } else if ch == '\\' {
                    escaped = true;
                } else if ch == '\'' {
                    state = State::Normal;
                }
                i += 1;
            }
            State::Double => {
                out.push(ch);
                if escaped {
                    escaped = false;
                } else if ch == '\\' {
                    escaped = true;
                } else if ch == '"' {
                    state = State::Normal;
                }
                i += 1;
            }
            State::Template => {
                out.push(ch);
                if escaped {
                    escaped = false;
                } else if ch == '\\' {
                    escaped = true;
                } else if ch == '`' {
                    state = State::Normal;
                }
                i += 1;
            }
        }
    }

    out.trim().to_string()
}

fn needs_space_js(prev: Option<char>, next: Option<char>) -> bool {
    let Some(a) = prev else { return false };
    let Some(b) = next else { return false };
    is_word_char(a) && is_word_char(b)
}

fn is_word_char(ch: char) -> bool {
    ch.is_ascii_alphanumeric() || ch == '_' || ch == '$'
}
