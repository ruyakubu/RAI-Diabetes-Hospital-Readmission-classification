

from pathlib import Path
import sys
import os

parent_dir =  os.path.dirname(os.getcwd())
 
# setting path
sys.path.append(parent_dir)

import argparse
import os
import shutil
import tempfile

from azureml.core import Run

import mlflow
import mlflow.sklearn

import pandas as pd
import numpy as np
from sklearn.compose import make_column_selector as selector
from sklearn.preprocessing import OneHotEncoder, OrdinalEncoder, StandardScaler
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline

from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.tree import DecisionTreeClassifier
from sklearn.pipeline import make_pipeline
from sklearn.model_selection import train_test_split



def parse_args():
    # setup arg parser
    parser = argparse.ArgumentParser()

    # add arguments
    parser.add_argument("--training_data", type=str, help="Path to training data")
    parser.add_argument("--target_column_name", type=str, help="Name of target column")
    parser.add_argument("--model_output", type=str, help="Path of output model")

    # parse args
    args = parser.parse_args()    

    # return args
    return args



def main(args):
    current_experiment = Run.get_context().experiment
    tracking_uri = current_experiment.workspace.get_mlflow_tracking_uri()
    print("tracking_uri: {0}".format(tracking_uri))
    mlflow.set_tracking_uri(tracking_uri)
    mlflow.set_experiment(current_experiment.name)

    # Read in data
    print("Reading data")
    all_training_data = pd.read_parquet(args.training_data)
    target = all_training_data[args.target_column_name]
    features = all_training_data.drop([args.target_column_name], axis = 1)  

    #features['age'] = pd.Categorical(all_training_data['age'], categories=['30 years or younger', '30-60 years', 'Over 60 years'], ordered=True)

    # Transform string data to numeric
    numerical_selector = selector(dtype_include=np.number)
    categorical_selector = selector(dtype_exclude=np.number)

    numerical_columns = numerical_selector(features)
    categorical_columns = categorical_selector(features)

    categorial_encoder = OneHotEncoder(handle_unknown="ignore")
    numerical_encoder = StandardScaler()

    preprocessor = ColumnTransformer([
    ('categorical-encoder', categorial_encoder, categorical_columns),
    ('standard_scaler', numerical_encoder, numerical_columns)])

    clf = make_pipeline(preprocessor, LogisticRegression())
    
    X_train, X_test, y_train, y_test = train_test_split(features, target, test_size=0.3, random_state=1)

    print("Training model...") 
    
    model = clf.fit(X_train, y_train)
 
    # Saving model with mlflow - leave this section unchanged
    model_dir =  "./model_output"
    with tempfile.TemporaryDirectory() as td:
        print("Saving model with MLFlow to temporary directory")
        tmp_output_dir = os.path.join(td, model_dir)
        mlflow.sklearn.save_model(sk_model=model, path=tmp_output_dir)

        print("Copying MLFlow model to output path")
        for file_name in os.listdir(tmp_output_dir):
            print("  Copying: ", file_name)
            # As of Python 3.8, copytree will acquire dirs_exist_ok as
            # an option, removing the need for listdir
            shutil.copy2(src=os.path.join(tmp_output_dir, file_name), dst=os.path.join(args.model_output, file_name))


# run script
if __name__ == "__main__":
    # add space in logs
    print("*" * 60)
    print("\n\n")

    # parse args
    args = parse_args()

    # run main function
    main(args)

    # add space in logs
    print("*" * 60)
    print("\n\n")
