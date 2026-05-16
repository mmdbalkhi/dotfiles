function udawn
    set SECRET "$(pass udawn)"
    set HOST "$(pass udawn-url)"

    if test (count $argv) -eq 0
        echo "Usage: gen_upload_url filename.ext"
        return 1
    end

    set FILE (echo -n $argv[1] | tr -d '\n' | jq -s -R -r @uri | tr -d '=')

    set EXPIRES (math (date +%s) + 900)

    set TOKEN (echo -n "$EXPIRES,$SECRET" | openssl dgst -md5 -binary | openssl base64 | tr '+/' '-_' | tr -d '=')

    echo "$HOST/upload/$TOKEN/$FILE?expires=$EXPIRES"
end
