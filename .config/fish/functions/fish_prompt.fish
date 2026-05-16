function fish_prompt
    # This is a simple prompt. It looks like
    # alfa@nobby /path/to/dir $
    # with the path shortened and colored
    # and a "#" instead of a "$" when run as root.
    set last_status $status
    set cmd_duration $CMD_DURATION

    set -l symbol '% '
    set -l color $fish_color_cwd
    if fish_is_root_user
        set symbol '# '
        set -q fish_color_cwd_root
        and set color $fish_color_cwd_root
    end
    
    echo -n $USER@$hostname
    
    set_color $color
    echo -n (prompt_pwd)
    set_color --reset

    # git
    echo -n (fish_vcs_prompt)

    # command duration
    if test $cmd_duration -gt 500
        set secs (math "$cmd_duration / 1000")
        set_color $color
        printf " [%ss]" $secs
    end

    # exit status
    if test $last_status -ne 0
        set_color red
        printf " [%d]" $last_status
        set_color --reset
    end
    echo -n $symbol
end
