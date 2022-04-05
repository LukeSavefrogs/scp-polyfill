#!/bin/env bash
# **********************************************************************************
#                                                                                  *
# Author/s    : Luca Salvarani                                                     *
# Created on  : 2022-04-05 00:01:27                                                *
# Description :                                                                    *
#                                                                                  *
# **********************************************************************************

# Test Upload:
# scp -r -C -q -o UserKnownHostsFile=/dev/null -o LogLevel=QUIET -o StrictHostKeyChecking=NO test_scp.txt root@172.30.62.4:/tmp
#
# Test Download:
# scp -r -C -q -o UserKnownHostsFile=/dev/null -o LogLevel=QUIET -o StrictHostKeyChecking=NO root@172.30.62.4:/tmp test_scp.txt
scp () {
	local -r __SCRIPT_VERSION="3.2.0";
	local -r __SCRIPT_NAME="${FUNCNAME[0]}";

	local -r __bold="\033[1m";
	local -r __underlined="\033[4m";
	local -r __yellow="\033[0;33m";
	local -r __red="\033[0;31m";
	local -r __green="\033[0;32m";
	local -r __light_blue="\033[0;34m";
	local -r __reset="\033[0m";

	# shellckeck disable=SC2059
	__usage () {
		local -r __indent_1=$'\t';
		local -r __indent_2=$'\t\t';
		local -r __indent_3=$'\t\t\t';
		
		printf "${__bold}NAME${__reset}:\n"
		printf "${__indent_1}${__bold}%s${__reset} - SCP Polyfill\n" "${__SCRIPT_NAME}";
		printf "\n"
		
		printf "${__bold}USAGE${__reset}:\n"
		printf "${__indent_1}${__yellow}%s${__reset}\n" "${__SCRIPT_NAME}";
		printf "${__indent_1}${__yellow}%s${__reset} --help\n" "${__SCRIPT_NAME}";
		printf "\n"
		
		printf "${__bold}OPTIONS${__reset}:\n"
		printf "${__indent_1}${__red}-f${__reset} ${__underlined}FILENAME${__reset}, ${__red}--file${__reset} ${__underlined}FILENAME${__reset}\n";
		printf "${__indent_2}\n";
		printf "\n";
		printf "${__indent_1}${__red}-h${__reset}, ${__red}--help${__reset}\n";
		printf "${__indent_2}Mostra questo messaggio di aiuto ed esce.\n";
		printf "\n";
		
		printf "${__bold}BUGS${__reset}:\n"
		printf "${__indent_1}Luca Salvarani - luca.salvarani@kyndryl.com\n"
		printf "\n"
		
		printf "${__bold}VERSION${__reset}:\n"
		printf "${__indent_1}%s\n" "${__SCRIPT_VERSION}"
		printf "\n"
	}

	local _ssh_options=();
	local _target_command="";
	local -A _target_command_settings=(
		[quiet]="false"
		[recursive]="false"
		[verbose]="false"
		[compress]="false"
		[ssh_options]=""
	);

	local -a _supported_commands=(sftp rsync);
	for _command in "${_supported_commands[@]}"; do
		if command -v "${_command}" >/dev/null 2>&1; then
			_target_command="${_command}";
			break;
		fi
	done
	
	if [[ -z "${_target_command}" ]]; then
		printf "ERROR: No valid command available. Install one of the following:\n" >&2;
		printf "\t- %s\n" "${_supported_commands[@]}" >&2;
		return 1;
	fi

	# From this excellent StackOverflow answer: https://stackoverflow.com/a/14203146/8965861
	OPTIND=1;
	POSITIONAL=();
	while [[ $# -gt 0 ]]; do
		case $1 in
			-C) # Compression enable.  Passes the -C flag to ssh(1) to enable compression
				_target_command_settings["compress"]="true";
				shift;
			;;
			-o) # Can be used to pass options to ssh in the format used in ssh_config(5).
				_ssh_options+=("-o '${2}'");
				
				if [[ "${_target_command_settings["ssh_options"]}" != "" ]]; then
					_target_command_settings["ssh_options"]+=" ";
				fi
				_target_command_settings["ssh_options"]+="-o \"${2}\"";
				shift 2;
			;;
			-q | --quiet) # Quiet mode: disables the progress meter as well as warning and diagnostic messages from ssh(1).
				_target_command_settings["quiet"]="true";
				shift;
			;;
			-r | --recursive) # Recursively copy entire directories.  Note that scp follows symbolic links encountered in the tree traversal.
				_target_command_settings["recursive"]="true";
				shift;
			;;
			-v | --verbose) # Verbose mode.  Causes scp and ssh(1) to print debugging messages about their progress. 
				_target_command_settings["verbose"]="true";
				shift;
			;;
			--set-command-preference*) # Proprietary option to choose command.
				_target_command="${1#*=}";
				if [[ -z "${_target_command//[[:blank:]]/}" ]]; then
					printf "ERROR: You MUST provide a command preference.\n" >&2;
					return 1;
				elif ! command -v "${_target_command}" >/dev/null 2>&1; then
					printf "ERROR: Invalid command preference. Command '%s' doesn't exist.\n" "${_target_command}" >&2;
					return 1;
				fi
				shift;
			;;
			-\? | -h |--help)
				__usage
				return 0;
			;;
			--)
				shift;
				while [[ $# -gt 0 ]]; do POSITIONAL+=("$1"); shift; done
				break;
			;;
			-*)
				printf "ERROR: Unknown option '%s'" "$1" >&2;
				return 1;
			;;
			*)
				POSITIONAL+=("$1");
				shift;
			;;
		esac;
	done;
	[[ ${#POSITIONAL[@]} -gt 0 ]] && set -- "${POSITIONAL[@]}";
	
	if [[ ${#POSITIONAL[@]} -lt 2 ]]; then
		printf "ERROR: Missing arguments.\n" >&2;
		return 1;
	fi
	
	local _source_path="${POSITIONAL[0]}";
	local _destination_path="${POSITIONAL[1]}";

	if [[ -z "${_source_path}" ]] || [[ -z "${_destination_path}" ]]; then
		printf "ERROR: Missing arguments.\n" >&2;
		return 1;
	fi

	local _command_string="";
	case "${_target_command}" in
		sftp)
			local _sftp_options=();
			for _setting in "${!_target_command_settings[@]}"; do
				_value="${_target_command_settings["${_setting}"]}";

				case "${_setting}" in
					quiet)
						if [[ "${_value}" == "true" ]]; then
							_sftp_options+=("-q");
						fi
					;;
					recursive)
						if [[ "${_value}" == "true" ]]; then
							_sftp_options+=("-r");
						fi
					;;
					verbose)
						if [[ "${_value}" == "true" ]]; then
							_sftp_options+=("-v");
						fi
					;;
					compress)
						if [[ "${_value}" == "true" ]]; then
							_sftp_options+=("-C");
						fi
					;;
					ssh_options)
						if [[ "${_value}" == "true" ]]; then
							_sftp_options+=("${_value}");
						fi
					;;
					*)
					;;
				esac;
			done

			connection_regex="^ *(([-a-zA-Z0-9_. ]+@)?[-a-zA-Z0-9_.]+:[[:print:]]+) *$";
			# if [[ "${_source_path}" =~ \(\([-a-zA-Z0-9_.\ ]+@\)?[-a-zA-Z0-9_.]+:[-\~/\"\'a-zA-Z0-9_.:]+\) ]]; then
			if [[ "${_source_path}" =~ ${connection_regex} ]]; then
				# printf "DEBUG: Detected DOWNLOAD.\n" >&2;
				_command_string="${_target_command} ${_sftp_options[*]} ${_source_path} ${_destination_path}";
			else 
				# printf "DEBUG: Detected UPLOAD.\n" >&2;
				_command_string="${_target_command} ${_sftp_options[*]} ${_destination_path} <<< 'put ${_source_path}'";
			fi
		;;
		rsync)
			local _rsync_options=();
			local _custom_ssh_command="ssh";
			for _setting in "${!_target_command_settings[@]}"; do
				_value="${_target_command_settings["${_setting}"]}";

				case "${_setting}" in
					quiet)
						if [[ "${_value}" == "true" ]]; then
							_rsync_options+=("--quiet");
						fi
					;;
					recursive)
						if [[ "${_value}" == "true" ]]; then
							# _rsync_options+=("--recursive");
							_rsync_options+=("--archive");
						fi
					;;
					verbose)
						if [[ "${_value}" == "true" ]]; then
							_rsync_options+=("--verbose");
						fi
					;;
					compress)
						if [[ "${_value}" == "true" ]]; then
							_rsync_options+=("--compress");
						fi
					;;
					ssh_options)
						if [[ -n "${_value}" ]]; then
							_custom_ssh_command+=" ${_value}";
						fi
					;;
					*)
					;;
				esac;
			done

			_command_string="${_target_command} -e '${_custom_ssh_command}' ${_rsync_options[*]} ${_source_path} ${_destination_path}";
		;;
		*)
			printf "ERROR: Unknown target command '%s'\n" "${_target_command}";
			return 1;
		;;
	esac;
	printf "INFO: Executing command:\t ${__light_blue}%s${__reset}\n" "${_command_string}";

	# Had to use `eval` otherwise the sftp 'put' command would not be evaluated
	eval "${_command_string}";
}
