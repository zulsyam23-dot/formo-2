const cp = require("child_process");
const fs = require("fs");
const path = require("path");
const vscode = require("vscode");

const FORMO_EXTENSIONS = new Set([".fm", ".fs", ".fl"]);
const FORMO_LANGUAGE_IDS = new Set(["formo-fm", "formo-fs", "formo-fl"]);

const HOVER_DOCS = {
  import:
    "**Formo `import`**\n\nGunakan untuk memuat module `.fm`/`.fs`.\nAlias sebaiknya PascalCase.",
  component:
    "**Formo `component`**\n\nDeklarasi UI reusable dengan satu root node.",
  token:
    "**Formo `token`**\n\nDeklarasi design token (warna, ukuran, radius, tipografi).",
  style:
    "**Formo `style`**\n\nDeklarasi style reusable. Nilai token dipanggil dengan `token(...)`.",
  logic:
    "**Formo `logic`**\n\nUnit logika utama. Event harus punya minimal satu global action.",
  service:
    "**Formo `service`**\n\nUnit logika reusable dan platform-agnostic (tanpa `platform web/desktop`).",
  adapter:
    "**Formo `adapter`**\n\nJembatan ke runtime/IO. Event adapter hanya boleh `action call`.",
  contract:
    "**Formo `contract`**\n\nKontrak perilaku lintas module. Event contract tanpa action.",
  state:
    "**Formo `state`**\n\nField state harus lowerCamelCase, bertipe, dan punya initializer.",
  event:
    "**Formo `event`**\n\nTrigger unit perilaku. Untuk FL gunakan lowerCamelCase.",
  action:
    "**Formo `action`**\n\nAksi event: `call`, `set`, `emit`, `throw`, `break`, `continue`, `return`.",
  platform:
    "**Formo `platform`**\n\nBlok platform FL. Gunakan urutan desktop dulu lalu web (desktop-first).",
  call:
    "**Formo `action call`**\n\nFormat valid: `action call Alias.member;` (wajib diakhiri `;`).",
  set:
    "**Formo `action set`**\n\nFormat valid: `action set field = expression;`.\nTarget harus field dari blok `state`.",
  emit: "**Formo `action emit`**\n\nMengirim signal/event internal.",
  throw:
    "**Formo `action throw`**\n\nHanya valid di dalam blok `try` atau `catch`.",
  web: "**Formo `platform web`**\n\nBlok aksi spesifik runtime web.",
  desktop: "**Formo `platform desktop`**\n\nBlok aksi spesifik runtime desktop.",
  if: "**Formo `if`**\n\nKontrol kondisi; blok harus berisi minimal satu action.",
  for: "**Formo `for`**\n\nKontrol iterasi; blok harus berisi minimal satu action.",
  while:
    "**Formo `while`**\n\nKontrol loop; `action break/continue` hanya valid di loop.",
  match: "**Formo `match`**\n\nKontrol percabangan pattern matching.",
  try: "**Formo `try`**\n\nKontrol penanganan error.",
  catch: "**Formo `catch`**\n\nPasangan dari `try`."
};

function isFormoDocument(document) {
  if (!document || document.isUntitled) {
    return false;
  }
  const ext = path.extname(document.fileName).toLowerCase();
  return FORMO_LANGUAGE_IDS.has(document.languageId) || FORMO_EXTENSIONS.has(ext);
}

function normalizeFsPath(p) {
  return path.resolve(p).replace(/\\/g, "/").toLowerCase();
}

function normalizeRelativePath(p) {
  return p.replace(/\\/g, "/");
}

function isAbsolutePathLike(p) {
  return /^[a-zA-Z]:[\\/]/.test(p) || p.startsWith("/") || p.startsWith("\\\\");
}

function extractLastJsonLine(output) {
  if (!output) {
    return null;
  }
  const lines = output.split(/\r?\n/);
  let parsed = null;
  for (const line of lines) {
    const t = line.trim();
    if (!t.startsWith("{") || !t.endsWith("}")) {
      continue;
    }
    try {
      parsed = JSON.parse(t);
    } catch {
      // ignore non-json lines
    }
  }
  return parsed;
}

