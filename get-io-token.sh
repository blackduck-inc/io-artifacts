#!/bin/sh

# Copyright (c) 2024 Black Duck Software, Inc. All rights reserved worldwide.

for i in "$@"; do
    case "$i" in
    --io.url=*) io_url="${i#*=}" ;;
    --login.id=*) login_id="${i#*=}" ;;
    --password=*) password="${i#*=}" ;;
    --token.name=*) token_name="${i#*=}" ;;
    *) ;;
    esac
done

loginResponse=$(curl -D cookie.txt --location --request POST "$io_url/api/auth/login" \
--header 'Content-Type: application/json' \
--data-raw '{
    "loginId": '\"$login_id\"',
    "password": '\"$password\"'
}');

sed -n 's/.*access_token*= *//p' cookie.txt > line.txt
access_token=$(sed 's/;.*//' line.txt)

response=$(curl --location --request POST "$io_url/api/auth/tokens" \
--header "Authorization: Bearer $access_token" \
--header 'Content-Type: application/json' \
-w "%{http_code}" \
-o output.json \
--data-raw '{
	"name": '\"$token_name\"'
}');

if [ "$response" != 200 ] && [ "$response" != 201 ]; then
	cat output.json
	printf "\nError: API /api/auth/tokens returned ${response}"
	exit 1
fi

userToken=$(jq -r '.token' output.json)
echo "IO_ACCESS_TOKEN: $userToken"

