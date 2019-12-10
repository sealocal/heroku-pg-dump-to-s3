#!/bin/bash

PYTHONHOME=/app/vendor/awscli/

Green='\033[0;32m'
EC='\033[0m'

EXPIRATION="30"
EXPIRATION_DATE=$(date --date="$EXPIRATION days" --iso-8601=seconds)
TIMESTAMP=$(date --iso-8601=seconds)

# Exit this script immediately if a command exits with a non-zero status
set -e

while [[ $# -gt 1 ]]
do
key="$1"

# Parse command-line arguments for this script
case $key in
    -exp|--expiration)
    EXPIRATION="$2"
    shift
    ;;
    -db|--dbname)
    DBNAME="$2"
    shift
    ;;
esac
shift
done

DBNAME=${DBNAME:='database'}
FILENAME="${DBNAME}_${TIMESTAMP}"

if [[ -z "$DBNAME" ]]; then
  echo "Missing DBNAME variable"
  exit 1
fi
if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
  echo "Missing AWS_ACCESS_KEY_ID variable"
  exit 1
fi
if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo "Missing AWS_SECRET_ACCESS_KEY variable"
  exit 1
fi
if [[ -z "$AWS_DEFAULT_REGION" ]]; then
  echo "Missing AWS_DEFAULT_REGION variable"
  exit 1
fi
if [[ -z "$S3_BUCKET_PATH" ]]; then
  echo "Missing S3_BUCKET_PATH variable"
  exit 1
fi
if [[ -z "$DATABASE_URL" ]]; then
  echo "Missing DATABASE_URL variable"
  exit 1
fi
if [[ -z "$DB_BACKUP_ENC_KEY" ]]; then
  echo "Missing DB_BACKUP_ENC_KEY variable"
  exit 1
fi

printf "${Green}Dump backup of DATABASE_URL ...${EC}\n"

# Borrow pg_dump flags from pg:dump per heroku support article
# https://help.heroku.com/7U1BTYHB/how-can-i-take-a-logical-backup-of-large-heroku-postgres-databases
time pg_dump \
  --no-acl --no-owner --quote-all-identifiers \
  --format=plain --compress=4 \
  $DATABASE_URL > ./"${FILENAME}"_plain_format.sql.gz

# Encrypt the plain format backup
openssl enc -aes-256-cbc -e -pass "env:DB_BACKUP_ENC_KEY" \
  -in ./"${FILENAME}"_plain_format.sql.gz \
  -out /tmp/"${FILENAME}"_plain_format.gz.enc

printf "${Green}Copy Postgres dump to AWS S3 at S3_BUCKET_PATH...${EC}\n"
time /app/vendor/awscli/bin/aws s3 cp /tmp/"${FILENAME}"_plain_format.gz.enc s3://$S3_BUCKET_PATH/$DBNAME/"${FILENAME}"_plain_format.gz.enc --expires $EXPIRATION_DATE

# Remove the database dump(s) from the app server
rm -v /tmp/"${FILENAME}"_plain_format.gz.enc ./"${FILENAME}"_plain_format.sql.gz