function toRange(document, line, col) {
  const safeLine = Math.max(0, Math.min((line || 1) - 1, Math.max(document.lineCount - 1, 0)));
  const lineText = document.lineCount > 0 ? document.lineAt(safeLine).text : "";
  const maxCol = lineText.length;
  const safeCol = Math.max(0, Math.min((col || 1) - 1, maxCol));
  const start = new vscode.Position(safeLine, safeCol);
  const endCol = maxCol === 0 ? safeCol : Math.min(safeCol + 1, maxCol);
  const end = new vscode.Position(safeLine, endCol);
  return new vscode.Range(start, end);
}

function toDiagnostic(document, entry) {
  const message = entry.message || "Formo validation failed.";
  const range = toRange(document, entry.line, entry.col);
  const diagnostic = new vscode.Diagnostic(
    range,
    message,
    vscode.DiagnosticSeverity.Error
  );
  diagnostic.source = "formo";
  if (entry.code) {
    diagnostic.code = entry.code;
  }
  return diagnostic;
}

function matchesCurrentDocument(workspaceRoot, document, fileField) {
  if (!fileField || !workspaceRoot) {
    return false;
  }
  const absolute = isAbsolutePathLike(fileField)
    ? fileField
    : path.join(workspaceRoot, fileField);
  return normalizeFsPath(absolute) === normalizeFsPath(document.fileName);
}

function collectDiagnosticsForDocument(workspaceRoot, document, cliJson) {
  const diagnostics = [];
  if (!cliJson || typeof cliJson !== "object") {
    return diagnostics;
  }

  if (Array.isArray(cliJson.diagnostics)) {
    for (const item of cliJson.diagnostics) {
      if (matchesCurrentDocument(workspaceRoot, document, item.file)) {
        diagnostics.push(toDiagnostic(document, item));
      }
    }
  }

  if (cliJson.errorMeta && typeof cliJson.errorMeta === "object") {
    const err = cliJson.errorMeta;
    if (
      !err.file ||
      matchesCurrentDocument(workspaceRoot, document, err.file)
    ) {
      diagnostics.push(
        toDiagnostic(document, {
          code: err.code,
          line: err.line,
          col: err.col,
          message: err.message || cliJson.error || "Formo error."
        })
      );
    }
  } else if (cliJson.ok === false && diagnostics.length === 0) {
    diagnostics.push(
      toDiagnostic(document, {
        line: 1,
        col: 1,
        message: cliJson.error || "Formo validation failed."
      })
    );
  }

  return diagnostics;
}

function buildValidationArgs(workspaceRoot, document) {
  const ext = path.extname(document.fileName).toLowerCase();
  const relativePath = normalizeRelativePath(
    path.relative(workspaceRoot, document.fileName)
  );

  if (ext === ".fl") {
    return ["logic", "--input", relativePath, "--json"];
  }

  const mainPath = path.join(workspaceRoot, "main.fm");
  const inputPath = fs.existsSync(mainPath) ? "main.fm" : relativePath;
  return ["check", "--input", normalizeRelativePath(inputPath), "--json"];
}

function runFormoCli(workspaceRoot, args) {
  return new Promise((resolve) => {
    const scriptPath = path.join(workspaceRoot, "scripts", "formo2_cli.ps1");
    if (!fs.existsSync(scriptPath)) {
      resolve({
        json: null,
        output: `missing script: ${scriptPath}`,
        error: new Error("formo2_cli.ps1 not found")
      });
      return;
    }

    const pwshArgs = [
      "-ExecutionPolicy",
      "Bypass",
      "-File",
      scriptPath,
      ...args
    ];
    cp.execFile(
      "powershell",
      pwshArgs,
      {
        cwd: workspaceRoot,
        windowsHide: true,
        maxBuffer: 16 * 1024 * 1024
      },
      (error, stdout, stderr) => {
        const output = `${stdout || ""}\n${stderr || ""}`.trim();
        resolve({
          json: extractLastJsonLine(output),
          output,
          error
        });
      }
    );
  });
}

