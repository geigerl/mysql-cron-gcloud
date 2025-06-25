# mysql-cron-gcloud

Cronjob to upload database backups (for example created by https://github.com/fradelg/docker-mysql-cron-backup) to Google Cloud Storage.

Read the code yourself, before you use it. Make backups before usage. Use at own risk.

## Dependencies
- docker base image from python: https://hub.docker.com/_/python/
- supercronic: https://github.com/aptible/supercronic
- google storage python SDK: https://pypi.org/project/google-cloud-storage/
- docker (obviously)