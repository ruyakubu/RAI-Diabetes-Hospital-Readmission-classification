#!/bin/bash

# name of resource group and azure ml workspace from global config setting
rg_name=$(az config get --local defaults.group --query value --output tsv)
ws_name=$(az config get --local defaults.workspace --query value --output tsv)

# Create dataset
echo '------------------------------------------'
echo 'Registering the Training and Testing dataset'
az ml data create -f cloud/train_data.yml

az ml data create -f cloud/test_data.yml

# generate unique compute name
uuid=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 12 | head -n 1)
computename=compute-$uuid

# Create compute instance
echo '------------------------------------------'
echo 'Creating a Compute Instance'
# az ml compute create -f cloud/compute-cpu.yml 
az ml compute create --name $computename --type computeinstance --size STANDARD_DS12_V2
echo 'compute name - created: ' $computename

# Bash function to replace compute name in training yaml file
replace_traincompute_yaml(){ 

   sed -i "s/<ENTER-COMPUTE-NAME-HERE>/$1/" cloud/training_job.yml
   
}

# Replace compute name in yaml file
replace_traincompute_yaml "$computename"
echo 'job - compute name: ' $computename


# Train model
echo '------------------------------------------'
echo 'Submitting the training job...'

run_id=$(az ml job create --name my_training_job -f cloud/training_job.yml --query name -o tsv)

# wait for job to finish while checking for status
if [[ -z "$run_id" ]]
then
  echo "Job creation failed"
  exit 3
fi
status=$(az ml job show -n $run_id --query status -o tsv)
if [[ -z "$status" ]]
then
  echo "Status query failed"
  exit 4
fi
running=("Queued" "Starting" "Preparing" "Running" "Finalizing")
while [[ ${running[*]} =~ $status ]]
do
  sleep 8 
  status=$(az ml job show -n $run_id --query status -o tsv)
  echo $status
done


# Wait for 3 minute for training job to complete
#sleep 3m 30s

echo 'Training run_ID is: ' $run_id

# Register model
model_name=rai_hospital_model
echo '------------------------------------------'
echo 'Registering model'
az ml model create --name $model_name --path "azureml://jobs/$run_id/outputs/model_output" --type mlflow_model

echo 'the model name is: ' $model_name

# Bash function to replace compute name in training yaml file
replace_dashboardcompute_yaml(){ 

   sed -i "s/<ENTER-COMPUTE-NAME-HERE>/$1/" cloud/rai_dashboard_pipeline.yml
   
}

# Replace compute name in yaml file
replace_dashboardcompute_yaml "$computename"

# Submit RAI Dashboard
echo '------------------------------------------'
echo 'Submitting job to create RAI dashboard....'

az ml job create --file cloud/rai_dashboard_pipeline.yml

echo '--------------------------------------------------------'
echo '  Please verify that the resources are created in the Azure portal'
echo '--------------------------------------------------------'
