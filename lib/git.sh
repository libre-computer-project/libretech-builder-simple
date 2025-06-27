#!/bin/bash

LBS_GIT_switchBranch(){
	local path_tar="$1"
	local branch_tar="$2"
	local branch_cur=$(git -C "$path_tar" branch --show-current)
	if [ "$branch_cur" = "" ]; then
		echo "$FUNCNAME not switching due to bisect."
	elif [ "$branch_cur" != "$branch_tar" ]; then
		#check for modified tracked
		local files_unc=$(git -C "$path_tar" status -s | grep -v '^??')
		if [ ! -z "$files_unc" ]; then
			echo "$FUNCNAME cannot switch branch when there are uncommited files."
			return 1
		fi
		local branch_exist=$(git -C "$path_tar" branch --list "$branch_tar")
		if [ -z "$branch_exist" ]; then
			if [ -z "$LBS_GIT_REMOTE_OVERRIDE" ]; then
				git -C "$path_tar" fetch --depth=1 "$LBS_GIT_REMOTE_DEFAULT" "$branch_tar"
			else
				for lbs_git_remote_override in $LBS_GIT_REMOTE_OVERRIDE; do
					if [ "$lbs_git_remote_override" = "$path_tar" ]; then
						local git_remote_var="${path_tar//-/}_GIT_REMOTE"
						declare -n git_remote=${git_remote_var^^}
						if ! git -C "$path_tar" remote show "$git_remote"; then
							local git_url_var="${path_tar//-/}_GIT_URL"
							declare -n git_url=${git_url_var^^}
							git -C "$path_tar" remote add "$git_remote" "$git_url"
						fi
						git -C "$path_tar" fetch --depth=1 "$git_remote" "$branch_tar"
					fi
				done
			fi
			git -C "$path_tar" checkout -b "$branch_tar" FETCH_HEAD
		else
			git -C "$path_tar" checkout "$branch_tar"
		fi
	fi
}
