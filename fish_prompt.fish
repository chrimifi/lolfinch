# prompt name: lolfinch
# prompt requires: jobs (fish builtin), git, hostname, sed


function lolfish -d "such rainbow. very newline. wow"

    # xterm-256color RGB color values
    # valid R G B hex values : 00, 57, 87, af, d7, ff
    #
    # red    ff0000
    # yellow ffff00
    # green  00ff00
    # blue   0000ff

    set -l colors ff0000 ff5700 ff8700 ffaf00 ffd700\
                  ffff00 d7ff00 afff00 87ff00 57ff00\
                  00ff00 00ff57 00ff87 00ffaf 00ffd7\
                  00ffff 00d7ff 00afff 0087ff 0057ff\
                  0000ff 5700ff 8700ff af00ff d700ff\
                  ff00ff ff00d7 ff00af ff0087 ff0057

    #
    # $colors[n]: color
    # n=1  : red
    # n=6  : yellow
    # n=16 : green
    # n=21 : blue
    # n=26 : magenta
    #
    # start with a random color
    if test -z $lolfish_next_color
        # Use a global variable for lolfish_next_color so the next
        # iteration of the prompt can continue the color sequence.
        set -g lolfish_next_color (math (random)%(count $colors plus_one))
    else if test $lolfish_next_color -gt (count $colors); or test $lolfish_next_color -le 0
        # Reset lolfish_next_color to the beginning when
        # it grows beyond the valid color range.
        set lolfish_next_color 1
    end

    # Set the color differential between prompt items.
    # Lower values produce a smoother rainbow effect.
    # Values between 1 and 5 work best.
    # 10 produces a pure RGB rainbow.
    # 5 works best for non 256 color terminals.

    set -l color_step 1

    # start the printing process
    for arg in $argv

        # print these special characters in normal color
        switch $arg
            case ' ' \( \) \[ \] \$ \# \@ \{ \} \/ \n
                set_color -o normal
                echo -n -s $arg
                continue
            case ✓
                set_color -o green
                echo -n -s $arg
                continue
            case ✗
                set_color -o red
                echo -n -s $arg
                continue
        end

        # saftey checks
        if test -z $color
            # set $color if it's not set yet
            set color $lolfish_next_color
        else if test $color -gt (count $colors); or test $color -le 0
            # Reset color to the beginning when it grows
            # beyond the valid color range.
            set color 1
        end

        set_color -o $colors[$color]
        echo -n -s $arg
        set color (math $color + $color_step)
    end

    # increment lolfish_next_color to use for the start of the next line
    set lolfish_next_color (math $lolfish_next_color + $color_step)

    set_color normal
end

set -g __fish_git_prompt_showdirtystate 'yes'
set -g __fish_git_prompt_char_dirtystate '±'
set -g __fish_git_prompt_char_cleanstate ''

function parse_git_dirty
  set -l submodule_syntax
  set submodule_syntax "--ignore-submodules=dirty"
  set git_dirty (command git status --porcelain $submodule_syntax  2> /dev/null)
  if [ -n "$git_dirty" ]
    if [ $__fish_git_prompt_showdirtystate = "yes" ]
      echo -n "$__fish_git_prompt_char_dirtystate"
    end
  else
    if [ $__fish_git_prompt_showdirtystate = "yes" ]
      echo -n "$__fish_git_prompt_char_cleanstate"
    end
  end
end

function fish_prompt

    # I like to always display the return value. Plus a big X if it's an error.
    set -l exit_status $status
    set -l exit_glyph '✗'
    if test $exit_status = 0
        set exit_glyph '✓'
    end

    # abbreviated home directory ~
    if command -s sed > /dev/null ^&1
        set current_dir (echo $PWD | sed -e "s,.*$HOME,~," ^/dev/null)
    else
        set current_dir $PWD
    end

    # the git stuff
    set -l ref
    set -l dirty
    if command git rev-parse --is-inside-work-tree >/dev/null 2>&1
      set dirty (parse_git_dirty)
      set ref (command git symbolic-ref HEAD 2> /dev/null)
      if [ $status -gt 0 ]
        set -l branch (command git show-ref --head -s --abbrev |head -n1 2> /dev/null)
        set ref "➦ $branch "
      end
      set branch_symbol \uE0A0
      set -l branch (echo $ref | sed  "s-refs/heads/-$branch_symbol -")
      set git_dir "$branch $dirty"
    end

    # hashtag the prompt for root user
    switch $USER
        case 'root'
            set prompt '#'
        case '*'
            set prompt '$'
    end

    # finally print the prompt
    lolfish $exit_status ' ' $exit_glyph ' ' $current_dir ' ' $git_dir \n $USER '@' (hostname -s) ' ' $prompt ' '
end
