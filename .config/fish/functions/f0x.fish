function f0x
    set url $(pass f0x-url)
    set header "XWHO: $(pass f0x)"

    if isatty stdin
        if test (count $argv) -eq 0
            echo "usage: paste text | paste file"
            return 1
        end

        if test -f $argv[1]
            curl -fsS -H $header --data-binary @$argv[1] $url
        else
            printf "%s" "$argv" | curl -fsS -H $header --data-binary @- $url
        end
    else
        curl -fsS -H $header --data-binary @- $url
    end
end
