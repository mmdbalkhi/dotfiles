# PLUGINs
source "%val{config}/plugins/plug.kak/rc/plug.kak"
plug "andreyorst/plug.kak" noload
plug "andreyorst/smarttab.kak" defer smarttab %{
    set-option global softtabstop 2
}

# indent 
hook global WinCreate .* %{ expandtab }

# LSP
map global user l ':enter-user-mode lsp<ret>' -docstring 'LSP mode'

map global insert <tab> '<a-;>:try lsp-snippets-select-next-placeholders catch %{ execute-keys -with-hooks <lt>tab> }<ret>' -docstring 'Select next snippet placeholder'

map global object a '<a-semicolon>lsp-object<ret>' -docstring 'LSP any symbol'
map global object <a-a> '<a-semicolon>lsp-object<ret>' -docstring 'LSP any symbol'
map global object f '<a-semicolon>lsp-object Function Method<ret>' -docstring 'LSP function or method'
map global object t '<a-semicolon>lsp-object Class Interface Struct<ret>' -docstring 'LSP class interface or struct'
map global object d '<a-semicolon>lsp-diagnostic-object --include-warnings<ret>' -docstring 'LSP errors and warnings'
map global object D '<a-semicolon>lsp-diagnostic-object<ret>' -docstring 'LSP errors'

hook -group lsp-filetype-clangd global BufSetOption filetype=(?:c|cpp) %{
        set-option buffer lsp_servers %{
        [clangd]
        args = ["--log=error"]
        root_globs = ["compile_commands.json", ".clangd", ".git", ".hg"]
    }
}

hook -group lsp-filetype-python global BufSetOption filetype=python %{
    set-option buffer lsp_servers %{
        [pylsp]
        root_globs = ["requirements.txt", "setup.py", "pyproject.toml", ".git", ".hg"]
        settings_section = "_"
        [pylsp.settings._]
        # See https://github.com/python-lsp/python-lsp-server#configuration
        # pylsp.configurationSources = ["flake8"]
        pylsp.plugins.jedi_completion.include_params = true
		pylsp.plugins.autopep8.enabled = false
		pylsp.plugins.yapf.enabled = true
		pylsp.plugins.rope_autoimport.enabled = true
		pylsp.plugins.rope_autoimport.completions.enabled = false
		pylsp.plugins.rope_autoimport.code_actions.enabled = true

    }
	map global normal <c-i> ':lsp-code-actions<ret>'
	# set-option buffer lsp_servers %{
    #     [pyright-langserver]
    #     root_globs = ["requirements.txt", "setup.py", "pyproject.toml", "pyrightconfig.json", ".git", ".hg"]
    #     args = ["--stdio"]
    # }
    # set-option -add buffer lsp_servers %{
    #     [ruff]
    #     args = ["server", "--quiet"]
    #     root_globs = ["requirements.txt", "setup.py", "pyproject.toml", ".git", ".hg"]
    #     settings_section = "_"
    #     [ruff.settings._.globalSettings]
    #     organizeImports = true
    #     fixAll = true
    # }
}

hook -group lsp-filetype-go global BufSetOption filetype=go %{
    set-option buffer lsp_servers %{
        [gopls]
        root_globs = ["Gopkg.toml", "go.mod", ".git", ".hg"]
        [gopls.settings.gopls]
        # See https://github.com/golang/tools/blob/master/gopls/doc/settings.md
        # "build.buildFlags" = []
        hints.assignVariableTypes = true
        hints.compositeLiteralFields = true
        hints.compositeLiteralTypes = true
        hints.constantValues = true
        hints.functionTypeParameters = true
        hints.parameterNames = true
        hints.rangeVariableTypes = true
        usePlaceholders = true
    }
}

hook -group lsp-filetype-rust global BufSetOption filetype=rust %{
    set-option buffer lsp_servers %{
        [rust-analyzer]
        root_globs = ["Cargo.toml"]
        single_instance = true
        command = "sh"
        args = [
            "-c",
            """
                if path=$(rustup which rust-analyzer 2>/dev/null); then
                    exec "$path"
                else
                    exec rust-analyzer
                fi
            """,
        ]
        [rust-analyzer.experimental]
        commands.commands = ["rust-analyzer.runSingle"]
        hoverActions = true
        [rust-analyzer.settings.rust-analyzer]
        # See https://rust-analyzer.github.io/manual.html#configuration
        # cargo.features = []
        check.command = "clippy"
    }
}

eval %sh{kak-lsp --kakoune -s $kak_session}
lsp-enable

