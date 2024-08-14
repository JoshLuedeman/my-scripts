import os
import subprocess
import py7zr

def get_env_var(env_var):
    # Get the folder path from an environment variable
    return os.getenv(env_var)

def extract_7z_files(src_folder_path, tgt_folder_path):
    # Loop through each 7z file in the folder
    for file_name in os.listdir(src_folder_path):
        if file_name.endswith('.7z'):
            # Create a new folder named after the 7z file (without extension)
            new_folder = os.path.join(tgt_folder_path, file_name[:-7])
            os.makedirs(new_folder, exist_ok=True)
            
            # Extract the contents of the 7z file to the new folder
            with py7zr.SevenZipFile(os.path.join(src_folder_path, file_name), mode='r') as archive:
                archive.extractall(path=new_folder)
            
            # Commit the new folder and its contents to a GitHub repository
            commit_to_github(new_folder,tgt_folder_path)

def commit_to_github(folder_path,tgt_folder_path):
    # Change directory to the folder
    os.chdir(tgt_folder_path)
    
    # Initialize a new git repository if it doesn't exist
    #if not os.path.exists(os.path.join(folder_path, '.git')):
    #    subprocess.run(['git', 'init'])
    
    # Add all files to the repository
    subprocess.run(['git', 'add', '.'])
    
    # Commit the changes
    subprocess.run(['git', 'commit', '-m', 'Add extracted file folder ' + folder_path + ' from 7z archive'])
    
    # Push the changes to the remote repository
    # Note: You need to set up the remote repository URL and authentication
    subprocess.run(['git', 'push', 'origin', 'main'])

def main():
    # Get the environment variables
    src_folder_path = get_env_var("UNZIP_PATH")
    tgt_folder_path = get_env_var("UNZIP_TARGET")
    repo = get_env_var("UNZIP_REPO")
    
    if src_folder_path:
        # Extract 7z files and commit to GitHub
        extract_7z_files(src_folder_path,tgt_folder_path)
    else:
        print(f"Environment variable src folder path not set.")

if __name__ == "__main__":
    main()