function extract
    for file in $argv
        if test -f $file
            switch $file
                case "*.tar.gz" "*.tgz" "*.tar" "*.tbz2"
                    tar xvf $file
                case "*.bz2"
                    bunzip2 $file
                case "*.gz"
                    gunzip $file
                case "*.rar"
                    unrar x -ad $file
                case "*.zip" "*.cbz" "*.epub"
                    unzip $file
                case "*.7z"
                    7z x $file
                case "*.xz"
                    unxz $file
                case "*"
                    echo "unknown archive: $file"
            end
        else
            echo "$file does not exist"
        end
    end
end
