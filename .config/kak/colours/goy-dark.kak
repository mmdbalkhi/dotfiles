# Goy Dark for Kakoune
# Dark glazed surfaces with mineral blue, turquoise and sage.

evaluate-commands %sh{
    bg='rgb:263335'
    bg_dim='rgb:202C2E'
    bg_mid='rgb:2E3D3E'
    bg_light='rgb:344647'

    fg='rgb:E0E8E4'
    fg_soft='rgb:91A9A0'
    fg_dim='rgb:6B8C85' # Slightly darker than fg_soft for comments/whitespace

    red='rgb:D2837C'
    orange='rgb:C6A16A' # Goy warning
    yellow='rgb:C5A96F' # Goy constant
    green='rgb:91B18C'
    cyan='rgb:75B7B0'   # Goy type
    blue='rgb:91AFCB'   # Goy keyword
    purple='rgb:B8A0B6' # Goy magenta
    pink='rgb:B0C5BE'   # Goy fnname

    sel='rgb:46605F'    # Goy bg-region
    sel_soft='rgb:344647' # Goy bg-hl-line

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
        set-face global StatusLineMode     ${bg},${blue}+b
        set-face global StatusLineInfo     ${bg},${cyan}
        set-face global StatusLineValue    ${bg},${yellow}
        set-face global StatusCursor       ${bg},${red}

        set-face global Prompt             ${cyan},${bg}+b

        set-face global MatchingChar       ${yellow},${bg}+b

        set-face global Whitespace         ${fg_dim},${bg}+f
        set-face global WrapMarker         Whitespace
        set-face global BufferPadding      ${bg},${bg}

        # syntax
        set-face global value         ${yellow}
        set-face global type          ${cyan}
        set-face global variable      ${fg}
        set-face global module        ${purple}
        set-face global function      ${pink}
        set-face global string        ${green}
        set-face global keyword       ${blue}+b
        set-face global operator      ${fg_soft}
        set-face global attribute     ${yellow}
        set-face global comment       ${fg_dim}+i
        set-face global documentation comment
        set-face global meta          ${yellow}
        set-face global builtin       ${red}

        # diagnostics
        set-face global DiagnosticError   ${red}
        set-face global DiagnosticWarning ${orange}
        set-face global DiagnosticHint    ${green}
        set-face global DiagnosticInfo    ${cyan}
    "
}