function adviceForDiagnostic(message, languageId) {
  const advice = [];
  const msg = (message || "").toLowerCase();

  if (msg.includes("must terminate with `;`")) {
    advice.push("Tambahkan `;` di akhir statement `action call` / `action set`.");
  }
  if (msg.includes("desktop-first policy")) {
    advice.push("Urutkan blok platform: `platform desktop` dulu, lalu `platform web`.");
  }
  if (msg.includes("symmetric web/desktop")) {
    advice.push("Samakan jumlah aksi di blok `platform desktop` dan `platform web`.");
  }
  if (msg.includes("unknown call alias")) {
    advice.push("Pastikan alias ada di `use \"...\" as Alias;` dan dipakai dengan format `Alias.member`.");
  }
  if (msg.includes("unknown state field")) {
    advice.push("Deklarasikan field di blok `state` sebelum dipakai oleh `action set`.");
  }
  if (msg.includes("direct runtime alias")) {
    advice.push("Pindahkan akses `Browser`/`Desktop` ke unit `adapter`, lalu panggil lewat alias adapter.");
  }
  if (msg.includes("expected `import` or `component`")) {
    advice.push("Untuk validasi `.fm/.fs`, pastikan entry project benar (umumnya `main.fm`).");
  }
  if (advice.length === 0) {
    advice.push("Jalankan `Formo: Validate Current File` untuk refresh diagnostik terbaru.");
    if (languageId === "formo-fl") {
      advice.push("Cek rule FL di `docs/FORMO_LOGIC_LAYER.md`.");
    }
  }

  return advice;
}

