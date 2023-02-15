#!/bin/bash

# Create compute cluster
echo '------------------------------------------'
echo 'Creating a Compute Cluster'
az ml compute create -f cloud/cluster-cpu.yml 


# Create dataset
echo '------------------------------------------'
echo 'Registering the Training and Testing dataset'
az ml data create -f cloud/train_data.yml

az ml data create -f cloud/test_data.yml


# Train model
echo '------------------------------------------'
echo 'Submitting the training job...'

run_id=$(az ml job create -f cloud/training_job.yml --query name -o tsv)

echo 'Training run_ID is: ' $run_id

# Register model
model_name=rai_hospital_model
echo '------------------------------------------'
echo 'Registering model'
az ml model create --name $model_name --path "azureml://jobs/$run_id/outputs/model_output" --type mlflow_model

echo 'the model name is: ' $model_name

# Submit RAI Dashboard
echo '------------------------------------------'
echo 'Submitting job to create RAI dashboard....'

az ml job create --file cloud/rai_dashboard_pipeline.yml

echo '--------------------------------------------------------'
echo '  Please verify in the resources created in the Azure portal'
echo '--------------------------------------------------------'
