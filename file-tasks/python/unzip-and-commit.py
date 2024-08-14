import zipfile
import os
import subprocess

target_dir = "C:\\Users\\joluedem\\git\\stackoverflow_data\\data\\"

def loop_zip_files(path):
    for root, dirs, files in os.walk(path):
        for file in files:
            if file.endswith('.zip'):
                zip_file = os.path.join(root, file)
                return zip_file

def extract_and_commit(zip_file, repo_url):
    # Extract the contents of the zip file
    folder_name = os.path.splitext(zip_file)
    with zipfile.ZipFile(zip_file, 'r') as zip_ref:
        zip_ref.extractall(folder_name)
    
    # Change directory to the extracted folder
    os.chdir(folder_name)
    
    # Initialize a new git repository
    subprocess.run(['git', 'init'])
    
    # Add the remote repository
    subprocess.run(['git', 'remote', 'add', 'origin', repo_url])
    
    # Add all files to the repository
    subprocess.run(['git', 'add', folder_name])
    
    # Commit the changes
    subprocess.run(['git', 'commit', '-m', 'Adding ' + folder_name + ' folder'])
    
    # Push the changes to the remote repository
    subprocess.run(['git', 'push', '-u', 'origin', 'master'])

# Example usage
path = "C:\\Users\\joluedem\\OneDrive - Microsoft\\data-sets\\stack-overflow\\"
repo_url = 'https://github.com/joluede_msft/stackoverflow_data.git'

extract_and_commit(loop_zip_files(path), repo_url)
