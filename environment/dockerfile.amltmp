FROM mcr.microsoft.com/azureml/openmpi4.1.0-ubuntu20.04:20230120.v1

ENV AZUREML_CONDA_ENVIRONMENT_PATH /azureml-envs/responsibleai-0.21

# Install wkhtmltopdf for pdf rendering from html
RUN apt-get -y update && apt-get -y install wkhtmltopdf

# Create conda environment
RUN conda create -p $AZUREML_CONDA_ENVIRONMENT_PATH \
    python=3.8 pip=21.3.1 -c anaconda -c conda-forge

# Prepend path to AzureML conda environment
ENV PATH $AZUREML_CONDA_ENVIRONMENT_PATH/bin:$PATH

# Install pip dependencies
# markupsafe and itsdangerous are bug workarounds
RUN pip install 'responsibleai~=0.21.0' \
                'raiwidgets~=0.21.0' \
                'pyarrow' \
                'markupsafe<=2.0.1' \
                'itsdangerous==2.0.1' \
                'mlflow' \
                'scikit-learn<1.1' \
                'pdfkit==1.0.0' \
                'plotly==5.6.0' \
                'kaleido==0.2.1' \
                'azureml-core==1.48.0' \
                'azureml-dataset-runtime==1.48.0' \
                'azureml-mlflow==1.48.0' \
                'imblearn'
                

RUN pip install --pre 'azure-ai-ml'

# no-deps install for domonic due to unresolvable dependencies requirment on urllib3 and requests.
# score card rendering is using domonic only for the html elements composer which does not involve requests or urllib3
RUN pip install --no-deps 'charset-normalizer==2.0.12' \
                          'cssselect==1.1.0' \
                          'elementpath==2.5.0' \
                          'html5lib==1.1' \
                          'webencodings==0.5.1' \
                          'domonic==0.9.10'

# This is needed for mpi to locate libpython
ENV LD_LIBRARY_PATH $AZUREML_CONDA_ENVIRONMENT_PATH/lib:$LD_LIBRARY_PATH
