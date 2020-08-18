#!/usr/bin/env bash

init_check() {
    # Checks if it is the first use (both variables are set)
    # if [[ -z ${DOT_REPO} && -z ${DOT_DEST} ]]; then
    #     initial_setup
    # else
    DOT_REPO="dotfiles"
    DOT_DEST="."
    
        repo_check
        manage
    # fi
}

repo_check() {
    # check if repo at DOT_DEST exists
    DOT_REPO_NAME=$(basename "${DOT_REPO}")
    if [[ -d ${HOME}/${DOT_DEST}/${DOT_REPO_NAME} ]]; then
        echo -e "\n Found ${DOT_REPO_NAME} as dotfile repo at ${HOME}/${DOT_DEST}/"
    else
        echo -e "\n\n[❌] ${DOT_REPO_NAME} not present inside ${HOME}/${DOT_DEST}"
        read -p "Should I clone it? [Y/n]: " -n 1 -r USER_INPUT
        USER_INPUT=${USER_INPUT:-y}
        case USER_INPUT in
            [y/Y]* ) clone_dotrepo "$DOT_DEST" "$DOT_REPO" ;;
            [n/N]* ) echo -e "${DOT_REPO_NAME} not found" ;;
            *)    printf "\n%s\n" "[❌] Invalid Input 🙄, Try Again" ;;
        esac
    fi
}

initial_setup() {
    echo -e "\n\nFirst time use 🔥\n\nSetup"
    echo -e "....................................."
    read -p "Enter dotfile repository URL: " -r DOT_REPO

    read -p "Where to clone $(basename "${DOT_REPO}") (${HOME}/..): " -r DOT_DEST
    DOT_DEST=${DOT_DEST:-$HOME}
    if [[ -d "$HOME/$DOT_DEST" ]]; then
        clone_dotrepo "$DOT_DEST" "$DOT_REPO"
    else
        echo -e "\n$DOT_DEST Not a valid directory"
        exit 1
    fi
}

add_env() {
    # export environment variables
    echo -e "\nExporting env variables DOT_DEST & DOT_REPO ..."

    current_shell=$(basename "$SHELL")
    echo ${current_shell}
    if [[ $current_shell == "zsh" ]]; then
        echo "export DOT_REPO=$1" >> "$HOME"/.zshrc
        echo "export DOT_DEST=$2" >> "$HOME"/.zshrc
    elif [[ $current_shell == "bash" ]]; then
        echo "export DOT_REPO=$1" >> "$HOME"/.bashrc
        echo "export DOT_DEST=$2" >> "$HOME"/.bashrc
    else
        echo "Couldn't exort DOT_REPO and DOT_DEST."
        echo "Consider exporting them manually."
        exit 1
    fi
    echo -e "Configuration for SHELL $current_shell has been updated."
}

manage() {
    while true;
    do
        echo -e "\n[1] Show diff"
        echo -e "[2] Push changed dotfiles to remote"
        echo -e "[3] Pull latest changes from remote"
        echo -e "[4] List all dotfiles"
        echo -e "[q/Q] Quit Session"

        # Default is [1]
        read -p "Please type your choice: [1]" -n 1 -r USER_INPUT

        # See Parameter Expansion
        USER_INPUT=${USER_INPUT:-1}
        case $USER_INPUT in
            [1]* ) show_diff_check;;
            [2]* ) dot_push;;
            [3]* ) dot_pull;;
            [4]* ) find_dotfiles;;
            [q/Q]* ) exit;;
            * )    printf "\n%s\n" "[❌]Invalid input, try again";;
            esac
    done
}

find_dotfiles() {
    printf "\n"
    readarray -t dotfiles < <( find "${HOME}" -maxdepth 1 -name ".*" -type f )
    printf "%s\n" "${dotfiles[@]}"
}

diff_check() {
    if [[ -z $1 ]]; then
        declare -ag file_arr
    fi

    # dotfiles in repository
    readarray -t dotfiles_repo < <( find "${HOME}/${DOT_DEST}/$(basename "${DOT_REPO}")" -maxdepth 1 -name ".*" -type f )

    # check length here?
    for i in "${!dotfiles_repo[@]}"
    do
        dotfile_name=$(basename "${dotfiles_repo[$i]}")
        # compare the HOME version of dotfile to repo version
        diff=$(diff -u --suppress-common-lines --color=always "${dotfiles_repo[$i]}" "${HOME}/${dotfile_name}")
        if [[ $diff != "" ]]; then
            if [[ $1 == "show" ]]; then
                printf "\n\n%s" "Running diff between ${HOME}/${dotfile_name} and "
                printf "%s\n" "${dotfiles_repo[$i]}"
                printf "%s\n\n" "$diff"
            fi
            file_arr+=("${dotfile_name}")
        fi
    done
    if [[ ${#file_arr} == 0 ]]; then
        echo -e "\n\nNo changes in dotfiles."
        return
    fi
}

show_diff_check() {
    diff_check "show"
}

dot_push() {
    diff_check
    echo -e "\nFollowing dotfiles changed: "
    for file in "${file_arr[@]}"; do
        echo "$file"
        cp "${HOME}/$file" "${HOME}/${DOT_DEST}/$(basename "${DOT_REPO}")"
    done

    dot_repo="${HOME}/${DOT_DEST}/$(basename "${DOT_REPO}")"
    git -C "$dot_repo" add -A

    echo -e "Enter commit message (Ctrl + d to save): "
    commit=$(</dev/stdin)

    git -C "$dot_repo" commit -m "$commit"

    git -C "$dot_repo" push
}

dot_pull() {
    echo -e "\nPulling dotfiles ..."
    dot_repo="${HOME}/${DOT_DEST}/$(basename "${DOT_REPO}")"
    echo -e "\nPulling changes in $dot_repo\n"
    git -C "$dot_repo" pull
}

clone_dotrepo (){
	DOT_DEST=$1
	DOT_REPO=$2
	
	if git -C "${HOME}/${DOT_DEST}" clone "${DOT_REPO}"; then
		if [[ -z ${DOT_REPO} && -z ${DOT_DEST} ]]; then
			add_env "$DOT_REPO" "$DOT_DEST"
		    echo -e "\n[✔️] dotman successfully configured"
		else
            echo -e "\n[❌] failed adding environment variables"
        fi
	else
		# invalid arguments to exit, Repository Not Found
		echo -e "\n[❌] $DOT_REPO Unavailable. Exiting"
		exit 1
	fi
}

# source ~/.zshrc
echo $(basename "$SHELL")
echo $DOT_DEST
echo $DOT_REPO
init_check
