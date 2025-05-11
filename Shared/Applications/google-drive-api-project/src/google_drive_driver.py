import argparse
import os
import sys
from pydrive2.auth import GoogleAuth
from pydrive2.drive import GoogleDrive

def getFileId(drive, file_path):
    """
    Get the ID of a file in Google Drive by its path.

    :param drive: Google Drive service instance.
    :param file_path: Path to the file in Google Drive (e.g., 'Parent/Child/File.txt').
    :return: The ID of the file if found, otherwise None.
    """
    folder_names = file_path.split('/')  # Split the path into parts
    parent_id = 'root'  # Start from the root folder

    for folder_name in folder_names[:-1]:  # Traverse all folders except the last part
        query = f"'{parent_id}' in parents and title='{folder_name}' and mimeType='application/vnd.google-apps.folder' and trashed=false"
        folder_list = drive.ListFile({'q': query}).GetList()

        if not folder_list:
            print(f"Error: Folder '{folder_name}' not found in path '{file_path}'.")
            return None
        parent_id = folder_list[0]['id']  # Move to the next folder in the path

    # Search for the file in the final folder
    file_name = folder_names[-1]
    query = f"'{parent_id}' in parents and title='{file_name}' and trashed=false"
    file_list = drive.ListFile({'q': query}).GetList()

    if not file_list:
        print(f"Error: File '{file_name}' not found in path '{file_path}'.")
        return None

    return file_list[0]['id']  # Return the ID of the file

def getFolderId(drive, folder_path):
    """
    Recursively search for a folder in Google Drive by its path.

    :param drive: Google Drive service instance.
    :param folder_path: Path to the folder (e.g., 'Parent/Child').
    :return: The ID of the folder if found, otherwise None.
    """
    folder_names = folder_path.split('/')  # Split the path into parts
    parent_id = 'root'  # Start from the root folder

    for folder_name in folder_names:
        query = f"'{parent_id}' in parents and title='{folder_name}' and mimeType='application/vnd.google-apps.folder' and trashed=false"
        folder_list = drive.ListFile({'q': query}).GetList()

        if not folder_list:
            print(f"Folder '{folder_name}' not found in path '{folder_path}'.")
            return None  # Folder not found
        parent_id = folder_list[0]['id']  # Move to the next folder in the path

    return parent_id  # Return the ID of the last folder in the path

def createFolder(drive, folder_path):
    """
    Recursively create folders in Google Drive based on the given path.

    :param drive: Google Drive service instance.
    :param folder_path: Path to the folder (e.g., 'Test/hoge/huga').
    :return: The ID of the last folder in the path.
    """
    folder_list = folder_path.split('/')  # Split the path into parts
    parent_id = 'root'  # Start from the root folder
    current_path = ''  # To build the folder path incrementally

    for folder_name in folder_list:
        # Build the current folder path
        current_path = f"{current_path}/{folder_name}" if current_path else folder_name

        # Check if the folder exists
        folder_id = getFolderId(drive, current_path)
        if folder_id is None:
            # Folder does not exist, create it
            folder_metadata = {
                'title': folder_name,
                'mimeType': 'application/vnd.google-apps.folder',
                'parents': [{'id': parent_id}]
            }
            folder = drive.CreateFile(folder_metadata)
            folder.Upload()
            print(f"Created folder: {current_path}")
            parent_id = folder['id']  # Update parent_id to the newly created folder
        else:
            # Folder exists, update parent_id to the existing folder's ID
            parent_id = folder_id

    return parent_id  # Return the ID of the last folder in the path

def uploadFile(drive, file_path, folder_name):
    """
    Upload a file to a specified folder in Google Drive.
    
    :param drive: Google Drive service instance.
    :param file_path: Path to the file to upload.
    :param folder_name: Name of the folder to upload the file to.
    """
    if not os.path.exists(file_path):
        print(f"Error: The file '{file_path}' does not exist.")
        exit(1)

    if folder_name != '':
        folder_id = getFolderId(drive, folder_name)
        if not folder_id:
            folder_id = createFolder(drive, folder_name)

    file_metadata = {
        'title': file_path.split('/')[-1],
        'parents': [{'id': folder_id}]
    }
    file_drive = drive.CreateFile(file_metadata)
    file_drive.SetContentFile(file_path)
    file_drive.Upload()
    print(f'Uploaded {file_path} to {folder_name}')

