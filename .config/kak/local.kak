# PLUGINs
source "%val{config}/plugins/plug.kak/rc/plug.kak"
plug "andreyorst/plug.kak" noload
plug "andreyorst/kaktree" config %{
    hook global WinSetOption filetype=kaktree %{
        remove-highlighter buffer/numbers
        remove-highlighter buffer/matching
        remove-highlighter buffer/wrap
        remove-highlighter buffer/show-whitespaces
    }
    kaktree-enable
}

plug "andreyorst/smarttab.kak" defer smarttab %{
     set-option global softtabstop 4
}

hook global WinCreate .* %{ expandtab }

eval %sh{kak-lsp --kakoune -s $kak_session}
lsp-enable

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

lsp-inlay-diagnostics-enable global
