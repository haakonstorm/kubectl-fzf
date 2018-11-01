# Copyright 2018 Anthonin Bonnefoy
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

export KUBECTL_FZF_CACHE="/tmp/kubectl_fzf_cache"
eval "`declare -f __kubectl_parse_get | sed '1s/.*/_&/'`"

_pod_selector()
{
	res=$(cut -d ' ' -f 1,2,4-7 ${KUBECTL_FZF_CACHE}/pods \
		| column -t \
		| sort \
		| fzf --sync -m --header="Namespace Name IP Node Status Age" --layout reverse -q "$1" \
		| awk '{print $2}')
	echo $res
}

_deployment_selector()
{
	res=$(cat ${KUBECTL_FZF_CACHE}/deployments \
		| column -t \
		| sort \
		| fzf -m --header="Deployment" --layout reverse -q "$1" \
		| awk '{print $1 " " $3}')
	echo $res
}

_service_selector()
{
	res=$(cut -d ' ' -f 1,2,4-7 ${KUBECTL_FZF_CACHE}/services \
		| column -t \
		| sort \
		| fzf -m --header="Namespace Service Type Ip Ports Selector" --layout reverse -q "$1" \
		| awk '{print $2}')
	echo $res
}

_node_selector()
{
	res=$(cut -d ' ' -f 1,3-7 ${KUBECTL_FZF_CACHE}/nodes \
		| column -t \
		| sort \
		| fzf -m --header="Node Roles InstanceType Zone InternalIp Age" --layout reverse -q "$1" \
		| awk '{print $1}')
	echo $res
}

_flag_selector()
{
	declare -A resources_to_label
	resources_to_label[pods]='$3'
	resources_to_label[services]='$3'
	resources_to_label[deployments]='$3'

	local file="${KUBECTL_FZF_CACHE}/$1"
	local column="${resources_to_label[$1]}"
	res=$(awk "{print $column }" "$file" \
		| paste -sd ',' \
		| tr ',' '\n' \
		| grep -v None \
		| sort \
		| uniq \
		| fzf -m --header="Label Value" --layout reverse -q "$2" \
		| awk '{print $1}')
	echo $res
}

__kubectl_parse_get()
{
	local penultimate=$(echo $COMP_LINE | awk '{print $(NF-1)}')
	local last_part=$(echo $COMP_LINE | awk '{print $(NF)}')

	local resource_name
	local autocomplete_fun
	case $1 in
		pod?(s) )
			resource_name="pods"
			autocomplete_fun=_pod_selector
			;;
		node?(s) )
			resource_name="nodes"
			autocomplete_fun=_node_selector
			;;
		deployment )
			resource_name="deployments"
			autocomplete_fun=_deployment_selector
			;;
		svc | service )
			resource_name="services"
			autocomplete_fun=_service_selector
			;;
		* )
			___kubectl_parse_get $*
			return
			;;
	esac


	echo "1: $1 2: $2 penul: $penultimate last: $last_part"  >> /tmp/debug

	if [[ $penultimate == "--selector" || $penultimate == "-l" || $last_part == "--selector" || $last_part == "-l" ]]; then
		if [[ $penultimate == "--selector" || $penultimate == "-l" ]]; then
			query=$last_part
		fi
		flags=$(_flag_selector $resource_name $query)
		if [[ -n $flags ]]; then
			COMPREPLY=( "$flags" )
		fi
		return
	fi

	local query=""
	if [[ $1 != $last_part ]]; then
		query=$last_part
	fi

	results=$( ${autocomplete_fun} $query )
	if [[ -n "$results" ]]; then
		COMPREPLY=( $results )
	fi
}
