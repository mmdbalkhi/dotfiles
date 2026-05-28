# Kanagawa Dragon for Kakoune

evaluate-commands %sh{
    bg='rgb:181616'
    bg_dim='rgb:1f1f28'
    bg_mid='rgb:282727'
    bg_light='rgb:2d2a2e'

    fg='rgb:c5c9c5'
    fg_soft='rgb:a6a69c'
    fg_dim='rgb:727169'

    red='rgb:c4746e'
    orange='rgb:b6927b'
    yellow='rgb:e6c384'
    green='rgb:87a987'
    cyan='rgb:7fb4ca'
    blue='rgb:8ba4b0'
    purple='rgb:938aa9'
    pink='rgb:a292a3'

    sel='rgb:2d4f67'
    sel_soft='rgb:223249'

    echo "
        # markup
        set-face global title   ${yellow}+b
        set-face global header  ${blue}+b
        set-face global bold    ${orange}+b
        set-face global italic  ${pink}+i
        set-face global mono    ${green}
        set-face global block   ${cyan}
        set-face global link    ${cyan}
        set-face global bullet  ${orange}
        set-face global list    ${orange}

        # ui
        set-face global Default            ${fg},${bg}
        set-face global PrimarySelection   ${fg},${sel}
        set-face global SecondarySelection ${fg_soft},${sel_soft}

        set-face global PrimaryCursor      ${bg},${red}
        set-face global SecondaryCursor    ${fg},${fg_dim}

        set-face global PrimaryCursorEol   ${bg_mid},${yellow}
        set-face global SecondaryCursorEol ${bg_mid},${fg_dim}

        set-face global LineNumbers        ${fg_dim},${bg}
        set-face global LineNumberCursor   ${yellow},${bg_mid}+b
        set-face global LineNumbersWrapped ${pink},${bg_mid}

        set-face global MenuForeground     ${fg},${bg_mid}+b
        set-face global MenuBackground     ${fg},${bg_light}

        set-face global MenuInfo           ${bg},${cyan}
        set-face global Information        ${bg},${cyan}
        set-face global Error              ${bg},${red}

        set-face global StatusLine         ${fg},${bg_mid}
        set-face global StatusLineMode     ${bg},${purple}+b
        set-face global StatusLineInfo     ${bg},${cyan}
        set-face global StatusLineValue    ${bg},${yellow}
        set-face global StatusCursor       ${bg},${red}

        set-face global Prompt             ${cyan},${bg}+b

        set-face global MatchingChar       ${yellow},${bg}+b

        set-face global Whitespace         ${fg_dim},${bg}+f
        set-face global WrapMarker         Whitespace
        set-face global BufferPadding      ${bg},${bg}

        # syntax
        set-face global value         ${orange}
        set-face global type          ${blue}
        set-face global variable      ${fg}
        set-face global module        ${pink}
        set-face global function      ${cyan}
        set-face global string        ${green}
        set-face global keyword       ${red}+b
        set-face global operator      ${pink}
        set-face global attribute     ${yellow}
        set-face global comment       ${fg_dim}+i
        set-face global documentation comment
        set-face global meta          ${yellow}
        set-face global builtin       ${red}

        # diagnostics
        set-face global DiagnosticError   ${red}
        set-face global DiagnosticWarning ${yellow}
        set-face global DiagnosticHint    ${green}
        set-face global DiagnosticInfo    ${cyan}
    "
}
