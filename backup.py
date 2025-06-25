#!/usr/bin/env python3
import os
import re
from datetime import datetime
from pathlib import Path
from google.cloud import storage
from google.oauth2 import service_account


def read_bool_value(env_var: str) -> bool:
    return env_var.lower().strip() in ('true', '1', 't', 'yes')


def main():
    # Path to the backup file inside the container
    file_name = os.environ['BACKUP_FILE_NAME'].strip()
    backups_dir = os.environ['IN_CONTAINER_BACKUPS_DIR'].strip()
    blob_dir_path = os.environ.get('BACKUP_FILE_BLOB_DIR_PATH', "").strip().lstrip("/").rstrip("/")
    max_backup_files = os.environ['MAX_BACKUP_FILES'].strip() 
    bucket_name = os.environ['BUCKET_NAME'].strip()
    credentials_path = os.environ['GCLOUD_STORAGE_CREDENTIALS_PATH'].strip()
    override_files = read_bool_value(os.environ.get("OVERRIDE_FILES", "False").strip())
    if not file_name:
        raise ValueError("BACKUP_FILE_PATH not set")
    if not backups_dir:
        raise ValueError("IN_CONTAINER_BACKUPS_DIR not set")
    if not bucket_name:
        raise ValueError("BUCKET_NAME not set")
    if not credentials_path:
        raise ValueError("GCLOUD_STORAGE_CREDENTIALS_PATH not set")
    if not max_backup_files:
        raise ValueError("MAX_BACKUP_FILES not set")
    
    max_backup_files = int(max_backup_files)

    if max_backup_files <= 0:
        raise ValueError(f"max_backup_files is smaller or equal to zero")

    file_ext_with_dot = ''.join(Path(file_name).suffixes)
    blob_path = Path(blob_dir_path) / f"autobackup_{datetime.today().strftime('%Y%m%d_%H%M%S')}{file_ext_with_dot}"

    full_file_path = Path(backups_dir) / file_name
    client = storage.Client(
        credentials=service_account.Credentials.from_service_account_file(
            credentials_path))
    bucket = client.bucket(bucket_name)

    # AFAIK/UNVERIFIED 2025 June 25th, can list at most 1000 blobs, use fields with nextPageToken to list more
    # see https://googleapis.dev/python/google-api-core/2.11.0/page_iterator.html
    blobs_in_blob_dir: list[storage.Blob] = list(client.list_blobs(  
        bucket_or_name=bucket,           
        prefix=blob_dir_path, 
        delimiter="/"
    ))

    regex_str = r"autobackup_\d{8}_\d{6}"
    
    if blob_dir_path:
        regex_str = rf"^{blob_dir_path}/" + regex_str
    pattern = re.compile(regex_str)
    print(f"Regex pattern: {regex_str}")
    files_in_blob_dir = []
    for x in blobs_in_blob_dir:
        if x.name and x.time_created:
            if pattern.match(x.name):
                files_in_blob_dir.append(x)
        else:
            raise RuntimeError("Blob has no attribute name or time_created")
    files_in_blob_dir = sorted(
        files_in_blob_dir,
        key=lambda x: x.time_created)    
    if len(files_in_blob_dir) >= max_backup_files:
        while len(files_in_blob_dir) >= max_backup_files:    
            print(f"delete oldest backup file: {files_in_blob_dir[0].name}")        
            files_in_blob_dir[0].delete()
            files_in_blob_dir.pop(0)
            
    blob = bucket.blob(blob_path.as_posix())

    if blob.exists():
        print(f"Blob exists already in gs://{bucket_name}/{blob_path.as_posix()}")
        if not override_files:
            raise ValueError("Option override_files is set to False")
        print(f"Overwrite file...")
    blob.upload_from_filename(full_file_path.as_posix())
    print(f"Uploaded {full_file_path.as_posix()} to gs://{bucket_name}/{blob_path.as_posix()}")


if __name__ == "__main__":
    main()