def resolvePath(input_path):
    """
    Resolve the given path to an absolute path.

    :param input_path: The input path (can be relative or absolute).
    :return: The absolute path.
    """
    if os.path.isabs(input_path):
        # If the path is already absolute, return it as is
        return input_path
    else:
        # If the path is relative, join it with the current working directory
        return os.path.abspath(os.path.join(os.getcwd(), input_path))

def downloadFile(drive, src_file_path, output_path):
    """
    Download a file from Google Drive.

    :param drive: Google Drive service instance.
    :param src_file_path: Path or ID of the file to download.
    :param output_path: Path to save the downloaded file (can be relative or absolute).
    """
    # Resolve the output path to an absolute path
    resolved_output_path = resolvePath(output_path)
    # Check if the resolved path is a directory
    if os.path.isdir(resolved_output_path):
        # Extract the file name from src_file_path and append it to the directory
        file_name = os.path.basename(src_file_path)
        resolved_output_path = os.path.join(resolved_output_path, file_name)

    # Get the file ID using getFileId()
    file_id = getFileId(drive, src_file_path)
    if file_id is None:
        print(f"Error: The file '{src_file_path}' does not exist in Google Drive.")
        exit(1)

    try:
        file_drive = drive.CreateFile({'id': file_id})
        file_drive.GetContentFile(resolved_output_path)
        print(f"Downloaded file to {resolved_output_path}")
    except Exception as e:
        print(f"Error downloading file: {e}")
        exit(1)

def authenticate():
    """
    Authenticate the user and return the Google Drive service.
    """
    try:

        config_dir = "/usr/local/config"  # コンテナ内のマウント先ディレクトリ
        credentials_path = os.path.join(config_dir, "credentials.json")
        settings_path = os.path.join(config_dir, "settings.yaml")

        gauth = GoogleAuth(settings_path)
        print (f"Using settings file: {settings_path}")
        gauth.LoadCredentialsFile(credentials_path)
        if gauth.credentials is None:
            print("No credentials found. Please authenticate.")
            gauth.CommandLineAuth()
            gauth.SaveCredentialsFile(credentials_path)
        elif gauth.access_token_expired:
            print("Access token expired. Refreshing...")
            gauth.Refresh()
        else:
            print("Using existing credentials.")
            gauth.CommandLineAuth()

        return GoogleDrive(gauth)
    except Exception as e:
        print("Authentication failed. Please contact the following email address to obtain the token: seiya_1998@icloud.com")
        print(f"Error details: {e}")
        exit(1)

def main():
    """
    Main function to authenticate and upload a file to Google Drive.
    """
    parser = argparse.ArgumentParser(description="Upload or download files to/from Google Drive.")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # Upload command
    upload_parser = subparsers.add_parser("upload", help="Upload a file to Google Drive")
    upload_parser.add_argument("-f", "--file", required=True, help="Path to the file to upload")
    upload_parser.add_argument("-t", "--target", required=True, help="Target folder name on Google Drive")

    # Download command
    download_parser = subparsers.add_parser("download", help="Download a file from Google Drive")
    download_parser.add_argument("-f", "--file", required=True, help="Path to the file on Google Drive")
    download_parser.add_argument("-o", "--output", required=True, help="Output path to save the downloaded file")

    args = parser.parse_args()

    drive = authenticate()
    if args.command == "upload":
        uploadFile(drive, args.file, args.target)
        print('File uploaded successfully.')
    elif args.command == "download":
        downloadFile(drive, args.file, args.output)
        print('File downloaded successfully.')
    else:
        parser.print_help()
        exit(1)
    

if __name__ == '__main__':
    main()