#!/bin/bash
# 
# parse-workflow.sh
# Author: William Bourdo
# Email: liam.bourdo@gmail.com
#
# This script is meant to pull all relevant values from jira's entities.xml
# to perform a migration of JMWE from cloud to server.

input_file=./input.xml
output_file=./jmwe-workflows.csv
work_file=./jmwe-work
error_log=./error.log

cp entities.xml $input_file
if [ -f $output_file ]; then
	mv $output_file $output_file"."$(date +%s)
fi

while [ -s $input_file ]
do
	# Find sub set of lines to start work on and separate into it's own file
	next_workflow=$(grep -m 1 -n '<Workflow\|<DraftWorkflow' $input_file | awk -F ":" ' { print $1 } ')
	next_dpf=$(grep -m 1 -n 'DelegatingPostFunction' $input_file | awk -F ":" ' { print $1 } ')

	# If next DPF is null exit
	if [ -z $next_dpf ]; then
		exit 1
	fi

	if [ "$next_workflow" -lt "$next_dpf" ]; then
		# Pull all lines between the next workflow definition and DPF
		sed -n "${next_workflow}"','"${next_dpf}"'p' $input_file | tac > $work_file

		# Assign values relevant to the workflow the transition was found in
		if grep --quiet '<Workflow' $work_file; then
			workflow_type="Workflow"
			workflow_name=$(grep -m 1 "<Workflow" $work_file | sed 's/^.*parentname="//' | sed 's/".*$//')
		else
			if grep --quiet '<DraftWorkflow' $work_file; then
				workflow_type="DraftWorkflow"
				workflow_name=$(grep -m 1 "<DraftWorkflow" $work_file | sed 's/^.*parentname="//' | sed 's/".*$//')
			else
				echo "ERROR: No WorkFlow Found"
				exit 1
			fi
		fi
	else
		head -n $next_dpf $input_file | tac > $work_file

	fi

	# Pull transition name
	transition_name=$(grep -m 1 "<action id" $work_file | sed 's/^.*name="//;s/".*$//')

	# Print relevant information into a log file and the output csv
	echo $(date +%s)":"$transition_name","$workflow_type","$workflow_name","$next_workflow","$next_dpf","$next_workflow >> $error_log
	echo $transition_name","$workflow_type","$workflow_name >> $output_file

	# Remove lines from input file for next iteration
	sed -i 1,"$next_dpf"d $input_file
done

