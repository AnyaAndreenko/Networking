#!/bin/bash

BUCKET="devops-ann-bucket-secure"

yc storage cp index.html s3://$BUCKET/index.html
yc storage cp image.jpg s3://$BUCKET/image.jpg