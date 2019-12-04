## Heroku Buildpack: heroku-pg-dump-to-s3

Capture Heroku Postgres backup with pg_dump and copy it to an s3 bucket. This buildpack installs the AWS CLI as a dependency.

### Installation

Add this buildpack to your Heroku app

```
heroku buildpacks:add https://github.com/sealocal/heroku-pg-dump-to-s3 --app <your_app>
```

### Configure environment variables

```
heroku config:add AWS_ACCESS_KEY_ID=someaccesskey --app <your_app>
heroku config:add AWS_SECRET_ACCESS_KEY=supermegasecret --app <your_app>
heroku config:add AWS_DEFAULT_REGION=eu-central-1 --app <your_app>
heroku config:add S3_BUCKET_PATH=your-bucket --app <your_app>
heroku config:add S3_BUCKET_PATH=your-bucket --app <your_app>
heroku config:add DB_BACKUP_ENC_KEY=password --app <your_app>
```

Go to settings page of your Heroku application and add Config Var `DBURL_FOR_BACKUP` with the same value as var `DATABASE_URL`. This is our DB connection string.

### Heroku Scheduler Addon

Add the Heroku Scheduler addon to your app

```
heroku addons:create scheduler --app <your_app>
```

Open the Heroku Scheduler addon page in the browser

```
heroku addons:open scheduler --app <your_app>
```

In the browser, add a job to be scheduled, pasting the command below as the Run Command to be invoked, and set the schedule to your preference.

```
bash /app/vendor/backup.sh -db <somedbname>
```

The `db` argument is used to build the filename of the Postgres dump.

### Debugging

If a backup is not successfully uploaded, you can [review the output of the job in the logs](https://devcenter.heroku.com/articles/scheduler#inspecting-output).

```
heroku logs -t --app <your_app> | grep 'backup.sh'
heroku logs --ps scheduler.x --app <you_app>
```
