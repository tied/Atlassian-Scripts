#!/bin/bash

input_file=./input.xml
output_file=./jmwe-workflows.csv
work_file=./jmwe-work
temp_file=./jmwe-temp
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
        if [ -z $next_dpf ]; then
                exit 1
        fi

        if [ "$next_workflow" -lt "$next_dpf" ]; then
                # Pull all lines between the next workflow definition and DPF
                sed -n "${next_workflow}"','"${next_dpf}"'p' $input_file | tac > $work_file

                if grep --quiet '<Workflow' $work_file; then
                        workflow_type="Workflow"
                        workflow_name=$(grep -m 1 "<Workflow" $work_file | sed 's/^.*name="//;s/".*$//')
                        workflow_line=$(grep -m 1 "<Workflow" $work_file)
                else
                        if grep --quiet '<DraftWorkflow' $work_file; then
                                workflow_type="DraftWorkflow"
                                workflow_name=$(grep -m 1 "<DraftWorkflow" $work_file | sed 's/^.*name="//;s/".*$//')
                                workflow_line=$(grep -m 1 "<DraftWorkflow" $work_file)
                        else
                                echo "ERROR: No WorkFlow Found"
                                exit 1
                        fi
                fi
        else
                head -n $next_dpf $input_file | tac > $work_file

        fi

        transition_name=$(grep -m 1 "<action id" $work_file | sed 's/^.*name="//;s/".*$//')

        echo -e $(date +%s)':'$transition_name','$workflow_type'\n'$workflow_name'\n'$next_workflow','$next_dpf','$next_workflow'\n' >> $error_log
        echo $transition_name","$workflow_type","$workflow_name >> $output_file

        # Remove lines from input file for next iteration
        sed -i 1,"$next_dpf"d $input_file
done
