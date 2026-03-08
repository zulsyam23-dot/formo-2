token {
  color.surface = #ffffff;
  color.accent = #0a84ff;
  color.accentSoft = #e8f1ff;
  color.text = #2f3542;
  radius.md = 12dp;
  space.sm = 8dp;
  space.md = 12dp;
  text.h1 = 20px;
  text.body = 16px;
}

style HeaderFrame {
  background: token(color.surface);
  border: 1px solid #d5dced;
  border-radius: token(radius.md);
  padding: token(space.md);
}

style Heading {
  color: token(color.accent);
  font-size: token(text.h1);
  font-weight: 700;
}

style BodyText {
  color: token(color.text);
  font-size: token(text.body);
}

style CardFrame {
  background: token(color.surface);
  border: 1px solid #d5dced;
  border-radius: token(radius.md);
  padding: token(space.md);
  margin-top: token(space.md);
}

style PrimaryButton {
  background: token(color.accentSoft);
  border: 1px solid token(color.accent);
  border-radius: token(radius.md);
  padding: token(space.sm);
}
