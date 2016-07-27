SCM_THEME_PROMPT_PREFIX=""
SCM_THEME_PROMPT_SUFFIX=""

SCM_THEME_PROMPT_DIRTY=" ${bold_red}✗${normal}"
SCM_THEME_PROMPT_CLEAN=" ${bold_green}✓${normal}"
SCM_GIT_CHAR="${bold_green}±${normal}"
SCM_SVN_CHAR="${bold_cyan}⑆${normal}"
SCM_HG_CHAR="${bold_red}☿${normal}"

#Mysql Prompt
export MYSQL_PS1="(\u@\h) [\d]> "

case $TERM in
        xterm*)
        TITLEBAR="\[\033]0;\w\007\]"
        ;;
        *)
        TITLEBAR=""
        ;;
esac

PS3=">> "

__my_rvm_ruby_version() {
    local gemset=$(echo $GEM_HOME | awk -F'@' '{print $2}')
  [ "$gemset" != "" ] && gemset="@$gemset"
    local version=$(echo $MY_RUBY_HOME | awk -F'-' '{print $2}')
    local full="$version$gemset"
  [ "$full" != "" ] && echo "[$full]"
}

is_vim_shell() {
        if [ ! -z "$VIMRUNTIME" ]
        then
                echo "[${cyan}vim shell${normal}]"
        fi
}

modern_scm_prompt() {
        CHAR=$(scm_char)
        if [ $CHAR = $SCM_NONE_CHAR ]
        then
                return
        else
                echo "[$(scm_char)][$(scm_prompt_info)]"
        fi
}

# show chroot if exist
chroot(){
    if [ -n "$debian_chroot" ]
    then 
        my_ps_chroot="${bold_cyan}$debian_chroot${normal}";
        echo "($my_ps_chroot)";
    fi
    }

# show virtualenvwrapper
my_ve(){
    if [ -n "$VIRTUAL_ENV" ]
    then 
        my_ps_ve="${bold_purple}$ve${normal}";
        echo "($my_ps_ve)";
    fi
    echo "";
    }


#prompt aliases
alias promptcpu="grep 'cpu ' /proc/stat | awk '{usage=(\$2+\$4)*100/(\$2+\$4+\$5)} END {print usage}' | awk '{printf(\"%.1f\n\", \$1)}'"
alias promptnetcon="awk 'END {print NR}' /proc/net/tcp"


prompt() {
    local LAST_COMMAND=$? # Must come first!

    # show last error code and brief description of some error codes
    my_last_error=""
        if [[ $LAST_COMMAND != 0 ]]; then
                my_last_error="${red}\[ERROR - Exit Code-${LAST_COMMAND}\]${normal} "
                if [[ $LAST_COMMAND == 1 ]]; then
                        my_last_error+="General error"
                elif [ $LAST_COMMAND == 2 ]; then
                        my_last_error+="Missing keyword, command, or permission problem"
                elif [ $LAST_COMMAND == 126 ]; then
                        my_last_error+="Permission problem or command is not an executable"
                elif [ $LAST_COMMAND == 127 ]; then
                        my_last_error+="Command not found"
                elif [ $LAST_COMMAND == 128 ]; then
                        my_last_error+="Invalid argument to exit"
                elif [ $LAST_COMMAND == 129 ]; then
                        my_last_error+="Fatal error signal 1"
                elif [ $LAST_COMMAND == 130 ]; then
                        my_last_error+="Script terminated by Control-C"
                elif [ $LAST_COMMAND == 131 ]; then
                        my_last_error+="Fatal error signal 3"
                elif [ $LAST_COMMAND == 132 ]; then
                        my_last_error+="Fatal error signal 4"
                elif [ $LAST_COMMAND == 133 ]; then
                        my_last_error+="Fatal error signal 5"
                elif [ $LAST_COMMAND == 134 ]; then
                        my_last_error+="Fatal error signal 6"
                elif [ $LAST_COMMAND == 135 ]; then
                        my_last_error+="Fatal error signal 7"
                elif [ $LAST_COMMAND == 136 ]; then
                        my_last_error+="Fatal error signal 8"
                elif [ $LAST_COMMAND == 137 ]; then
                        my_last_error+="Fatal error signal 9"
                elif [ $LAST_COMMAND -gt 255 ]; then
                        my_last_error+="Exit status out of range"
                else
                        my_last_error+="Unknown error code"
                fi
                my_last_error+="\n"
        else
                my_last_error="";
        fi

    #Setup user and host prompts
    my_ps_host=""
    my_ps_host=""
    local SSH_IP=`echo $SSH_CLIENT | awk '{ print $1 }'`
    local SSH2_IP=`echo $SSH2_CLIENT | awk '{ print $1 }'`
        if [ $SSH2_IP ] || [ $SSH_IP ] ; then
            case "`id -u`" in
                0) my_ps_host="${bold_orange}ssh:\h${normal}";
                   my_ps_user="${bold_red}\u${normal}";
                ;;
                *) my_ps_host="${yellow}ssh:\h${normal}"
                   my_ps_user="${bold_green}\u${normal}";
                ;;
            esac
	else
            case "`id -u`" in
                0) my_ps_host="${bold_yellow}\h${normal}"
                   my_ps_user="${bold_red}\u${normal}";
                ;;
                *) my_ps_host="${green}\h${normal}"
                   my_ps_user="${bold_green}\u${normal}";
                ;;
            esac
        fi

    #Stats
    my_stats="${green}c:$(promptcpu)% nc:$(promptnetcon) j:\j${normal}"
    

    if [ -n "$VIRTUAL_ENV" ]
    then
        ve=`basename $VIRTUAL_ENV`;
    fi

    #Format prompt
    PS1="${TITLEBAR}${my_last_error}┌─$(my_ve)$(chroot)[$my_ps_user][$my_ps_host][$my_stats]$(modern_scm_prompt)$(__my_rvm_ruby_version)[${cyan}\w${normal}]$(is_vim_shell)\n└─▪ "
PS2="└─▪ "
}


safe_append_prompt_command prompt
