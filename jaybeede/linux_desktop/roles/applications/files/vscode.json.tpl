{
    "[dockerfile]": {
        "editor.defaultFormatter": "ms-azuretools.vscode-docker"
    },
    "search.followSymlinks": false,
    "debug.console.fontSize": 12,
    "debug.console.lineHeight": 7,
    "diffEditor.ignoreTrimWhitespace": false,
    "editor.copyWithSyntaxHighlighting": false,
    "editor.fontSize": 12,
    "editor.largeFileOptimizations": true,
    "editor.mouseWheelZoom": true,
    "editor.renderWhitespace": "none",
    "editor.tokenColorCustomizations": {
        "textMateRules": [
            {
                "scope": "log.error",
                "settings": {
                    "fontStyle": "bold"
                }
            },
            {
                "scope": "log.warning",
                "settings": {
                    "fontStyle": "bold"
                }
            }
        ]
    },
    "editor.wordWrap": "on",
    "explorer.confirmDelete": false,
    "files.associations": {
        "*.inc": "perl",
        "Dockerfile": "dockerfile"
    },
    "files.exclude": {
        "**/.git/**": true,
        ".*/": true,
        "**/*.old.tar.gz": true,
        "**/*.old": true,
        "**/*.bck": true,
        "**/*.tdy": true,
        "**/*~": true,
        "**/.code-workspace": true,
        "**/.vscode": true
    },
    "files.hotExit": "off",
    "files.watcherExclude": {
        "**/.git/**": true,
        ".*/": true,
        "**/*.old.tar.gz": true,
        "**/*.old": true,
        "**/*.bck": true,
        "**/*.tdy": true,
        "**/*~": true,
        "**/.code-workspace": true,
        "**/.vscode": true
    },
    "git.autofetch": "all",
    "git.autorefresh": true,
    "logFileHighlighter.customPatterns": [
        {
            "pattern": "^.*(ok|success|Ok|OK|Success|SUCCESS).*$",
            "background": "#00FF6A",
            "foreground": "#000000",
            "fontStyle": "bold"
        },
        {
            "pattern": "^.*(info|Info|INFO).*$",
            "background": "#0046FF",
            "foreground": "#FFFFFF",
            "fontStyle": "bold"
        },
        {
            "pattern": "^.*(warn|Warn|WARN|unable|Unable|UNABLE|cannot|Cannot|CANNOT|can't|CAN'T).*$",
            "background": "#f4ad42",
            "foreground": "#000000",
            "fontStyle": "bold"
        },
        {
            "pattern": "^.*(fail|error|Fail|Error|FAIL|ERROR).*$",
            "background": "#af1f1f",
            "foreground": "#FFFFFF",
            "fontStyle": "bold"
        }
    ],
    "notebook.cellToolbarLocation": {
        "default": "right",
        "jupyter-notebook": "left"
    },
    "python.formatting.autopep8Args": [
        "--max-line-length=500",
        "--indent-size=4",
        "--ignore=E402"
    ],
    "python.linting.pylintEnabled": true,
    "python.linting.pylintArgs": [
        "-r",
        "n",
        "--rcfile",
        "/dev/null",
        "--disable",
        "attribute-defined-outside-init, import-error, inconsistent-return-statements, invalid-name, line-too-long, locally-disabled, logging-not-lazy, missing-docstring, no-name-in-module, no-self-use, too-many-branches, too-many-instance-attributes, too-many-locals, too-many-nested-blocks, too-many-statements, bare-except"
    ],
    "security.workspace.trust.banner": "never",
    "security.workspace.trust.enabled": false,
    "security.workspace.trust.startupPrompt": "never",
    "security.workspace.trust.untrustedFiles": "open",
    "shellcheck.enableQuickFix": true,
    "shellcheck.exclude": [],
    "shellcheck.ignorePatterns": {
        "**/.git/*.*": true,
        "**/Personal-Wiki/**/*.*": true,
        "**/*.zsh": true
    },
    "shellcheck.run": "onSave",
    "shellcheck.customArgs": [
        "-x",
        "-a",
        "-P",
        "--"
    ],
    "update.mode": "none",
    "update.showReleaseNotes": false,
    "window.menuBarVisibility": "visible",
    "window.newWindowDimensions": "maximized",
    "window.restoreWindows": "folders",
    "window.titleBarStyle": "custom",
    "workbench.activityBar.visible": false,
    "workbench.editor.revealIfOpen": true,
    "workbench.editor.wrapTabs": true,
    "workbench.editorAssociations": {
        "*.ipynb": "jupyter-notebook"
    },
    "workbench.startupEditor": "newUntitledFile",
    "workbench.statusBar.visible": true,
    "extensions.ignoreRecommendations": true,
    "zenMode.silentNotifications": false,
    "redhat.telemetry.enabled": false,
    "yaml.format.bracketSpacing": true,
    "[yaml]": {
        "editor.autoIndent": "full"
    },
    "yaml.yamlVersion": "1.2",
    "yaml.format.singleQuote": false,
    "markdown.preview.fontSize": 15,
    "notebook.diff.enablePreview": true,
    "simple-perl.perltidyArgs": [
        "-l=0",
        "-q"
    ],
    "markdownlint.config": {
        "MD004": false,
        "MD033": false
    },
    "[markdown]": {
        "editor.defaultFormatter": "DavidAnson.vscode-markdownlint"
    },
    "[shellscript]": {
        "editor.defaultFormatter": "mkhl.shfmt"
    },
    "git-graph.maxDepthOfRepoSearch": 10,
    "hadolint.cliOptions": [
        "--ignore=DL3006",
        "--ignore=DL3007",
        "--ignore=DL3008",
        "--ignore=DL3013",
        "--ignore=DL3016",
        "--ignore=DL3018",
        "--ignore=DL3028",
        "--no-color"
    ],
    "[css]": {
        "editor.defaultFormatter": "vscode.css-language-features"
    },
    "[scss]": {
        "editor.defaultFormatter": "lonefy.vscode-JS-CSS-HTML-formatter"
    },
    "yaml.schemas": {
        "https://json.schemastore.org/github-workflow": "/.github/workflows/**/*.yml"
    },
    "html.format.wrapLineLength": 0,
    "cSpell.enableFiletypes": [
        "markdown"
    ],
    "cSpell.language": "en,fr",
    "cSpell.userWords": [
        "ansible",
        "jaybeede",
        "linux",
        "unblank"
    ],
    "workbench.colorTheme": "Custom Accentuation Color Dark High Contrast",
    "luahelper.format.column_limit": 500,
    "cacdhc.accentuationColor": "{{ theme_primary_color }}"
}