function activate(context) {
  const diagnostics = vscode.languages.createDiagnosticCollection("formo");
  const output = vscode.window.createOutputChannel("Formo Advisor");
  const timers = new Map();
  const running = new Set();
  const rerun = new Set();

  context.subscriptions.push(diagnostics, output);

  const validateNow = async (document) => {
    if (!isFormoDocument(document)) {
      return;
    }
    const folder = vscode.workspace.getWorkspaceFolder(document.uri);
    if (!folder) {
      return;
    }
    const workspaceRoot = folder.uri.fsPath;
    const docKey = normalizeFsPath(document.fileName);

    if (running.has(docKey)) {
      rerun.add(docKey);
      return;
    }

    running.add(docKey);
    try {
      const args = buildValidationArgs(workspaceRoot, document);
      const result = await runFormoCli(workspaceRoot, args);
      if (!result.json) {
        diagnostics.set(
          document.uri,
          [
            toDiagnostic(document, {
              line: 1,
              col: 1,
              message: `Formo extension tidak bisa membaca output JSON validator.\n${result.output || ""}`
            })
          ]
        );
        return;
      }
      const docDiagnostics = collectDiagnosticsForDocument(
        workspaceRoot,
        document,
        result.json
      );
      diagnostics.set(document.uri, docDiagnostics);
    } finally {
      running.delete(docKey);
      if (rerun.has(docKey)) {
        rerun.delete(docKey);
        validateNow(document);
      }
    }
  };

  const scheduleValidation = (document, immediate = false) => {
    if (!isFormoDocument(document)) {
      return;
    }
    const key = normalizeFsPath(document.fileName);
    const oldTimer = timers.get(key);
    if (oldTimer) {
      clearTimeout(oldTimer);
    }

    const config = vscode.workspace.getConfiguration("formo");
    const debounceMs = Math.max(150, Number(config.get("validation.debounceMs", 800)));
    const wait = immediate ? 0 : debounceMs;

    const timer = setTimeout(() => {
      timers.delete(key);
      validateNow(document);
    }, wait);
    timers.set(key, timer);
  };

  context.subscriptions.push(
    vscode.commands.registerCommand("formo.validateCurrent", async () => {
      const editor = vscode.window.activeTextEditor;
      if (!editor || !isFormoDocument(editor.document)) {
        vscode.window.showInformationMessage("Tidak ada file Formo aktif.");
        return;
      }
      await validateNow(editor.document);
      const current = diagnostics.get(editor.document.uri) || [];
      vscode.window.showInformationMessage(
        current.length === 0
          ? "Formo validation: tidak ada error."
          : `Formo validation: ${current.length} error.`
      );
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand("formo.explainDiagnostic", async () => {
      const editor = vscode.window.activeTextEditor;
      if (!editor || !isFormoDocument(editor.document)) {
        vscode.window.showInformationMessage("Tidak ada file Formo aktif.");
        return;
      }
      const currentDiagnostics = diagnostics.get(editor.document.uri) || [];
      if (currentDiagnostics.length === 0) {
        vscode.window.showInformationMessage("Tidak ada diagnostic untuk dijelaskan.");
        return;
      }
      const line = editor.selection.active.line;
      const target =
        currentDiagnostics.find((d) => d.range.contains(new vscode.Position(line, 0))) ||
        currentDiagnostics[0];
      const advice = adviceForDiagnostic(target.message, editor.document.languageId);
      output.clear();
      output.appendLine("Formo Advisor");
      output.appendLine("================");
      output.appendLine(`Diagnostic: ${target.message}`);
      output.appendLine("");
      output.appendLine("Saran:");
      for (const item of advice) {
        output.appendLine(`- ${item}`);
      }
      output.show(true);
    })
  );

  const quickFixProvider = {
    provideCodeActions(document, _range, context) {
      const actions = [];
      const folder = vscode.workspace.getWorkspaceFolder(document.uri);
      const docsPath = folder
        ? path.join(folder.uri.fsPath, "docs", "FORMO_LOGIC_LAYER.md")
        : null;

      for (const diagnostic of context.diagnostics) {
        const msg = diagnostic.message || "";
        if (/must terminate with `;`/i.test(msg)) {
          const line = diagnostic.range.start.line;
          const lineText = document.lineAt(line).text;
          if (!lineText.trimEnd().endsWith(";")) {
            const edit = new vscode.WorkspaceEdit();
            edit.insert(
              document.uri,
              new vscode.Position(line, lineText.length),
              ";"
            );
            const fix = new vscode.CodeAction(
              "Formo: Add missing ';'",
              vscode.CodeActionKind.QuickFix
            );
            fix.edit = edit;
            fix.isPreferred = true;
            fix.diagnostics = [diagnostic];
            actions.push(fix);
          }
        }

        if (
          /desktop-first policy|symmetric web\/desktop|grouped as desktop then web/i.test(msg) &&
          docsPath &&
          fs.existsSync(docsPath)
        ) {
          const openDocs = new vscode.CodeAction(
            "Formo: Open FL parity rules",
            vscode.CodeActionKind.QuickFix
          );
          openDocs.command = {
            command: "vscode.open",
            title: "Open FL rules",
            arguments: [vscode.Uri.file(docsPath)]
          };
          openDocs.diagnostics = [diagnostic];
          actions.push(openDocs);
        }
      }
      return actions;
    }
  };

  context.subscriptions.push(
    vscode.languages.registerCodeActionsProvider(
      "formo-fl",
      quickFixProvider,
      { providedCodeActionKinds: [vscode.CodeActionKind.QuickFix] }
    )
  );

  context.subscriptions.push(
    vscode.languages.registerHoverProvider(
      ["formo-fm", "formo-fs", "formo-fl"],
      {
        provideHover(document, position) {
          const range = document.getWordRangeAtPosition(
            position,
            /[A-Za-z_][A-Za-z0-9_]*/
          );
          if (!range) {
            return undefined;
          }
          const word = document.getText(range);
          const content = HOVER_DOCS[word];
          if (!content) {
            return undefined;
          }
          const markdown = new vscode.MarkdownString(content);
          markdown.isTrusted = false;
          return new vscode.Hover(markdown, range);
        }
      }
    )
  );

  context.subscriptions.push(
    vscode.workspace.onDidOpenTextDocument((document) => {
      if (isFormoDocument(document)) {
        scheduleValidation(document, true);
      }
    })
  );

  context.subscriptions.push(
    vscode.workspace.onDidSaveTextDocument((document) => {
      if (isFormoDocument(document)) {
        scheduleValidation(document, true);
      }
    })
  );

  context.subscriptions.push(
    vscode.workspace.onDidChangeTextDocument((event) => {
      const document = event.document;
      if (!isFormoDocument(document)) {
        return;
      }
      const trigger = vscode.workspace
        .getConfiguration("formo")
        .get("validation.trigger", "onSave");
      if (trigger === "onType") {
        scheduleValidation(document, false);
      }
    })
  );

  context.subscriptions.push(
    vscode.workspace.onDidCloseTextDocument((document) => {
      if (isFormoDocument(document)) {
        diagnostics.delete(document.uri);
      }
      const key = normalizeFsPath(document.fileName || "");
      const timer = timers.get(key);
      if (timer) {
        clearTimeout(timer);
        timers.delete(key);
      }
    })
  );

  if (vscode.window.activeTextEditor && isFormoDocument(vscode.window.activeTextEditor.document)) {
    scheduleValidation(vscode.window.activeTextEditor.document, true);
  }
}

function deactivate() {}

module.exports = {
  activate,
  deactivate
};
