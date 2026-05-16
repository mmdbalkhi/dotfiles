function ipinfo
    curl -H "Authorization: Bearer $(pass ipinfo)" https://ipinfo.io/$argv[1] | jq
end
