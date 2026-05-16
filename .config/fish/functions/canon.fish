function canon
    awk '
    {
        sub(/\r$/, "")              # remove CR
        gsub(/\t/, " ")             # tabs -> spaces
        gsub(/  +/, " ")            # collapse multiple spaces
        sub(/[ ]+$/, "")            # trim trailing spaces
        lines[++n] = $0
    }
    END {
        while (n > 0 && lines[n] == "")
            n--

        for (i = 1; i <= n; i++)
            print lines[i]

        print ""
    }'
end
