#!/bin/bash
set -e
set -o pipefail

dependencies_dir=$1
workspace_python_dir=$2/.python
workspace_template_python_dir=$3/.python
python_version=$4

if [[ ! -d ${workspace_template_python_dir}/${python_version} ]]; then
  # First run - initial build
  # - no virtual environment created or activated
  echo '--- Initial Build ---'
  /usr/local/bin/python -m venv ${workspace_python_dir}/${python_version}
else
  echo '--- Custom Build ---'
  # Second run - customise build
  mv ${workspace_template_python_dir}/${python_version} ${workspace_python_dir}
fi

# Activate virtual environment
source ${workspace_python_dir}/${python_version}/bin/activate
# Update PIP
python -m pip install --no-cache-dir --upgrade pip
# Install PIP packages
pip install --no-cache-dir -r ${dependencies_dir}/requirements.txt
# Install PIPX packages
count=$(grep -cv '^\s*$\|^\s*\#' ${dependencies_dir}/pipx.txt) || true
if [[ ${count} -ne 0 ]]; then
  grep -v '^\s*$\|^\s*\#' ${dependencies_dir}/pipx.txt | xargs -I {} -n1 pipx install --python /usr/local/bin/python --pip-args='--no-cache-dir' {}
fi
# Move virtual environment to workspace template dir, to be copied to volume later
mkdir -p ${workspace_template_python_dir}
mv -v ${workspace_python_dir}/${python_version} ${workspace_template_python_dir}
